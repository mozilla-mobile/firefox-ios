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
Use this rule to prevent multiple entries with the same key in mappings.

.. rubric:: Examples

#. With ``key-duplicates: {}``

   the following code snippet would **PASS**:
   ::

    - key 1: v
      key 2: val
      key 3: value
    - {a: 1, b: 2, c: 3}

   the following code snippet would **FAIL**:
   ::

    - key 1: v
      key 2: val
      key 1: value

   the following code snippet would **FAIL**:
   ::

    - {a: 1, b: 2, b: 3}

   the following code snippet would **FAIL**:
   ::

    duplicated key: 1
    "duplicated key": 2

    other duplication: 1
    ? >-
        other
        duplication
    : 2
"""

import yaml

from yamllint.linter import LintProblem


ID = 'key-duplicates'
TYPE = 'token'

MAP, SEQ = range(2)


class Parent(object):
    def __init__(self, type):
        self.type = type
        self.keys = []


def check(conf, token, prev, next, nextnext, context):
    if 'stack' not in context:
        context['stack'] = []

    if isinstance(token, (yaml.BlockMappingStartToken,
                          yaml.FlowMappingStartToken)):
        context['stack'].append(Parent(MAP))
    elif isinstance(token, (yaml.BlockSequenceStartToken,
                            yaml.FlowSequenceStartToken)):
        context['stack'].append(Parent(SEQ))
    elif isinstance(token, (yaml.BlockEndToken,
                            yaml.FlowMappingEndToken,
                            yaml.FlowSequenceEndToken)):
        context['stack'].pop()
    elif (isinstance(token, yaml.KeyToken) and
          isinstance(next, yaml.ScalarToken)):
        # This check is done because KeyTokens can be found inside flow
        # sequences... strange, but allowed.
        if len(context['stack']) > 0 and context['stack'][-1].type == MAP:
            if (next.value in context['stack'][-1].keys and
                    # `<<` is "merge key", see http://yaml.org/type/merge.html
                    next.value != '<<'):
                yield LintProblem(
                    next.start_mark.line + 1, next.start_mark.column + 1,
                    'duplication of key "%s" in mapping' % next.value)
            else:
                context['stack'][-1].keys.append(next.value)
