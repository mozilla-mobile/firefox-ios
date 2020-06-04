from collections import deque
from contextlib import contextmanager
from decimal import Decimal
from io import BytesIO
from unittest import TestCase
import json
import os
import sys
import tempfile
import unittest

from twisted.trial.unittest import SynchronousTestCase
import attr

from jsonschema import FormatChecker, TypeChecker, exceptions, validators
from jsonschema.compat import PY3, pathname2url
from jsonschema.tests._helpers import bug


def startswith(validator, startswith, instance, schema):
    if not instance.startswith(startswith):
        yield exceptions.ValidationError(u"Whoops!")


class TestCreateAndExtend(SynchronousTestCase):
    def setUp(self):
        self.addCleanup(
            self.assertEqual,
            validators.meta_schemas,
            dict(validators.meta_schemas),
        )

        self.meta_schema = {u"$id": "some://meta/schema"}
        self.validators = {u"startswith": startswith}
        self.type_checker = TypeChecker()
        self.Validator = validators.create(
            meta_schema=self.meta_schema,
            validators=self.validators,
            type_checker=self.type_checker,
        )

    def test_attrs(self):
        self.assertEqual(
            (
                self.Validator.VALIDATORS,
                self.Validator.META_SCHEMA,
                self.Validator.TYPE_CHECKER,
            ), (
                self.validators,
                self.meta_schema,
                self.type_checker,
            ),
        )

    def test_init(self):
        schema = {u"startswith": u"foo"}
        self.assertEqual(self.Validator(schema).schema, schema)

    def test_iter_errors(self):
        schema = {u"startswith": u"hel"}
        iter_errors = self.Validator(schema).iter_errors

        errors = list(iter_errors(u"hello"))
        self.assertEqual(errors, [])

        expected_error = exceptions.ValidationError(
            u"Whoops!",
            instance=u"goodbye",
            schema=schema,
            validator=u"startswith",
            validator_value=u"hel",
            schema_path=deque([u"startswith"]),
        )

        errors = list(iter_errors(u"goodbye"))
        self.assertEqual(len(errors), 1)
        self.assertEqual(errors[0]._contents(), expected_error._contents())

    def test_if_a_version_is_provided_it_is_registered(self):
        Validator = validators.create(
            meta_schema={u"$id": "something"},
            version="my version",
        )
        self.addCleanup(validators.meta_schemas.pop, "something")
        self.assertEqual(Validator.__name__, "MyVersionValidator")

    def test_if_a_version_is_not_provided_it_is_not_registered(self):
        original = dict(validators.meta_schemas)
        validators.create(meta_schema={u"id": "id"})
        self.assertEqual(validators.meta_schemas, original)

    def test_validates_registers_meta_schema_id(self):
        meta_schema_key = "meta schema id"
        my_meta_schema = {u"id": meta_schema_key}

        validators.create(
            meta_schema=my_meta_schema,
            version="my version",
            id_of=lambda s: s.get("id", ""),
        )
        self.addCleanup(validators.meta_schemas.pop, meta_schema_key)

        self.assertIn(meta_schema_key, validators.meta_schemas)

    def test_validates_registers_meta_schema_draft6_id(self):
        meta_schema_key = "meta schema $id"
        my_meta_schema = {u"$id": meta_schema_key}

        validators.create(
            meta_schema=my_meta_schema,
            version="my version",
        )
        self.addCleanup(validators.meta_schemas.pop, meta_schema_key)

        self.assertIn(meta_schema_key, validators.meta_schemas)

    def test_create_default_types(self):
        Validator = validators.create(meta_schema={}, validators=())
        self.assertTrue(
            all(
                Validator({}).is_type(instance=instance, type=type)
                for type, instance in [
                    (u"array", []),
                    (u"boolean", True),
                    (u"integer", 12),
                    (u"null", None),
                    (u"number", 12.0),
                    (u"object", {}),
                    (u"string", u"foo"),
                ]
            ),
        )

    def test_extend(self):
        original = dict(self.Validator.VALIDATORS)
        new = object()

        Extended = validators.extend(
            self.Validator,
            validators={u"new": new},
        )
        self.assertEqual(
            (
                Extended.VALIDATORS,
                Extended.META_SCHEMA,
                Extended.TYPE_CHECKER,
                self.Validator.VALIDATORS,
            ), (
                dict(original, new=new),
                self.Validator.META_SCHEMA,
                self.Validator.TYPE_CHECKER,
                original,
            ),
        )

    def test_extend_idof(self):
        """
        Extending a validator preserves its notion of schema IDs.
        """
        def id_of(schema):
            return schema.get(u"__test__", self.Validator.ID_OF(schema))
        correct_id = "the://correct/id/"
        meta_schema = {
            u"$id": "the://wrong/id/",
            u"__test__": correct_id,
        }
        Original = validators.create(
            meta_schema=meta_schema,
            validators=self.validators,
            type_checker=self.type_checker,
            id_of=id_of,
        )
        self.assertEqual(Original.ID_OF(Original.META_SCHEMA), correct_id)

        Derived = validators.extend(Original)
        self.assertEqual(Derived.ID_OF(Derived.META_SCHEMA), correct_id)


