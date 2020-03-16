#!/usr/bin/env bash

set -eu

CONFIGURATION="Release"
FRAMEWORK_NAME="MozillaAppServices.framework.zip"
ARCHIVE=true

while [[ "$#" -gt 0 ]]; do case $1 in
  --configuration) CONFIGURATION="$2"; shift;shift;;
  --out) FRAMEWORK_NAME="$2"; shift;shift;;
  --no-archive) ARCHIVE=false; shift;;
  *) echo "Unknown parameter: $1"; exit 1;
esac; done

set -vx

# Help out iOS folks who might want to run this but haven't
# updated rust recently.
rustup update stable

carthage bootstrap --platform iOS --cache-builds

set -o pipefail && \
carthage build --no-skip-current --platform iOS --verbose --configuration "${CONFIGURATION}" --cache-builds | \
tee raw_xcodebuild.log | \
xcpretty

if [ "$ARCHIVE" = true ]; then
    ## When https://github.com/Carthage/Carthage/issues/2623 is fixed,
    ## carthage build --archive should work to produce a zip

    # Exclude SwiftProtobuf.
    zip -r "${FRAMEWORK_NAME}" Carthage/Build/iOS megazords/ios/DEPENDENCIES.md -x '*SwiftProtobuf.framework*/*'
fi
