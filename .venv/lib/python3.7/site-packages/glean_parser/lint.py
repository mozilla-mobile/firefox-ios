# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import enum
from pathlib import Path
import re
import sys
from typing import Any, Callable, Dict, Generator, List, Iterable, Tuple, Union  # noqa


from . import metrics
from . import parser
from . import util


from yamllint.config import YamlLintConfig  # type: ignore
from yamllint import linter  # type: ignore


LintGenerator = Generator[str, None, None]


class CheckType(enum.Enum):
    warning = 0
    error = 1


def _split_words(name: str) -> List[str]:
    """
    Helper function to split words on either `.` or `_`.
    """
    return re.split("[._]", name)


def _hamming_distance(str1: str, str2: str) -> int:
    """
    Count the # of differences between strings str1 and str2,
    padding the shorter one with whitespace
    """

    diffs = 0
    if len(str1) < len(str2):
        str1, str2 = str2, str1
    len_dist = len(str1) - len(str2)
    str2 += " " * len_dist

    for ch1, ch2 in zip(str1, str2):
        if ch1 != ch2:
            diffs += 1
    return diffs


def check_common_prefix(
    category_name: str, metrics: Iterable[metrics.Metric]
) -> LintGenerator:
    """
    Check if all metrics begin with a common prefix.
    """
    metric_words = sorted([_split_words(metric.name) for metric in metrics])

    if len(metric_words) < 2:
        return

    first = metric_words[0]
    last = metric_words[-1]

    for i in range(min(len(first), len(last))):
        if first[i] != last[i]:
            break

    if i > 0:
        common_prefix = "_".join(first[:i])
        yield (
            "Within category '{}', all metrics begin with prefix "
            "'{}'. Remove prefixes and (possibly) rename category."
        ).format(category_name, common_prefix)


def check_unit_in_name(
    metric: metrics.Metric, parser_config: Dict[str, Any] = {}
) -> LintGenerator:
    """
    The metric name ends in a unit.
    """
    TIME_UNIT_ABBREV = {
        "nanosecond": "ns",
        "microsecond": "us",
        "millisecond": "ms",
        "second": "s",
        "minute": "m",
        "hour": "h",
        "day": "d",
    }

    MEMORY_UNIT_ABBREV = {
        "byte": "b",
        "kilobyte": "kb",
        "megabyte": "mb",
        "gigabyte": "gb",
    }

    name_words = _split_words(metric.name)
    unit_in_name = name_words[-1]

    time_unit = getattr(metric, "time_unit", None)
    memory_unit = getattr(metric, "memory_unit", None)
    unit = getattr(metric, "unit", None)

    if time_unit is not None:
        if (
            unit_in_name == TIME_UNIT_ABBREV.get(time_unit.name)
            or unit_in_name == time_unit.name
        ):
            yield (
                "Suffix '{}' is redundant with time_unit. " "Only include time_unit."
            ).format(unit_in_name)
        elif (
            unit_in_name in TIME_UNIT_ABBREV.keys()
            or unit_in_name in TIME_UNIT_ABBREV.values()
        ):
            yield (
                "Suffix '{}' doesn't match time_unit. "
                "Confirm the unit is correct and only include time_unit."
            ).format(unit_in_name)

    elif memory_unit is not None:
        if (
            unit_in_name == MEMORY_UNIT_ABBREV.get(memory_unit.name)
            or unit_in_name == memory_unit.name
        ):
            yield (
                "Suffix '{}' is redundant with memory_unit. "
                "Only include memory_unit."
            ).format(unit_in_name)
        elif (
            unit_in_name in MEMORY_UNIT_ABBREV.keys()
            or unit_in_name in MEMORY_UNIT_ABBREV.values()
        ):
            yield (
                "Suffix '{}' doesn't match memory_unit. "
                "Confirm the unit is correct and only include memory_unit."
            ).format(unit_in_name)

    elif unit is not None:
        if unit_in_name == unit:
            yield (
                "Suffix '{}' is redundant with unit param. " "Only include unit."
            ).format(unit_in_name)


def check_category_generic(
    category_name: str, metrics: Iterable[metrics.Metric]
) -> LintGenerator:
    """
    The category name is too generic.
    """
    GENERIC_CATEGORIES = ["metrics", "events"]

    if category_name in GENERIC_CATEGORIES:
        yield "Category '{}' is too generic.".format(category_name)


def check_bug_number(
    metric: metrics.Metric, parser_config: Dict[str, Any] = {}
) -> LintGenerator:
    number_bugs = [str(bug) for bug in metric.bugs if isinstance(bug, int)]

    if len(number_bugs):
        yield (
            "For bugs {}: "
            "Bug numbers are deprecated and should be changed to full URLs."
        ).format(", ".join(number_bugs))


def check_valid_in_baseline(
    metric: metrics.Metric, parser_config: Dict[str, Any] = {}
) -> LintGenerator:
    allow_reserved = parser_config.get("allow_reserved", False)

    if not allow_reserved and "baseline" in metric.send_in_pings:
        yield (
            "The baseline ping is Glean-internal. "
            "User metrics should go into the 'metrics' ping or custom pings."
        )


def check_misspelled_pings(
    metric: metrics.Metric, parser_config: Dict[str, Any] = {}
) -> LintGenerator:
    builtin_pings = ["metrics", "events"]

    for ping in metric.send_in_pings:
        for builtin in builtin_pings:
            distance = _hamming_distance(ping, builtin)
            if distance == 1:
                yield ("Ping '{}' seems misspelled. Did you mean '{}'?").format(
                    ping, builtin
                )


def check_user_lifetime_expiration(
    metric: metrics.Metric, parser_config: Dict[str, Any] = {}
) -> LintGenerator:

    if metric.lifetime == metrics.Lifetime.user and metric.expires != "never":
        yield (
            "Metrics with `user` lifetime cannot have an expiration date. "
            "They live as long as the user profile does."
        )


