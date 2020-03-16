#! /usr/bin/python
# DevTools/LibraryVersions.py - Helper for the library's version number
#
# Copyright (c) 2014 - 2017 Apple Inc. and the project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See LICENSE.txt for license information:
# https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
#

"""Helper script to for the versions numbers in the project sources."""

import optparse
import os
import re
import sys

_VERSION_RE = re.compile(r'^(?P<major>\d+)\.(?P<minor>\d+)(.(?P<revision>\d+))?$')

_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_PODSPEC_PATH = os.path.join(_PROJECT_ROOT, 'SwiftProtobuf.podspec')
_VERSION_SWIFT_PATH = os.path.join(_PROJECT_ROOT, 'Sources/SwiftProtobuf/Version.swift')
_XCODE_PROJECT_PATH = os.path.join(_PROJECT_ROOT, 'SwiftProtobuf.xcodeproj/project.pbxproj')

def Fail(message):
  sys.stderr.write('Error: %s\n' % message)
  sys.exit(1)


def ExtractVersion(s):
  match = _VERSION_RE.match(s)
  return (match.group('major'), match.group('minor'), match.group('revision') or '0')


def ValidateFiles():
  # Extra from SwiftProtobuf.podspec
  pod_content = open(_PODSPEC_PATH).read()
  match = re.search(r'version = \'(\d+.\d+.\d+)\'', pod_content)
  if not match:
    Fail('Failed to extract a version from SwiftProtobuf.podspec')
  (major, minor, revision) = ExtractVersion(match.group(1))

  # Test Sources/SwiftProtobuf/Version.swift
  version_swift_content = open(_VERSION_SWIFT_PATH).read()
  major_line = 'public static let major = %s\n' % major
  minor_line = 'public static let minor = %s\n' % minor
  revision_line = 'public static let revision = %s\n' % revision
  had_major = major_line in version_swift_content
  had_minor = minor_line in version_swift_content
  had_revision = revision_line in version_swift_content
  if not had_major or not had_minor or not had_revision:
    Fail('Version in Sources/SwiftProtobuf/Version.swift did not match SwiftProtobuf.podspec')

  # Test SwiftProtobuf.xcodeproj/project.pbxproj
  xcode_project_content = open(_XCODE_PROJECT_PATH).read()
  matches = re.findall(r'CURRENT_PROJECT_VERSION = %s\.%s\.%s;' % (major, minor, revision),
                       xcode_project_content)
  if len(matches) != 2:
    Fail('Version in SwiftProtobuf.xcodeproj/project.pbxproj did not match SwiftProtobuf.podspec')


def UpdateFiles(version_string):
  (major, minor, revision) = ExtractVersion(version_string)

  # Update SwiftProtobuf.podspec
  pod_content = open(_PODSPEC_PATH).read()
  pod_content = re.sub(r'version = \'(\d+\.\d+\.\d+)\'',
                       'version = \'%s.%s.%s\'' % (major, minor, revision),
                       pod_content)
  open(_PODSPEC_PATH, 'w').write(pod_content)

  # Update Sources/SwiftProtobuf/Version.swift
  version_swift_content = open(_VERSION_SWIFT_PATH).read()
  version_swift_content = re.sub(r'public static let major = \d+\n',
                                 'public static let major = %s\n' % major,
                                 version_swift_content)
  version_swift_content = re.sub(r'public static let minor = \d+\n',
                                 'public static let minor = %s\n' % minor,
                                 version_swift_content)
  version_swift_content = re.sub(r'public static let revision = \d+\n',
                                 'public static let revision = %s\n' % revision,
                                 version_swift_content)
  open(_VERSION_SWIFT_PATH, 'w').write(version_swift_content)

  # Update SwiftProtobuf.xcodeproj/project.pbxproj
  xcode_project_content = open(_XCODE_PROJECT_PATH).read()
  xcode_project_content = re.sub(r'CURRENT_PROJECT_VERSION = \d+\.\d+\.\d+',
                                 'CURRENT_PROJECT_VERSION = %s.%s.%s' % (major, minor, revision),
                                 xcode_project_content)
  open(_XCODE_PROJECT_PATH, 'w').write(xcode_project_content)


def main(args):
  usage = '%prog [OPTIONS] [VERSION]'
  description = (
      'Helper for the version numbers in the project sources.'
  )
  parser = optparse.OptionParser(usage=usage, description=description)
  parser.add_option('--validate',
                    default=False, action='store_true',
                    help='Check if the versions in all the files match.')
  opts, extra_args = parser.parse_args(args)

  if opts.validate:
    if extra_args:
      parser.error('No version can be given when using --validate.')
  else:
    if len(extra_args) != 1:
      parser.error('Expected one argument, the version number to ensure is in the sources.')
    if not _VERSION_RE.match(extra_args[0]):
      parser.error('Version does not appear to be in the form of x.y.z.')

  # Always validate, just use the flag to tell if we're expected to also have set something.
  if not opts.validate:
    UpdateFiles(extra_args[0])
  ValidateFiles()
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
