#!/usr/bin/env python3

import asyncio
import json
import logging
import os
from datetime import datetime, timezone
from functools import wraps, partial
from pathlib import Path
from urllib import request


log = logging.getLogger(__name__)
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.DEBUG,
)

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
if not GITHUB_TOKEN:
    log.warning(
        "GITHUB_TOKEN not set. This script may hit the default rate limit of 60 requests per hour."
    )

ISSUES_AND_PULL_REQUESTS_URL = "https://api.github.com/repos/{repo_owner}/{repo_name}/issues?state=all&direction=asc&per_page=100&page={page}"
REPO_NAMES = ("android-components", "fenix", "focus-android", "firefox-android")
NUMBER_TYPES = ("pulls", "issues")
DATA_DIR = (Path(__file__).parent / "data").absolute()


def async_wrap(func):
    @wraps(func)
    async def run(*args, loop=None, executor=None, **kwargs):
        if loop is None:
            loop = asyncio.get_event_loop()
        pfunc = partial(func, *args, **kwargs)
        return await loop.run_in_executor(executor, pfunc)

    return run


async def query_github(page, repo_owner, repo_name, last_updated):
    url = ISSUES_AND_PULL_REQUESTS_URL.format(
        page=page,
        repo_owner=repo_owner,
        repo_name=repo_name,
    )
    if last_updated is not None:
        since = last_updated.isoformat(timespec="seconds").replace("+00:00", "Z")
        url = f"{url}&since={since}"
    log.debug(url)
    headers = {
        "Accept": "application/vnd.github+json",
    }
    if GITHUB_TOKEN:
        headers["Authorization"] = f"Bearer {GITHUB_TOKEN}"

    req = request.Request(
        url,
        headers=headers,
    )
    opened_url = request.urlopen(req)
    async_read = async_wrap(opened_url.read)
    data = await async_read()
    encoding = opened_url.info().get_content_charset("utf-8")
    return json.loads(data.decode(encoding))


async def get_all_new_numbers(repo_owner, repo_name, last_updated):
    log.info(f"Getting all issues and PRs for {repo_name}...")
    page = 1
    all_new_numbers = {
        "issues": [],
        "pulls": [],
    }

    while True:
        new_items = await query_github(page, repo_owner, repo_name, last_updated)
        if not new_items:
            break
        for item in new_items:
            numbers_list = (
                all_new_numbers["pulls"]
                if "pull_request" in item.keys()
                else all_new_numbers["issues"]
            )
            numbers_list.append(item["number"])
        page += 1

    log.info(
        f"Got {len(all_new_numbers['pulls'])} new pulls and {len(all_new_numbers['issues'])} new issues for {repo_name}!"
    )
    return all_new_numbers


async def build_dict_async(keys, async_func, *async_func_args, **async_func_kwargs):
    tasks = []
    for key in keys:
        tasks.append(async_func(key, *async_func_args, **async_func_kwargs))

    results = await asyncio.gather(*tasks)

    return dict(zip(keys, results))


async def get_all_new_numbers_for_repo(repo_name, last_updated):
    return await get_all_new_numbers("mozilla-mobile", repo_name, last_updated)


async def async_main(last_updated):
    return await build_dict_async(
        REPO_NAMES, get_all_new_numbers_for_repo, last_updated
    )


def _simple_merge_dicts(dict1, dict2):
    for repo_name in REPO_NAMES:
        for number_type in NUMBER_TYPES:
            dict2.setdefault(repo_name, {}).setdefault(number_type, [])
            numbers_list = dict1.setdefault(repo_name, {}).setdefault(number_type, [])
            numbers_list.extend(dict2[repo_name][number_type])
            dict1[repo_name][number_type] = sorted(list(set(numbers_list)))


def sync_main():
    time_at_startup = datetime.now(timezone.utc)
    with open(DATA_DIR / "repo-numbers.json") as f:
        repo_numbers = json.load(f)

    last_updated = repo_numbers.get("$last_updated")
    if last_updated:
        last_updated = datetime.fromisoformat(last_updated)

    all_new_numbers = asyncio.run(async_main(last_updated))

    _simple_merge_dicts(repo_numbers, all_new_numbers)
    repo_numbers["$last_updated"] = time_at_startup.isoformat(timespec="seconds")

    with open(DATA_DIR / "repo-numbers.json", "w") as f:
        json.dump(repo_numbers, f, sort_keys=True, indent=4)


__name__ == "__main__" and sync_main()