# The checks that operate on an entire category of metrics:
#    {NAME: (function, is_error)}
CATEGORY_CHECKS = {
    "COMMON_PREFIX": (check_common_prefix, CheckType.error),
    "CATEGORY_GENERIC": (check_category_generic, CheckType.error),
}  # noqa type: Dict[str, Tuple[Callable[[str, Iterable[metrics.Metric]], LintGenerator], CheckType]]


# The checks that operate on individual metrics:
#     {NAME: (function, is_error)}
INDIVIDUAL_CHECKS = {
    "UNIT_IN_NAME": (check_unit_in_name, CheckType.error),
    "BUG_NUMBER": (check_bug_number, CheckType.error),
    "BASELINE_PING": (check_valid_in_baseline, CheckType.error),
    "MISSPELLED_PING": (check_misspelled_pings, CheckType.error),
    "USER_LIFETIME_EXPIRATION": (check_user_lifetime_expiration, CheckType.warning),
}  # type: Dict[str, Tuple[Callable[[metrics.Metric, dict], LintGenerator], CheckType]]


class GlinterNit:
    def __init__(self, check_name: str, name: str, msg: str, check_type: CheckType):
        self.check_name = check_name
        self.name = name
        self.msg = msg
        self.check_type = check_type

    def format(self):
        return "{}: {}: {}: {}".format(
            self.check_type.name.upper(), self.check_name, self.name, self.msg
        )


def lint_metrics(
    objs: metrics.ObjectTree, parser_config: Dict[str, Any] = {}, file=sys.stderr
) -> List[GlinterNit]:
    """
    Performs glinter checks on a set of metrics objects.

    :param objs: Tree of metric objects, as returns by `parser.parse_objects`.
    :param file: The stream to write errors to.
    :returns: List of nits.
    """
    nits = []  # type: List[GlinterNit]
    for (category_name, category) in sorted(list(objs.items())):
        if category_name == "pings":
            continue

        # Make sure the category has only Metrics, not Pings
        category_metrics = dict(
            (name, metric)
            for (name, metric) in category.items()
            if isinstance(metric, metrics.Metric)
        )

        for (cat_check_name, (cat_check_func, check_type)) in CATEGORY_CHECKS.items():
            if any(
                cat_check_name in metric.no_lint for metric in category_metrics.values()
            ):
                continue
            nits.extend(
                GlinterNit(cat_check_name, category_name, msg, check_type)
                for msg in cat_check_func(category_name, category_metrics.values())
            )

        for (metric_name, metric) in sorted(list(category_metrics.items())):
            for (check_name, (check_func, check_type)) in INDIVIDUAL_CHECKS.items():
                new_nits = list(check_func(metric, parser_config))
                if len(new_nits):
                    if check_name not in metric.no_lint:
                        nits.extend(
                            GlinterNit(
                                check_name,
                                ".".join([metric.category, metric.name]),
                                msg,
                                check_type,
                            )
                            for msg in new_nits
                        )
                else:
                    if (
                        check_name not in CATEGORY_CHECKS
                        and check_name in metric.no_lint
                    ):
                        nits.append(
                            GlinterNit(
                                "SUPERFLUOUS_NO_LINT",
                                ".".join([metric.category, metric.name]),
                                (
                                    "Superfluous no_lint entry '{}'. "
                                    "Please remove it."
                                ).format(check_name),
                                CheckType.warning,
                            )
                        )

    if len(nits):
        print("Sorry, Glean found some glinter nits:", file=file)
        for nit in nits:
            print(nit.format(), file=file)
        print("", file=file)
        print("Please fix the above nits to continue.", file=file)
        print(
            "To disable a check, add a `no_lint` parameter "
            "with a list of check names to disable.\n"
            "This parameter can appear with each individual metric, or at the "
            "top-level to affect the entire file.",
            file=file,
        )

    return nits


def lint_yaml_files(input_filepaths: Iterable[Path], file=sys.stderr) -> List:
    """
    Performs glinter YAML lint on a set of files.

    :param input_filepaths: List of input files to lint.
    :param file: The stream to write errors to.
    :returns: List of nits.
    """

    # Generic type since the actual type comes from yamllint, which we don't
    # control.
    nits = []  # type: List
    for path in input_filepaths:
        # yamllint needs both the file content and the path.
        file_content = None
        with path.open("r", encoding="utf-8") as fd:
            file_content = fd.read()

        problems = linter.run(file_content, YamlLintConfig("extends: default"), path)
        nits.extend(p for p in problems)

    if len(nits):
        print("Sorry, Glean found some glinter nits:", file=file)
        for p in nits:
            print("{} ({}:{}) - {}".format(path, p.line, p.column, p.message))
        print("", file=file)
        print("Please fix the above nits to continue.", file=file)

    return nits


def glinter(
    input_filepaths: Iterable[Path], parser_config: Dict[str, Any] = {}, file=sys.stderr
) -> int:
    """
    Commandline helper for glinter.

    :param input_filepaths: List of Path objects to load metrics from.
    :param parser_config: Parser configuration object, passed to
      `parser.parse_objects`.
    :param file: The stream to write the errors to.
    :return: Non-zero if there were any glinter errors.
    """
    if lint_yaml_files(input_filepaths, file=file):
        return 1

    objs = parser.parse_objects(input_filepaths, parser_config)

    if util.report_validation_errors(objs):
        return 1

    nits = lint_metrics(objs.value, parser_config=parser_config, file=file)
    if any(nit.check_type == CheckType.error for nit in nits):
        return 1
    if len(nits) == 0:
        print("✨ Your metrics are Glean! ✨", file=file)
    return 0
