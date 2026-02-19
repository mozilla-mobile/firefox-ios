# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.transforms.task import payload_builder
from taskgraph.util.schema import taskref_or_string
from voluptuous import Optional, Required

@payload_builder(
    "scriptworker-tree",
    schema={
        Required("bump"): bool,
        Optional("bump-files"): [str],
        Optional("push"): bool,
        Optional("force-dry-run"): bool,
        Optional("branch"): str,
        Optional("next-version"): str,
        Optional("create-branch-info"): {
            "branch-name": str
        },
    },
)
def build_version_bump_payload(config, task, task_def):
    worker = task["worker"]
    task_def["tags"]["worker-implementation"] = "scriptworker"

    scopes = task_def.setdefault("scopes", [])
    scope_prefix = f"project:mobile:{config.params['project']}:treescript:action"
    task_def["payload"] = {}

    if "bump" in worker:
        if not worker["bump-files"]:
            raise Exception("Version Bump requested without bump-files")

        bump_info = {}
        # Next version could come from either shipit or automatically from version bump transform
        bump_info["next_version"] = config.params.get("next_version") or worker.get("next-version")
        bump_info["files"] = worker["bump-files"]
        task_def["payload"]["version_bump_info"] = bump_info
        scopes.append(f"{scope_prefix}:version_bump")

    if worker.get("push"):
        task_def["payload"]["push"] = True

    if worker.get("force-dry-run"):
        task_def["payload"]["dry_run"] = True

    if worker.get("branch"):
        task_def["payload"]["branch"] = worker["branch"]

    if worker.get("create-branch-info"):
        task_def["payload"]["create_branch_info"] = {
            "branch_name": worker["create-branch-info"]["branch-name"],
        }
        scopes.append(f"{scope_prefix}:create_branch")


@payload_builder(
    "scriptworker-github",
    schema={
        Optional("upstream-artifacts"): [
            {
                Required("taskId"): taskref_or_string,
                Required("taskType"): str,
                Required("paths"): [str],
            }
        ],
        Optional("artifact-map"): [object],
        Required("action"): str,
        Required("git-tag"): str,
        Required("git-revision"): str,
        Required("github-project"): str,
        Required("is-prerelease"): bool,
        Optional("release-body"): str,
        Required("release-name"): str,
    },
)
def build_github_release_payload(config, task, task_def):
    worker = task["worker"]

    task_def["tags"]["worker-implementation"] = "scriptworker"

    task_def["payload"] = {
        "artifactMap": worker.get("artifact-map", {}),
        "gitTag": worker["git-tag"],
        "gitRevision": worker["git-revision"],
        "isPrerelease": worker["is-prerelease"],
        "releaseBody": worker.get("release-body"),
        "releaseName": worker["release-name"],
        "upstreamArtifacts": worker.get("upstream-artifacts", []),
    }

    scope_prefix = config.graph_config["scriptworker"]["scope-prefix"]
    task_def["scopes"].extend(
        [
            "{}:github:project:{}".format(scope_prefix, worker["github-project"]),
            "{}:github:action:{}".format(scope_prefix, worker["action"]),
        ]
    )


@payload_builder(
    "scriptworker-shipit-release",
    schema={
        Required("branch"): str,
        Required("phase"): str,
        Required("product"): str,
        Required("revision"): str,
        Required("version"): str,
    }
)
def build_shipit_release_payload(config, task, task_def):
    task_def["payload"] = {
        "product": task["worker"]["product"],
        "branch": task["worker"]["branch"],
        "phase": task["worker"]["phase"],
        "version": task["worker"]["version"],
        "cron_revision": task["worker"]["revision"],
    }

@payload_builder(
    "scriptworker-shipit-merge",
    schema={
        Required("merge-automation-id"): int,
    }
)
def build_shipit_release_payload(config, task, task_def):
    task_def["payload"] = {
        "automation_id": task["worker"]["merge-automation-id"],
    }
