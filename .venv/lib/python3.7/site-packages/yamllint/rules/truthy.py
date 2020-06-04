# -*- coding: utf-8 -*-
# Copyright (C) 2016 Peter Ericson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""
Use this rule to forbid non-explictly typed truthy values other than allowed
ones (by default: ``true`` and ``false``), for example ``YES`` or ``off``.

This can be useful to prevent surprises from YAML parsers transforming
``[yes, FALSE, Off]`` into ``[true, false, false]`` or
``{y: 1, yes: 2, on: 3, true: 4, True: 5}`` into ``{y: 1, true: 5}``.

.. rubric:: Options

* ``allowed-values`` defines the list of truthy values which will be ignored
  during linting. The default is ``['true', 'false']``, but can be changed to
  any list containing: ``'TRUE'``, ``'True'``,  ``'true'``, ``'FALSE'``,
  ``'False'``, ``'false'``, ``'YES'``, ``'Yes'``, ``'yes'``, ``'NO'``,
  ``'No'``, ``'no'``, ``'ON'``, ``'On'``, ``'on'``, ``'OFF'``, ``'Off'``,
  ``'off'``.
* ``check-keys`` disables verification for keys in mappings. By default,
  ``truthy`` rule applies to both keys and values. Set this option to ``false``
  to prevent this.

.. rubric:: Examples

#. With ``truthy: {}``

   the following code snippet would **PASS**:
   ::

    boolean: true

    object: {"True": 1, 1: "True"}

    "yes":  1
    "on":   2
    "True": 3

     explicit:
       string1: !!str True
       string2: !!str yes
       string3: !!str off
       encoded: !!binary |
                  True
                  OFF
                  pad==  # this decodes as 'N\xbb\x9e8Qii'
       boolean1: !!bool true
       boolean2: !!bool "false"
       boolean3: !!bool FALSE
       boolean4: !!bool True
       boolean5: !!bool off
       boolean6: !!bool NO

   the following code snippet would **FAIL**:
   ::

    object: {True: 1, 1: True}

   the following code snippet would **FAIL**:
   ::

    yes:  1
    on:   2
    True: 3

#. With ``truthy: {allowed-values: ["yes", "no"]}``

   the following code snippet would **PASS**:
   ::

    - yes
    - no
    - "true"
    - 'false'
    - foo
    - bar

   the following code snippet would **FAIL**:
   ::

    - true
    - false
    - on
    - off

#. With ``truthy: {check-keys: false}``

   the following code snippet would **PASS**:
   ::

    yes:  1
    on:   2
    true: 3

   the following code snippet would **FAIL**:
   ::

    yes:  Yes
    on:   On
    true: True
"""

import yaml

from yamllint.linter import LintProblem


TRUTHY = ['YES', 'Yes', 'yes',
          'NO', 'No', 'no',
          'TRUE', 'True', 'true',
          'FALSE', 'False', 'false',
          'ON', 'On', 'on',
          'OFF', 'Off', 'off']


ID = 'truthy'
TYPE = 'token'
CONF = {'allowed-values': list(TRUTHY), 'check-keys': bool}
DEFAULT = {'allowed-values': ['true', 'false'], 'check-keys': True}


def check(conf, token, prev, next, nextnext, context):
    if prev and isinstance(prev, yaml.tokens.TagToken):
        return

    if (not conf['check-keys'] and isinstance(prev, yaml.tokens.KeyToken) and
            isinstance(token, yaml.tokens.ScalarToken)):
        return

    if isinstance(token, yaml.tokens.ScalarToken):
        if (token.value in (set(TRUTHY) - set(conf['allowed-values'])) and
                token.style is None):
            yield LintProblem(token.start_mark.line + 1,
                              token.start_mark.column + 1,
                              "truthy value should be one of [" +
                              ", ".join(sorted(conf['allowed-values'])) + "]")
