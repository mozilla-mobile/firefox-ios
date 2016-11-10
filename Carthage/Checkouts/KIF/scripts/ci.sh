#!/usr/bin/env bash

set -o xtrace
set -o errexit
set -o pipefail

SIMULATOR=$1

if [ -z "${SIMULATOR}" ]; then
  echo 'Must supply a simulator description in the form of "name=iPad Air,OS=9.2"'
  exit 1
fi

# Workaround https://github.com/travis-ci/travis-ci/issues/3040
open -b com.apple.iphonesimulator

rm -rf ${PWD}/build

# Frameworks are only supported on iOS8 and later
if [[ ! ${SIMULATOR} =~ .*OS=7.* ]]; then
  env NSUnbufferedIO=YES xcodebuild test -derivedDataPath=${PWD}/build/KIFFramework -scheme KIFFrameworkConsumerTests -destination "platform=iOS Simulator,${SIMULATOR}" | xcpretty -c
fi

env NSUnbufferedIO=YES xcodebuild test -scheme KIF -derivedDataPath=${PWD}/build/KIF -destination "platform=iOS Simulator,${SIMULATOR}" | xcpretty -c