class TestLegacyTypeChecking(SynchronousTestCase):
    def test_create_default_types(self):
        Validator = validators.create(meta_schema={}, validators=())
        self.assertEqual(
            set(Validator.DEFAULT_TYPES), {
                u"array",
                u"boolean",
                u"integer",
                u"null",
                u"number",
                u"object", u"string",
            },
        )
        self.flushWarnings()

    def test_extend(self):
        Validator = validators.create(meta_schema={}, validators=())
        original = dict(Validator.VALIDATORS)
        new = object()

        Extended = validators.extend(
            Validator,
            validators={u"new": new},
        )
        self.assertEqual(
            (
                Extended.VALIDATORS,
                Extended.META_SCHEMA,
                Extended.TYPE_CHECKER,
                Validator.VALIDATORS,

                Extended.DEFAULT_TYPES,
                Extended({}).DEFAULT_TYPES,
                self.flushWarnings()[0]["message"],
            ), (
                dict(original, new=new),
                Validator.META_SCHEMA,
                Validator.TYPE_CHECKER,
                original,

                Validator.DEFAULT_TYPES,
                Validator.DEFAULT_TYPES,
                self.flushWarnings()[0]["message"],
            ),
        )

    def test_types_redefines_the_validators_type_checker(self):
        schema = {"type": "string"}
        self.assertFalse(validators.Draft7Validator(schema).is_valid(12))

        validator = validators.Draft7Validator(
            schema,
            types={"string": (str, int)},
        )
        self.assertTrue(validator.is_valid(12))
        self.flushWarnings()

    def test_providing_default_types_warns(self):
        self.assertWarns(
            category=DeprecationWarning,
            message=(
                "The default_types argument is deprecated. "
                "Use the type_checker argument instead."
            ),
            # https://tm.tl/9363 :'(
            filename=sys.modules[self.assertWarns.__module__].__file__,

            f=validators.create,
            meta_schema={},
            validators={},
            default_types={"foo": object},
        )

    def test_cannot_ask_for_default_types_with_non_default_type_checker(self):
        """
        We raise an error when you ask a validator with non-default
        type checker for its DEFAULT_TYPES.

        The type checker argument is new, so no one but this library
        itself should be trying to use it, and doing so while then
        asking for DEFAULT_TYPES makes no sense (not to mention is
        deprecated), since type checkers are not strictly about Python
        type.
        """
        Validator = validators.create(
            meta_schema={},
            validators={},
            type_checker=TypeChecker(),
        )
        with self.assertRaises(validators._DontDoThat) as e:
            Validator.DEFAULT_TYPES

        self.assertIn(
            "DEFAULT_TYPES cannot be used on Validators using TypeCheckers",
            str(e.exception),
        )
        with self.assertRaises(validators._DontDoThat):
            Validator({}).DEFAULT_TYPES

        self.assertFalse(self.flushWarnings())

    def test_providing_explicit_type_checker_does_not_warn(self):
        Validator = validators.create(
            meta_schema={},
            validators={},
            type_checker=TypeChecker(),
        )
        self.assertFalse(self.flushWarnings())

        Validator({})
        self.assertFalse(self.flushWarnings())

    def test_providing_neither_does_not_warn(self):
        Validator = validators.create(meta_schema={}, validators={})
        self.assertFalse(self.flushWarnings())

        Validator({})
        self.assertFalse(self.flushWarnings())

    def test_providing_default_types_with_type_checker_errors(self):
        with self.assertRaises(TypeError) as e:
            validators.create(
                meta_schema={},
                validators={},
                default_types={"foo": object},
                type_checker=TypeChecker(),
            )

        self.assertIn(
            "Do not specify default_types when providing a type checker",
            str(e.exception),
        )
        self.assertFalse(self.flushWarnings())

    def test_extending_a_legacy_validator_with_a_type_checker_errors(self):
        Validator = validators.create(
            meta_schema={},
            validators={},
            default_types={u"array": list}
        )
        with self.assertRaises(TypeError) as e:
            validators.extend(
                Validator,
                validators={},
                type_checker=TypeChecker(),
            )

        self.assertIn(
            (
                "Cannot extend a validator created with default_types "
                "with a type_checker. Update the validator to use a "
                "type_checker when created."
            ),
            str(e.exception),
        )
        self.flushWarnings()

    def test_extending_a_legacy_validator_does_not_rewarn(self):
        Validator = validators.create(meta_schema={}, default_types={})
        self.assertTrue(self.flushWarnings())

        validators.extend(Validator)
        self.assertFalse(self.flushWarnings())

    def test_accessing_default_types_warns(self):
        Validator = validators.create(meta_schema={}, validators={})
        self.assertFalse(self.flushWarnings())

        self.assertWarns(
            DeprecationWarning,
            (
                "The DEFAULT_TYPES attribute is deprecated. "
                "See the type checker attached to this validator instead."
            ),
            # https://tm.tl/9363 :'(
            sys.modules[self.assertWarns.__module__].__file__,

            getattr,
            Validator,
            "DEFAULT_TYPES",
        )

    def test_accessing_default_types_on_the_instance_warns(self):
        Validator = validators.create(meta_schema={}, validators={})
        self.assertFalse(self.flushWarnings())

        self.assertWarns(
            DeprecationWarning,
            (
                "The DEFAULT_TYPES attribute is deprecated. "
                "See the type checker attached to this validator instead."
            ),
            # https://tm.tl/9363 :'(
            sys.modules[self.assertWarns.__module__].__file__,

            getattr,
            Validator({}),
            "DEFAULT_TYPES",
        )

    def test_providing_types_to_init_warns(self):
        Validator = validators.create(meta_schema={}, validators={})
        self.assertFalse(self.flushWarnings())

        self.assertWarns(
            category=DeprecationWarning,
            message=(
                "The types argument is deprecated. "
                "Provide a type_checker to jsonschema.validators.extend "
                "instead."
            ),
            # https://tm.tl/9363 :'(
            filename=sys.modules[self.assertWarns.__module__].__file__,

            f=Validator,
            schema={},
            types={"bar": object},
        )


class TestIterErrors(TestCase):
    def setUp(self):
        self.validator = validators.Draft3Validator({})

    def test_iter_errors(self):
        instance = [1, 2]
        schema = {
            u"disallow": u"array",
            u"enum": [["a", "b", "c"], ["d", "e", "f"]],
            u"minItems": 3,
        }

        got = (e.message for e in self.validator.iter_errors(instance, schema))
        expected = [
            "%r is disallowed for [1, 2]" % (schema["disallow"],),
            "[1, 2] is too short",
            "[1, 2] is not one of %r" % (schema["enum"],),
        ]
        self.assertEqual(sorted(got), sorted(expected))

    def test_iter_errors_multiple_failures_one_validator(self):
        instance = {"foo": 2, "bar": [1], "baz": 15, "quux": "spam"}
        schema = {
            u"properties": {
                "foo": {u"type": "string"},
                "bar": {u"minItems": 2},
                "baz": {u"maximum": 10, u"enum": [2, 4, 6, 8]},
            },
        }

        errors = list(self.validator.iter_errors(instance, schema))
        self.assertEqual(len(errors), 4)


