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
Use this rule to forbid trailing spaces at the end of lines.

.. rubric:: Examples

#. With ``trailing-spaces: {}``

   the following code snippet would **PASS**:
   ::

    this document doesn't contain
    any trailing
    spaces

   the following code snippet would **FAIL**:
   ::

    this document contains     """ """
    trailing spaces
    on lines 1 and 3         """ """
"""


import string

from yamllint.linter import LintProblem


ID = 'trailing-spaces'
TYPE = 'line'


def check(conf, line):
    if line.end == 0:
        return

    # YAML recognizes two white space characters: space and tab.
    # http://yaml.org/spec/1.2/spec.html#id2775170

    pos = line.end
    while line.buffer[pos - 1] in string.whitespace and pos > line.start:
        pos -= 1

    if pos != line.end and line.buffer[pos] in ' \t':
        yield LintProblem(line.line_no, pos - line.start + 1,
                          'trailing spaces')
