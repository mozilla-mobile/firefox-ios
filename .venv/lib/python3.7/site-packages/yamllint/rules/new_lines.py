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
Use this rule to force the type of new line characters.

.. rubric:: Options

* Set ``type`` to ``unix`` to use UNIX-typed new line characters (``\\n``), or
  ``dos`` to use DOS-typed new line characters (``\\r\\n``).
"""


from yamllint.linter import LintProblem


ID = 'new-lines'
TYPE = 'line'
CONF = {'type': ('unix', 'dos')}
DEFAULT = {'type': 'unix'}


def check(conf, line):
    if line.start == 0 and len(line.buffer) > line.end:
        if conf['type'] == 'dos':
            if (line.end + 2 > len(line.buffer) or
                    line.buffer[line.end:line.end + 2] != '\r\n'):
                yield LintProblem(1, line.end - line.start + 1,
                                  'wrong new line character: expected \\r\\n')
        else:
            if line.buffer[line.end] == '\r':
                yield LintProblem(1, line.end - line.start + 1,
                                  'wrong new line character: expected \\n')
