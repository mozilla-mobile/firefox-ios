from unittest import TestCase
import json
import subprocess
import sys

from jsonschema import Draft4Validator, ValidationError, cli, __version__
from jsonschema.compat import NativeIO
from jsonschema.exceptions import SchemaError


def fake_validator(*errors):
    errors = list(reversed(errors))

    class FakeValidator(object):
        def __init__(self, *args, **kwargs):
            pass

        def iter_errors(self, instance):
            if errors:
                return errors.pop()
            return []

        def check_schema(self, schema):
            pass

    return FakeValidator


class TestParser(TestCase):

    FakeValidator = fake_validator()
    instance_file = "foo.json"
    schema_file = "schema.json"

    def setUp(self):
        cli.open = self.fake_open
        self.addCleanup(delattr, cli, "open")

    def fake_open(self, path):
        if path == self.instance_file:
            contents = ""
        elif path == self.schema_file:
            contents = {}
        else:  # pragma: no cover
            self.fail("What is {!r}".format(path))
        return NativeIO(json.dumps(contents))

    def test_find_validator_by_fully_qualified_object_name(self):
        arguments = cli.parse_args(
            [
                "--validator",
                "jsonschema.tests.test_cli.TestParser.FakeValidator",
                "--instance", self.instance_file,
                self.schema_file,
            ]
        )
        self.assertIs(arguments["validator"], self.FakeValidator)

    def test_find_validator_in_jsonschema(self):
        arguments = cli.parse_args(
            [
                "--validator", "Draft4Validator",
                "--instance", self.instance_file,
                self.schema_file,
            ]
        )
        self.assertIs(arguments["validator"], Draft4Validator)


class TestCLI(TestCase):
    def test_draft3_schema_draft4_validator(self):
        stdout, stderr = NativeIO(), NativeIO()
        with self.assertRaises(SchemaError):
            cli.run(
                {
                    "validator": Draft4Validator,
                    "schema": {
                        "anyOf": [
                            {"minimum": 20},
                            {"type": "string"},
                            {"required": True},
                        ],
                    },
                    "instances": [1],
                    "error_format": "{error.message}",
                },
                stdout=stdout,
                stderr=stderr,
            )

    def test_successful_validation(self):
        stdout, stderr = NativeIO(), NativeIO()
        exit_code = cli.run(
            {
                "validator": fake_validator(),
                "schema": {},
                "instances": [1],
                "error_format": "{error.message}",
            },
            stdout=stdout,
            stderr=stderr,
        )
        self.assertFalse(stdout.getvalue())
        self.assertFalse(stderr.getvalue())
        self.assertEqual(exit_code, 0)

    def test_unsuccessful_validation(self):
        error = ValidationError("I am an error!", instance=1)
        stdout, stderr = NativeIO(), NativeIO()
        exit_code = cli.run(
            {
                "validator": fake_validator([error]),
                "schema": {},
                "instances": [1],
                "error_format": "{error.instance} - {error.message}",
            },
            stdout=stdout,
            stderr=stderr,
        )
        self.assertFalse(stdout.getvalue())
        self.assertEqual(stderr.getvalue(), "1 - I am an error!")
        self.assertEqual(exit_code, 1)

    def test_unsuccessful_validation_multiple_instances(self):
        first_errors = [
            ValidationError("9", instance=1),
            ValidationError("8", instance=1),
        ]
        second_errors = [ValidationError("7", instance=2)]
        stdout, stderr = NativeIO(), NativeIO()
        exit_code = cli.run(
            {
                "validator": fake_validator(first_errors, second_errors),
                "schema": {},
                "instances": [1, 2],
                "error_format": "{error.instance} - {error.message}\t",
            },
            stdout=stdout,
            stderr=stderr,
        )
        self.assertFalse(stdout.getvalue())
        self.assertEqual(stderr.getvalue(), "1 - 9\t1 - 8\t2 - 7\t")
        self.assertEqual(exit_code, 1)

    def test_version(self):
        version = subprocess.check_output(
            [sys.executable, "-m", "jsonschema", "--version"],
            stderr=subprocess.STDOUT,
        )
        version = version.decode("utf-8").strip()
        self.assertEqual(version, __version__)
