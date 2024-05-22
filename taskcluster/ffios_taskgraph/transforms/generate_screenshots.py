# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.transforms.base import TransformSequence
from taskgraph.transforms.task import payload_builders
from taskgraph.util.schema import Schema, taskref_or_string
from voluptuous import Extra, Optional, Required

transforms = TransformSequence()

worker_schema = payload_builders["scriptworker-bitrise"].schema["bitrise"]
schema = Schema(
    {
        Optional("attributes"): {
            Optional("chunk_locales"): [str],
            Extra: object,
        },
        Optional("build-derived-data-path"): taskref_or_string,
        Required("bitrise"): {
            Required("workflows"): worker_schema["workflows"],
            Optional("artifact_prefix"): worker_schema["artifact_prefix"],
        },
        Extra: object,
    }
)

transforms.add_validate(schema)


@transforms.add
def set_environment(config, tasks):
    """Sets some environment variables needed by the generate-screenshots
    workflow.
    """
    for task in tasks:
        # locales
        locales = (
            " ".join(task.get("attributes", {}).get("chunk_locales", [])) or "en-US"
        )
        derived_data_path = task.pop("build-derived-data-path", None)

        def _get_default_workflow():
            default_workflow = {"MOZ_LOCALES": locales}
            if derived_data_path:
                default_workflow["MOZ_DERIVED_DATA_PATH"] = derived_data_path
            return default_workflow

        # Create an object with specific workflow configs
        task_workflows = {}
        for workflow_config in task["bitrise"]["workflows"]:
            if isinstance(workflow_config, str):
                task_workflows.setdefault(workflow_config, [])
                task_workflows[workflow_config].append(_get_default_workflow())
            elif isinstance(workflow_config, dict):
                for workflow_id, env_permutations in workflow_config.items():
                    task_workflows.setdefault(workflow_id, [])
                    for env in env_permutations:
                        workflow_env = _get_default_workflow()
                        # Update the workflow env config with data from bitrise.workflow.<workflow_id>
                        workflow_env.update(env)
                        task_workflows[workflow_id].append(workflow_env)

        task["bitrise"]["workflows"] = [task_workflows]
        yield task
