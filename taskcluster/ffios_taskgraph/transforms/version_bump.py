# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
"""
Add the right git branch configuration to the worker definition
"""

from taskgraph.transforms.base import TransformSequence

transforms = TransformSequence()

@transforms.add
def add_branch_to_worker_config(config, tasks):
    for task in tasks:
        task["worker"].update(branch=config.params["head_ref"])
        yield task
