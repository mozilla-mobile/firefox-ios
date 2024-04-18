# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.transforms.base import TransformSequence
from taskgraph.util.schema import Schema, taskref_or_string
from voluptuous import Extra, Optional

transforms = TransformSequence()

schema = Schema(
    {
        Optional("attributes"): {
            Optional("chunk_locales"): [str],
            Extra: object,
        },
        Optional("build-derived-data-path"): taskref_or_string,
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
        env = task.setdefault("bitrise", {}).setdefault("env", {})

        # locales
        locales = (
            " ".join(task.get("attributes", {}).get("chunk_locales", [])) or "en-US"
        )
        env["MOZ_LOCALES"] = locales

        # derived data path
        derived_data_path = task.pop("build-derived-data-path", None)
        if derived_data_path:
            env["MOZ_DERIVED_DATA_PATH"] = derived_data_path

        yield task
