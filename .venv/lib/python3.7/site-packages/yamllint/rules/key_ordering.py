# -*- coding: utf-8 -*-
# Copyright (C) 2017 Johannes F. Knauf
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
Use this rule to enforce alphabetical ordering of keys in mappings. The sorting
order uses the Unicode code point number. As a result, the ordering is
case-sensitive and not accent-friendly (see examples below).

.. rubric:: Examples

#. With ``key-ordering: {}``

   the following code snippet would **PASS**:
   ::

    - key 1: v
      key 2: val
      key 3: value
    - {a: 1, b: 2, c: 3}
    - T-shirt: 1
      T-shirts: 2
      t-shirt: 3
      t-shirts: 4
    - hair: true
      hais: true
      haïr: true
      haïssable: true

   the following code snippet would **FAIL**:
   ::

    - key 2: v
      key 1: val

   the following code snippet would **FAIL**:
   ::

    - {b: 1, a: 2}

   the following code snippet would **FAIL**:
   ::

    - T-shirt: 1
      t-shirt: 2
      T-shirts: 3
      t-shirts: 4

   the following code snippet would **FAIL**:
   ::

    - haïr: true
      hais: true
"""

import yaml

from yamllint.linter import LintProblem


ID = 'key-ordering'
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
            if any(next.value < key for key in context['stack'][-1].keys):
                yield LintProblem(
                    next.start_mark.line + 1, next.start_mark.column + 1,
                    'wrong ordering of key "%s" in mapping' % next.value)
            else:
                context['stack'][-1].keys.append(next.value)
