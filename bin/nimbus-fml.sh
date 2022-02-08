#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Nimbus Feature Manifest Language Generator
#
# For more infomration, check out https://experimenter.info/fml-spec
#
# This script generates Swift definitions for all the experimentable features supported by Nimbus. 
# It generates Swift code to be included in the final build.
#
# To use it in a Swift project, follow these steps:
# 1. Import the `nimbus-fml.sh` script into your project.
# 2. Add a `<NAME>.yaml` feature manifest file. Check out https://experimenter.info/fml-spec for the spec.
# 3. Add a new "Run Script" build step and set the command to `bash $PWD/nimbus-fml.sh`
# 4. Add your FML filee as an Input File for the "Run Script" step.
# 5. Run the build.
# 6. Add the "FML.swift" file in the `Generated` folder to your project.
# 7. Add the same "FML.swift" from the `Generated` folder as Output Files of the newly created "Run SCript" step.
# 8. Start using the generated feature code.

set -e

# CMDNAME is used in the usage text below.
# shellcheck disable=SC2034
CMDNAME=$(basename "$0")
USAGE=$(cat <<'HEREDOC'
$(CMDNAME)
Tarik Eshaq <teshaq@mozilla.com>

Nimbus Feature Manifest Language generator.

This script generates the code needed to interact with Nimbus, exposing features which are experimentable.

For more infomration, check out https://experimenter.info/fml-spec

The script structure was adopted from the similar script "sdk_generator.sh" written by the Glean team.

This script should be executed as a "Run Build Script" phase from Xcode.

USAGE:
    ${CMDNAME} [OPTIONS] <MANIFEST_PATH>

ARGS:
    <MANIFEST_PATH>  The path to the FML yaml file to parse. default: \$SCRIPT_INPUT_FILE_0 environment variable.

OPTIONS:
    -o, --output  <PATH>             Folder to place generated FML code in. Default: \$SOURCE_ROOT/\$PROJECT/Generated
    -n, --namespace <NIMBUS_NAMESPACE> The module where Nimbus is imported from. Default: no external module
    -h, --help                       Display this help message.
HEREDOC
)

helptext() {
    echo "$USAGE"
}

MANIFEST_PATH=
OUTPUT_DIR="${SOURCE_ROOT}/${PROJECT}/Generated"
NAMESPACE=
AS_VERSION=v91.0.1

while (( "$#" )); do
    case "$1" in
        -o|--output)
            OUTPUT_DIR=$2
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE=$2
            shift 2
            ;;
        -h|--help)
            helptext
            exit 0
            ;;
        --) # end argument parsing
            shift
            break
            ;;
        --*=|-*) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            MANIFEST_PATH=$1
            shift
            ;;
    esac
done

if [ -z $MANIFEST_PATH ]; then
    if [ -z "$SCRIPT_INPUT_FILE_COUNT" ] || [ "$SCRIPT_INPUT_FILE_COUNT" -eq 0 ]; then
        echo "Error: No input files provided for the Nimbus Feature Manifest."
        exit 2
    fi
    MANIFEST_PATH=$SCRIPT_INPUT_FILE_0
fi

if [ -z "$SOURCE_ROOT" ]; then
    echo "Error: No \$SOURCE_ROOT defined."
    echo "Execute this script as a build step in Xcode."
    exit 2
fi

if [ -z "$PROJECT" ]; then
    echo "Error: No \$PROJECT defined."
    echo "Execute this script as a build step in Xcode."
    exit 2
fi
if [ -z "$MOZ_BUNDLE_DISPLAY_NAME" ]; then
    echo "Error: No \$MOZ_BUNDLE_DISPLAY_NAME defined."
    echo "Execute this script as a build step in Xcode."
    exit 2
fi

# We create the nimbus-fml directory, which is gitignored, we use -p to make sure this doesn't fail if it already exists
mkdir -p ${SOURCE_ROOT}/nimbus-fml
# We now download the nimbus-fml from the github release
curl -L https://github.com/mozilla/application-services/releases/download/${AS_VERSION}/nimbus-fml.zip --output ${SOURCE_ROOT}/nimbus-fml/nimbus-fml.zip
# We also download the checksum
curl -L https://github.com/mozilla/application-services/releases/download/${AS_VERSION}/nimbus-fml.sha256 --output ${SOURCE_ROOT}/nimbus-fml/nimbus-fml.sha256
pushd ${SOURCE_ROOT}/nimbus-fml
shasum --check nimbus-fml.sha256
popd

## Once the FML is downloaded, we need to unzip it, and run the appropriate nimbus-fml that reflects
## the architecture of the device running this script.
unzip -o ${SOURCE_ROOT}/nimbus-fml/nimbus-fml.zip -d ${SOURCE_ROOT}/nimbus-fml

## We get the device's architecture
ARCH=$(uname -m)
BINARY_PATH=
if [[ "$ARCH" == 'x86_64' ]]
then
    BINARY_PATH=${SOURCE_ROOT}/nimbus-fml/x86_64-apple-darwin/release/nimbus-fml
elif [[ "$ARCH" == 'arm64' ]]
then
    BINARY_PATH=${SOURCE_ROOT}/nimbus-fml/aarch64-apple-darwin/release/nimbus-fml
else
    echo "Error: Unsupported architecture. This script can only run on Mac devices running x86_64 or arm64"
    exit 2
fi


## The `MOZ_BUNDLE_DISPLAY_NAME` has the name of the scheme
## we use it as a channel in the Feature Manifest. 
## We seperate the first word of it, since Fennec builds sometimes have the user name after the scheme
SCHEME=${MOZ_BUNDLE_DISPLAY_NAME%% *}
$BINARY_PATH $MANIFEST_PATH -o $OUTPUT_DIR/FxNimbus.swift ios features --classname FxNimbus --channel $SCHEME

# The FML doesn't currenlty support adding a custom import, so we do this in this script.
# See: https://mozilla-hub.atlassian.net/browse/EXP-2199
if [[ ! -z $NAMESPACE ]]; then
    echo -e "import $NAMESPACE\n$(cat $OUTPUT_DIR/FxNimbus.swift)" > $OUTPUT_DIR/FxNimbus.swift
fi

exit 0
