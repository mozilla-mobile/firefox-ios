# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
"""
Resolve secrets and dummy secrets
"""

from __future__ import absolute_import, print_function, unicode_literals

from taskgraph.transforms.base import TransformSequence


transforms = TransformSequence()


@transforms.add
def add_command(config, tasks):
    for task in tasks:
        commands = task["run"].setdefault("commands", [])
        locale = task.pop("locale")
        commands.append([
            "python3",
            "taskcluster/scripts/generate-screenshots.py",
            "--token-file", ".bitrise_token",
            "--branch", config.params["head_ref"],
            "--commit", config.params["head_rev"],
            "--locale", locale
        ])

        yield task
