# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
"""
Add the right git branch configuration to the worker definition
"""

from mozilla_version.ios import MobileIosVersion
from taskgraph.transforms.base import TransformSequence

transforms = TransformSequence()

@transforms.add
def version_bump_task(config, tasks):
    for task in tasks:
        if "create-branch-info" in task["worker"]:
            version = MobileIosVersion.parse(config.params["version"])
            task["worker"]["create-branch-info"]["branch-name"] = (
                f"release/v{version.major_number}.{version.minor_number}"
            )

        task["worker"]["next-version"] = config.params["next_version"] or config.params["version"]
        task["worker"].update(branch=config.params["head_ref"])

        if config.params.get("merge_config", {}).get("force-dry-run"):
            task["worker"]["force-dry-run"] = True

        yield task
