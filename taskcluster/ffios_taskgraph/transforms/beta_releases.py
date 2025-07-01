# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from urllib.parse import urlparse
import os.path

from git import Git
from mozilla_version.ios import MobileIosVersion
from taskgraph.transforms.base import TransformSequence
from taskgraph.util.schema import resolve_keyed_by
import requests
import taskgraph


transforms = TransformSequence()

@transforms.add
def resolve_keys(config, tasks):
    for task in tasks:
        for key in ("scopes",):
            resolve_keyed_by(
                task,
                key,
                item_name=task["name"],
                **{
                    "level": config.params["level"],
                }
            )

        yield task


@transforms.add
def resolve_beta_branch_and_head(config, tasks):
    for task in tasks:
        current_release_branch = "[SKIPPED]"
        revision = "[SKIPPED]"
        version = "[SKIPPED]"

        if not taskgraph.fast:
            heads = Git().ls_remote("origin", "refs/heads/release/v*").splitlines()
            branch_heads = dict(head.split('\t')[::-1] for head in heads)
            current_release_head = max(branch_heads, key=lambda branch: float(branch.removeprefix("refs/heads/release/v")))
            revision = branch_heads[current_release_head]
            current_release_branch = current_release_head.removeprefix("refs/heads/")

            repository_url = config.params["base_repository"]
            if "git@" in repository_url:
                path = repository_url.split(":", 1)[1]
            else:
                path = urlparse(repository_url).path.strip("/")

            owner, repo = path.split("/", 1)
            repo = repo.removesuffix(".git")
            req = requests.get(f"https://raw.githubusercontent.com/{owner}/{repo}/{current_release_branch}/version.txt")
            req.raise_for_status()

            version = req.text.strip()
            parsed_version = MobileIosVersion.parse(version)
            if not parsed_version.is_beta:
                print("The latest release branch isn't a beta, not generating a beta release task")
                return

        worker = task.setdefault("worker", {})
        worker["branch"] = current_release_branch
        worker["revision"] = revision
        worker["version"] = version

        yield task

