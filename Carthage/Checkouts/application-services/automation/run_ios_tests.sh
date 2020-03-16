#!/usr/bin/env bash

set -euvx

# Help out iOS folks who might want to run this but haven't
# updated rust recently.
rustup update stable

set -o pipefail && \
xcodebuild \
  -workspace ./megazords/ios/MozillaAppServices.xcodeproj/project.xcworkspace \
  -scheme MozillaAppServices \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 8' \
  test | \
tee raw_xcodetest.log | \
xcpretty && exit "${PIPESTATUS[0]}"
