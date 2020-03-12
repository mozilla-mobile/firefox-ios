#!/usr/bin/python
#
#  Copyright 2016 Google Inc. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

"""Rename the prebuilt OCHamcrest framework to not use the IOS suffix.

Script to rename 'OCHamcrestIOS' to 'OCHamcrest' in the
OCHamcrestIOS framework. We use 'OCHamcrest' as our imports in EarlGrey
and using the OCHamcrestIOS.framework breaks these imports. This changes
the name of the framework and the public files and their imports to
'OCHamcrest'.

Ensure that this script is located in the same folder as where you
have the OCHamcrestIOS.framework file.
"""

import glob
import os
import sys


def _ChangeFrameworkName():
  """Change OCHamcrestIOS.framework to OCHamcrest.framework."""
  file_path = _FilePathRelativeToScriptDirectory('../OCHamcrest.framework')
  if os.path.isdir(file_path):
    print '''
    OCHamcrest.framework is already present in the script directory: %s/../.
    Please remove the file since we do not over-write it.
    ''' % _CurrentScriptDirectory()
    exit(1)
  file_path = _FilePathRelativeToScriptDirectory('OCHamcrestIOS.framework')
  if not os.path.isdir(file_path):
    print '''
    OCHamcrestIOS.framework not present in the script directory: %s/../.
    Please make sure that the rename-ochamcrest.py script is present in
    the same folder as the OCHamcrestIOS.framework file.
    ''' % _CurrentScriptDirectory()
    exit(1)

  real_path = _FilePathRelativeToScriptDirectory('OCHamcrestIOS.framework')
  os.rename(real_path,
            real_path.replace('OCHamcrestIOS.framework',
                              'OCHamcrest.framework'))


def _ChangeFrameworkHeaderFileNames():
  """Change OCHamcrestIOS.h files to OCHamcrest.h."""
  script_header_dir = 'OCHamcrest.framework/Headers/*'
  script_dir = 'OCHamcrest.framework/*'
  file_glob = glob.glob(_FilePathRelativeToScriptDirectory(script_header_dir))
  extension_glob = glob.glob(_FilePathRelativeToScriptDirectory(script_dir))
  file_glob.extend(extension_glob)
  for oc_file in file_glob:
    os.rename(oc_file, oc_file.replace('OCHamcrestIOS', 'OCHamcrest'))


def _ChangeFrameworkTextInFiles():
  """Change instances of OCHamcrestIOS to OCHamcrest."""
  abs_path = _FilePathRelativeToScriptDirectory('OCHamcrest.framework')
  for dname, _, files in os.walk(abs_path):
    for fname in files:
      relative_file_path = os.path.join(dname, fname)
      if relative_file_path.endswith('.h'):
        _ReplaceInFile(relative_file_path,
                       '#import <OCHamcrestIOS',
                       '#import <OCHamcrest')
      elif relative_file_path.endswith('.plist'):
        _ReplaceInFile(relative_file_path, 'OCHamcrestIOS', 'OCHamcrest')


def _ReplaceInFile(filepath, original, replacement):
  """Replaces original text to the replacement in a file."""
  with open(filepath) as oc_file:
    data = None
    with open(filepath, 'rt') as input_file:
      if input_file:
        data = oc_file.read().replace(original, replacement)
    with open(filepath, 'wt') as out_file:
      out_file.write(data)


def _FilePathRelativeToScriptDirectory(file_name):
  """Returns the path of the file with respect to the script directory."""
  return os.path.join(_CurrentScriptDirectory(), file_name)


def _CurrentScriptDirectory():
  """Returns the directory where the script is located."""
  return os.path.dirname(os.path.realpath(sys.argv[0]))

if __name__ == '__main__':
  print 'Changing OCHamcrestIOS.framework to OCHamcrest.framework...'
  _ChangeFrameworkName()
  _ChangeFrameworkHeaderFileNames()
  _ChangeFrameworkTextInFiles()
  print 'Done. OCHamcrest.framework is now present in the EarlGrey directory.'
  exit(0)
