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
Use this rule to require a new line character (``\\n``) at the end of files.

The POSIX standard `requires the last line to end with a new line character
<http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html#tag_03_206>`_.
All UNIX tools expect a new line at the end of files. Most text editors use
this convention too.
"""


from yamllint.linter import LintProblem


ID = 'new-line-at-end-of-file'
TYPE = 'line'


def check(conf, line):
    if line.end == len(line.buffer) and line.end > line.start:
        yield LintProblem(line.line_no, line.end - line.start + 1,
                          'no new line character at the end of file')