class TestValidationErrorMessages(TestCase):
    def message_for(self, instance, schema, *args, **kwargs):
        kwargs.setdefault("cls", validators.Draft3Validator)
        with self.assertRaises(exceptions.ValidationError) as e:
            validators.validate(instance, schema, *args, **kwargs)
        return e.exception.message

    def test_single_type_failure(self):
        message = self.message_for(instance=1, schema={u"type": u"string"})
        self.assertEqual(message, "1 is not of type %r" % u"string")

    def test_single_type_list_failure(self):
        message = self.message_for(instance=1, schema={u"type": [u"string"]})
        self.assertEqual(message, "1 is not of type %r" % u"string")

    def test_multiple_type_failure(self):
        types = u"string", u"object"
        message = self.message_for(instance=1, schema={u"type": list(types)})
        self.assertEqual(message, "1 is not of type %r, %r" % types)

    def test_object_without_title_type_failure(self):
        type = {u"type": [{u"minimum": 3}]}
        message = self.message_for(instance=1, schema={u"type": [type]})
        self.assertEqual(message, "1 is less than the minimum of 3")

    def test_object_with_named_type_failure(self):
        schema = {u"type": [{u"name": "Foo", u"minimum": 3}]}
        message = self.message_for(instance=1, schema=schema)
        self.assertEqual(message, "1 is less than the minimum of 3")

    def test_minimum(self):
        message = self.message_for(instance=1, schema={"minimum": 2})
        self.assertEqual(message, "1 is less than the minimum of 2")

    def test_maximum(self):
        message = self.message_for(instance=1, schema={"maximum": 0})
        self.assertEqual(message, "1 is greater than the maximum of 0")

    def test_dependencies_single_element(self):
        depend, on = "bar", "foo"
        schema = {u"dependencies": {depend: on}}
        message = self.message_for(
            instance={"bar": 2},
            schema=schema,
            cls=validators.Draft3Validator,
        )
        self.assertEqual(message, "%r is a dependency of %r" % (on, depend))

    def test_dependencies_list_draft3(self):
        depend, on = "bar", "foo"
        schema = {u"dependencies": {depend: [on]}}
        message = self.message_for(
            instance={"bar": 2},
            schema=schema,
            cls=validators.Draft3Validator,
        )
        self.assertEqual(message, "%r is a dependency of %r" % (on, depend))

    def test_dependencies_list_draft7(self):
        depend, on = "bar", "foo"
        schema = {u"dependencies": {depend: [on]}}
        message = self.message_for(
            instance={"bar": 2},
            schema=schema,
            cls=validators.Draft7Validator,
        )
        self.assertEqual(message, "%r is a dependency of %r" % (on, depend))

    def test_additionalItems_single_failure(self):
        message = self.message_for(
            instance=[2],
            schema={u"items": [], u"additionalItems": False},
        )
        self.assertIn("(2 was unexpected)", message)

    def test_additionalItems_multiple_failures(self):
        message = self.message_for(
            instance=[1, 2, 3],
            schema={u"items": [], u"additionalItems": False}
        )
        self.assertIn("(1, 2, 3 were unexpected)", message)

    def test_additionalProperties_single_failure(self):
        additional = "foo"
        schema = {u"additionalProperties": False}
        message = self.message_for(instance={additional: 2}, schema=schema)
        self.assertIn("(%r was unexpected)" % (additional,), message)

    def test_additionalProperties_multiple_failures(self):
        schema = {u"additionalProperties": False}
        message = self.message_for(
            instance=dict.fromkeys(["foo", "bar"]),
            schema=schema,
        )

        self.assertIn(repr("foo"), message)
        self.assertIn(repr("bar"), message)
        self.assertIn("were unexpected)", message)

    def test_const(self):
        schema = {u"const": 12}
        message = self.message_for(
            instance={"foo": "bar"},
            schema=schema,
            cls=validators.Draft6Validator,
        )
        self.assertIn("12 was expected", message)

    def test_contains(self):
        schema = {u"contains": {u"const": 12}}
        message = self.message_for(
            instance=[2, {}, []],
            schema=schema,
            cls=validators.Draft6Validator,
        )
        self.assertIn(
            "None of [2, {}, []] are valid under the given schema",
            message,
        )

    def test_invalid_format_default_message(self):
        checker = FormatChecker(formats=())
        checker.checks(u"thing")(lambda value: False)

        schema = {u"format": u"thing"}
        message = self.message_for(
            instance="bla",
            schema=schema,
            format_checker=checker,
        )

        self.assertIn(repr("bla"), message)
        self.assertIn(repr("thing"), message)
        self.assertIn("is not a", message)

    def test_additionalProperties_false_patternProperties(self):
        schema = {u"type": u"object",
                  u"additionalProperties": False,
                  u"patternProperties": {
                      u"^abc$": {u"type": u"string"},
                      u"^def$": {u"type": u"string"},
                  }}
        message = self.message_for(
            instance={u"zebra": 123},
            schema=schema,
            cls=validators.Draft4Validator,
        )
        self.assertEqual(
            message,
            "{} does not match any of the regexes: {}, {}".format(
                repr(u"zebra"), repr(u"^abc$"), repr(u"^def$"),
            ),
        )
        message = self.message_for(
            instance={u"zebra": 123, u"fish": 456},
            schema=schema,
            cls=validators.Draft4Validator,
        )
        self.assertEqual(
            message,
            "{}, {} do not match any of the regexes: {}, {}".format(
                repr(u"fish"), repr(u"zebra"), repr(u"^abc$"), repr(u"^def$")
            ),
        )

    def test_False_schema(self):
        message = self.message_for(
            instance="something",
            schema=False,
            cls=validators.Draft7Validator,
        )
        self.assertIn("False schema does not allow 'something'", message)


