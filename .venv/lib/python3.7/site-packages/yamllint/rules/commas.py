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
Use this rule to control the number of spaces before and after commas (``,``).

.. rubric:: Options

* ``max-spaces-before`` defines the maximal number of spaces allowed before
  commas (use ``-1`` to disable).
* ``min-spaces-after`` defines the minimal number of spaces required after
  commas.
* ``max-spaces-after`` defines the maximal number of spaces allowed after
  commas (use ``-1`` to disable).

.. rubric:: Examples

#. With ``commas: {max-spaces-before: 0}``

   the following code snippet would **PASS**:
   ::

    strange var:
      [10, 20, 30, {x: 1, y: 2}]

   the following code snippet would **FAIL**:
   ::

    strange var:
      [10, 20 , 30, {x: 1, y: 2}]

#. With ``commas: {max-spaces-before: 2}``

   the following code snippet would **PASS**:
   ::

    strange var:
      [10  , 20 , 30,  {x: 1  , y: 2}]

#. With ``commas: {max-spaces-before: -1}``

   the following code snippet would **PASS**:
   ::

    strange var:
      [10,
       20   , 30
       ,   {x: 1, y: 2}]

#. With ``commas: {min-spaces-after: 1, max-spaces-after: 1}``

   the following code snippet would **PASS**:
   ::

    strange var:
      [10, 20,30, {x: 1, y: 2}]

   the following code snippet would **FAIL**:
   ::

    strange var:
      [10, 20,30,   {x: 1,   y: 2}]

#. With ``commas: {min-spaces-after: 1, max-spaces-after: 3}``

   the following code snippet would **PASS**:
   ::

    strange var:
      [10, 20,  30,  {x: 1,   y: 2}]

#. With ``commas: {min-spaces-after: 0, max-spaces-after: 1}``

   the following code snippet would **PASS**:
   ::

    strange var:
      [10, 20,30, {x: 1, y: 2}]
"""


import yaml

from yamllint.linter import LintProblem
from yamllint.rules.common import spaces_after, spaces_before


ID = 'commas'
TYPE = 'token'
CONF = {'max-spaces-before': int,
        'min-spaces-after': int,
        'max-spaces-after': int}
DEFAULT = {'max-spaces-before': 0,
           'min-spaces-after': 1,
           'max-spaces-after': 1}


def check(conf, token, prev, next, nextnext, context):
    if isinstance(token, yaml.FlowEntryToken):
        if (prev is not None and conf['max-spaces-before'] != -1 and
                prev.end_mark.line < token.start_mark.line):
            yield LintProblem(token.start_mark.line + 1,
                              max(1, token.start_mark.column),
                              'too many spaces before comma')
        else:
            problem = spaces_before(token, prev, next,
                                    max=conf['max-spaces-before'],
                                    max_desc='too many spaces before comma')
            if problem is not None:
                yield problem

        problem = spaces_after(token, prev, next,
                               min=conf['min-spaces-after'],
                               max=conf['max-spaces-after'],
                               min_desc='too few spaces after comma',
                               max_desc='too many spaces after comma')
        if problem is not None:
            yield problem
