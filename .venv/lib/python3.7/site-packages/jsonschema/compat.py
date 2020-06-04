"""
Python 2/3 compatibility helpers.

Note: This module is *not* public API.
"""
import contextlib
import operator
import sys


try:
    from collections.abc import MutableMapping, Sequence  # noqa
except ImportError:
    from collections import MutableMapping, Sequence  # noqa

PY3 = sys.version_info[0] >= 3

if PY3:
    zip = zip
    from functools import lru_cache
    from io import StringIO as NativeIO
    from urllib.parse import (
        unquote, urljoin, urlunsplit, SplitResult, urlsplit
    )
    from urllib.request import pathname2url, urlopen
    str_types = str,
    int_types = int,
    iteritems = operator.methodcaller("items")
else:
    from itertools import izip as zip  # noqa
    from io import BytesIO as NativeIO
    from urlparse import urljoin, urlunsplit, SplitResult, urlsplit
    from urllib import pathname2url, unquote  # noqa
    import urllib2  # noqa
    def urlopen(*args, **kwargs):
        return contextlib.closing(urllib2.urlopen(*args, **kwargs))

    str_types = basestring
    int_types = int, long
    iteritems = operator.methodcaller("iteritems")

    from functools32 import lru_cache


def urldefrag(url):
    if "#" in url:
        s, n, p, q, frag = urlsplit(url)
        defrag = urlunsplit((s, n, p, q, ""))
    else:
        defrag = url
        frag = ""
    return defrag, frag


# flake8: noqa
