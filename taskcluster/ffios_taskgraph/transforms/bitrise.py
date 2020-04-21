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
def set_run_config(config, tasks):
    for task in tasks:
        run = task.setdefault("run", {})
        run.setdefault("using", "run-commands")
        run.setdefault("use-caches", False)

        run["secrets"] = {
            "by-level": {
                "3": [{
                    "name": "project/mobile/firefox-ios/bitrise",
                    "key": "api_key",
                    "path": ".bitrise_token",
                }],
                "default": [],
            },
        }

        run["dummy-secrets"] = {
            "by-level": {
                "3": [],
                "default": [{
                    "content": "faketoken",
                    "path": ".bitrise_token",
                }],
            },
        }

        yield task


@transforms.add
def set_worker_config(config, tasks):
    for task in tasks:
        locale = task["locale"]

        worker = task.setdefault("worker", {})
        artifacts = worker.setdefault("artifacts", [])

        artifacts.extend([{
            "type": "file",
            "name": "public/logs/bitrise.log",
            "path": "/builds/worker/checkouts/src/bitrise.log",
        }, {
            "type": "file",
            "name": "public/screenshots/{}.zip".format(locale),
            "path": "/builds/worker/checkouts/src/{}.zip".format(locale),
        }])

        worker.setdefault("docker-image", {"in-tree": "screenshots"})
        worker.setdefault("max-run-time", 3600)

        task.setdefault("worker-type", "b-linux")

        yield task


@transforms.add
def add_command(config, tasks):
    for task in tasks:
        commands = task["run"].setdefault("commands", [])
        locale = task.pop("locale")
        workflow = task.pop("bitrise-workflow")

        command = [
            "python3",
            "taskcluster/scripts/bitrise-schedule.py",
            "--token-file", ".bitrise_token",
            "--branch", config.params["head_ref"],
            "--commit", config.params["head_rev"],
            "--workflow", workflow,
            "--locale", locale
        ]

        derived_data_path = task.pop("build-derived-data-path", "")
        if derived_data_path:
            command.extend(["--derived-data-path", derived_data_path])

        commands.append(command)

        yield task
