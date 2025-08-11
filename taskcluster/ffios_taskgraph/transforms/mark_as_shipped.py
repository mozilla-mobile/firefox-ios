# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
                    "product-type": task["attributes"]["product-type"],
                    "level": config.params["level"],
                }
            )

        yield task

@transforms.add
def add_release_name(config, tasks):
    for task in tasks:
        product = "{}-ios".format(
            task["attributes"]["product-type"].capitalize()
        )  # Shipit capitalizes the product names
        version = config.params.get("version", "[UNKNOWN]")
        build_number = config.params.get("build_number", 1)
        task.setdefault("worker", {})[
            "release-name"
        ] = f"{product}-{version}-build{build_number}"
        yield task
