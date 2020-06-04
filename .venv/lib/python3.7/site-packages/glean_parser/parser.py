# -*- coding: utf-8 -*-

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""
Code for parsing metrics.yaml files.
"""

from collections import OrderedDict
import functools
from pathlib import Path
import textwrap
from typing import Any, Dict, Generator, Iterable, Optional, Tuple, Union

import jsonschema  # type: ignore
from jsonschema.exceptions import ValidationError  # type: ignore

from .metrics import Metric, ObjectTree
from .pings import Ping, RESERVED_PING_NAMES
from . import util


ROOT_DIR = Path(__file__).parent
SCHEMAS_DIR = ROOT_DIR / "schemas"

METRICS_ID = "moz://mozilla.org/schemas/glean/metrics/1-0-0"
PINGS_ID = "moz://mozilla.org/schemas/glean/pings/1-0-0"

FILE_TYPES = {METRICS_ID: "metrics", PINGS_ID: "pings"}


def _update_validator(validator):
    """
    Adds some custom validators to the jsonschema validator that produce
    nicer error messages.
    """

    def required(validator, required, instance, schema):
        if not validator.is_type(instance, "object"):
            return
        missing_properties = set(
            property for property in required if property not in instance
        )
        if len(missing_properties):
            missing_properties = sorted(list(missing_properties))
            yield ValidationError(
                "Missing required properties: {}".format(", ".join(missing_properties))
            )

    validator.VALIDATORS["required"] = required


def _load_file(
    filepath: Path,
) -> Generator[str, None, Tuple[Dict[str, util.JSONType], Optional[str]]]:
    """
    Load a metrics.yaml or pings.yaml format file.
    """
    try:
        content = util.load_yaml_or_json(filepath, ordered_dict=True)
    except Exception as e:
        yield util.format_error(filepath, "", textwrap.fill(str(e)))
        return {}, None

    if content is None:
        yield util.format_error(
            filepath, "", "'{}' file can not be empty.".format(filepath)
        )
        return {}, None

    if not isinstance(content, dict):
        return {}, None

    if content == {}:
        return {}, None

    schema_key = content.get("$schema")
    if not isinstance(schema_key, str):
        raise TypeError("Invalid schema key {}".format(schema_key))

    filetype = FILE_TYPES.get(schema_key)

    for error in validate(content, filepath):
        content = {}
        yield error

    return content, filetype


@functools.lru_cache(maxsize=1)
def _load_schemas() -> Dict[str, Tuple[Any, Any]]:
    """
    Load all of the known schemas from disk, and put them in a map based on the
    schema's $id.
    """
    schemas = {}
    for schema_path in SCHEMAS_DIR.glob("*.yaml"):
        schema = util.load_yaml_or_json(schema_path)
        resolver = util.get_null_resolver(schema)
        validator_class = jsonschema.validators.validator_for(schema)
        _update_validator(validator_class)
        validator_class.check_schema(schema)
        validator = validator_class(schema, resolver=resolver)
        schemas[schema["$id"]] = (schema, validator)
    return schemas


def _get_schema(
    schema_id: str, filepath: Union[str, Path] = "<input>"
) -> Tuple[Any, Any]:
    """
    Get the schema for the given schema $id.
    """
    schemas = _load_schemas()
    if schema_id not in schemas:
        raise ValueError(
            util.format_error(
                filepath,
                "",
                "$schema key must be one of {}".format(", ".join(schemas.keys())),
            )
        )
    return schemas[schema_id]


def _get_schema_for_content(
    content: Dict[str, util.JSONType], filepath: Union[str, Path]
) -> Tuple[Any, Any]:
    """
    Get the appropriate schema for the given JSON content.
    """
    schema_url = content.get("$schema")
    if not isinstance(schema_url, str):
        raise TypeError("Invalid $schema type {}".format(schema_url))
    return _get_schema(schema_url, filepath)


def get_parameter_doc(key: str) -> str:
    """
    Returns documentation about a specific metric parameter.
    """
    schema, _ = _get_schema(METRICS_ID)
    return schema["definitions"]["metric"]["properties"][key]["description"]


def get_ping_parameter_doc(key: str) -> str:
    """
    Returns documentation about a specific ping parameter.
    """
    schema, _ = _get_schema(PINGS_ID)
    return schema["additionalProperties"]["properties"][key]["description"]


def validate(
    content: Dict[str, util.JSONType], filepath: Union[str, Path] = "<input>"
) -> Generator[str, None, None]:
    """
    Validate the given content against the appropriate schema.
    """
    try:
        schema, validator = _get_schema_for_content(content, filepath)
    except ValueError as e:
        yield str(e)
    else:
        yield from (
            util.format_error(filepath, "", util.pprint_validation_error(e))
            for e in validator.iter_errors(content)
        )


def _instantiate_metrics(
    all_objects: ObjectTree,
    sources: Dict[Any, Path],
    content: Dict[str, util.JSONType],
    filepath: Path,
    config: Dict[str, Any],
) -> Generator[str, None, None]:
    """
    Load a list of metrics.yaml files, convert the JSON information into Metric
    objects, and merge them into a single tree.
    """
    global_no_lint = content.get("no_lint", [])

    for category_key, category_val in content.items():
        if category_key.startswith("$"):
            continue
        if category_key == "no_lint":
            continue
        if not config.get("allow_reserved") and category_key.split(".")[0] == "glean":
            yield util.format_error(
                filepath,
                "For category '{}'".format(category_key),
                "Categories beginning with 'glean' are reserved for "
                "Glean internal use.",
            )
            continue
        all_objects.setdefault(category_key, OrderedDict())

        if not isinstance(category_val, dict):
            raise TypeError("Invalid content for {}".format(category_key))

        for metric_key, metric_val in category_val.items():
            try:
                metric_obj = Metric.make_metric(
                    category_key, metric_key, metric_val, validated=True, config=config
                )
            except Exception as e:
                yield util.format_error(
                    filepath,
                    "On instance {}.{}".format(category_key, metric_key),
                    str(e),
                )
                metric_obj = None
            else:
                if (
                    not config.get("allow_reserved")
                    and "all-pings" in metric_obj.send_in_pings
                ):
                    yield util.format_error(
                        filepath,
                        "On instance {}.{}".format(category_key, metric_key),
                        'Only internal metrics may specify "all-pings" '
                        'in "send_in_pings"',
                    )
                    metric_obj = None

            if metric_obj is not None:
                metric_obj.no_lint = list(set(metric_obj.no_lint + global_no_lint))

            already_seen = sources.get((category_key, metric_key))
            if already_seen is not None:
                # We've seen this metric name already
                yield util.format_error(
                    filepath,
                    "",
                    ("Duplicate metric name '{}.{}'" "already defined in '{}'").format(
                        category_key, metric_key, already_seen
                    ),
                )
            else:
                all_objects[category_key][metric_key] = metric_obj
                sources[(category_key, metric_key)] = filepath


def _instantiate_pings(
    all_objects: ObjectTree,
    sources: Dict[Any, Path],
    content: Dict[str, util.JSONType],
    filepath: Path,
    config: Dict[str, Any],
) -> Generator[str, None, None]:
    """
    Load a list of pings.yaml files, convert the JSON information into Ping
    objects.
    """
    for ping_key, ping_val in content.items():
        if ping_key.startswith("$"):
            continue
        if not config.get("allow_reserved"):
            if ping_key in RESERVED_PING_NAMES:
                yield util.format_error(
                    filepath,
                    "For ping '{}'".format(ping_key),
                    "Ping uses a reserved name ({})".format(RESERVED_PING_NAMES),
                )
                continue
        if not isinstance(ping_val, dict):
            raise TypeError("Invalid content for ping {}".format(ping_key))
        ping_val["name"] = ping_key
        try:
            ping_obj = Ping(**ping_val)
        except Exception as e:
            yield util.format_error(
                filepath, "On instance '{}'".format(ping_key), str(e)
            )
            continue

        already_seen = sources.get(ping_key)
        if already_seen is not None:
            # We've seen this ping name already
            yield util.format_error(
                filepath,
                "",
                ("Duplicate ping name '{}'" "already defined in '{}'").format(
                    ping_key, already_seen
                ),
            )
        else:
            all_objects.setdefault("pings", {})[ping_key] = ping_obj
            sources[ping_key] = filepath


def _preprocess_objects(objs: ObjectTree, config: Dict[str, Any]) -> ObjectTree:
    """
    Preprocess the object tree to better set defaults.
    """
    for category in objs.values():
        for obj in category.values():
            if not isinstance(obj, Metric):
                continue

            if not config.get("do_not_disable_expired", False) and hasattr(
                obj, "is_disabled"
            ):
                obj.disabled = obj.is_disabled()

            if hasattr(obj, "send_in_pings"):
                if "default" in obj.send_in_pings:
                    obj.send_in_pings = obj.default_store_names + [
                        x for x in obj.send_in_pings if x != "default"
                    ]
                obj.send_in_pings = sorted(list(set(obj.send_in_pings)))
    return objs


@util.keep_value
def parse_objects(
    filepaths: Iterable[Path], config: Dict[str, Any] = {}
) -> Generator[str, None, ObjectTree]:
    """
    Parse one or more metrics.yaml and/or pings.yaml files, returning a tree of
    `metrics.Metric` and `pings.Ping` instances.

    The result is a generator over any errors.  If there are no errors, the
    actual metrics can be obtained from `result.value`.  For example::

      result = metrics.parse_metrics(filepaths)
      for err in result:
          print(err)
      all_metrics = result.value

    The result value is a dictionary of category names to categories, where
    each category is a dictionary from metric name to `metrics.Metric`
    instances.  There is also the special category `pings` containing all
    of the `pings.Ping` instances.

    :param filepaths: list of Path objects to metrics.yaml and/or pings.yaml
        files
    :param config: A dictionary of options that change parsing behavior.
        Supported keys are:

        - `allow_reserved`: Allow values reserved for internal Glean use.
        - `do_not_disable_expired`: Don't mark expired metrics as disabled.
          This is useful when you want to retain the original "disabled"
          value from the `metrics.yaml`, rather than having it overridden when
          the metric expires.
    """
    all_objects = OrderedDict()  # type: ObjectTree
    sources = {}  # type: Dict[Any, Path]
    filepaths = util.ensure_list(filepaths)
    for filepath in filepaths:
        content, filetype = yield from _load_file(filepath)
        if filetype == "metrics":
            yield from _instantiate_metrics(
                all_objects, sources, content, filepath, config
            )
        elif filetype == "pings":
            yield from _instantiate_pings(
                all_objects, sources, content, filepath, config
            )

    return _preprocess_objects(all_objects, config)
