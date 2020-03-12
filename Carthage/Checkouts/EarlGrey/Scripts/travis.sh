#!/bin/bash
#
#  Copyright 2016 Google Inc.
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

set -euxo pipefail

xcodebuild -version
xcodebuild -showsdks

gem install cocoapods

CONFIG="Debug"
ACTION="test"

# Runs xcodebuild retrying up to 3 times on failure to start testing (exit code 65).
# The following arguments specified in the order below:
#  $1 : .xcodeproj file
#  $2 : scheme to run
#
# The output is formatted using xcpretty and redirected to xcodebuild.log for failure analysis.
execute_xcodebuild() {
  if [ -z ${1+x} ]; then
    echo "first argument must be a valid .xcodeproj file"
    exit 1
  elif [ -z ${2+x} ]; then
    echo "second argument must be a valid scheme"
    exit 1
  fi

  local retval_command=0
  # Are we running a test?
  [[ "${ACTION}" == *"test"* ]] && is_running_test=1 || is_running_test=0

  # Are we running a workspace or a project?
  [[ "${1}" == *".xcodeproj"* ]] && file_type="-project" || file_type="-workspace"

  for retry_attempts in {1..3}; do
    # As we are attempting retries, disable exiting when command below fails.
    set +e
    env NSUnbufferedIO=YES xcodebuild ${file_type} ${1} -scheme ${2} -sdk "$SDK" -destination "$DESTINATION" -configuration "$CONFIG" ONLY_ACTIVE_ARCH=NO $ACTION | tee xcodebuild.log | xcpretty -sc;
    retval_command=$?

    # Retry condition 1: Tests haven't started.
    # We achieve that by looking for keyword "Test Suite" in xcodebuild.log.
    # FIXME: This is a brittle check and may break in future versions of Xcode. Come up with a better fix?
    $(grep -q -m 1 "Test Suite" xcodebuild.log)
    retval_test_started=$?

    # Re-enable exiting on command failures.
    set -e

    if [[ ${is_running_test} -ne 1 ]]; then
      break
    fi

    # Should we retry?
    if [[ ${retval_command} -eq 65 ]] && [[ ${retval_test_started} -ne 0 ]]; then
      continue
    else
      break
    fi
  done

  set +e
  # In case of failure in test's +setUp or +tearDown, Xcode doesn't exit with an error code but logs it.
  # Add another check to make sure no unexpected failure occurred.
  $(grep -q -m 1 -ie ".*[1-9]\d* unexpected" xcodebuild.log)
  retval_expected_test_failures=$?
  set -e

  if [[ ${retval_command} -ne 0 ]]; then
    exit ${retval_command}
  elif [[ ${is_running_test} -eq 1 ]] && [[ ${retval_expected_test_failures} -eq 0 ]]; then
    exit 1
  fi
}

if [ "${TYPE}" == "RUBY" ]; then
  rvm use 2.2.2;
  cd gem;
  bundle install --retry=3;
  rake;
elif [ "${TYPE}" == "UNIT" ]; then
  execute_xcodebuild Tests/UnitTests/UnitTests.xcodeproj EarlGreyUnitTests
elif [ "${TYPE}" == "FUNCTIONAL_SWIFT" ]; then
  execute_xcodebuild Tests/FunctionalTests/FunctionalTests.xcodeproj EarlGreyFunctionalSwiftTests
elif [ "${TYPE}" == "FUNCTIONAL" ]; then
  execute_xcodebuild Tests/FunctionalTests/FunctionalTests.xcodeproj EarlGreyFunctionalTests
elif [ "${TYPE}" == "CONTRIB" ]; then
  execute_xcodebuild Demo/EarlGreyContribs/EarlGreyContribs.xcodeproj EarlGreyContribsTests
elif [ "${TYPE}" == "CONTRIB_SWIFT" ]; then
  execute_xcodebuild Demo/EarlGreyContribs/EarlGreyContribs.xcodeproj EarlGreyContribsSwiftTests
elif [ "${TYPE}" == "EXAMPLE_PODS" ]; then
  pod install --project-directory=Demo/EarlGreyExample
  execute_xcodebuild Demo/EarlGreyExample/EarlGreyExample.xcworkspace EarlGreyExampleTests
elif [ "${TYPE}" == "EXAMPLE_PODS_SWIFT" ]; then
  gem uninstall -aIx nanaimo
  cd gem/
  bundle install
  rake install
  cd ../Demo/EarlGreyExample
  pod update
  cd ../../
  pod install --project-directory=Demo/EarlGreyExample
  execute_xcodebuild Demo/EarlGreyExample/EarlGreyExample.xcworkspace EarlGreyExampleSwiftTests
elif [ "${TYPE}" == "CARTHAGE" ]; then
  CONFIG="Release"
  ACTION="clean build"
  execute_xcodebuild EarlGrey.xcodeproj EarlGrey
elif [ "${TYPE}" == "PACKAGE" ]; then
  Scripts/package.sh
else
  echo "Unrecognized Type: ${TYPE}"
  exit 1
fi
