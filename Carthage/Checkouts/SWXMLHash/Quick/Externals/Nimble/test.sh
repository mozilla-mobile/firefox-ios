#!/bin/sh

XCPRETTY= #`which xcpretty`
BUILD_DIR=`pwd`/build

set -e

function test {
    echo "Running ALL iOS and OSX"

    set -x
    osascript -e 'tell app "iOS Simulator" to quit'
    xcodebuild -project Nimble.xcodeproj -scheme "Nimble-iOS" -configuration "Debug" -sdk "iphonesimulator8.0" -destination "name=iPad Air,OS=8.0" -destination-timeout 5 build test

    osascript -e 'tell app "iOS Simulator" to quit'
    xcodebuild -project Nimble.xcodeproj -scheme "Nimble-iOS" -configuration "Debug" -sdk "iphonesimulator8.0" -destination "name=iPhone 5s,OS=8.0" -destination-timeout 5 build test

    osascript -e 'tell app "iOS Simulator" to quit'
    xcodebuild -project Nimble.xcodeproj -scheme "Nimble-OSX" -configuration "Debug" -sdk "macosx" -destination-timeout 5 build test
    set +x
}

function clean {
    rm -rf ~/Library/Developer/Xcode/DerivedData
}

function main {
    if [ ! -z "$XCPRETTY" ]; then
        echo "XCPretty found. Use 'XCPRETTY= $0' if you want to disable."
    fi

    case "$1" in
        clean) clean ;;
        *) test ;;
    esac
}

main $@

