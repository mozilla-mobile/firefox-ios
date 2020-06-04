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

from yamllint.rules import (
    braces,
    brackets,
    colons,
    commas,
    comments,
    comments_indentation,
    document_end,
    document_start,
    empty_lines,
    empty_values,
    hyphens,
    indentation,
    key_duplicates,
    key_ordering,
    line_length,
    new_line_at_end_of_file,
    new_lines,
    octal_values,
    quoted_strings,
    trailing_spaces,
    truthy,
)

_RULES = {
    braces.ID: braces,
    brackets.ID: brackets,
    colons.ID: colons,
    commas.ID: commas,
    comments.ID: comments,
    comments_indentation.ID: comments_indentation,
    document_end.ID: document_end,
    document_start.ID: document_start,
    empty_lines.ID: empty_lines,
    empty_values.ID: empty_values,
    hyphens.ID: hyphens,
    indentation.ID: indentation,
    key_duplicates.ID: key_duplicates,
    key_ordering.ID: key_ordering,
    line_length.ID: line_length,
    new_line_at_end_of_file.ID: new_line_at_end_of_file,
    new_lines.ID: new_lines,
    octal_values.ID: octal_values,
    quoted_strings.ID: quoted_strings,
    trailing_spaces.ID: trailing_spaces,
    truthy.ID: truthy,
}


def get(id):
    if id not in _RULES:
        raise ValueError('no such rule: "%s"' % id)

    return _RULES[id]
