# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import absolute_import, print_function, unicode_literals

import time

from taskgraph.transforms.task import index_builder

# Please ping the l10n team and contributors if these routes change.
# In the future, notifying consumers may be easier (https://bugzilla.mozilla.org/show_bug.cgi?id=1548810), but
# we need to remember to tell users for the time being
SCREENSHOTS_ROUTE_TEMPLATES = [
    "index.{trust-domain}.v2.{project}.{variant}.latest.{locale}",
    "index.{trust-domain}.v2.{project}.{variant}.{build_date}.revision.{head_rev}.{locale}",
    "index.{trust-domain}.v2.{project}.{variant}.{build_date}.latest.{locale}",
    "index.{trust-domain}.v2.{project}.{variant}.revision.{head_rev}.{locale}",
]


@index_builder("l10n-screenshots")
def add_signing_indexes(config, task):
    if config.params["level"] != "3":
        return task

    subs = config.params.copy()
    subs["build_date"] = time.strftime(
        "%Y.%m.%d", time.gmtime(config.params["build_date"])
    )
    subs["trust-domain"] = config.graph_config["trust-domain"]
    subs["variant"] = "l10n-screenshots"

    routes = task.setdefault("routes", [])
    for tpl in SCREENSHOTS_ROUTE_TEMPLATES:
        for locale in task["attributes"]["chunk_locales"]:
            subs["locale"] = locale
            routes.append(tpl.format(**subs))

    task["routes"] = _deduplicate_and_sort_sequence(routes)

    return task


def _deduplicate_and_sort_sequence(sequence):
    return sorted(list(set(sequence)))