class TestValidationErrorDetails(TestCase):
    # TODO: These really need unit tests for each individual validator, rather
    #       than just these higher level tests.
    def test_anyOf(self):
        instance = 5
        schema = {
            "anyOf": [
                {"minimum": 20},
                {"type": "string"},
            ],
        }

        validator = validators.Draft4Validator(schema)
        errors = list(validator.iter_errors(instance))
        self.assertEqual(len(errors), 1)
        e = errors[0]

        self.assertEqual(e.validator, "anyOf")
        self.assertEqual(e.validator_value, schema["anyOf"])
        self.assertEqual(e.instance, instance)
        self.assertEqual(e.schema, schema)
        self.assertIsNone(e.parent)

        self.assertEqual(e.path, deque([]))
        self.assertEqual(e.relative_path, deque([]))
        self.assertEqual(e.absolute_path, deque([]))

        self.assertEqual(e.schema_path, deque(["anyOf"]))
        self.assertEqual(e.relative_schema_path, deque(["anyOf"]))
        self.assertEqual(e.absolute_schema_path, deque(["anyOf"]))

        self.assertEqual(len(e.context), 2)

        e1, e2 = sorted_errors(e.context)

        self.assertEqual(e1.validator, "minimum")
        self.assertEqual(e1.validator_value, schema["anyOf"][0]["minimum"])
        self.assertEqual(e1.instance, instance)
        self.assertEqual(e1.schema, schema["anyOf"][0])
        self.assertIs(e1.parent, e)

        self.assertEqual(e1.path, deque([]))
        self.assertEqual(e1.absolute_path, deque([]))
        self.assertEqual(e1.relative_path, deque([]))

        self.assertEqual(e1.schema_path, deque([0, "minimum"]))
        self.assertEqual(e1.relative_schema_path, deque([0, "minimum"]))
        self.assertEqual(
            e1.absolute_schema_path, deque(["anyOf", 0, "minimum"]),
        )

        self.assertFalse(e1.context)

        self.assertEqual(e2.validator, "type")
        self.assertEqual(e2.validator_value, schema["anyOf"][1]["type"])
        self.assertEqual(e2.instance, instance)
        self.assertEqual(e2.schema, schema["anyOf"][1])
        self.assertIs(e2.parent, e)

        self.assertEqual(e2.path, deque([]))
        self.assertEqual(e2.relative_path, deque([]))
        self.assertEqual(e2.absolute_path, deque([]))

        self.assertEqual(e2.schema_path, deque([1, "type"]))
        self.assertEqual(e2.relative_schema_path, deque([1, "type"]))
        self.assertEqual(e2.absolute_schema_path, deque(["anyOf", 1, "type"]))

        self.assertEqual(len(e2.context), 0)

    def test_type(self):
        instance = {"foo": 1}
        schema = {
            "type": [
                {"type": "integer"},
                {
                    "type": "object",
                    "properties": {"foo": {"enum": [2]}},
                },
            ],
        }

        validator = validators.Draft3Validator(schema)
        errors = list(validator.iter_errors(instance))
        self.assertEqual(len(errors), 1)
        e = errors[0]

        self.assertEqual(e.validator, "type")
        self.assertEqual(e.validator_value, schema["type"])
        self.assertEqual(e.instance, instance)
        self.assertEqual(e.schema, schema)
        self.assertIsNone(e.parent)

        self.assertEqual(e.path, deque([]))
        self.assertEqual(e.relative_path, deque([]))
        self.assertEqual(e.absolute_path, deque([]))

        self.assertEqual(e.schema_path, deque(["type"]))
        self.assertEqual(e.relative_schema_path, deque(["type"]))
        self.assertEqual(e.absolute_schema_path, deque(["type"]))

        self.assertEqual(len(e.context), 2)

        e1, e2 = sorted_errors(e.context)

        self.assertEqual(e1.validator, "type")
        self.assertEqual(e1.validator_value, schema["type"][0]["type"])
        self.assertEqual(e1.instance, instance)
        self.assertEqual(e1.schema, schema["type"][0])
        self.assertIs(e1.parent, e)

        self.assertEqual(e1.path, deque([]))
        self.assertEqual(e1.relative_path, deque([]))
        self.assertEqual(e1.absolute_path, deque([]))

        self.assertEqual(e1.schema_path, deque([0, "type"]))
        self.assertEqual(e1.relative_schema_path, deque([0, "type"]))
        self.assertEqual(e1.absolute_schema_path, deque(["type", 0, "type"]))

        self.assertFalse(e1.context)

        self.assertEqual(e2.validator, "enum")
        self.assertEqual(e2.validator_value, [2])
        self.assertEqual(e2.instance, 1)
        self.assertEqual(e2.schema, {u"enum": [2]})
        self.assertIs(e2.parent, e)

        self.assertEqual(e2.path, deque(["foo"]))
        self.assertEqual(e2.relative_path, deque(["foo"]))
        self.assertEqual(e2.absolute_path, deque(["foo"]))

        self.assertEqual(
            e2.schema_path, deque([1, "properties", "foo", "enum"]),
        )
        self.assertEqual(
            e2.relative_schema_path, deque([1, "properties", "foo", "enum"]),
        )
        self.assertEqual(
            e2.absolute_schema_path,
            deque(["type", 1, "properties", "foo", "enum"]),
        )

        self.assertFalse(e2.context)

    def test_single_nesting(self):
        instance = {"foo": 2, "bar": [1], "baz": 15, "quux": "spam"}
        schema = {
            "properties": {
                "foo": {"type": "string"},
                "bar": {"minItems": 2},
                "baz": {"maximum": 10, "enum": [2, 4, 6, 8]},
            },
        }

        validator = validators.Draft3Validator(schema)
        errors = validator.iter_errors(instance)
        e1, e2, e3, e4 = sorted_errors(errors)

        self.assertEqual(e1.path, deque(["bar"]))
        self.assertEqual(e2.path, deque(["baz"]))
        self.assertEqual(e3.path, deque(["baz"]))
        self.assertEqual(e4.path, deque(["foo"]))

        self.assertEqual(e1.relative_path, deque(["bar"]))
        self.assertEqual(e2.relative_path, deque(["baz"]))
        self.assertEqual(e3.relative_path, deque(["baz"]))
        self.assertEqual(e4.relative_path, deque(["foo"]))

        self.assertEqual(e1.absolute_path, deque(["bar"]))
        self.assertEqual(e2.absolute_path, deque(["baz"]))
        self.assertEqual(e3.absolute_path, deque(["baz"]))
        self.assertEqual(e4.absolute_path, deque(["foo"]))

        self.assertEqual(e1.validator, "minItems")
        self.assertEqual(e2.validator, "enum")
        self.assertEqual(e3.validator, "maximum")
        self.assertEqual(e4.validator, "type")

    def test_multiple_nesting(self):
        instance = [1, {"foo": 2, "bar": {"baz": [1]}}, "quux"]
        schema = {
            "type": "string",
            "items": {
                "type": ["string", "object"],
                "properties": {
                    "foo": {"enum": [1, 3]},
                    "bar": {
                        "type": "array",
                        "properties": {
                            "bar": {"required": True},
                            "baz": {"minItems": 2},
                        },
                    },
                },
            },
        }

        validator = validators.Draft3Validator(schema)
        errors = validator.iter_errors(instance)
        e1, e2, e3, e4, e5, e6 = sorted_errors(errors)

        self.assertEqual(e1.path, deque([]))
        self.assertEqual(e2.path, deque([0]))
        self.assertEqual(e3.path, deque([1, "bar"]))
        self.assertEqual(e4.path, deque([1, "bar", "bar"]))
        self.assertEqual(e5.path, deque([1, "bar", "baz"]))
        self.assertEqual(e6.path, deque([1, "foo"]))

        self.assertEqual(e1.schema_path, deque(["type"]))
        self.assertEqual(e2.schema_path, deque(["items", "type"]))
        self.assertEqual(
            list(e3.schema_path), ["items", "properties", "bar", "type"],
        )
        self.assertEqual(
            list(e4.schema_path),
            ["items", "properties", "bar", "properties", "bar", "required"],
        )
        self.assertEqual(
            list(e5.schema_path),
            ["items", "properties", "bar", "properties", "baz", "minItems"]
        )
        self.assertEqual(
            list(e6.schema_path), ["items", "properties", "foo", "enum"],
        )

        self.assertEqual(e1.validator, "type")
        self.assertEqual(e2.validator, "type")
        self.assertEqual(e3.validator, "type")
        self.assertEqual(e4.validator, "required")
        self.assertEqual(e5.validator, "minItems")
        self.assertEqual(e6.validator, "enum")

    def test_recursive(self):
        schema = {
            "definitions": {
                "node": {
                    "anyOf": [{
                        "type": "object",
                        "required": ["name", "children"],
                        "properties": {
                            "name": {
                                "type": "string",
                            },
                            "children": {
                                "type": "object",
                                "patternProperties": {
                                    "^.*$": {
                                        "$ref": "#/definitions/node",
                                    },
                                },
                            },
                        },
                    }],
                },
            },
            "type": "object",
            "required": ["root"],
            "properties": {"root": {"$ref": "#/definitions/node"}},
        }

        instance = {
            "root": {
                "name": "root",
                "children": {
                    "a": {
                        "name": "a",
                        "children": {
                            "ab": {
                                "name": "ab",
                                # missing "children"
                            },
                        },
                    },
                },
            },
        }
        validator = validators.Draft4Validator(schema)

        e, = validator.iter_errors(instance)
        self.assertEqual(e.absolute_path, deque(["root"]))
        self.assertEqual(
            e.absolute_schema_path, deque(["properties", "root", "anyOf"]),
        )

        e1, = e.context
        self.assertEqual(e1.absolute_path, deque(["root", "children", "a"]))
        self.assertEqual(
            e1.absolute_schema_path, deque(
                [
                    "properties",
                    "root",
                    "anyOf",
                    0,
                    "properties",
                    "children",
                    "patternProperties",
                    "^.*$",
                    "anyOf",
                ],
            ),
        )

        e2, = e1.context
        self.assertEqual(
            e2.absolute_path, deque(
                ["root", "children", "a", "children", "ab"],
            ),
        )
        self.assertEqual(
            e2.absolute_schema_path, deque(
                [
                    "properties",
                    "root",
                    "anyOf",
                    0,
                    "properties",
                    "children",
                    "patternProperties",
                    "^.*$",
                    "anyOf",
                    0,
                    "properties",
                    "children",
                    "patternProperties",
                    "^.*$",
                    "anyOf",
                ],
            ),
        )

    def test_additionalProperties(self):
        instance = {"bar": "bar", "foo": 2}
        schema = {"additionalProperties": {"type": "integer", "minimum": 5}}

        validator = validators.Draft3Validator(schema)
        errors = validator.iter_errors(instance)
        e1, e2 = sorted_errors(errors)

        self.assertEqual(e1.path, deque(["bar"]))
        self.assertEqual(e2.path, deque(["foo"]))

        self.assertEqual(e1.validator, "type")
        self.assertEqual(e2.validator, "minimum")

    def test_patternProperties(self):
        instance = {"bar": 1, "foo": 2}
        schema = {
            "patternProperties": {
                "bar": {"type": "string"},
                "foo": {"minimum": 5},
            },
        }

        validator = validators.Draft3Validator(schema)
        errors = validator.iter_errors(instance)
        e1, e2 = sorted_errors(errors)

        self.assertEqual(e1.path, deque(["bar"]))
        self.assertEqual(e2.path, deque(["foo"]))

        self.assertEqual(e1.validator, "type")
        self.assertEqual(e2.validator, "minimum")

    def test_additionalItems(self):
        instance = ["foo", 1]
        schema = {
            "items": [],
            "additionalItems": {"type": "integer", "minimum": 5},
        }

        validator = validators.Draft3Validator(schema)
        errors = validator.iter_errors(instance)
        e1, e2 = sorted_errors(errors)

        self.assertEqual(e1.path, deque([0]))
        self.assertEqual(e2.path, deque([1]))

        self.assertEqual(e1.validator, "type")
        self.assertEqual(e2.validator, "minimum")

    def test_additionalItems_with_items(self):
        instance = ["foo", "bar", 1]
        schema = {
            "items": [{}],
            "additionalItems": {"type": "integer", "minimum": 5},
        }

        validator = validators.Draft3Validator(schema)
        errors = validator.iter_errors(instance)
        e1, e2 = sorted_errors(errors)

        self.assertEqual(e1.path, deque([1]))
        self.assertEqual(e2.path, deque([2]))

        self.assertEqual(e1.validator, "type")
        self.assertEqual(e2.validator, "minimum")

    def test_propertyNames(self):
        instance = {"foo": 12}
        schema = {"propertyNames": {"not": {"const": "foo"}}}

        validator = validators.Draft7Validator(schema)
        error, = validator.iter_errors(instance)

        self.assertEqual(error.validator, "not")
        self.assertEqual(
            error.message,
            "%r is not allowed for %r" % ({"const": "foo"}, "foo"),
        )
        self.assertEqual(error.path, deque([]))
        self.assertEqual(error.schema_path, deque(["propertyNames", "not"]))

    def test_if_then(self):
        schema = {
            "if": {"const": 12},
            "then": {"const": 13},
        }

        validator = validators.Draft7Validator(schema)
        error, = validator.iter_errors(12)

        self.assertEqual(error.validator, "const")
        self.assertEqual(error.message, "13 was expected")
        self.assertEqual(error.path, deque([]))
        self.assertEqual(error.schema_path, deque(["if", "then", "const"]))

    def test_if_else(self):
        schema = {
            "if": {"const": 12},
            "else": {"const": 13},
        }

        validator = validators.Draft7Validator(schema)
        error, = validator.iter_errors(15)

        self.assertEqual(error.validator, "const")
        self.assertEqual(error.message, "13 was expected")
        self.assertEqual(error.path, deque([]))
        self.assertEqual(error.schema_path, deque(["if", "else", "const"]))

    def test_boolean_schema_False(self):
        validator = validators.Draft7Validator(False)
        error, = validator.iter_errors(12)

        self.assertEqual(
            (
                error.message,
                error.validator,
                error.validator_value,
                error.instance,
                error.schema,
                error.schema_path,
            ),
            (
                "False schema does not allow 12",
                None,
                None,
                12,
                False,
                deque([]),
            ),
        )

    def test_ref(self):
        ref, schema = "someRef", {"additionalProperties": {"type": "integer"}}
        validator = validators.Draft7Validator(
            {"$ref": ref},
            resolver=validators.RefResolver("", {}, store={ref: schema}),
        )
        error, = validator.iter_errors({"foo": "notAnInteger"})

        self.assertEqual(
            (
                error.message,
                error.validator,
                error.validator_value,
                error.instance,
                error.absolute_path,
                error.schema,
                error.schema_path,
            ),
            (
                "'notAnInteger' is not of type 'integer'",
                "type",
                "integer",
                "notAnInteger",
                deque(["foo"]),
                {"type": "integer"},
                deque(["additionalProperties", "type"]),
            ),
        )


