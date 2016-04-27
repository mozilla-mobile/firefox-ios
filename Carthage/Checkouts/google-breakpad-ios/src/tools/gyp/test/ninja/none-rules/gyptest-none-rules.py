#!/usr/bin/env python

# Copyright (c) 2014 Google Inc. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Verify that 'none' targets produce valid ninja rules.
"""

import os
import sys
import TestCommon
import TestGyp

# This is a ninja-specific test.
test = TestGyp.TestGyp(formats=['ninja'])

test.run_gyp('none-rules.gyp')

subninja = open(test.built_file_path('build.ninja')).read()
if 'build doc: phony' not in subninja:
  test.fail_test()

# Build the library.
test.build('none-rules.gyp', 'doc')
