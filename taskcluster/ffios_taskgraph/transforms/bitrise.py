# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.transforms.base import TransformSequence
from taskgraph.transforms.task import payload_builders
from taskgraph.util.schema import Schema
from voluptuous import Extra, Optional, Required

transforms = TransformSequence()

# Defined in `mozilla_taskgraph.worker_types`.
worker_schema = payload_builders["scriptworker-bitrise"].schema["bitrise"]
bitrise_schema = Schema({
    Required("bitrise"): {
        Required("workflows"): worker_schema["workflows"],
        Optional("artifact_prefix"): worker_schema["artifact_prefix"],
        Optional("build_params"): worker_schema["build_params"],
        Optional("env"): worker_schema["env"],
    },
    Extra: object,
})

transforms.add_validate(bitrise_schema)


@transforms.add
def set_bitrise_app(config, tasks):
    for task in tasks:
        task["bitrise"]["app"] = config.params["project"]
        yield task


@transforms.add
def set_build_params(config, tasks):
    build_params = {}

    if config.params["commit_message"]:
        build_params["commit_message"] = config.params["commit_message"]

    if config.params["pull_request_number"]:
        build_params["pull_request_id"] = config.params["pull_request_number"]

    if not build_params:
        yield from tasks
    else:
        for task in tasks:
            task["bitrise"].setdefault("build_params", {}).update(build_params)
            yield task


@transforms.add
def add_worker(config, tasks):
    for task in tasks:
        worker = task.setdefault("worker", {})
        worker["bitrise"] = task.pop("bitrise")
        yield task