class MetaSchemaTestsMixin(object):
    # TODO: These all belong upstream
    def test_invalid_properties(self):
        with self.assertRaises(exceptions.SchemaError):
            self.Validator.check_schema({"properties": {"test": object()}})

    def test_minItems_invalid_string(self):
        with self.assertRaises(exceptions.SchemaError):
            # needs to be an integer
            self.Validator.check_schema({"minItems": "1"})

    def test_enum_allows_empty_arrays(self):
        """
        Technically, all the spec says is they SHOULD have elements, not MUST.

        See https://github.com/Julian/jsonschema/issues/529.
        """
        self.Validator.check_schema({"enum": []})

    def test_enum_allows_non_unique_items(self):
        """
        Technically, all the spec says is they SHOULD be unique, not MUST.

        See https://github.com/Julian/jsonschema/issues/529.
        """
        self.Validator.check_schema({"enum": [12, 12]})


class ValidatorTestMixin(MetaSchemaTestsMixin, object):
    def test_valid_instances_are_valid(self):
        schema, instance = self.valid
        self.assertTrue(self.Validator(schema).is_valid(instance))

    def test_invalid_instances_are_not_valid(self):
        schema, instance = self.invalid
        self.assertFalse(self.Validator(schema).is_valid(instance))

    def test_non_existent_properties_are_ignored(self):
        self.Validator({object(): object()}).validate(instance=object())

    def test_it_creates_a_ref_resolver_if_not_provided(self):
        self.assertIsInstance(
            self.Validator({}).resolver,
            validators.RefResolver,
        )

    def test_it_delegates_to_a_ref_resolver(self):
        ref, schema = "someCoolRef", {"type": "integer"}
        resolver = validators.RefResolver("", {}, store={ref: schema})
        validator = self.Validator({"$ref": ref}, resolver=resolver)

        with self.assertRaises(exceptions.ValidationError):
            validator.validate(None)

    def test_it_delegates_to_a_legacy_ref_resolver(self):
        """
        Legacy RefResolvers support only the context manager form of
        resolution.
        """

        class LegacyRefResolver(object):
            @contextmanager
            def resolving(this, ref):
                self.assertEqual(ref, "the ref")
                yield {"type": "integer"}

        resolver = LegacyRefResolver()
        schema = {"$ref": "the ref"}

        with self.assertRaises(exceptions.ValidationError):
            self.Validator(schema, resolver=resolver).validate(None)

    def test_is_type_is_true_for_valid_type(self):
        self.assertTrue(self.Validator({}).is_type("foo", "string"))

    def test_is_type_is_false_for_invalid_type(self):
        self.assertFalse(self.Validator({}).is_type("foo", "array"))

    def test_is_type_evades_bool_inheriting_from_int(self):
        self.assertFalse(self.Validator({}).is_type(True, "integer"))
        self.assertFalse(self.Validator({}).is_type(True, "number"))

    @unittest.skipIf(PY3, "In Python 3 json.load always produces unicode")
    def test_string_a_bytestring_is_a_string(self):
        self.Validator({"type": "string"}).validate(b"foo")

    def test_patterns_can_be_native_strings(self):
        """
        See https://github.com/Julian/jsonschema/issues/611.
        """
        self.Validator({"pattern": "foo"}).validate("foo")

    def test_it_can_validate_with_decimals(self):
        schema = {"items": {"type": "number"}}
        Validator = validators.extend(
            self.Validator,
            type_checker=self.Validator.TYPE_CHECKER.redefine(
                "number",
                lambda checker, thing: isinstance(
                    thing, (int, float, Decimal),
                ) and not isinstance(thing, bool),
            )
        )

        validator = Validator(schema)
        validator.validate([1, 1.1, Decimal(1) / Decimal(8)])

        invalid = ["foo", {}, [], True, None]
        self.assertEqual(
            [error.instance for error in validator.iter_errors(invalid)],
            invalid,
        )

    def test_it_returns_true_for_formats_it_does_not_know_about(self):
        validator = self.Validator(
            {"format": "carrot"}, format_checker=FormatChecker(),
        )
        validator.validate("bugs")

    def test_it_does_not_validate_formats_by_default(self):
        validator = self.Validator({})
        self.assertIsNone(validator.format_checker)

    def test_it_validates_formats_if_a_checker_is_provided(self):
        checker = FormatChecker()
        bad = ValueError("Bad!")

        @checker.checks("foo", raises=ValueError)
        def check(value):
            if value == "good":
                return True
            elif value == "bad":
                raise bad
            else:  # pragma: no cover
                self.fail("What is {}? [Baby Don't Hurt Me]".format(value))

        validator = self.Validator(
            {"format": "foo"}, format_checker=checker,
        )

        validator.validate("good")
        with self.assertRaises(exceptions.ValidationError) as cm:
            validator.validate("bad")

        # Make sure original cause is attached
        self.assertIs(cm.exception.cause, bad)

    def test_non_string_custom_type(self):
        non_string_type = object()
        schema = {"type": [non_string_type]}
        Crazy = validators.extend(
            self.Validator,
            type_checker=self.Validator.TYPE_CHECKER.redefine(
                non_string_type,
                lambda checker, thing: isinstance(thing, int),
            )
        )
        Crazy(schema).validate(15)

    def test_it_properly_formats_tuples_in_errors(self):
        """
        A tuple instance properly formats validation errors for uniqueItems.

        See https://github.com/Julian/jsonschema/pull/224
        """
        TupleValidator = validators.extend(
            self.Validator,
            type_checker=self.Validator.TYPE_CHECKER.redefine(
                "array",
                lambda checker, thing: isinstance(thing, tuple),
            )
        )
        with self.assertRaises(exceptions.ValidationError) as e:
            TupleValidator({"uniqueItems": True}).validate((1, 1))
        self.assertIn("(1, 1) has non-unique elements", str(e.exception))


