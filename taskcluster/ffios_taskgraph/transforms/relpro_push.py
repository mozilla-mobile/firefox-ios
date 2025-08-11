from taskgraph.transforms.base import TransformSequence
from taskgraph.util.schema import resolve_keyed_by


transforms = TransformSequence()


@transforms.add
def resolve_keyed_by_build_type(config, tasks):
    for task in tasks:
        resolve_keyed_by(
            task,
            "treeherder.symbol",
            task["name"],
            **{
                "build-type": task["attributes"]["build-type"],
                "product-variant": task["attributes"].get("product-variant"),
            },
        )
        build_type = task["attributes"]["build-type"]
        is_focus = task["attributes"]["product-type"] == "focus"
        dependency_label = (
            task["attributes"]["product-variant"] if is_focus else build_type
        )

        for workflow in task["worker"]["bitrise"]["workflows"]:
            for params in workflow.values():
                param = {
                    "BUILD_TASK_ID": {"task-reference": f"<promote-{dependency_label}>"}
                }
                if is_focus:
                    param["API_BITRISE_SCHEME"] = task["attributes"][
                        "product-variant"
                    ].capitalize()
                params.append(param)

        yield task
