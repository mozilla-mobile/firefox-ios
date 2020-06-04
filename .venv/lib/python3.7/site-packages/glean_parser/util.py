# -*- coding: utf-8 -*-

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from collections import OrderedDict
import datetime
import functools
import json
from pathlib import Path
import sys
import textwrap
from typing import Any, Callable, Iterable, Sequence, Tuple, Union
import urllib.request

import appdirs  # type: ignore
import diskcache  # type: ignore
import jinja2
import jsonschema  # type: ignore
from jsonschema import _utils  # type: ignore
import yaml

if sys.version_info < (3, 7):
    import iso8601  # type: ignore


TESTING_MODE = "pytest" in sys.modules


JSONType = Union[list, dict, str, int, float, None]
"""
The types supported by JSON.

This is only an approximation -- this should really be a recursive type.
"""

# Adapted from
# https://stackoverflow.com/questions/34667108/ignore-dates-and-times-while-parsing-yaml


class _NoDatesSafeLoader(yaml.SafeLoader):
    @classmethod
    def remove_implicit_resolver(cls, tag_to_remove):
        """
        Remove implicit resolvers for a particular tag

        Takes care not to modify resolvers in super classes.

        We want to load datetimes as strings, not dates, because we
        go on to serialise as json which doesn't have the advanced types
        of yaml, and leads to incompatibilities down the track.
        """
        if "yaml_implicit_resolvers" not in cls.__dict__:
            cls.yaml_implicit_resolvers = cls.yaml_implicit_resolvers.copy()

        for first_letter, mappings in cls.yaml_implicit_resolvers.items():
            cls.yaml_implicit_resolvers[first_letter] = [
                (tag, regexp) for tag, regexp in mappings if tag != tag_to_remove
            ]


# Since we use JSON schema to validate, and JSON schema doesn't support
# datetimes, we don't want the YAML loader to give us datetimes -- just
# strings.
_NoDatesSafeLoader.remove_implicit_resolver("tag:yaml.org,2002:timestamp")


if sys.version_info < (3, 7):
    # In Python prior to 3.7, dictionary order is not preserved. However, we
    # want the metrics to appear in the output in the same order as they are in
    # the metrics.yaml file, so on earlier versions of Python we must use an
    # OrderedDict object.
    def ordered_yaml_load(stream):
        class OrderedLoader(_NoDatesSafeLoader):
            pass

        def construct_mapping(loader, node):
            loader.flatten_mapping(node)
            return OrderedDict(loader.construct_pairs(node))

        OrderedLoader.add_constructor(
            yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping
        )
        return yaml.load(stream, OrderedLoader)

    def ordered_yaml_dump(data, **kwargs):
        class OrderedDumper(yaml.Dumper):
            pass

        def _dict_representer(dumper, data):
            return dumper.represent_mapping(
                yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, data.items()
            )

        OrderedDumper.add_representer(OrderedDict, _dict_representer)
        return yaml.dump(data, Dumper=OrderedDumper, **kwargs)


else:

    def ordered_yaml_load(stream):
        return yaml.load(stream, Loader=_NoDatesSafeLoader)

    def ordered_yaml_dump(data, **kwargs):
        return yaml.dump(data, **kwargs)


def load_yaml_or_json(path: Path, ordered_dict: bool = False):
    """
    Load the content from either a .json or .yaml file, based on the filename
    extension.

    :param path: `pathlib.Path` object
    :rtype object: The tree of objects as a result of parsing the file.
    :raises ValueError: The file is neither a .json, .yml or .yaml file.
    """
    # If in py.test, support bits of literal JSON/YAML content
    if TESTING_MODE and isinstance(path, dict):
        return path

    if not path.is_file():
        return {}

    if path.suffix == ".json":
        with path.open("r", encoding="utf-8") as fd:
            return json.load(fd)
    elif path.suffix in (".yml", ".yaml", ".yamlx"):
        with path.open("r", encoding="utf-8") as fd:
            if ordered_dict:
                return ordered_yaml_load(fd)
            else:
                return yaml.load(fd, Loader=_NoDatesSafeLoader)
    else:
        raise ValueError("Unknown file extension {}".format(path.suffix))


def ensure_list(value: Any) -> Sequence[Any]:
    """
    Ensures that the value is a list. If it is anything but a list or tuple, a
    list with a single element containing only value is returned.
    """
    if not isinstance(value, (list, tuple)):
        return [value]
    return value


def to_camel_case(input: str, capitalize_first_letter: bool) -> str:
    """
    Convert the value to camelCase.

    This additionally replaces any '.' with '_'. The first letter is capitalized
    depending on `capitalize_first_letter`.
    """
    sanitized_input = input.replace(".", "_").replace("-", "_")
    # Filter out any empty token. This could happen due to leading '_' or
    # consecutive '__'.
    tokens = [s.capitalize() for s in sanitized_input.split("_") if len(s) != 0]
    # If we're not meant to capitalize the first letter, then lowercase it.
    if not capitalize_first_letter:
        tokens[0] = tokens[0].lower()
    # Finally join the tokens and capitalize.
    return "".join(tokens)


def camelize(value: str) -> str:
    """
    Convert the value to camelCase (with a lower case first letter).

    This is a thin wrapper around inflection.camelize that handles dots in
    addition to underscores.
    """
    return to_camel_case(value, False)


def Camelize(value: str) -> str:
    """
    Convert the value to CamelCase (with an upper case first letter).

    This is a thin wrapper around inflection.camelize that handles dots in
    addition to underscores.
    """
    return to_camel_case(value, True)


