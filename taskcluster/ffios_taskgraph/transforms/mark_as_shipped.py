from taskgraph.transforms.base import TransformSequence
from taskgraph.util.schema import resolve_keyed_by

transforms = TransformSequence()

@transforms.add
def resolve_keys(config, tasks):
    for task in tasks:
        for key in ("scopes", "treeherder.symbol"):
            resolve_keyed_by(
                task,
                key,
                item_name=task["name"],
                **{
                    "release-type": task["attributes"]["release-type"],
                    "level": config.params["level"],
                }
            )

        yield task

@transforms.add
def add_release_name(config, tasks):
    for task in tasks:
        product = "Firefox-ios" # Shipit capitalizes the product names
        version = config.params.get("version", "[UNKNOWN]")
        build_number = config.params.get("build_number", 1)
        task.setdefault("worker", {})["release-name"] = f"{product}-{version}-build{build_number}"
        yield task
