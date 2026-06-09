# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.transforms.base import TransformSequence
from taskgraph.util.schema import resolve_keyed_by

transforms = TransformSequence()


@transforms.add
def make_task_description(config, tasks):
    merge_config = config.params.get("merge_config", {})
    merge_automation_id = merge_config.get("merge-automation-id")

    if not merge_automation_id:
        return

    for task in tasks:
        resolve_keyed_by(
            task,
            "scopes",
            item_name=task["name"],
            level=config.params["level"],
        )

        task["worker"]["merge-automation-id"] = merge_automation_id

        yield task

