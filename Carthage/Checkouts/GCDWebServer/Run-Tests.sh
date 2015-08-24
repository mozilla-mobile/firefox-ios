#!/bin/bash -ex

OSX_SDK="macosx"
if [ -z "$TRAVIS" ]; then
  IOS_SDK="iphoneos"
else
  IOS_SDK="iphonesimulator"
fi

OSX_TARGET="GCDWebServer (Mac)"
IOS_TARGET="GCDWebServer (iOS)"
CONFIGURATION="Release"

BUILD_DIR="/tmp/GCDWebServer-Build"
PRODUCT="$BUILD_DIR/$CONFIGURATION/GCDWebServer"

PAYLOAD_ZIP="Tests/Payload.zip"
PAYLOAD_DIR="/tmp/GCDWebServer-Payload"

function runTests {
  rm -rf "$PAYLOAD_DIR"
  ditto -x -k "$PAYLOAD_ZIP" "$PAYLOAD_DIR"
  TZ=GMT find "$PAYLOAD_DIR" -type d -exec SetFile -d "1/1/2014 00:00:00" -m "1/1/2014 00:00:00" '{}' \;  # ZIP archives do not preserve directories dates
  if [ "$4" != "" ]; then
    cp -f "$4" "$PAYLOAD_DIR/Payload"
    pushd "$PAYLOAD_DIR/Payload"
    TZ=GMT SetFile -d "1/1/2014 00:00:00" -m "1/1/2014 00:00:00" `basename "$4"`
    popd
  fi
  logLevel=2 $1 -mode "$2" -root "$PAYLOAD_DIR/Payload" -tests "$3"
}

# Build for iOS for oldest deployment target (TODO: run tests on iOS)
rm -rf "$BUILD_DIR"
xcodebuild -sdk "$IOS_SDK" -target "$IOS_TARGET" -configuration "$CONFIGURATION" build "SYMROOT=$BUILD_DIR" "IPHONEOS_DEPLOYMENT_TARGET=5.1.1" > /dev/null

# Build for iOS for default deployment target (TODO: run tests on iOS)
rm -rf "$BUILD_DIR"
xcodebuild -sdk "$IOS_SDK" -target "$IOS_TARGET" -configuration "$CONFIGURATION" build "SYMROOT=$BUILD_DIR" > /dev/null

# Build for OS X for oldest deployment target
rm -rf "$BUILD_DIR"
xcodebuild -sdk "$OSX_SDK" -target "$OSX_TARGET" -configuration "$CONFIGURATION" build "SYMROOT=$BUILD_DIR" "MACOSX_DEPLOYMENT_TARGET=10.7" > /dev/null

# Build for OS X for default deployment target
rm -rf "$BUILD_DIR"
xcodebuild -sdk "$OSX_SDK" -target "$OSX_TARGET" -configuration "$CONFIGURATION" build "SYMROOT=$BUILD_DIR" > /dev/null

# Run tests
runTests $PRODUCT "htmlForm" "Tests/HTMLForm"
runTests $PRODUCT "htmlFileUpload" "Tests/HTMLFileUpload"
runTests $PRODUCT "webServer" "Tests/WebServer"
runTests $PRODUCT "webDAV" "Tests/WebDAV-Transmit"
runTests $PRODUCT "webDAV" "Tests/WebDAV-Cyberduck"
runTests $PRODUCT "webDAV" "Tests/WebDAV-Finder"
runTests $PRODUCT "webUploader" "Tests/WebUploader"
runTests $PRODUCT "webServer" "Tests/WebServer-Sample-Movie" "Tests/Sample-Movie.mp4"

# Done
echo "\nAll tests completed successfully!"
