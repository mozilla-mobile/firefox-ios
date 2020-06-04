"""
Test runner for the JSON Schema official test suite

Tests comprehensive correctness of each draft's validator.

See https://github.com/json-schema-org/JSON-Schema-Test-Suite for details.
"""

import sys
import warnings

from jsonschema import (
    Draft3Validator,
    Draft4Validator,
    Draft6Validator,
    Draft7Validator,
    draft3_format_checker,
    draft4_format_checker,
    draft6_format_checker,
    draft7_format_checker,
)
from jsonschema.tests._helpers import bug
from jsonschema.tests._suite import Suite
from jsonschema.validators import _DEPRECATED_DEFAULT_TYPES, create


SUITE = Suite()
DRAFT3 = SUITE.version(name="draft3")
DRAFT4 = SUITE.version(name="draft4")
DRAFT6 = SUITE.version(name="draft6")
DRAFT7 = SUITE.version(name="draft7")


def skip(message, **kwargs):
    def skipper(test):
        if all(value == getattr(test, attr) for attr, value in kwargs.items()):
            return message
    return skipper


def missing_format(checker):
    def missing_format(test):
        schema = test.schema
        if schema is True or schema is False or "format" not in schema:
            return

        if schema["format"] not in checker.checkers:
            return "Format checker {0!r} not found.".format(schema["format"])
    return missing_format


is_narrow_build = sys.maxunicode == 2 ** 16 - 1
if is_narrow_build:  # pragma: no cover
    message = "Not running surrogate Unicode case, this Python is narrow."

    def narrow_unicode_build(test):  # pragma: no cover
        return skip(
            message=message,
            description="one supplementary Unicode code point is not long enough",
        )(test) or skip(
            message=message,
            description="two supplementary Unicode code points is long enough",
        )(test)
else:
    def narrow_unicode_build(test):  # pragma: no cover
        return


TestDraft3 = DRAFT3.to_unittest_testcase(
    DRAFT3.tests(),
    DRAFT3.optional_tests_of(name="bignum"),
    DRAFT3.optional_tests_of(name="format"),
    DRAFT3.optional_tests_of(name="zeroTerminatedFloats"),
    Validator=Draft3Validator,
    format_checker=draft3_format_checker,
    skip=lambda test: (
        narrow_unicode_build(test)
        or missing_format(draft3_format_checker)(test)
        or skip(
            message="Upstream bug in strict_rfc3339",
            subject="format",
            description="case-insensitive T and Z",
        )(test)
    ),
)


TestDraft4 = DRAFT4.to_unittest_testcase(
    DRAFT4.tests(),
    DRAFT4.optional_tests_of(name="bignum"),
    DRAFT4.optional_tests_of(name="format"),
    DRAFT4.optional_tests_of(name="zeroTerminatedFloats"),
    Validator=Draft4Validator,
    format_checker=draft4_format_checker,
    skip=lambda test: (
        narrow_unicode_build(test)
        or missing_format(draft4_format_checker)(test)
        or skip(
            message=bug(),
            subject="ref",
            case_description="Recursive references between schemas",
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description="Location-independent identifier",
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description=(
                "Location-independent identifier with absolute URI"
            ),
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description=(
                "Location-independent identifier with base URI change in subschema"
            ),
        )(test)
        or skip(
            message=bug(),
            subject="refRemote",
            case_description="base URI change - change folder in subschema",
        )(test)
        or skip(
            message="Upstream bug in strict_rfc3339",
            subject="format",
            description="case-insensitive T and Z",
        )(test)
    ),
)


TestDraft6 = DRAFT6.to_unittest_testcase(
    DRAFT6.tests(),
    DRAFT6.optional_tests_of(name="bignum"),
    DRAFT6.optional_tests_of(name="format"),
    DRAFT6.optional_tests_of(name="zeroTerminatedFloats"),
    Validator=Draft6Validator,
    format_checker=draft6_format_checker,
    skip=lambda test: (
        narrow_unicode_build(test)
        or missing_format(draft6_format_checker)(test)
        or skip(
            message=bug(),
            subject="ref",
            case_description="Recursive references between schemas",
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description="Location-independent identifier",
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description=(
                "Location-independent identifier with absolute URI"
            ),
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description=(
                "Location-independent identifier with base URI change in subschema"
            ),
        )(test)
        or skip(
            message=bug(),
            subject="refRemote",
            case_description="base URI change - change folder in subschema",
        )(test)
        or skip(
            message="Upstream bug in strict_rfc3339",
            subject="format",
            description="case-insensitive T and Z",
        )(test)
    ),
)


TestDraft7 = DRAFT7.to_unittest_testcase(
    DRAFT7.tests(),
    DRAFT7.format_tests(),
    DRAFT7.optional_tests_of(name="bignum"),
    DRAFT7.optional_tests_of(name="content"),
    DRAFT7.optional_tests_of(name="zeroTerminatedFloats"),
    Validator=Draft7Validator,
    format_checker=draft7_format_checker,
    skip=lambda test: (
        narrow_unicode_build(test)
        or missing_format(draft7_format_checker)(test)
        or skip(
            message=bug(),
            subject="ref",
            case_description="Recursive references between schemas",
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description="Location-independent identifier",
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description=(
                "Location-independent identifier with absolute URI"
            ),
        )(test)
        or skip(
            message=bug(371),
            subject="ref",
            case_description=(
                "Location-independent identifier with base URI change in subschema"
            ),
        )(test)
        or skip(
            message=bug(),
            subject="refRemote",
            case_description="base URI change - change folder in subschema",
        )(test)
        or skip(
            message="Upstream bug in strict_rfc3339",
            subject="date-time",
            description="case-insensitive T and Z",
        )(test)
        or skip(
            message=bug(593),
            subject="content",
            case_description=(
                "validation of string-encoded content based on media type"
            ),
        )(test)
        or skip(
            message=bug(593),
            subject="content",
            case_description="validation of binary string-encoding",
        )(test)
        or skip(
            message=bug(593),
            subject="content",
            case_description=(
                "validation of binary-encoded media type documents"
            ),
        )(test)
    ),
)


with warnings.catch_warnings():
    warnings.simplefilter("ignore", DeprecationWarning)

    TestDraft3LegacyTypeCheck = DRAFT3.to_unittest_testcase(
        # Interestingly the any part couldn't really be done w/the old API.
        (
            (test for test in each if test.schema != {"type": "any"})
            for each in DRAFT3.tests_of(name="type")
        ),
        name="TestDraft3LegacyTypeCheck",
        Validator=create(
            meta_schema=Draft3Validator.META_SCHEMA,
            validators=Draft3Validator.VALIDATORS,
            default_types=_DEPRECATED_DEFAULT_TYPES,
        ),
    )

    TestDraft4LegacyTypeCheck = DRAFT4.to_unittest_testcase(
        DRAFT4.tests_of(name="type"),
        name="TestDraft4LegacyTypeCheck",
        Validator=create(
            meta_schema=Draft4Validator.META_SCHEMA,
            validators=Draft4Validator.VALIDATORS,
            default_types=_DEPRECATED_DEFAULT_TYPES,
        ),
    )
