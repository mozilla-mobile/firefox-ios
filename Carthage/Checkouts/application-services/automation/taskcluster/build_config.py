# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import print_function

import itertools
import os
from enum import Enum

import yaml

cached_build_config = None


def read_build_config():
    global cached_build_config

    if cached_build_config is None:
        with open(os.path.join(os.path.dirname(__file__), '..', '..', '.buildconfig-android.yml'), 'rb') as f:
            cached_build_config = yaml.safe_load(f)
    return cached_build_config


class PublicationType(Enum):
    AAR = 'aar'
    JAR = 'jar'


class Publication:
    def __init__(self, name: str, publication_type: PublicationType, version: str, project_path: str):
        self._name = name
        self._type = publication_type
        self._version = version
        self._project_path = project_path

    def to_artifacts(self, extensions):
        primary_extensions = ('.pom', '.aar', '-sources.jar') if self._type == PublicationType.AAR else ('.pom', '.jar')
        extensions = [package_ext + digest_ext for package_ext, digest_ext in
                      itertools.product(primary_extensions, extensions)]

        artifacts = []
        for extension in extensions:
            artifact_filename = '{}-{}{}'.format(self._name, self._version, extension)
            filename_with_package = f'org/mozilla/appservices/{self._name}/{self._version}/{artifact_filename}'
            artifacts.append({
                'taskcluster_path': f'public/build/{artifact_filename}',
                'build_fs_path': f'{self._project_path}/build/maven/{filename_with_package}',
                'maven_destination': f'maven2/org/mozilla/appservices/{self._name}/{self._version}/{artifact_filename}'
            })
        return artifacts


def module_definitions():
    build_config = read_build_config()
    version = build_config['libraryVersion']
    modules_defs = []
    for (name, project) in build_config['projects'].items():
        project_path = '/build/repo/{}'.format(project['path'])
        module_artifacts = []
        for artifact in project['publications']:
            artifact_name = artifact['name']
            artifact_type = PublicationType(artifact['type'])

            extensions = ('.pom', '.aar', '-sources.jar') if artifact_type == PublicationType.AAR else ('.pom', '.jar')
            extensions = [package_ext + digest_ext for package_ext, digest_ext in itertools.product(extensions, ('', '.sha1', '.md5'))]
            for extension in extensions:
                artifact_filename = '{}-{}{}'.format(artifact_name, version, extension)
                filename_with_package = f'org/mozilla/appservices/{artifact_name}/{version}/{artifact_filename}'
                module_artifacts.append({
                    'taskcluster_path': f'public/build/{artifact_filename}',
                    'build_fs_path': f'{project_path}/build/maven/{filename_with_package}',
                    'maven_destination': f'maven2/org/mozilla/appservices/{artifact_name}/{version}{artifact_filename}'
                })


        modules_defs.append({
            'name': name,
            'publications': [Publication(publication['name'], PublicationType(publication['type']), version, project_path)
                             for publication in project['publications']],
            'artifacts': module_artifacts,
            'uploadSymbols': project.get('uploadSymbols', False),
            'path': project['path'],
        })
    return modules_defs

def appservices_version():
    build_config = read_build_config()
    return build_config['libraryVersion']
