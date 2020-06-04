# -*- coding: utf-8 -*-
# Copyright (C) 2018 ClearScore
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
Use this rule to forbid any string values that are not quoted, or to prevent
quoted strings without needing it. You can also enforce the type of the quote
used.

.. rubric:: Options

* ``quote-type`` defines allowed quotes: ``single``, ``double`` or ``any``
  (default).
* ``required`` defines whether using quotes in string values is required
  (``true``, default) or not (``false``), or only allowed when really needed
  (``only-when-needed``).
* ``extra-required`` is a list of PCRE regexes to force string values to be
  quoted, if they match any regex. This option can only be used with
  ``required: false`` and  ``required: only-when-needed``.
* ``extra-allowed`` is a list of PCRE regexes to allow quoted string values,
  even if ``required: only-when-needed`` is set.

**Note**: Multi-line strings (with ``|`` or ``>``) will not be checked.

.. rubric:: Examples

#. With ``quoted-strings: {quote-type: any, required: true}``

   the following code snippet would **PASS**:
   ::

    foo: "bar"
    bar: 'foo'
    number: 123
    boolean: true

   the following code snippet would **FAIL**:
   ::

    foo: bar

#. With ``quoted-strings: {quote-type: single, required: only-when-needed}``

   the following code snippet would **PASS**:
   ::

    foo: bar
    bar: foo
    not_number: '123'
    not_boolean: 'true'
    not_comment: '# comment'
    not_list: '[1, 2, 3]'
    not_map: '{a: 1, b: 2}'

   the following code snippet would **FAIL**:
   ::

    foo: 'bar'

#. With ``quoted-strings: {required: false, extra-required: [^http://,
   ^ftp://]}``

   the following code snippet would **PASS**:
   ::

    - localhost
    - "localhost"
    - "http://localhost"
    - "ftp://localhost"

   the following code snippet would **FAIL**:
   ::

    - http://localhost
    - ftp://localhost

#. With ``quoted-strings: {required: only-when-needed, extra-allowed:
   [^http://, ^ftp://], extra-required: [QUOTED]}``

   the following code snippet would **PASS**:
   ::

    - localhost
    - "http://localhost"
    - "ftp://localhost"
    - "this is a string that needs to be QUOTED"

   the following code snippet would **FAIL**:
   ::

    - "localhost"
    - this is a string that needs to be QUOTED
"""

import re

import yaml

from yamllint.linter import LintProblem

ID = 'quoted-strings'
TYPE = 'token'
CONF = {'quote-type': ('any', 'single', 'double'),
        'required': (True, False, 'only-when-needed'),
        'extra-required': [str],
        'extra-allowed': [str]}
DEFAULT = {'quote-type': 'any',
           'required': True,
           'extra-required': [],
           'extra-allowed': []}


def VALIDATE(conf):
    if conf['required'] is True and len(conf['extra-allowed']) > 0:
        return 'cannot use both "required: true" and "extra-allowed"'
    if conf['required'] is True and len(conf['extra-required']) > 0:
        return 'cannot use both "required: true" and "extra-required"'
    if conf['required'] is False and len(conf['extra-allowed']) > 0:
        return 'cannot use both "required: false" and "extra-allowed"'


DEFAULT_SCALAR_TAG = u'tag:yaml.org,2002:str'


def _quote_match(quote_type, token_style):
    return ((quote_type == 'any') or
            (quote_type == 'single' and token_style == "'") or
            (quote_type == 'double' and token_style == '"'))


def _quotes_are_needed(string):
    loader = yaml.BaseLoader('key: ' + string)
    # Remove the 5 first tokens corresponding to 'key: ' (StreamStartToken,
    # BlockMappingStartToken, KeyToken, ScalarToken(value=key), ValueToken)
    for _ in range(5):
        loader.get_token()
    try:
        a, b = loader.get_token(), loader.get_token()
        if (isinstance(a, yaml.ScalarToken) and a.style is None and
                isinstance(b, yaml.BlockEndToken)):
            return False
        return True
    except yaml.scanner.ScannerError:
        return True


def check(conf, token, prev, next, nextnext, context):
    if not (isinstance(token, yaml.tokens.ScalarToken) and
            isinstance(prev, (yaml.BlockEntryToken, yaml.FlowEntryToken,
                              yaml.FlowSequenceStartToken, yaml.TagToken,
                              yaml.ValueToken))):

        return

    # Ignore explicit types, e.g. !!str testtest or !!int 42
    if (prev and isinstance(prev, yaml.tokens.TagToken) and
            prev.value[0] == '!!'):
        return

    # Ignore numbers, booleans, etc.
    resolver = yaml.resolver.Resolver()
    tag = resolver.resolve(yaml.nodes.ScalarNode, token.value, (True, False))
    if token.plain and tag != DEFAULT_SCALAR_TAG:
        return

    # Ignore multi-line strings
    if (not token.plain) and (token.style == "|" or token.style == ">"):
        return

    quote_type = conf['quote-type']

    msg = None
    if conf['required'] is True:

        # Quotes are mandatory and need to match config
        if token.style is None or not _quote_match(quote_type, token.style):
            msg = "string value is not quoted with %s quotes" % quote_type

    elif conf['required'] is False:

        # Quotes are not mandatory but when used need to match config
        if token.style and not _quote_match(quote_type, token.style):
            msg = "string value is not quoted with %s quotes" % quote_type

        elif not token.style:
            is_extra_required = any(re.search(r, token.value)
                                    for r in conf['extra-required'])
            if is_extra_required:
                msg = "string value is not quoted"

    elif conf['required'] == 'only-when-needed':

        # Quotes are not strictly needed here
        if (token.style and tag == DEFAULT_SCALAR_TAG and token.value and
                not _quotes_are_needed(token.value)):
            is_extra_required = any(re.search(r, token.value)
                                    for r in conf['extra-required'])
            is_extra_allowed = any(re.search(r, token.value)
                                   for r in conf['extra-allowed'])
            if not (is_extra_required or is_extra_allowed):
                msg = "string value is redundantly quoted with %s quotes" % (
                    quote_type)

        # But when used need to match config
        elif token.style and not _quote_match(quote_type, token.style):
            msg = "string value is not quoted with %s quotes" % quote_type

        elif not token.style:
            is_extra_required = len(conf['extra-required']) and any(
                re.search(r, token.value) for r in conf['extra-required'])
            if is_extra_required:
                msg = "string value is not quoted"

    if msg is not None:
        yield LintProblem(
            token.start_mark.line + 1,
            token.start_mark.column + 1,
            msg)
