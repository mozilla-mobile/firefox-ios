# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.parameters import Parameters

from taskgraph.actions.registry import register_callback_action
from taskgraph.decision import taskgraph_decision

@register_callback_action(
    name="merge-automation",
    title="Merge Day Automation",
    symbol="${input.behavior}",
    description="Merge repository branches.",
    permission="merge-automation",
    order=500,
    context=[],
    schema=lambda graph_config: {
        "type": "object",
        "properties": {
            "force-dry-run": {
                "type": "boolean",
                "description": "Override other options and do not push changes",
                "default": True,
            },
            "behavior": {
                "type": "string",
                "description": "The type of release promotion to perform.",
                # this enum should be kept in sync with the merge-automation kind
                "enum": [
                    "major",
                    "minor",
                ],
                "default": "major",
            },
            "merge-automation-id": {
                "type": "integer",
                "description": "Shipit merge automation ID for marking as merged.",
            },
        },
        "required": ["behavior"],
    },
)
def merge_automation_action(parameters, graph_config, input, task_group_id, task_id):
    # make parameters read-write
    parameters = dict(parameters)

    parameters["target_tasks_method"] = "merge_automation"
    parameters["merge_config"] = {
        "force-dry-run": input.get("force-dry-run", False),
        "behavior": input.get("behavior", "major"),
    }

    for field in [
        "merge-automation-id",
    ]:
        if input.get(field):
            parameters["merge_config"][field] = input[field]

    parameters["tasks_for"] = "action"
    # make parameters read-only
    parameters = Parameters(**parameters)

    taskgraph_decision({"root": graph_config.root_dir}, parameters=parameters)
