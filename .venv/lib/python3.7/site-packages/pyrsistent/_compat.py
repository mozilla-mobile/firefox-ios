from six import string_types


# enum compat
try:
    from enum import Enum
except:
    class Enum(object): pass
    # no objects will be instances of this class

# collections compat
try:
    from collections.abc import (
        Container,
        Hashable,
        Iterable,
        Mapping,
        Sequence,
        Set,
        Sized,
    )
except ImportError:
    from collections import (
        Container,
        Hashable,
        Iterable,
        Mapping,
        Sequence,
        Set,
        Sized,
    )
