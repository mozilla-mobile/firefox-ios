#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# General:

# This utility simplifies managing the `include` block of the
# nimbus.fml.yaml file. There are two main options:

# --add fileName : option to add a new feature. Argument should be camelCase
#                  Note: --add also runs --update
# --update : updates the `include` block of the FML file.

# Adds the files in the 'nimbus-features' directory in the
# `include` block of the FML
addFeatureFilesToNimbus() {
    for filename in firefox-ios/nimbus-features/*.yaml; do
        relativeName="${filename#firefox-ios/}"
        echo "  - $relativeName" >> $1
    done
}

# Removes the files listed in the FML's `include` block
cleanupNimbusFile() {
    grep -v "nimbus-features" $1 > temp
    rm $1
    mv temp $1
}

updateNimbusFML() {
    NIMBUSFML=firefox-ios/nimbus.fml.yaml

    cleanupNimbusFile $NIMBUSFML
    addFeatureFilesToNimbus $NIMBUSFML
}

# Takes a given feature name in camelCase and coverts it to kebab-case
configureFeatureName() {
    echo $1 | sed -r 's/([a-z0-9])([A-Z])/\1-\2/g' | tr '[:upper:]' '[:lower:]'
}

# Prefills a newly created feature file with
addNewFeatureContent() {
    KEBAB_FEATURE_NAME=$(configureFeatureName $2)
    echo """# The configuration for the $2 feature
features:
  $KEBAB_FEATURE_NAME:
    description: >
      Feature description
    variables:
      new-variable:
        description: >
          Variable description
        type: Boolean
        default: false
    defaults:
      - channel: beta
        value:
          new-variable: false
      - channel: developer
        value:
          new-variable: false

objects:

enums:
""" > $1
}

if [ "$1" == "--add" ]; then
    NEW_FILE=firefox-ios/nimbus-features/$2.yaml
    touch $NEW_FILE
    addNewFeatureContent $NEW_FILE $2
    updateNimbusFML
    echo "Added new feature successfully"
fi

if [ "$1" == "--update" ]; then
    updateNimbusFML
fi

if [ $# -eq 0 ]; then
    echo "No arguments supplied. Please see the documentation in the script."
fi
