import numbers

from pyrsistent import pmap
import attr

from jsonschema.compat import int_types, str_types
from jsonschema.exceptions import UndefinedTypeCheck


def is_array(checker, instance):
    return isinstance(instance, list)


def is_bool(checker, instance):
    return isinstance(instance, bool)


def is_integer(checker, instance):
    # bool inherits from int, so ensure bools aren't reported as ints
    if isinstance(instance, bool):
        return False
    return isinstance(instance, int_types)


def is_null(checker, instance):
    return instance is None


def is_number(checker, instance):
    # bool inherits from int, so ensure bools aren't reported as ints
    if isinstance(instance, bool):
        return False
    return isinstance(instance, numbers.Number)


def is_object(checker, instance):
    return isinstance(instance, dict)


def is_string(checker, instance):
    return isinstance(instance, str_types)


def is_any(checker, instance):
    return True


@attr.s(frozen=True)
class TypeChecker(object):
    """
    A ``type`` property checker.

    A `TypeChecker` performs type checking for an `IValidator`. Type
    checks to perform are updated using `TypeChecker.redefine` or
    `TypeChecker.redefine_many` and removed via `TypeChecker.remove`.
    Each of these return a new `TypeChecker` object.

    Arguments:

        type_checkers (dict):

            The initial mapping of types to their checking functions.
    """
    _type_checkers = attr.ib(default=pmap(), converter=pmap)

    def is_type(self, instance, type):
        """
        Check if the instance is of the appropriate type.

        Arguments:

            instance (object):

                The instance to check

            type (str):

                The name of the type that is expected.

        Returns:

            bool: Whether it conformed.


        Raises:

            `jsonschema.exceptions.UndefinedTypeCheck`:
                if type is unknown to this object.
        """
        try:
            fn = self._type_checkers[type]
        except KeyError:
            raise UndefinedTypeCheck(type)

        return fn(self, instance)

    def redefine(self, type, fn):
        """
        Produce a new checker with the given type redefined.

        Arguments:

            type (str):

                The name of the type to check.

            fn (collections.Callable):

                A function taking exactly two parameters - the type
                checker calling the function and the instance to check.
                The function should return true if instance is of this
                type and false otherwise.

        Returns:

            A new `TypeChecker` instance.
        """
        return self.redefine_many({type: fn})

    def redefine_many(self, definitions=()):
        """
        Produce a new checker with the given types redefined.

        Arguments:

            definitions (dict):

                A dictionary mapping types to their checking functions.

        Returns:

            A new `TypeChecker` instance.
        """
        return attr.evolve(
            self, type_checkers=self._type_checkers.update(definitions),
        )

    def remove(self, *types):
        """
        Produce a new checker with the given types forgotten.

        Arguments:

            types (~collections.Iterable):

                the names of the types to remove.

        Returns:

            A new `TypeChecker` instance

        Raises:

            `jsonschema.exceptions.UndefinedTypeCheck`:

                if any given type is unknown to this object
        """

        checkers = self._type_checkers
        for each in types:
            try:
                checkers = checkers.remove(each)
            except KeyError:
                raise UndefinedTypeCheck(each)
        return attr.evolve(self, type_checkers=checkers)


draft3_type_checker = TypeChecker(
    {
        u"any": is_any,
        u"array": is_array,
        u"boolean": is_bool,
        u"integer": is_integer,
        u"object": is_object,
        u"null": is_null,
        u"number": is_number,
        u"string": is_string,
    },
)
draft4_type_checker = draft3_type_checker.remove(u"any")
draft6_type_checker = draft4_type_checker.redefine(
    u"integer",
    lambda checker, instance: (
        is_integer(checker, instance) or
        isinstance(instance, float) and instance.is_integer()
    ),
)
draft7_type_checker = draft6_type_checker
