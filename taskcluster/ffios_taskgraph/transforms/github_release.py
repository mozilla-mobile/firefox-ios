# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
from taskgraph.transforms.base import TransformSequence
from taskgraph.util.schema import resolve_keyed_by

transforms = TransformSequence()

@transforms.add
def resolve_by_keys(config, tasks):
    for task in tasks:
        for key in (
            "worker.github-project",
            "worker.release-name",
            "worker.release-body",
            "worker.is-prerelease",
        ):
            resolve_keyed_by(
                task,
                key,
                item_name=task["name"],
                **{
                    "level": config.params["level"],
                    "release-type": task.get("attributes", {}).get("release-type"),
                }
            )

        yield task

@transforms.add
def build_parameters(config, tasks):
    for task in tasks:
        worker = task.setdefault("worker", {})
        worker["git-revision"] = config.params["head_rev"]

        for field in (
            "release-body",
            "release-name",
            "git-tag",
        ):
            worker[field] = worker[field].format(**config.params)
        yield task
