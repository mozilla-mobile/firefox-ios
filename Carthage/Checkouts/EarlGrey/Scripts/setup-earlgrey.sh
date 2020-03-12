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

# Download Fishhook in the EarlGrey directory in the fishhook/ directory.
obtain_fishhook() {
  # Set the current branch, commit or tag of Fishhook to use.
  readonly FISHHOOK_VERSION="0.2"
  # URL for Fishhook to be downloaded from.
  readonly FISHHOOK_URL="https://github.com/facebook/fishhook/archive/${FISHHOOK_VERSION}.zip"
  echo "Obtaining the fishhook dependency."

  # Git Clone Fishhook. Make sure the destination folder is called “fishhook”.
  if [[ -d "${EARLGREY_DIR}/fishhook" ]]; then
    echo "The fishhook directory is already present at $EARLGREY_DIR/fishhook." \
    "If you experience issues with running EarlGrey then please remove" \
    "this directory and run this script again."
  else
    # Download the required fishhook version.
    err_str="There was an error downloading fishhook."
    err_str+="Please check if you are having problems with your connection."
    run_command err_str curl -LOk --fail ${FISHHOOK_URL}

    if [[ ! -f "${FISHHOOK_VERSION}.zip" ]]; then
      echo "The fishhook zip file downloaded seems to have the incorrect" \
      "version. Please download directly from $FISHHOOK_URL and check" \
      "if there are any issues." >&2
      exit 1
    fi

    # Unzip the downloaded .zip file and rename the directory to fishhook/
    err_str="There was an issue while unzipping the Fishhook zip file."
    err_str+="Please ensure if it unzips manually since it might be corrupt."
    run_command err_str unzip ${FISHHOOK_VERSION}.zip > /dev/null

    if [[ ! -d "fishhook-${FISHHOOK_VERSION}" ]]; then
      echo "The correct fishhook version was not unzipped. Please check if" \
      "fishhook-$FISHHOOK_VERSION exists in the EarlGrey Directory."
      exit 1
    fi

    mv fishhook-${FISHHOOK_VERSION} "${EARLGREY_DIR}/fishhook/"
    if [[ $? != 0 ]]; then
      echo "There was an issue moving Fishhook as per" \
      "the EarlGrey specification." >&2
      exit 1
    fi

    rm ${FISHHOOK_VERSION}.zip
    echo "Fishhook downloaded at $EARLGREY_DIR/fishhook"
  fi
}

# Download the OCHamcrest IOS framework and rename the files to
# remove the 'IOS' moniker from it.
obtain_ochamcrest() {
  # Set the current release number for OCHamcrest.
  readonly OCHAMCREST_VERSION="OCHamcrest-5.0.0"
  # URL for OCHamcrest to be downloaded from.
  readonly OCHAMCREST_URL="https://github.com/hamcrest/OCHamcrest/releases/download/v5.0.0/${OCHAMCREST_VERSION}.zip"

  echo "Obtaining the OCHamcrest dependency."

  # Check if the required OCHamcrest.framework exists or not.
  if [[ -d "${EARLGREY_DIR}/OCHamcrest.framework" ]]; then
    echo "The required OCHamcrest.framework directory already exists at" \
    "$EARLGREY_DIR/OCHamcrest.framework. If you experience issues with running" \
    "EarlGrey then please remove this directory and run this script" \
    "again."
  else
    # Download the OCHamcrestIOS framework into the EarlGrey/ directory.
    err_str="There was an error downloading OCHamcrest."
    err_str+="Please check if you are having problems with your connection."
    run_command err_str curl -LOk ${OCHAMCREST_URL}

    if [[ ! -f "${OCHAMCREST_VERSION}.zip" ]]; then
      echo "The required $OCHAMCREST_VERSION Framework was not cloned" \
      "correctly. Try downloading OCHamcrestIOS.framework to the EarlGrey" \
      "folder manually and then run ./rename-ochamcrestIOS.py" >&2
      exit 1
    fi

    # Unzip the archive, and move the OCHamcrestIOS framework to the
    # EarlGrey/ directory, deleting the zip archive in the process.
    err_str="There was an issue while unzipping the OCHamcrest zip file."
    err_str+="Please ensure if it unzips manually since it might be corrupt."
    run_command err_str unzip ${OCHAMCREST_VERSION}.zip > /dev/null

    mv ${OCHAMCREST_VERSION}/OCHamcrestIOS.framework/ .
    rm -r ${OCHAMCREST_VERSION}*

    # Ensure that the correct OCHamcrestIOS.framework is the only OCHamcrest
    # file or directory present.
    if [[ -f "${OCHAMCREST_VERSION}.zip" ]] \
        || [[ -d "${OCHAMCREST_VERSION}" ]] \
        || [[ ! -d "OCHamcrestIOS.framework" ]]; then
      echo "There is an error in modifying the OCHamcrestIOS.framework file." >&2
      exit 1
    fi

    # Run the rename-ochamcrestIOS.py file to set up the OCHamcrest.framework
    # that we need.
    echo "Renaming the OCHamcrestIOS framework for EarlGrey Dependencies."
    ./rename-ochamcrestIOS.py

    mv "OCHamcrest.framework/" "${EARLGREY_DIR}/."

    if [[ $? != 0 ]]; then
      echo "There was an issue in cleaning the OCHamcrestIOS as per" \
      "the EarlGrey specification." >&2
      exit 1
    fi
  fi
}

