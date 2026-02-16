# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
"""
Add the right git branch configuration to the worker definition
"""

from pathlib import Path
from taskgraph.transforms.base import TransformSequence
from mozilla_version.ios import MobileIosVersion

transforms = TransformSequence()

@transforms.add
def version_bump_task(config, tasks):
    for task in tasks:
        versionfile = Path(__file__).parent.parent.parent.parent / "version.txt"
        with open(versionfile) as fd:
            version = MobileIosVersion.parse(fd.readline())

        if "create-branch-info" in task["worker"]:
            # We need to default to major here so taskgraph full can produce a valid task
            behavior = config.params.get("merge_config", {}).get("behavior", "major")
            if behavior == "major":
                version_string = f"release/v{version.major_number}"
                version = version.bump("major_number")
            elif behavior == "minor":
                version_string = f"release/v{version.major_number}.{version.minor_number}"
                version = version.bump("minor_number")
            else:
                raise Exception(f"Unknown merge-automation behavior: {behavior}")
            task["worker"]["create-branch-info"]["branch-name"] = version_string

        task["worker"]["next-version"] = str(version)
        task["worker"].update(branch=config.params["head_ref"])
        yield task
