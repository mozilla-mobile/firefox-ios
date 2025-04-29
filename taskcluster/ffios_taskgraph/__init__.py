# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from importlib import import_module

from mozilla_taskgraph import register as register_mozilla_taskgraph
from taskgraph.util import schema

schema.EXCEPTED_SCHEMA_IDENTIFIERS.append(
    lambda path: any(
        exc in path for exc in ("['attributes']",)
    )
)


def register(graph_config):
    """
    Import all modules that are siblings of this one, triggering decorators in
    the process.
    """
    # Setup mozilla-taskgraph
    register_mozilla_taskgraph(graph_config)

    _import_modules(["job", "parameters", "routes", "target_tasks", "release_promotion", "worker_types"])


def _import_modules(modules):
    for module in modules:
        import_module(f".{module}", package=__name__)
