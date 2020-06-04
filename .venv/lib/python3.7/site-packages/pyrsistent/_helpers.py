from functools import wraps
import six
from pyrsistent._pmap import PMap, pmap
from pyrsistent._pset import PSet, pset
from pyrsistent._pvector import PVector, pvector


def freeze(o):
    """
    Recursively convert simple Python containers into pyrsistent versions
    of those containers.

    - list is converted to pvector, recursively
    - dict is converted to pmap, recursively on values (but not keys)
    - set is converted to pset, but not recursively
    - tuple is converted to tuple, recursively.

    Sets and dict keys are not recursively frozen because they do not contain
    mutable data by convention. The main exception to this rule is that
    dict keys and set elements are often instances of mutable objects that
    support hash-by-id, which this function can't convert anyway.

    >>> freeze(set([1, 2]))
    pset([1, 2])
    >>> freeze([1, {'a': 3}])
    pvector([1, pmap({'a': 3})])
    >>> freeze((1, []))
    (1, pvector([]))
    """
    typ = type(o)
    if typ is dict:
        return pmap(dict((k, freeze(v)) for k, v in six.iteritems(o)))
    if typ is list:
        return pvector(map(freeze, o))
    if typ is tuple:
        return tuple(map(freeze, o))
    if typ is set:
        return pset(o)
    return o


def thaw(o):
    """
    Recursively convert pyrsistent containers into simple Python containers.

    - pvector is converted to list, recursively
    - pmap is converted to dict, recursively on values (but not keys)
    - pset is converted to set, but not recursively
    - tuple is converted to tuple, recursively.

    >>> from pyrsistent import s, m, v
    >>> thaw(s(1, 2))
    {1, 2}
    >>> thaw(v(1, m(a=3)))
    [1, {'a': 3}]
    >>> thaw((1, v()))
    (1, [])
    """
    if isinstance(o, PVector):
        return list(map(thaw, o))
    if isinstance(o, PMap):
        return dict((k, thaw(v)) for k, v in o.iteritems())
    if isinstance(o, PSet):
        return set(o)
    if type(o) is tuple:
        return tuple(map(thaw, o))
    return o


def mutant(fn):
    """
    Convenience decorator to isolate mutation to within the decorated function (with respect
    to the input arguments).

    All arguments to the decorated function will be frozen so that they are guaranteed not to change.
    The return value is also frozen.
    """
    @wraps(fn)
    def inner_f(*args, **kwargs):
        return freeze(fn(*[freeze(e) for e in args], **dict(freeze(item) for item in kwargs.items())))

    return inner_f
