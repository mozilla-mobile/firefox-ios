#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Local modifications/additions can be made in `nimbus-fml-configuration.local.sh`

## Set the channel that is used to generate the Swift code.
## The `CONFIGURATION` to derive the channel used in the feature manifest.
CHANNEL=
case "${CONFIGURATION}" in
    Fennec)
        CHANNEL="developer"
        ;;
    Fennec_Testing)
        CHANNEL="developer"
        ;;
    Fennec_Enterprise)
        CHANNEL="developer"
        ;;
    FirefoxStaging)
        CHANNEL="beta"
        ;;
    FirefoxBeta)
        CHANNEL="beta"
        ;;
    Firefox)
        CHANNEL="release"
        ;;
    *) # The channel must match up with the channels listed in APP_FML_FILE.
        CHANNEL="$CONFIGURATION"
        ;;
esac
export CHANNEL

## Set the name of the Swift module that contains the Nimbus SDK.
## Default: MozillaAppServices
# export MOZ_APPSERVICES_MODULE=
fml_file=nimbus.fml.yaml

## Set the list of directories to scan for *.fml.yaml files.
## This can have individual files, but are relative to SOURCE_ROOT
## Default: $PROJECT
export MODULES="$PROJECT $fml_file nimbus-features/messaging/messaging.fml.yaml"

## Set the directory where the generated files are placed.
## This is relative to SOURCE_ROOT.
## By default this is $MODULE/Generated
# export GENERATED_SRC_DIR=

## Set the root level nimbus.fml.yaml file. This is used to generate the experimenter file for the whole app.
## This is relative to SOURCE_ROOT.
## Default: $PROJECT/nimbus.fml.yaml
export APP_FML_FILE=$fml_file

## Set the list of repo files.
## This gives the FML the branches/tags/locations for the dependencies that may have FML files in them.
## These can be absolute, relative to SOURCE_ROOT, a URL to a JSON/YAML file, or a URL shortcut.
## Default: is empty.
# export REPO_FILES=dependency-versions.json

## Set the directory where FMLs from other repos will be downloaded.
## Default: build/nimbus/fml-cache
# export CACHE_DIR=

## Set the path for where the experimenter manifest is generated. This can be json or yaml.
## This is relative to SOURCE_ROOT.
## Default: .experimenter.yaml
# export EXPERIMENTER_MANIFEST=

## Set the version of the Application Services' Nimbus FML is downloaded from. This version does includes the 'v'
## By default, this is derived from the Swift Package Manager.
# export AS_VERSION=

## Set the directory of the app-services directory. This is useful for local development of `nimbus-fml`.
## By default, this is empty, and a pre-built version of `nimbus-fml` will downloaded.
# export MOZ_APPSERVICES_LOCAL=
