# -*- coding: utf-8 -*-

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""
Outputter to generate Swift code for metrics.
"""

import enum
import json
from pathlib import Path
from typing import Any, Dict, Union

from . import metrics
from . import pings
from . import util
from collections import defaultdict

# An (imcomplete) list of reserved keywords in Swift.
# These will be replaced in generated code by their escaped form.
SWIFT_RESERVED_NAMES = ["internal", "typealias"]


def swift_datatypes_filter(value: util.JSONType) -> str:
    """
    A Jinja2 filter that renders Swift literals.

    Based on Python's JSONEncoder, but overrides:
      - dicts to use `[key: value]`
      - sets to use `[...]`
      - enums to use the like-named Swift enum
    """

    class SwiftEncoder(json.JSONEncoder):
        def iterencode(self, value):
            if isinstance(value, dict):
                yield "["
                first = True
                for key, subvalue in value.items():
                    if not first:
                        yield ", "
                    yield from self.iterencode(key)
                    yield ": "
                    yield from self.iterencode(subvalue)
                    first = False
                yield "]"
            elif isinstance(value, enum.Enum):
                yield ("." + util.camelize(value.name))
            elif isinstance(value, set):
                yield "["
                first = True
                for subvalue in sorted(list(value)):
                    if not first:
                        yield ", "
                    yield from self.iterencode(subvalue)
                    first = False
                yield "]"
            elif value is None:
                yield "nil"
            else:
                yield from super().iterencode(value)

    return "".join(SwiftEncoder().iterencode(value))


def type_name(obj: Union[metrics.Metric, pings.Ping]) -> str:
    """
    Returns the Swift type to use for a given metric or ping object.
    """
    generate_enums = getattr(obj, "_generate_enums", [])
    if len(generate_enums):
        template_args = []
        for member, suffix in generate_enums:
            if len(getattr(obj, member)):
                template_args.append(util.Camelize(obj.name) + suffix)
            else:
                if suffix == "Keys":
                    template_args.append("NoExtraKeys")
                else:
                    template_args.append("No" + suffix)

        return "{}<{}>".format(class_name(obj.type), ", ".join(template_args))

    return class_name(obj.type)


def class_name(obj_type: str) -> str:
    """
    Returns the Swift class name for a given metric or ping type.
    """
    if obj_type == "ping":
        return "Ping"
    if obj_type.startswith("labeled_"):
        obj_type = obj_type[8:]
    return util.Camelize(obj_type) + "MetricType"


def variable_name(var: str) -> str:
    """
    Returns a valid Swift variable name, escaping keywords if necessary.
    """
    if var in SWIFT_RESERVED_NAMES:
        return "`" + var + "`"
    else:
        return var


def output_swift(
    objs: metrics.ObjectTree, output_dir: Path, options: Dict[str, Any] = {}
) -> None:
    """
    Given a tree of objects, output Swift code to `output_dir`.

    :param objects: A tree of objects (metrics and pings) as returned from
        `parser.parse_objects`.
    :param output_dir: Path to an output directory to write to.
    :param options: options dictionary, with the following optional keys:
        - namespace: The namespace to generate metrics in
        - glean_namespace: The namespace to import Glean from
        - allow_reserved: When True, this is a Glean-internal build
    """
    template = util.get_jinja2_template(
        "swift.jinja2",
        filters=(
            ("swift", swift_datatypes_filter),
            ("type_name", type_name),
            ("class_name", class_name),
            ("variable_name", variable_name),
        ),
    )

    # The object parameters to pass to constructors.
    # **CAUTION**: This list needs to be in the order the type constructor expects them.
    # The `test_order_of_fields` test checks that the generated code is valid.
    # **DO NOT CHANGE THE ORDER OR ADD NEW FIELDS IN THE MIDDLE**
    extra_args = [
        "category",
        "name",
        "send_in_pings",
        "lifetime",
        "disabled",
        "time_unit",
        "allowed_extra_keys",
        "reason_codes",
    ]

    namespace = options.get("namespace", "GleanMetrics")
    glean_namespace = options.get("glean_namespace", "Glean")

    for category_key, category_val in objs.items():
        filename = util.Camelize(category_key) + ".swift"
        filepath = output_dir / filename

        custom_pings = defaultdict()  # type: Dict[str, pings.Ping]
        for obj in category_val.values():
            if isinstance(obj, pings.Ping):
                custom_pings[obj.name] = obj

        has_labeled_metrics = any(
            getattr(metric, "labeled", False) for metric in category_val.values()
        )

        with filepath.open("w", encoding="utf-8") as fd:
            fd.write(
                template.render(
                    category_name=category_key,
                    objs=category_val,
                    extra_args=extra_args,
                    namespace=namespace,
                    glean_namespace=glean_namespace,
                    has_labeled_metrics=has_labeled_metrics,
                    is_ping_type=len(custom_pings) > 0,
                    allow_reserved=options.get("allow_reserved", False),
                )
            )
            # Jinja2 squashes the final newline, so we explicitly add it
            fd.write("\n")
