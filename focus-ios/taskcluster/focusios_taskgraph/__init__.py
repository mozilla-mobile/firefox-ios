# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import absolute_import, print_function, unicode_literals

import os
import re

from importlib import import_module
from six import text_type
from voluptuous import All, Any, Range, Required

from taskgraph.parameters import extend_parameters_schema


def register(graph_config):
    """
    Import all modules that are siblings of this one, triggering decorators in
    the process.
    """
    _import_modules(["job"])


def _import_modules(modules):
    for module in modules:
        import_module(".{}".format(module), package=__name__)