class AntiDraft6LeakMixin(object):
    """
    Make sure functionality from draft 6 doesn't leak backwards in time.
    """

    def test_True_is_not_a_schema(self):
        with self.assertRaises(exceptions.SchemaError) as e:
            self.Validator.check_schema(True)
        self.assertIn("True is not of type", str(e.exception))

    def test_False_is_not_a_schema(self):
        with self.assertRaises(exceptions.SchemaError) as e:
            self.Validator.check_schema(False)
        self.assertIn("False is not of type", str(e.exception))

    @unittest.skip(bug(523))
    def test_True_is_not_a_schema_even_if_you_forget_to_check(self):
        resolver = validators.RefResolver("", {})
        with self.assertRaises(Exception) as e:
            self.Validator(True, resolver=resolver).validate(12)
        self.assertNotIsInstance(e.exception, exceptions.ValidationError)

    @unittest.skip(bug(523))
    def test_False_is_not_a_schema_even_if_you_forget_to_check(self):
        resolver = validators.RefResolver("", {})
        with self.assertRaises(Exception) as e:
            self.Validator(False, resolver=resolver).validate(12)
        self.assertNotIsInstance(e.exception, exceptions.ValidationError)


class TestDraft3Validator(AntiDraft6LeakMixin, ValidatorTestMixin, TestCase):
    Validator = validators.Draft3Validator
    valid = {}, {}
    invalid = {"type": "integer"}, "foo"

    def test_any_type_is_valid_for_type_any(self):
        validator = self.Validator({"type": "any"})
        validator.validate(object())

    def test_any_type_is_redefinable(self):
        """
        Sigh, because why not.
        """
        Crazy = validators.extend(
            self.Validator,
            type_checker=self.Validator.TYPE_CHECKER.redefine(
                "any", lambda checker, thing: isinstance(thing, int),
            )
        )
        validator = Crazy({"type": "any"})
        validator.validate(12)
        with self.assertRaises(exceptions.ValidationError):
            validator.validate("foo")

    def test_is_type_is_true_for_any_type(self):
        self.assertTrue(self.Validator({}).is_valid(object(), {"type": "any"}))

    def test_is_type_does_not_evade_bool_if_it_is_being_tested(self):
        self.assertTrue(self.Validator({}).is_type(True, "boolean"))
        self.assertTrue(self.Validator({}).is_valid(True, {"type": "any"}))


