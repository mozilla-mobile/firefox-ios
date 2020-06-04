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

from __future__ import print_function

import argparse
import io
import os
import platform
import sys

from yamllint import APP_DESCRIPTION, APP_NAME, APP_VERSION
from yamllint import linter
from yamllint.config import YamlLintConfig, YamlLintConfigError
from yamllint.linter import PROBLEM_LEVELS


def find_files_recursively(items, conf):
    for item in items:
        if os.path.isdir(item):
            for root, dirnames, filenames in os.walk(item):
                for f in filenames:
                    filepath = os.path.join(root, f)
                    if conf.is_yaml_file(filepath):
                        yield filepath
        else:
            yield item


def supports_color():
    supported_platform = not (platform.system() == 'Windows' and not
                              ('ANSICON' in os.environ or
                               ('TERM' in os.environ and
                                os.environ['TERM'] == 'ANSI')))
    return (supported_platform and
            hasattr(sys.stdout, 'isatty') and sys.stdout.isatty())


class Format(object):
    @staticmethod
    def parsable(problem, filename):
        return ('%(file)s:%(line)s:%(column)s: [%(level)s] %(message)s' %
                {'file': filename,
                 'line': problem.line,
                 'column': problem.column,
                 'level': problem.level,
                 'message': problem.message})

    @staticmethod
    def standard(problem, filename):
        line = '  %d:%d' % (problem.line, problem.column)
        line += max(12 - len(line), 0) * ' '
        line += problem.level
        line += max(21 - len(line), 0) * ' '
        line += problem.desc
        if problem.rule:
            line += '  (%s)' % problem.rule
        return line

    @staticmethod
    def standard_color(problem, filename):
        line = '  \033[2m%d:%d\033[0m' % (problem.line, problem.column)
        line += max(20 - len(line), 0) * ' '
        if problem.level == 'warning':
            line += '\033[33m%s\033[0m' % problem.level
        else:
            line += '\033[31m%s\033[0m' % problem.level
        line += max(38 - len(line), 0) * ' '
        line += problem.desc
        if problem.rule:
            line += '  \033[2m(%s)\033[0m' % problem.rule
        return line


def show_problems(problems, file, args_format, no_warn):
    max_level = 0
    first = True

    for problem in problems:
        max_level = max(max_level, PROBLEM_LEVELS[problem.level])
        if no_warn and (problem.level != 'error'):
            continue
        if args_format == 'parsable':
            print(Format.parsable(problem, file))
        elif args_format == 'colored' or \
                (args_format == 'auto' and supports_color()):
            if first:
                print('\033[4m%s\033[0m' % file)
                first = False
            print(Format.standard_color(problem, file))
        else:
            if first:
                print(file)
                first = False
            print(Format.standard(problem, file))

    if not first and args_format != 'parsable':
        print('')

    return max_level


def run(argv=None):
    parser = argparse.ArgumentParser(prog=APP_NAME,
                                     description=APP_DESCRIPTION)
    files_group = parser.add_mutually_exclusive_group(required=True)
    files_group.add_argument('files', metavar='FILE_OR_DIR', nargs='*',
                             default=(),
                             help='files to check')
    files_group.add_argument('-', action='store_true', dest='stdin',
                             help='read from standard input')
    config_group = parser.add_mutually_exclusive_group()
    config_group.add_argument('-c', '--config-file', dest='config_file',
                              action='store',
                              help='path to a custom configuration')
    config_group.add_argument('-d', '--config-data', dest='config_data',
                              action='store',
                              help='custom configuration (as YAML source)')
    parser.add_argument('-f', '--format',
                        choices=('parsable', 'standard', 'colored', 'auto'),
                        default='auto', help='format for parsing output')
    parser.add_argument('-s', '--strict',
                        action='store_true',
                        help='return non-zero exit code on warnings '
                             'as well as errors')
    parser.add_argument('--no-warnings',
                        action='store_true',
                        help='output only error level problems')
    parser.add_argument('-v', '--version', action='version',
                        version='{} {}'.format(APP_NAME, APP_VERSION))

    args = parser.parse_args(argv)

    # User-global config is supposed to be in ~/.config/yamllint/config
    if 'XDG_CONFIG_HOME' in os.environ:
        user_global_config = os.path.join(
            os.environ['XDG_CONFIG_HOME'], 'yamllint', 'config')
    else:
        user_global_config = os.path.expanduser('~/.config/yamllint/config')

    try:
        if args.config_data is not None:
            if args.config_data != '' and ':' not in args.config_data:
                args.config_data = 'extends: ' + args.config_data
            conf = YamlLintConfig(content=args.config_data)
        elif args.config_file is not None:
            conf = YamlLintConfig(file=args.config_file)
        elif os.path.isfile('.yamllint'):
            conf = YamlLintConfig(file='.yamllint')
        elif os.path.isfile('.yamllint.yaml'):
            conf = YamlLintConfig(file='.yamllint.yaml')
        elif os.path.isfile('.yamllint.yml'):
            conf = YamlLintConfig(file='.yamllint.yml')
        elif os.path.isfile(user_global_config):
            conf = YamlLintConfig(file=user_global_config)
        else:
            conf = YamlLintConfig('extends: default')
    except YamlLintConfigError as e:
        print(e, file=sys.stderr)
        sys.exit(-1)

    max_level = 0

    for file in find_files_recursively(args.files, conf):
        filepath = file[2:] if file.startswith('./') else file
        try:
            with io.open(file, newline='') as f:
                problems = linter.run(f, conf, filepath)
        except EnvironmentError as e:
            print(e, file=sys.stderr)
            sys.exit(-1)
        prob_level = show_problems(problems, file, args_format=args.format,
                                   no_warn=args.no_warnings)
        max_level = max(max_level, prob_level)

    # read yaml from stdin
    if args.stdin:
        try:
            problems = linter.run(sys.stdin, conf, '')
        except EnvironmentError as e:
            print(e, file=sys.stderr)
            sys.exit(-1)
        prob_level = show_problems(problems, 'stdin', args_format=args.format,
                                   no_warn=args.no_warnings)
        max_level = max(max_level, prob_level)

    if max_level == PROBLEM_LEVELS['error']:
        return_code = 1
    elif max_level == PROBLEM_LEVELS['warning']:
        return_code = 2 if args.strict else 0
    else:
        return_code = 0

    sys.exit(return_code)
