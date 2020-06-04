#!/usr/bin/env python
"""
A performance benchmark using the example from issue #232.

See https://github.com/Julian/jsonschema/pull/232.
"""
from twisted.python.filepath import FilePath
from pyperf import Runner
from pyrsistent import m

from jsonschema.tests._suite import Version
import jsonschema


issue232 = Version(
    path=FilePath(__file__).sibling("issue232"),
    remotes=m(),
    name="issue232",
)


if __name__ == "__main__":
    issue232.benchmark(
        runner=Runner(),
        Validator=jsonschema.Draft4Validator,
    )