class TestDraft4Validator(AntiDraft6LeakMixin, ValidatorTestMixin, TestCase):
    Validator = validators.Draft4Validator
    valid = {}, {}
    invalid = {"type": "integer"}, "foo"


class TestDraft6Validator(ValidatorTestMixin, TestCase):
    Validator = validators.Draft6Validator
    valid = {}, {}
    invalid = {"type": "integer"}, "foo"


class TestDraft7Validator(ValidatorTestMixin, TestCase):
    Validator = validators.Draft7Validator
    valid = {}, {}
    invalid = {"type": "integer"}, "foo"


class TestValidatorFor(SynchronousTestCase):
    def test_draft_3(self):
        schema = {"$schema": "http://json-schema.org/draft-03/schema"}
        self.assertIs(
            validators.validator_for(schema),
            validators.Draft3Validator,
        )

        schema = {"$schema": "http://json-schema.org/draft-03/schema#"}
        self.assertIs(
            validators.validator_for(schema),
            validators.Draft3Validator,
        )

    def test_draft_4(self):
        schema = {"$schema": "http://json-schema.org/draft-04/schema"}
        self.assertIs(
            validators.validator_for(schema),
            validators.Draft4Validator,
        )

        schema = {"$schema": "http://json-schema.org/draft-04/schema#"}
        self.assertIs(
            validators.validator_for(schema),
            validators.Draft4Validator,
        )

    def test_draft_6(self):
        schema = {"$schema": "http://json-schema.org/draft-06/schema"}
        self.assertIs(
            validators.validator_for(schema),
            validators.Draft6Validator,
        )

        schema = {"$schema": "http://json-schema.org/draft-06/schema#"}
        self.assertIs(
            validators.validator_for(schema),
            validators.Draft6Validator,
        )

    def test_draft_7(self):
        schema = {"$schema": "http://json-schema.org/draft-07/schema"}
        self.assertIs(
            validators.validator_for(schema),
            validators.Draft7Validator,
        )

        schema = {"$schema": "http://json-schema.org/draft-07/schema#"}
        self.assertIs(
            validators.validator_for(schema),
            validators.Draft7Validator,
        )

    def test_True(self):
        self.assertIs(
            validators.validator_for(True),
            validators._LATEST_VERSION,
        )

    def test_False(self):
        self.assertIs(
            validators.validator_for(False),
            validators._LATEST_VERSION,
        )

    def test_custom_validator(self):
        Validator = validators.create(
            meta_schema={"id": "meta schema id"},
            version="12",
            id_of=lambda s: s.get("id", ""),
        )
        schema = {"$schema": "meta schema id"}
        self.assertIs(
            validators.validator_for(schema),
            Validator,
        )

    def test_custom_validator_draft6(self):
        Validator = validators.create(
            meta_schema={"$id": "meta schema $id"},
            version="13",
        )
        schema = {"$schema": "meta schema $id"}
        self.assertIs(
            validators.validator_for(schema),
            Validator,
        )

    def test_validator_for_jsonschema_default(self):
        self.assertIs(validators.validator_for({}), validators._LATEST_VERSION)

    def test_validator_for_custom_default(self):
        self.assertIs(validators.validator_for({}, default=None), None)

    def test_warns_if_meta_schema_specified_was_not_found(self):
        self.assertWarns(
            category=DeprecationWarning,
            message=(
                "The metaschema specified by $schema was not found. "
                "Using the latest draft to validate, but this will raise "
                "an error in the future."
            ),
            # https://tm.tl/9363 :'(
            filename=sys.modules[self.assertWarns.__module__].__file__,

            f=validators.validator_for,
            schema={u"$schema": "unknownSchema"},
            default={},
        )

    def test_does_not_warn_if_meta_schema_is_unspecified(self):
        validators.validator_for(schema={}, default={}),
        self.assertFalse(self.flushWarnings())


class TestValidate(SynchronousTestCase):
    def assertUses(self, schema, Validator):
        result = []
        self.patch(Validator, "check_schema", result.append)
        validators.validate({}, schema)
        self.assertEqual(result, [schema])

    def test_draft3_validator_is_chosen(self):
        self.assertUses(
            schema={"$schema": "http://json-schema.org/draft-03/schema#"},
            Validator=validators.Draft3Validator,
        )
        # Make sure it works without the empty fragment
        self.assertUses(
            schema={"$schema": "http://json-schema.org/draft-03/schema"},
            Validator=validators.Draft3Validator,
        )

    def test_draft4_validator_is_chosen(self):
        self.assertUses(
            schema={"$schema": "http://json-schema.org/draft-04/schema#"},
            Validator=validators.Draft4Validator,
        )
        # Make sure it works without the empty fragment
        self.assertUses(
            schema={"$schema": "http://json-schema.org/draft-04/schema"},
            Validator=validators.Draft4Validator,
        )

    def test_draft6_validator_is_chosen(self):
        self.assertUses(
            schema={"$schema": "http://json-schema.org/draft-06/schema#"},
            Validator=validators.Draft6Validator,
        )
        # Make sure it works without the empty fragment
        self.assertUses(
            schema={"$schema": "http://json-schema.org/draft-06/schema"},
            Validator=validators.Draft6Validator,
        )

    def test_draft7_validator_is_chosen(self):
        self.assertUses(
            schema={"$schema": "http://json-schema.org/draft-07/schema#"},
            Validator=validators.Draft7Validator,
        )
        # Make sure it works without the empty fragment
        self.assertUses(
            schema={"$schema": "http://json-schema.org/draft-07/schema"},
            Validator=validators.Draft7Validator,
        )

    def test_draft7_validator_is_the_default(self):
        self.assertUses(schema={}, Validator=validators.Draft7Validator)

    def test_validation_error_message(self):
        with self.assertRaises(exceptions.ValidationError) as e:
            validators.validate(12, {"type": "string"})
        self.assertRegexpMatches(
            str(e.exception),
            "(?s)Failed validating u?'.*' in schema.*On instance",
        )

    def test_schema_error_message(self):
        with self.assertRaises(exceptions.SchemaError) as e:
            validators.validate(12, {"type": 12})
        self.assertRegexpMatches(
            str(e.exception),
            "(?s)Failed validating u?'.*' in metaschema.*On schema",
        )

    def test_it_uses_best_match(self):
        # This is a schema that best_match will recurse into
        schema = {"oneOf": [{"type": "string"}, {"type": "array"}]}
        with self.assertRaises(exceptions.ValidationError) as e:
            validators.validate(12, schema)
        self.assertIn("12 is not of type", str(e.exception))


