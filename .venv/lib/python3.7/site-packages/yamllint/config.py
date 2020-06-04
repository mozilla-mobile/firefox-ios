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

import os.path

import pathspec
import yaml

import yamllint.rules


class YamlLintConfigError(Exception):
    pass


class YamlLintConfig(object):
    def __init__(self, content=None, file=None):
        assert (content is None) ^ (file is None)

        self.ignore = None

        self.yaml_files = pathspec.PathSpec.from_lines(
            'gitwildmatch', ['*.yaml', '*.yml', '.yamllint'])

        if file is not None:
            with open(file) as f:
                content = f.read()

        self.parse(content)
        self.validate()

    def is_file_ignored(self, filepath):
        return self.ignore and self.ignore.match_file(filepath)

    def is_yaml_file(self, filepath):
        return self.yaml_files.match_file(filepath)

    def enabled_rules(self, filepath):
        return [yamllint.rules.get(id) for id, val in self.rules.items()
                if val is not False and (
                    filepath is None or 'ignore' not in val or
                    not val['ignore'].match_file(filepath))]

    def extend(self, base_config):
        assert isinstance(base_config, YamlLintConfig)

        for rule in self.rules:
            if (isinstance(self.rules[rule], dict) and
                    rule in base_config.rules and
                    base_config.rules[rule] is not False):
                base_config.rules[rule].update(self.rules[rule])
            else:
                base_config.rules[rule] = self.rules[rule]

        self.rules = base_config.rules

        if base_config.ignore is not None:
            self.ignore = base_config.ignore

    def parse(self, raw_content):
        try:
            conf = yaml.safe_load(raw_content)
        except Exception as e:
            raise YamlLintConfigError('invalid config: %s' % e)

        if not isinstance(conf, dict):
            raise YamlLintConfigError('invalid config: not a dict')

        self.rules = conf.get('rules', {})
        for rule in self.rules:
            if self.rules[rule] == 'enable':
                self.rules[rule] = {}
            elif self.rules[rule] == 'disable':
                self.rules[rule] = False

        # Does this conf override another conf that we need to load?
        if 'extends' in conf:
            path = get_extended_config_file(conf['extends'])
            base = YamlLintConfig(file=path)
            try:
                self.extend(base)
            except Exception as e:
                raise YamlLintConfigError('invalid config: %s' % e)

        if 'ignore' in conf:
            if not isinstance(conf['ignore'], str):
                raise YamlLintConfigError(
                    'invalid config: ignore should contain file patterns')
            self.ignore = pathspec.PathSpec.from_lines(
                'gitwildmatch', conf['ignore'].splitlines())

        if 'yaml-files' in conf:
            if not (isinstance(conf['yaml-files'], list)
                    and all(isinstance(i, str) for i in conf['yaml-files'])):
                raise YamlLintConfigError(
                    'invalid config: yaml-files '
                    'should be a list of file patterns')
            self.yaml_files = pathspec.PathSpec.from_lines('gitwildmatch',
                                                           conf['yaml-files'])

    def validate(self):
        for id in self.rules:
            try:
                rule = yamllint.rules.get(id)
            except Exception as e:
                raise YamlLintConfigError('invalid config: %s' % e)

            self.rules[id] = validate_rule_conf(rule, self.rules[id])


def validate_rule_conf(rule, conf):
    if conf is False:  # disable
        return False

    if isinstance(conf, dict):
        if ('ignore' in conf and
                not isinstance(conf['ignore'], pathspec.pathspec.PathSpec)):
            if not isinstance(conf['ignore'], str):
                raise YamlLintConfigError(
                    'invalid config: ignore should contain file patterns')
            conf['ignore'] = pathspec.PathSpec.from_lines(
                'gitwildmatch', conf['ignore'].splitlines())

        if 'level' not in conf:
            conf['level'] = 'error'
        elif conf['level'] not in ('error', 'warning'):
            raise YamlLintConfigError(
                'invalid config: level should be "error" or "warning"')

        options = getattr(rule, 'CONF', {})
        options_default = getattr(rule, 'DEFAULT', {})
        for optkey in conf:
            if optkey in ('ignore', 'level'):
                continue
            if optkey not in options:
                raise YamlLintConfigError(
                    'invalid config: unknown option "%s" for rule "%s"' %
                    (optkey, rule.ID))
            # Example: CONF = {option: (bool, 'mixed')}
            #          → {option: true}         → {option: mixed}
            if isinstance(options[optkey], tuple):
                if (conf[optkey] not in options[optkey] and
                        type(conf[optkey]) not in options[optkey]):
                    raise YamlLintConfigError(
                        'invalid config: option "%s" of "%s" should be in %s'
                        % (optkey, rule.ID, options[optkey]))
            # Example: CONF = {option: ['flag1', 'flag2', int]}
            #          → {option: [flag1]}      → {option: [42, flag1, flag2]}
            elif isinstance(options[optkey], list):
                if (type(conf[optkey]) is not list or
                        any(flag not in options[optkey] and
                            type(flag) not in options[optkey]
                            for flag in conf[optkey])):
                    raise YamlLintConfigError(
                        ('invalid config: option "%s" of "%s" should only '
                         'contain values in %s')
                        % (optkey, rule.ID, str(options[optkey])))
            # Example: CONF = {option: int}
            #          → {option: 42}
            else:
                if not isinstance(conf[optkey], options[optkey]):
                    raise YamlLintConfigError(
                        'invalid config: option "%s" of "%s" should be %s'
                        % (optkey, rule.ID, options[optkey].__name__))
        for optkey in options:
            if optkey not in conf:
                conf[optkey] = options_default[optkey]

        if hasattr(rule, 'VALIDATE'):
            res = rule.VALIDATE(conf)
            if res:
                raise YamlLintConfigError('invalid config: %s: %s' %
                                          (rule.ID, res))
    else:
        raise YamlLintConfigError(('invalid config: rule "%s": should be '
                                   'either "enable", "disable" or a dict')
                                  % rule.ID)

    return conf


def get_extended_config_file(name):
    # Is it a standard conf shipped with yamllint...
    if '/' not in name:
        std_conf = os.path.join(os.path.dirname(os.path.realpath(__file__)),
                                'conf', name + '.yaml')

        if os.path.isfile(std_conf):
            return std_conf

    # or a custom conf on filesystem?
    return name