# Download OCMock for the EarlGrey Unit Tests in the EarlGrey
# Unit Tests directory as ocmock/.
obtain_ocmock() {
  # Path for OCMock to be installed at.
  readonly OCMOCK_PATH="${EARLGREY_DIR}/Tests/UnitTests/ocmock"
  # Set the current branch, commit or tag of OCMock to use.
  readonly OCMOCK_VERSION="master"
  # URL for OCMock to be downloaded from.
  readonly OCMOCK_URL="https://github.com/erikdoe/ocmock/archive/${OCMOCK_VERSION}.zip"
  echo "Obtaining the OCMock dependency."

  # Git Clone OCMock. Make sure the destination folder is called “ocmock”.
  if [[ -d "${OCMOCK_PATH}" ]]; then
    echo "The ocmock directory is already present at ${OCMOCK_PATH}." \
    "If you experience issues with running EarlGrey then please remove" \
    "this directory and run this script again."
  else
    # Download the required OCMock version.
    err_str="There was an error downloading OCMock."
    err_str+="Please check if you are having problems with your connection."
    run_command err_str $(curl -LOk --fail ${OCMOCK_URL})

    if [[ ! -f "${OCMOCK_VERSION}.zip" ]]; then
      echo "The OCMock zip file downloaded seems to have the incorrect" \
      "version. Please download directly from $OCMOCK_URL and check" \
      "if there are any issues." >&2
      exit 1
    fi

    # Unzip the downloaded .zip file and rename the directory to ocmock/
    err_str="There was an issue while unzipping the OCMock zip file. "
    err_str+="Please ensure if it unzips manually since it might be corrupt."
    run_command err_str unzip ${OCMOCK_VERSION}.zip > /dev/null

    if [[ ! -d "ocmock-${OCMOCK_VERSION}" ]]; then
      echo "The correct OCMock version was not unzipped. Please check if" \
      "ocmock-$OCMOCK_VERSION exists in the EarlGrey Directory."
      exit 1
    fi

    mv ocmock-${OCMOCK_VERSION} "${OCMOCK_PATH}"
    rm "${ocmock-"$OCMOCK_VERSION"}".zip

    echo "OCMock downloaded at $OCMOCK_PATH"
  fi
}

# A method to run a command and in case of any execution error
# echo a user provided error.
run_command() {
  ERROR="$1"
  shift
  "$@"
  if [[ $? != 0 ]]; then
     echo "$ERROR" >&2
     exit 1
  fi
}

# Turn on Debug Settings.
set -u

# Path of the script.
readonly EARLGREY_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Path of EarlGrey from the script.
readonly EARLGREY_DIR="${EARLGREY_SCRIPT_DIR}/.."

echo "Changing into EarlGrey Directory"
# Change Directory to the directory that contains EarlGrey.
pushd "${EARLGREY_SCRIPT_DIR}" >> /dev/null

obtain_fishhook
obtain_ochamcrest
obtain_ocmock

echo "The EarlGrey Project and the Test Projects are ready to be run."
# Return back to the calling folder since the script ran successfully.
popd >> /dev/null
