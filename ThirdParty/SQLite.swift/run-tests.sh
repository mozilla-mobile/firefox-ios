#!/bin/bash
set -ev
if [ -n "$BUILD_SCHEME" ]; then
    if [ -n "$IOS_SIMULATOR" ]; then
        make test BUILD_SCHEME="$BUILD_SCHEME" IOS_SIMULATOR="$IOS_SIMULATOR"
    else
        make test BUILD_SCHEME="$BUILD_SCHEME"
    fi
elif [ -n "$VALIDATOR_SUBSPEC" ]; then
    cd Tests/CocoaPods && make test
elif [ -n "$CARTHAGE_PLATFORM" ]; then
    cd Tests/Carthage && make test CARTHAGE_PLATFORM="$CARTHAGE_PLATFORM"
elif [ -n "${PACKAGE_MANAGER_COMMAND}" ]; then
    swift ${PACKAGE_MANAGER_COMMAND}
fi
