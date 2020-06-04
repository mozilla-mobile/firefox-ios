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
Use this rule to control the number of spaces after hyphens (``-``).

.. rubric:: Options

* ``max-spaces-after`` defines the maximal number of spaces allowed after
  hyphens.

.. rubric:: Examples

#. With ``hyphens: {max-spaces-after: 1}``

   the following code snippet would **PASS**:
   ::

    - first list:
        - a
        - b
    - - 1
      - 2
      - 3

   the following code snippet would **FAIL**:
   ::

    -  first list:
         - a
         - b

   the following code snippet would **FAIL**:
   ::

    - - 1
      -  2
      - 3

#. With ``hyphens: {max-spaces-after: 3}``

   the following code snippet would **PASS**:
   ::

    -   key
    -  key2
    - key42

   the following code snippet would **FAIL**:
   ::

    -    key
    -   key2
    -  key42
"""


import yaml

from yamllint.rules.common import spaces_after


ID = 'hyphens'
TYPE = 'token'
CONF = {'max-spaces-after': int}
DEFAULT = {'max-spaces-after': 1}


def check(conf, token, prev, next, nextnext, context):
    if isinstance(token, yaml.BlockEntryToken):
        problem = spaces_after(token, prev, next,
                               max=conf['max-spaces-after'],
                               max_desc='too many spaces after hyphen')
        if problem is not None:
            yield problem
