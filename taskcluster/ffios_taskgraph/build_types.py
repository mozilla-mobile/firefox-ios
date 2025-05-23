# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.util.dependencies import group_by

BUILD_TYPE_FOR_RELEASE_TYPE = {
    "release": ["beta", "release"],
    "beta": ["beta"],
}

def should_build_type_get_targetted_for_release_type(task, release_type):
    task_build_type = task.attributes.get("build-type")
    target_build_types = BUILD_TYPE_FOR_RELEASE_TYPE[release_type]

    return task_build_type in target_build_types


@group_by("filtered-build-type")
def group_by_filter(config, tasks):
    single_group = []
    release_type = config.params.get("release_type")

    for task in tasks:
        if not should_build_type_get_targetted_for_release_type(task, release_type):
            continue
        single_group.append(task)

    if not single_group:
        return []

    return [single_group]
