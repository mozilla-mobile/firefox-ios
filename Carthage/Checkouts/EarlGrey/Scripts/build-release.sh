#!/bin/bash
#
#  Copyright 2017 Google Inc.
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
#

#  Build EarlGrey.framework in two SDK's: iphoneos and iphonesimulator, and 
#  lipo into one universal framework under the BUILD_DIR folder.

: "${PROJECT_FILE_PATH:=$(dirname ${BASH_SOURCE[0]})/../EarlGrey.xcodeproj}"
: "${BUILD_DIR:=build}"
: "${CONFIGURATION_NAME:=Release}"
: "${OUTPUT_DIR:=build}"

mkdir -p "${OUTPUT_DIR}"

xcrun xcodebuild build -project "${PROJECT_FILE_PATH}" -target "EarlGrey" \
  -configuration "${CONFIGURATION_NAME}" -sdk iphoneos CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO ENTITLEMENTS_REQUIRED=NO ONLY_ACTIVE_ARCH=NO \
  CONFIGURATION_BUILD_DIR="${OUTPUT_DIR}/iphoneos"

xcrun xcodebuild build \ -project "${PROJECT_FILE_PATH}" -target "EarlGrey" \
  -configuration "${CONFIGURATION_NAME}" -sdk iphonesimulator CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO ENTITLEMENTS_REQUIRED=NO ONLY_ACTIVE_ARCH=NO \
  CONFIGURATION_BUILD_DIR="${OUTPUT_DIR}/iphonesimulator"

# Use the framework built for device as the final product and lipo it later.
cp -r "${OUTPUT_DIR}/iphoneos/EarlGrey.framework" "${OUTPUT_DIR}"

xcrun lipo -create "${OUTPUT_DIR}/iphoneos/EarlGrey.framework/EarlGrey" \
  "${OUTPUT_DIR}/iphonesimulator/EarlGrey.framework/EarlGrey" \
  -output "${OUTPUT_DIR}/EarlGrey.framework/EarlGrey"

