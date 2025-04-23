from taskgraph.transforms.task import payload_builder
from taskgraph.util.schema import taskref_or_string
from voluptuous import Optional, Required

@payload_builder(
    "scriptworker-tree",
    schema={
        Required("bump"): bool,
        Optional("bump-files"): [str],
        Optional("push"): bool,
        Optional("branch"): str,
    },
)
def build_version_bump_payload(config, task, task_def):
    worker = task["worker"]
    task_def["tags"]["worker-implementation"] = "scriptworker"

    scopes = task_def.setdefault("scopes", [])
    scope_prefix = f"project:mobile:{config.params['project']}:treescript:action"
    task_def["payload"] = {}

    if worker["bump"]:
        if not worker["bump-files"]:
            raise Exception("Version Bump requested without bump-files")

        bump_info = {}
        bump_info["next_version"] = config.params["next_version"]
        bump_info["files"] = worker["bump-files"]
        task_def["payload"]["version_bump_info"] = bump_info
        scopes.append(f"{scope_prefix}:version_bump")

    if worker["push"]:
        task_def["payload"]["push"] = True

    if worker.get("force-dry-run"):
        task_def["payload"]["dry_run"] = True

    if worker.get("branch"):
        task_def["payload"]["branch"] = worker["branch"]


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