@functools.lru_cache()
def get_jinja2_template(
    template_name: str, filters: Iterable[Tuple[str, Callable]] = ()
):
    """
    Get a Jinja2 template that ships with glean_parser.

    The template has extra filters for camel-casing identifiers.

    :param template_name: Name of a file in ``glean_parser/templates``
    :param filters: tuple of 2-tuple. A tuple of (name, func) pairs defining
        additional filters.
    """
    env = jinja2.Environment(
        loader=jinja2.PackageLoader("glean_parser", "templates"),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    env.filters["camelize"] = camelize
    env.filters["Camelize"] = Camelize
    for filter_name, filter_func in filters:
        env.filters[filter_name] = filter_func

    return env.get_template(template_name)


def keep_value(f):
    """
    Wrap a generator so the value it returns (rather than yields), will be
    accessible on the .value attribute when the generator is exhausted.
    """

    class ValueKeepingGenerator(object):
        def __init__(self, g):
            self.g = g
            self.value = None

        def __iter__(self):
            self.value = yield from self.g

    @functools.wraps(f)
    def g(*args, **kwargs):
        return ValueKeepingGenerator(f(*args, **kwargs))

    return g


def get_null_resolver(schema):
    """
    Returns a JSON Pointer resolver that does nothing.

    This lets us handle the moz: URLs in our schemas.
    """

    class NullResolver(jsonschema.RefResolver):
        def resolve_remote(self, uri):
            if uri in self.store:
                return self.store[uri]
            if uri == "":
                return self.referrer

    return NullResolver.from_schema(schema)


def fetch_remote_url(url: str, cache: bool = True):
    """
    Fetches the contents from an HTTP url or local file path, and optionally
    caches it to disk.
    """
    # Include the Python version in the cache key, since caches aren't
    # sharable across Python versions.
    key = (url, str(sys.version_info))

    is_http = url.startswith("http")

    if not is_http:
        with open(url, "r", encoding="utf-8") as fd:
            contents = fd.read()
        return contents

    if cache:
        cache_dir = appdirs.user_cache_dir("glean_parser", "mozilla")
        with diskcache.Cache(cache_dir) as dc:
            if key in dc:
                return dc[key]

    contents = urllib.request.urlopen(url).read()  # type: ignore

    # On Python 3.5, urlopen does not handle the unicode decoding for us. This
    # is ok because we control these files and we know they are in UTF-8,
    # however, this wouldn't be correct in general.
    if sys.version_info < (3, 6):
        contents = contents.decode("utf8")  # type: ignore

    if cache:
        with diskcache.Cache(cache_dir) as dc:
            dc[key] = contents

    return contents


_unset = _utils.Unset()


def pprint_validation_error(error) -> str:
    """
    A version of jsonschema's ValidationError __str__ method that doesn't
    include the schema fragment that failed.  This makes the error messages
    much more succinct.

    It also shows any subschemas of anyOf/allOf that failed, if any (what
    jsonschema calls "context").
    """
    essential_for_verbose = (
        error.validator,
        error.validator_value,
        error.instance,
        error.schema,
    )
    if any(m is _unset for m in essential_for_verbose):
        return textwrap.fill(error.message)

    instance = error.instance
    for path in list(error.relative_path)[::-1]:
        if isinstance(path, str):
            instance = {path: instance}
        else:
            instance = [instance]

    yaml_instance = ordered_yaml_dump(instance, width=72, default_flow_style=False)

    parts = ["```", yaml_instance.rstrip(), "```", "", textwrap.fill(error.message)]
    if error.context:
        parts.extend(
            textwrap.fill(x.message, initial_indent="    ", subsequent_indent="    ")
            for x in error.context
        )

    description = error.schema.get("description")
    if description:
        parts.extend(["", "Documentation for this node:", _utils.indent(description)])

    return "\n".join(parts)


def format_error(filepath: Union[str, Path], header: str, content: str) -> str:
    """
    Format a jsonshema validation error.
    """
    if isinstance(filepath, Path):
        filepath = filepath.resolve()
    else:
        filepath = "<string>"
    if header:
        return "{}: {}\n{}".format(filepath, header, _utils.indent(content))
    else:
        return "{}:\n{}".format(filepath, _utils.indent(content))


def is_expired(expires: str) -> bool:
    """
    Parses the `expires` field in a metric or ping and returns whether
    the object should be considered expired.
    """
    if expires == "never":
        return False
    elif expires == "expired":
        return True
    else:
        try:
            if sys.version_info < (3, 7):
                date = iso8601.parse_date(expires).date()
            else:
                date = datetime.date.fromisoformat(expires)
        except ValueError:
            raise ValueError(
                (
                    "Invalid expiration date '{}'. "
                    "Must be of the form yyyy-mm-dd in UTC."
                ).format(expires)
            )
        return date <= datetime.datetime.utcnow().date()


def validate_expires(expires: str) -> None:
    """
    Raises ValueError if `expires` is not valid.
    """
    if expires in ("never", "expired"):
        return
    if sys.version_info < (3, 7):
        iso8601.parse_date(expires)
    else:
        datetime.date.fromisoformat(expires)


def report_validation_errors(all_objects):
    """
    Report any validation errors found to the console.
    """
    found_error = False
    for error in all_objects:
        found_error = True
        print("=" * 78, file=sys.stderr)
        print(error, file=sys.stderr)
    return found_error
