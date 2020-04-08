#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import argparse
import asyncio
import logging
import sys

from aiohttp_retry import RetryClient


log = logging.getLogger(__name__)

BITRISE_APP_SLUG_ID = "6c06d3a40422d10f"
BITRISE_URL_TEMPLATE = "https://api.bitrise.io/v0.1/apps/" + BITRISE_APP_SLUG_ID + "/{suffix}"


class TaskException(Exception):
    def __init__(self, *args, exit_code=1):
        """Initialize ScriptWorkerTaskException.
        Args:
            *args: These are passed on via super().
            exit_code (int, optional): The exit_code we should exit with when
                this exception is raised.  Defaults to 1 (failure).
        """
        self.exit_code = exit_code
        super(Exception, self).__init__(*args)


def sync_main(
    loop_function=asyncio.get_event_loop,
):
    """
    This function sets up the basic needs for a script to run. More specifically:
        * it initializes the logging
        * it creates the asyncio event loop so that `async_main` can run
    Args:
        loop_function (function, optional): the function to call to get the
            event loop; here for testing purposes. Defaults to
            ``asyncio.get_event_loop``.
    """
    _init_logging()

    parser = argparse.ArgumentParser(description="Generate a screenshot by delegating the work to bitrise.io")

    parser.add_argument("--token-file", required=True, type=argparse.FileType("r"), help="file that contains the bitrise.io token")
    parser.add_argument("--branch", required=True, help="the git branch to generate screenshots from")
    parser.add_argument("--commit", required=True, help="the git commit hash to generate screenshots from")
    parser.add_argument("--locale", required=True, help="locale to generate the screenshots for")

    result = parser.parse_args()

    token = result.token_file.read().strip()
    if token.rstrip() == "faketoken":
        log.warn('"faketoken" detected. Not uploading anything to the service.')
        sys.exit(0)

    loop = loop_function()
    loop.run_until_complete(_handle_asyncio_loop(
        async_main, token, result.branch, result.commit, result.locale
    ))


def _init_logging():
    logging.basicConfig(
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        level=logging.DEBUG,
    )


async def _handle_asyncio_loop(async_main, token, branch, commit, locale):
    try:
        await async_main(token, branch, commit, locale)
    except TaskException as exc:
        log.exception("Failed to run task")
        sys.exit(exc.exit_code)


async def async_main(token, branch, commit, locale):
    headers = {"Authorization": token}
    async with RetryClient(headers=headers) as client:
        build_slug = await schedule_build(client, branch, commit, locale)
        log.info("Created new job. Slug: {}".format(build_slug))

        try:
            await wait_for_job_to_finish(client, build_slug)
            log.info("Job {} is successful. Retrieving artifacts...".format(build_slug))
            await download_artifacts(client, build_slug)
        finally:
            log.info("Retrieving bitrise log...")
            await download_log(client, build_slug)


async def schedule_build(client, branch, commit, locale):
    url = BITRISE_URL_TEMPLATE.format(suffix="builds")
    data = {
        "hook_info": {
            "type": "bitrise",
        },
        "build_params": {
            "branch": branch,
            "commit_hash": commit,
            "environments": [{
                "mapped_to": "MOZ_LOCALE",
                "value": locale,
            }],
            "workflow_id": "jlorenzo_L10nScreenshotsTests",
        },
    }

    response = await do_http_request_json(client, url, method="post", json=data)
    if response.get("status", "") != "ok":
        raise Exception("Bitrise status is not ok. Got: {}".format(response))

    return response["build_slug"]


async def wait_for_job_to_finish(client, build_slug):
    suffix = "builds/{}".format(build_slug)
    url = BITRISE_URL_TEMPLATE.format(suffix=suffix)

    while True:
        response = await do_http_request_json(client, url)
        if response["data"]["finished_at"]:
            log.info("Job {} is now finished, checking result...".format(build_slug))
            break
        else:
            log.info("Job {} is still running. Waiting another minute...".format(build_slug))
            await asyncio.sleep(60)

    if response["data"]["status_text"] != "success":
        if response["data"]["status_text"] == "error":
            raise TaskException("Job {} errored! Got: {}".format(build_slug, response), exit_code=1)
        if response["data"]["status_text"] == "aborted":
            raise TaskException("Job {} was aborted. Got: {}".format(build_slug, response), exit_code=2)
        raise TaskException("Job {} is finished but not successful. Got: {}".format(build_slug, response), exit_code=3)


async def download_artifacts(client, build_slug):
    suffix = "builds/{}/artifacts".format(build_slug)
    url = BITRISE_URL_TEMPLATE.format(suffix=suffix)

    response = await do_http_request_json(client, url)

    artifacts_metadata = {
        metadata["slug"]: metadata["title"]
        for metadata in response["data"]
    }

    for artifact_slug, title in artifacts_metadata.items():
        suffix = "builds/{}/artifacts/{}".format(build_slug, artifact_slug)
        url = BITRISE_URL_TEMPLATE.format(suffix=suffix)

        response = await do_http_request_json(client, url)
        download_url = response["data"]["expiring_download_url"]
        await download_file(download_url, title)


async def download_log(client, build_slug):
    suffix = "builds/{}/log".format(build_slug)
    url = BITRISE_URL_TEMPLATE.format(suffix=suffix)

    response = await do_http_request_json(client, url)
    download_url = response["expiring_raw_log_url"]
    await download_file(download_url, "bitrise.log")


CHUNK_SIZE = 128


async def download_file(download_url, file_destination):
    async with RetryClient() as s3_client:
        async with s3_client.get(download_url) as resp:
            with open(file_destination, "wb") as fd:
                while True:
                    chunk = await resp.content.read(CHUNK_SIZE)
                    if not chunk:
                        break
                    fd.write(chunk)

    log.info("'{}' downloaded".format(file_destination))


async def do_http_request_json(client, url, method="get", **kwargs):
    method_and_url = "{} {}".format(method.upper(), url)
    log.debug("Making request {}...".format(method_and_url))

    http_function = getattr(client, method)
    async with http_function(url, **kwargs) as r:
        log.debug("{} returned HTTP code {}".format(method_and_url, r.status))
        response = await r.json()

    log.debug("{} returned JSON {}".format(method_and_url, response))

    return response


__name__ == "__main__" and sync_main()
