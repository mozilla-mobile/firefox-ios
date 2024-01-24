# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.transforms.base import TransformSequence


transforms = TransformSequence()


@transforms.add
def set_run_config(config, tasks):
    for task in tasks:
        run = task.setdefault("run", {})
        run.setdefault("using", "run-commands")
        run.setdefault("use-caches", False)
        run["secrets"] = [{
            "name": "project/mobile/firefox-ios/bitrise",
            "key": "api_key",
            "path": ".bitrise_token",
        }]

        yield task


_ARTIFACTS_DIRECTORY = "/builds/worker/artifacts"


@transforms.add
def set_worker_config(config, tasks):
    for task in tasks:
        worker = task.setdefault("worker", {})
        artifacts = worker.setdefault("artifacts", [])

        artifacts.append({
            "type": "file",
            "name": "public/logs/bitrise.log",
            "path": f"{_ARTIFACTS_DIRECTORY}/bitrise.log",
        })

        for locale in task.get("attributes", {}).get("chunk_locales", []):
            artifacts.append({
                "type": "file",
                "name": f"public/screenshots/{locale}.zip",
                "path": f"{_ARTIFACTS_DIRECTORY}/{locale}.zip",
            })

        worker.setdefault("docker-image", {"in-tree": "screenshots"})
        worker.setdefault("max-run-time", 10800)

        task.setdefault("worker-type", "bitrise")

        yield task


@transforms.add
def add_bitrise_command(config, tasks):
    for task in tasks:
        commands = task["run"].setdefault("commands", [])
        workflow = task.pop("bitrise-workflow")

        command = [
            "python3",
            "taskcluster/scripts/bitrise-schedule.py",
            "--token-file", ".bitrise_token",
            "--branch", config.params["head_ref"],
            "--commit", config.params["head_rev"],
            "--workflow", workflow,
            "--artifacts-directory", _ARTIFACTS_DIRECTORY
        ]

        for locale in task.get("attributes", {}).get("chunk_locales", []):
            command.extend(["--importLocales", locale])

        derived_data_path = task.pop("build-derived-data-path", "")
        if derived_data_path:
            command.extend(["--derived-data-path", derived_data_path])

        commands.append(command)

        yield task

# Commented functuion due to issue #7248 causing less screenshots taken
# @transforms.add
# def add_screenshot_checks_command(config, tasks):
#    for task in tasks:
#        commands = task["run"]["commands"]

#        command = [
#            "python3",
#            "taskcluster/scripts/check-screenshots.py",
#            "--artifacts-directory", _ARTIFACTS_DIRECTORY,
#            "--screenshots-configuration", "l10n-screenshots-config.yml",
#        ]

#        for locale in task["attributes"]["chunk_locales"]:
#            command.extend(["--importLocales", locale])

#        commands.append(command)

#        yield task
