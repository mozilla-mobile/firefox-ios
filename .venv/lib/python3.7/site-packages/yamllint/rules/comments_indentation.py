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
Use this rule to force comments to be indented like content.

.. rubric:: Examples

#. With ``comments-indentation: {}``

   the following code snippet would **PASS**:
   ::

    # Fibonacci
    [0, 1, 1, 2, 3, 5]

   the following code snippet would **FAIL**:
   ::

      # Fibonacci
    [0, 1, 1, 2, 3, 5]

   the following code snippet would **PASS**:
   ::

    list:
        - 2
        - 3
        # - 4
        - 5

   the following code snippet would **FAIL**:
   ::

    list:
        - 2
        - 3
    #    - 4
        - 5

   the following code snippet would **PASS**:
   ::

    # This is the first object
    obj1:
      - item A
      # - item B
    # This is the second object
    obj2: []

   the following code snippet would **PASS**:
   ::

    # This sentence
    # is a block comment

   the following code snippet would **FAIL**:
   ::

    # This sentence
     # is a block comment
"""


import yaml

from yamllint.linter import LintProblem
from yamllint.rules.common import get_line_indent


ID = 'comments-indentation'
TYPE = 'comment'


# Case A:
#
#     prev: line:
#       # commented line
#       current: line
#
# Case B:
#
#       prev: line
#       # commented line 1
#     # commented line 2
#     current: line

def check(conf, comment):
    # Only check block comments
    if (not isinstance(comment.token_before, yaml.StreamStartToken) and
            comment.token_before.end_mark.line + 1 == comment.line_no):
        return

    next_line_indent = comment.token_after.start_mark.column
    if isinstance(comment.token_after, yaml.StreamEndToken):
        next_line_indent = 0

    if isinstance(comment.token_before, yaml.StreamStartToken):
        prev_line_indent = 0
    else:
        prev_line_indent = get_line_indent(comment.token_before)

    # In the following case only the next line indent is valid:
    #     list:
    #         # comment
    #         - 1
    #         - 2
    if prev_line_indent <= next_line_indent:
        prev_line_indent = next_line_indent

    # If two indents are valid but a previous comment went back to normal
    # indent, for the next ones to do the same. In other words, avoid this:
    #     list:
    #         - 1
    #     # comment on valid indent (0)
    #         # comment on valid indent (4)
    #     other-list:
    #         - 2
    if (comment.comment_before is not None and
            not comment.comment_before.is_inline()):
        prev_line_indent = comment.comment_before.column_no - 1

    if (comment.column_no - 1 != prev_line_indent and
            comment.column_no - 1 != next_line_indent):
        yield LintProblem(comment.line_no, comment.column_no,
                          'comment not indented like content')
