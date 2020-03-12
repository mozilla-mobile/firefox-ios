#!/bin/bash -exu -o pipefail

if [[ -f "/usr/local/bin/xcpretty" ]]; then
  PRETTYFIER="xcpretty"  
else
  PRETTYFIER="tee"  # Passthrough stdout
fi

OSX_SDK="macosx"
IOS_SDK="iphonesimulator"
TVOS_SDK="appletvsimulator"

OSX_SDK_VERSION=`xcodebuild -version -sdk | grep -A 1 '^MacOSX' | tail -n 1 |  awk '{ print $2 }'`
IOS_SDK_VERSION=`xcodebuild -version -sdk | grep -A 1 '^iPhoneOS' | tail -n 1 |  awk '{ print $2 }'`
TVOS_SDK_VERSION=`xcodebuild -version -sdk | grep -A 1 '^AppleTVOS' | tail -n 1 |  awk '{ print $2 }'`

OSX_TARGET="GCDWebServer (Mac)"
IOS_TARGET="GCDWebServer (iOS)"
TVOS_TARGET="GCDWebServer (tvOS)"
CONFIGURATION="Release"

OSX_TEST_SCHEME="GCDWebServers (Mac)"

BUILD_DIR="`pwd`/build"
PRODUCT="$BUILD_DIR/$CONFIGURATION/GCDWebServer"

PAYLOAD_ZIP="Tests/Payload.zip"
PAYLOAD_DIR="`pwd`/build/Payload"

function runTests {
  EXECUTABLE="$1"
  MODE="$2"
  TESTS="$3"
  FILE="${4:-}"
  
  rm -rf "$PAYLOAD_DIR"
  ditto -x -k "$PAYLOAD_ZIP" "$PAYLOAD_DIR"
  TZ=GMT find "$PAYLOAD_DIR" -type d -exec SetFile -d "1/1/2014 00:00:00" -m "1/1/2014 00:00:00" '{}' \;  # ZIP archives do not preserve directories dates
  if [ "$FILE" != "" ]; then
    cp -f "$4" "$PAYLOAD_DIR/Payload"
    pushd "$PAYLOAD_DIR/Payload"
    TZ=GMT SetFile -d "1/1/2014 00:00:00" -m "1/1/2014 00:00:00" `basename "$FILE"`
    popd
  fi
  logLevel=2 $EXECUTABLE -mode "$MODE" -root "$PAYLOAD_DIR/Payload" -tests "$TESTS"
}

# Run built-in OS X tests
rm -rf "$BUILD_DIR"
xcodebuild test -scheme "$OSX_TEST_SCHEME" "SYMROOT=$BUILD_DIR"

# Build for OS X for oldest supported deployment target
rm -rf "$BUILD_DIR"
xcodebuild build -sdk "$OSX_SDK" -target "$OSX_TARGET" -configuration "$CONFIGURATION" "SYMROOT=$BUILD_DIR" "MACOSX_DEPLOYMENT_TARGET=10.7" | $PRETTYFIER

# Run tests
runTests $PRODUCT "htmlForm" "Tests/HTMLForm"
runTests $PRODUCT "htmlFileUpload" "Tests/HTMLFileUpload"
runTests $PRODUCT "webServer" "Tests/WebServer"
runTests $PRODUCT "webDAV" "Tests/WebDAV-Transmit"
runTests $PRODUCT "webDAV" "Tests/WebDAV-Cyberduck"
runTests $PRODUCT "webDAV" "Tests/WebDAV-Finder"
runTests $PRODUCT "webUploader" "Tests/WebUploader"
runTests $PRODUCT "webServer" "Tests/WebServer-Sample-Movie" "Tests/Sample-Movie.mp4"

# Build for OS X for current deployment target
rm -rf "$BUILD_DIR"
xcodebuild build -sdk "$OSX_SDK" -target "$OSX_TARGET" -configuration "$CONFIGURATION" "SYMROOT=$BUILD_DIR" "MACOSX_DEPLOYMENT_TARGET=$OSX_SDK_VERSION" | $PRETTYFIER

# Build for iOS for oldest supported deployment target
rm -rf "$BUILD_DIR"
xcodebuild build -sdk "$IOS_SDK" -target "$IOS_TARGET" -configuration "$CONFIGURATION" "SYMROOT=$BUILD_DIR" "IPHONEOS_DEPLOYMENT_TARGET=8.0" | $PRETTYFIER

# Build for iOS for current deployment target
rm -rf "$BUILD_DIR"
xcodebuild build -sdk "$IOS_SDK" -target "$IOS_TARGET" -configuration "$CONFIGURATION" "SYMROOT=$BUILD_DIR" "IPHONEOS_DEPLOYMENT_TARGET=$IOS_SDK_VERSION" | $PRETTYFIER

# Build for tvOS for current deployment target
rm -rf "$BUILD_DIR"
xcodebuild build -sdk "$TVOS_SDK" -target "$TVOS_TARGET" -configuration "$CONFIGURATION" "SYMROOT=$BUILD_DIR" "TVOS_DEPLOYMENT_TARGET=$TVOS_SDK_VERSION" | $PRETTYFIER

# Done
echo "\nAll tests completed successfully!"
