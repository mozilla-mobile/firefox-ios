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
Use this rule to control the number of spaces inside braces (``{`` and ``}``).

.. rubric:: Options

* ``min-spaces-inside`` defines the minimal number of spaces required inside
  braces.
* ``max-spaces-inside`` defines the maximal number of spaces allowed inside
  braces.
* ``min-spaces-inside-empty`` defines the minimal number of spaces required
  inside empty braces.
* ``max-spaces-inside-empty`` defines the maximal number of spaces allowed
  inside empty braces.

.. rubric:: Examples

#. With ``braces: {min-spaces-inside: 0, max-spaces-inside: 0}``

   the following code snippet would **PASS**:
   ::

    object: {key1: 4, key2: 8}

   the following code snippet would **FAIL**:
   ::

    object: { key1: 4, key2: 8 }

#. With ``braces: {min-spaces-inside: 1, max-spaces-inside: 3}``

   the following code snippet would **PASS**:
   ::

    object: { key1: 4, key2: 8 }

   the following code snippet would **PASS**:
   ::

    object: { key1: 4, key2: 8   }

   the following code snippet would **FAIL**:
   ::

    object: {    key1: 4, key2: 8   }

   the following code snippet would **FAIL**:
   ::

    object: {key1: 4, key2: 8 }

#. With ``braces: {min-spaces-inside-empty: 0, max-spaces-inside-empty: 0}``

   the following code snippet would **PASS**:
   ::

    object: {}

   the following code snippet would **FAIL**:
   ::

    object: { }

#. With ``braces: {min-spaces-inside-empty: 1, max-spaces-inside-empty: -1}``

   the following code snippet would **PASS**:
   ::

    object: {         }

   the following code snippet would **FAIL**:
   ::

    object: {}
"""


import yaml

from yamllint.rules.common import spaces_after, spaces_before


ID = 'braces'
TYPE = 'token'
CONF = {'min-spaces-inside': int,
        'max-spaces-inside': int,
        'min-spaces-inside-empty': int,
        'max-spaces-inside-empty': int}
DEFAULT = {'min-spaces-inside': 0,
           'max-spaces-inside': 0,
           'min-spaces-inside-empty': -1,
           'max-spaces-inside-empty': -1}


def check(conf, token, prev, next, nextnext, context):
    if (isinstance(token, yaml.FlowMappingStartToken) and
            isinstance(next, yaml.FlowMappingEndToken)):
        problem = spaces_after(token, prev, next,
                               min=(conf['min-spaces-inside-empty']
                                    if conf['min-spaces-inside-empty'] != -1
                                    else conf['min-spaces-inside']),
                               max=(conf['max-spaces-inside-empty']
                                    if conf['max-spaces-inside-empty'] != -1
                                    else conf['max-spaces-inside']),
                               min_desc='too few spaces inside empty braces',
                               max_desc='too many spaces inside empty braces')
        if problem is not None:
            yield problem

    elif isinstance(token, yaml.FlowMappingStartToken):
        problem = spaces_after(token, prev, next,
                               min=conf['min-spaces-inside'],
                               max=conf['max-spaces-inside'],
                               min_desc='too few spaces inside braces',
                               max_desc='too many spaces inside braces')
        if problem is not None:
            yield problem

    elif (isinstance(token, yaml.FlowMappingEndToken) and
            (prev is None or
             not isinstance(prev, yaml.FlowMappingStartToken))):
        problem = spaces_before(token, prev, next,
                                min=conf['min-spaces-inside'],
                                max=conf['max-spaces-inside'],
                                min_desc='too few spaces inside braces',
                                max_desc='too many spaces inside braces')
        if problem is not None:
            yield problem
