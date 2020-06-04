# -*- coding: utf-8 -*-

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""
Validates the contents of a Glean ping against the schema.
"""

import functools
import io
import json
from pathlib import Path
import sys

import jsonschema  # type: ignore

from . import util


ROOT_DIR = Path(__file__).parent
SCHEMAS_DIR = ROOT_DIR / "schemas"


@functools.lru_cache(maxsize=1)
def _get_ping_schema(schema_url):
    contents = util.fetch_remote_url(schema_url)
    return json.loads(contents)


def _validate_ping(ins, outs, schema_url):
    schema = _get_ping_schema(schema_url)

    resolver = util.get_null_resolver(schema)

    document = json.load(ins)

    validator_class = jsonschema.validators.validator_for(schema)
    validator = validator_class(schema, resolver=resolver)

    has_error = 0
    for error in validator.iter_errors(document):
        outs.write("=" * 76)
        outs.write("\n")
        outs.write(util.format_error("", "", util.pprint_validation_error(error)))
        outs.write("\n")
        has_error = 1

    return has_error


def validate_ping(ins, outs=None, schema_url=None):
    """
    Validates the contents of a Glean ping.

    :param ins: Input stream or file path to the ping contents to validate
    :param outs: Output stream to write errors to. (Defaults to stdout)
    :param schema_url: HTTP URL or local filesystem path to Glean ping schema.
        Defaults to the current version of the schema in
        mozilla-pipeline-schemas.
    :rtype: int 1 if any errors occurred, otherwise 0.
    """
    if schema_url is None:
        raise TypeError("Missing required argument 'schema_url'")

    if outs is None:
        outs = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

    if isinstance(ins, (str, bytes, Path)):
        with open(ins, "r", encoding="utf-8") as fd:
            return _validate_ping(fd, outs, schema_url=schema_url)
    else:
        return _validate_ping(ins, outs, schema_url=schema_url)
