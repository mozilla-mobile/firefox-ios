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

#  Build and archive EarlGrey.framework into EarlGrey.zip in the current running
#  folder so it is ready to use for github release and cocoapods deployment.

SOURCE_DIR="$(dirname ${BASH_SOURCE[0]})"
CURRENT_DIR="${PWD}"

: "${PROJECT_FILE_PATH:=${SOURCE_DIR}/../EarlGrey.xcodeproj}"
: "${OUTPUT_DIR:=${SOURCE_DIR}/build}"

readonly PACKAGE_NAME="EarlGrey"
readonly OUTPUT_TMP_DIR=$(mktemp -d)
readonly OUTPUT_PACKAGE_DIR="${OUTPUT_TMP_DIR}/${PACKAGE_NAME}"
readonly PACKAGE_FILES="README.md CHANGELOG.md LICENSE"

# Make a universal dynamic framework build.
export OUTPUT_DIR="${OUTPUT_TMP_DIR}/build"
(cd "${SOURCE_DIR}/.." \
  && xcrun xcodebuild build -project "${PROJECT_FILE_PATH}" -target "Release")

# Copy files to the temp dir and zip.
mkdir -p "${OUTPUT_PACKAGE_DIR}"
(cd "${SOURCE_DIR}/.." && cp "${PACKAGE_FILES}" "${OUTPUT_PACKAGE_DIR}")

# Symlink the framework so we don't need to copy.
ln -s "${OUTPUT_DIR}/EarlGrey.framework" "${OUTPUT_PACKAGE_DIR}/EarlGrey.framework"

(cd "${OUTPUT_DIR}/.." \
  && zip -r -X "${CURRENT_DIR}/${PACKAGE_NAME}.zip" "${PACKAGE_NAME}")

rm -rf "${OUTPUT_TMP_DIR}"
