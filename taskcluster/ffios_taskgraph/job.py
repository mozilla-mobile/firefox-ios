# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from taskgraph.transforms.run import run_task_using, configure_taskdesc_for_run
from taskgraph.util.schema import Schema, taskref_or_string
from voluptuous import Required, Optional

from shlex import quote as shell_quote

secret_schema = {
    Required("name"): str,
    Required("path"): str,
    Required("key"): str,
    Optional("json"): bool,
}

run_commands_schema = Schema({
    Required("using"): "run-commands",
    Optional("pre-commands"): [[str]],
    Required("commands"): [[taskref_or_string]],
    Required("workdir"): str,
    Optional("use-caches"): bool,
    Optional("secrets"): [secret_schema],
})


@run_task_using("docker-worker", "run-commands", schema=run_commands_schema)
def configure_run_commands_schema(config, task, taskdesc):
    run = task["run"]
    pre_commands = run.pop("pre-commands", [])
    pre_commands += [
        _generate_secret_command(secret) for secret in run.get("secrets", [])
    ]

    all_commands = pre_commands + run.pop("commands", [])

    run["command"] = _convert_commands_to_string(all_commands)
    _inject_secrets_scopes(run, taskdesc)
    _set_run_task_attributes(task)
    configure_taskdesc_for_run(config, task, taskdesc, task["worker"]["implementation"])


def _generate_secret_command(secret):
    secret_command = [
        "python3",
        "taskcluster/scripts/get-secret.py",
        "-s", secret["name"],
        "-k", secret["key"],
        "-f", secret["path"],
    ]
    if secret.get("json"):
        secret_command.append("--json")

    return secret_command


def _convert_commands_to_string(commands):
    should_artifact_reference = False
    should_task_reference = False

    sanitized_commands = []
    for command in commands:
        sanitized_parts = []
        for part in command:
            if isinstance(part, dict):
                if "artifact-reference" in part:
                    part_string = part["artifact-reference"]
                    should_artifact_reference = True
                elif "task-reference" in part:
                    part_string = part["task-reference"]
                    should_task_reference = True
                else:
                    raise ValueError(f'Unsupported dict: {part}')
            else:
                part_string = part

            sanitized_parts.append(part_string)
        sanitized_commands.append(sanitized_parts)

    shell_quoted_commands = [" ".join(map(shell_quote, command)) for command in sanitized_commands]
    full_string_command = " && ".join(shell_quoted_commands)

    if should_artifact_reference and should_task_reference:
        raise NotImplementedError('"arifact-reference" and "task-reference" cannot be both used')
    elif should_artifact_reference:
        return {"artifact-reference": full_string_command}
    elif should_task_reference:
        return {"task-reference": full_string_command}
    else:
        return full_string_command


def _inject_secrets_scopes(run, taskdesc):
    secrets = run.pop("secrets", [])
    scopes = taskdesc.setdefault("scopes", [])
    new_secret_scopes = ["secrets:get:{}".format(secret["name"]) for secret in secrets]
    new_secret_scopes = list(set(new_secret_scopes))  # Scopes must not have any duplicates
    scopes.extend(new_secret_scopes)


def _set_run_task_attributes(task):
    run = task["run"]
    run["cwd"] = "{checkout}"
    run["using"] = "run-task"
