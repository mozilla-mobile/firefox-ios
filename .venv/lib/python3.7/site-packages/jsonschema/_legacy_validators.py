from jsonschema import _utils
from jsonschema.compat import iteritems
from jsonschema.exceptions import ValidationError


def dependencies_draft3(validator, dependencies, instance, schema):
    if not validator.is_type(instance, "object"):
        return

    for property, dependency in iteritems(dependencies):
        if property not in instance:
            continue

        if validator.is_type(dependency, "object"):
            for error in validator.descend(
                instance, dependency, schema_path=property,
            ):
                yield error
        elif validator.is_type(dependency, "string"):
            if dependency not in instance:
                yield ValidationError(
                    "%r is a dependency of %r" % (dependency, property)
                )
        else:
            for each in dependency:
                if each not in instance:
                    message = "%r is a dependency of %r"
                    yield ValidationError(message % (each, property))


def disallow_draft3(validator, disallow, instance, schema):
    for disallowed in _utils.ensure_list(disallow):
        if validator.is_valid(instance, {"type": [disallowed]}):
            yield ValidationError(
                "%r is disallowed for %r" % (disallowed, instance)
            )


def extends_draft3(validator, extends, instance, schema):
    if validator.is_type(extends, "object"):
        for error in validator.descend(instance, extends):
            yield error
        return
    for index, subschema in enumerate(extends):
        for error in validator.descend(instance, subschema, schema_path=index):
            yield error


def items_draft3_draft4(validator, items, instance, schema):
    if not validator.is_type(instance, "array"):
        return

    if validator.is_type(items, "object"):
        for index, item in enumerate(instance):
            for error in validator.descend(item, items, path=index):
                yield error
    else:
        for (index, item), subschema in zip(enumerate(instance), items):
            for error in validator.descend(
                item, subschema, path=index, schema_path=index,
            ):
                yield error


def minimum_draft3_draft4(validator, minimum, instance, schema):
    if not validator.is_type(instance, "number"):
        return

    if schema.get("exclusiveMinimum", False):
        failed = instance <= minimum
        cmp = "less than or equal to"
    else:
        failed = instance < minimum
        cmp = "less than"

    if failed:
        yield ValidationError(
            "%r is %s the minimum of %r" % (instance, cmp, minimum)
        )


def maximum_draft3_draft4(validator, maximum, instance, schema):
    if not validator.is_type(instance, "number"):
        return

    if schema.get("exclusiveMaximum", False):
        failed = instance >= maximum
        cmp = "greater than or equal to"
    else:
        failed = instance > maximum
        cmp = "greater than"

    if failed:
        yield ValidationError(
            "%r is %s the maximum of %r" % (instance, cmp, maximum)
        )


def properties_draft3(validator, properties, instance, schema):
    if not validator.is_type(instance, "object"):
        return

    for property, subschema in iteritems(properties):
        if property in instance:
            for error in validator.descend(
                instance[property],
                subschema,
                path=property,
                schema_path=property,
            ):
                yield error
        elif subschema.get("required", False):
            error = ValidationError("%r is a required property" % property)
            error._set(
                validator="required",
                validator_value=subschema["required"],
                instance=instance,
                schema=schema,
            )
            error.path.appendleft(property)
            error.schema_path.extend([property, "required"])
            yield error


def type_draft3(validator, types, instance, schema):
    types = _utils.ensure_list(types)

    all_errors = []
    for index, type in enumerate(types):
        if validator.is_type(type, "object"):
            errors = list(validator.descend(instance, type, schema_path=index))
            if not errors:
                return
            all_errors.extend(errors)
        else:
            if validator.is_type(instance, type):
                return
    else:
        yield ValidationError(
            _utils.types_msg(instance, types), context=all_errors,
        )