class TestRefResolver(SynchronousTestCase):

    base_uri = ""
    stored_uri = "foo://stored"
    stored_schema = {"stored": "schema"}

    def setUp(self):
        self.referrer = {}
        self.store = {self.stored_uri: self.stored_schema}
        self.resolver = validators.RefResolver(
            self.base_uri, self.referrer, self.store,
        )

    def test_it_does_not_retrieve_schema_urls_from_the_network(self):
        ref = validators.Draft3Validator.META_SCHEMA["id"]
        self.patch(
            self.resolver,
            "resolve_remote",
            lambda *args, **kwargs: self.fail("Should not have been called!"),
        )
        with self.resolver.resolving(ref) as resolved:
            pass
        self.assertEqual(resolved, validators.Draft3Validator.META_SCHEMA)

    def test_it_resolves_local_refs(self):
        ref = "#/properties/foo"
        self.referrer["properties"] = {"foo": object()}
        with self.resolver.resolving(ref) as resolved:
            self.assertEqual(resolved, self.referrer["properties"]["foo"])

    def test_it_resolves_local_refs_with_id(self):
        schema = {"id": "http://bar/schema#", "a": {"foo": "bar"}}
        resolver = validators.RefResolver.from_schema(
            schema,
            id_of=lambda schema: schema.get(u"id", u""),
        )
        with resolver.resolving("#/a") as resolved:
            self.assertEqual(resolved, schema["a"])
        with resolver.resolving("http://bar/schema#/a") as resolved:
            self.assertEqual(resolved, schema["a"])

    def test_it_retrieves_stored_refs(self):
        with self.resolver.resolving(self.stored_uri) as resolved:
            self.assertIs(resolved, self.stored_schema)

        self.resolver.store["cached_ref"] = {"foo": 12}
        with self.resolver.resolving("cached_ref#/foo") as resolved:
            self.assertEqual(resolved, 12)

    def test_it_retrieves_unstored_refs_via_requests(self):
        ref = "http://bar#baz"
        schema = {"baz": 12}

        if "requests" in sys.modules:
            self.addCleanup(
                sys.modules.__setitem__, "requests", sys.modules["requests"],
            )
        sys.modules["requests"] = ReallyFakeRequests({"http://bar": schema})

        with self.resolver.resolving(ref) as resolved:
            self.assertEqual(resolved, 12)

    def test_it_retrieves_unstored_refs_via_urlopen(self):
        ref = "http://bar#baz"
        schema = {"baz": 12}

        if "requests" in sys.modules:
            self.addCleanup(
                sys.modules.__setitem__, "requests", sys.modules["requests"],
            )
        sys.modules["requests"] = None

        @contextmanager
        def fake_urlopen(url):
            self.assertEqual(url, "http://bar")
            yield BytesIO(json.dumps(schema).encode("utf8"))

        self.addCleanup(setattr, validators, "urlopen", validators.urlopen)
        validators.urlopen = fake_urlopen

        with self.resolver.resolving(ref) as resolved:
            pass
        self.assertEqual(resolved, 12)

    def test_it_retrieves_local_refs_via_urlopen(self):
        with tempfile.NamedTemporaryFile(delete=False, mode="wt") as tempf:
            self.addCleanup(os.remove, tempf.name)
            json.dump({"foo": "bar"}, tempf)

        ref = "file://{}#foo".format(pathname2url(tempf.name))
        with self.resolver.resolving(ref) as resolved:
            self.assertEqual(resolved, "bar")

    def test_it_can_construct_a_base_uri_from_a_schema(self):
        schema = {"id": "foo"}
        resolver = validators.RefResolver.from_schema(
            schema,
            id_of=lambda schema: schema.get(u"id", u""),
        )
        self.assertEqual(resolver.base_uri, "foo")
        self.assertEqual(resolver.resolution_scope, "foo")
        with resolver.resolving("") as resolved:
            self.assertEqual(resolved, schema)
        with resolver.resolving("#") as resolved:
            self.assertEqual(resolved, schema)
        with resolver.resolving("foo") as resolved:
            self.assertEqual(resolved, schema)
        with resolver.resolving("foo#") as resolved:
            self.assertEqual(resolved, schema)

    def test_it_can_construct_a_base_uri_from_a_schema_without_id(self):
        schema = {}
        resolver = validators.RefResolver.from_schema(schema)
        self.assertEqual(resolver.base_uri, "")
        self.assertEqual(resolver.resolution_scope, "")
        with resolver.resolving("") as resolved:
            self.assertEqual(resolved, schema)
        with resolver.resolving("#") as resolved:
            self.assertEqual(resolved, schema)

    def test_custom_uri_scheme_handlers(self):
        def handler(url):
            self.assertEqual(url, ref)
            return schema

        schema = {"foo": "bar"}
        ref = "foo://bar"
        resolver = validators.RefResolver("", {}, handlers={"foo": handler})
        with resolver.resolving(ref) as resolved:
            self.assertEqual(resolved, schema)

    def test_cache_remote_on(self):
        response = [object()]

        def handler(url):
            try:
                return response.pop()
            except IndexError:  # pragma: no cover
                self.fail("Response must not have been cached!")

        ref = "foo://bar"
        resolver = validators.RefResolver(
            "", {}, cache_remote=True, handlers={"foo": handler},
        )
        with resolver.resolving(ref):
            pass
        with resolver.resolving(ref):
            pass

    def test_cache_remote_off(self):
        response = [object()]

        def handler(url):
            try:
                return response.pop()
            except IndexError:  # pragma: no cover
                self.fail("Handler called twice!")

        ref = "foo://bar"
        resolver = validators.RefResolver(
            "", {}, cache_remote=False, handlers={"foo": handler},
        )
        with resolver.resolving(ref):
            pass

    def test_if_you_give_it_junk_you_get_a_resolution_error(self):
        error = ValueError("Oh no! What's this?")

        def handler(url):
            raise error

        ref = "foo://bar"
        resolver = validators.RefResolver("", {}, handlers={"foo": handler})
        with self.assertRaises(exceptions.RefResolutionError) as err:
            with resolver.resolving(ref):
                self.fail("Shouldn't get this far!")  # pragma: no cover
        self.assertEqual(err.exception, exceptions.RefResolutionError(error))

    def test_helpful_error_message_on_failed_pop_scope(self):
        resolver = validators.RefResolver("", {})
        resolver.pop_scope()
        with self.assertRaises(exceptions.RefResolutionError) as exc:
            resolver.pop_scope()
        self.assertIn("Failed to pop the scope", str(exc.exception))


def sorted_errors(errors):
    def key(error):
        return (
            [str(e) for e in error.path],
            [str(e) for e in error.schema_path],
        )
    return sorted(errors, key=key)


@attr.s
class ReallyFakeRequests(object):

    _responses = attr.ib()

    def get(self, url):
        response = self._responses.get(url)
        if url is None:  # pragma: no cover
            raise ValueError("Unknown URL: " + repr(url))
        return _ReallyFakeJSONResponse(json.dumps(response))


@attr.s
class _ReallyFakeJSONResponse(object):

    _response = attr.ib()

    def json(self):
        return json.loads(self._response)
