# -*- coding: utf-8 -*-
# Copyright (C) 2016 Adrien Vergé
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
Use this rule to control the number of spaces before and after colons (``:``).

.. rubric:: Options

* ``max-spaces-before`` defines the maximal number of spaces allowed before
  colons (use ``-1`` to disable).
* ``max-spaces-after`` defines the maximal number of spaces allowed after
  colons (use ``-1`` to disable).

.. rubric:: Examples

#. With ``colons: {max-spaces-before: 0, max-spaces-after: 1}``

   the following code snippet would **PASS**:
   ::

    object:
      - a
      - b
    key: value

#. With ``colons: {max-spaces-before: 1}``

   the following code snippet would **PASS**:
   ::

    object :
      - a
      - b

   the following code snippet would **FAIL**:
   ::

    object  :
      - a
      - b

#. With ``colons: {max-spaces-after: 2}``

   the following code snippet would **PASS**:
   ::

    first:  1
    second: 2
    third:  3

   the following code snippet would **FAIL**:
   ::

    first: 1
    2nd:   2
    third: 3
"""


import yaml

from yamllint.rules.common import is_explicit_key, spaces_after, spaces_before


ID = 'colons'
TYPE = 'token'
CONF = {'max-spaces-before': int,
        'max-spaces-after': int}
DEFAULT = {'max-spaces-before': 0,
           'max-spaces-after': 1}


def check(conf, token, prev, next, nextnext, context):
    if isinstance(token, yaml.ValueToken):
        problem = spaces_before(token, prev, next,
                                max=conf['max-spaces-before'],
                                max_desc='too many spaces before colon')
        if problem is not None:
            yield problem

        problem = spaces_after(token, prev, next,
                               max=conf['max-spaces-after'],
                               max_desc='too many spaces after colon')
        if problem is not None:
            yield problem

    if isinstance(token, yaml.KeyToken) and is_explicit_key(token):
        problem = spaces_after(token, prev, next,
                               max=conf['max-spaces-after'],
                               max_desc='too many spaces after question mark')
        if problem is not None:
            yield problem
