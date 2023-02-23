#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# Use the --add option to add a new feature
# Use the --update option to update all features in the FML

addFeatureFilesToNimbus() {
    for filename in nimbus-features/*.yaml; do
        echo "  - $filename" >> $1
    done
}

cleanupNimbusFile() {
    grep -v "nimbus-features" $1 > temp
    rm $1
    mv temp $1
}

updateNimbusFML() {
    NIMBUSFML=nimbus.fml.yaml

    cleanupNimbusFile $NIMBUSFML
    addFeatureFilesToNimbus $NIMBUSFML
}

configureFeatureName() {
    echo $1 | sed -r 's/([a-z0-9])([A-Z])/\1-\2/g' | tr '[:upper:]' '[:lower:]'
}

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
        value: {
          \"new-variable\": true
          }
        }
      - channel: developer
        value: {
          \"new-variable\": true
          }
        }

objects:

enums:
""" > $1
}

if [ "$1" == "--add" ]; then
    NEW_FILE=nimbus-features/$2.yaml
    touch $NEW_FILE
    addNewFeatureContent $NEW_FILE $2
    updateNimbusFML
    echo "Added new feature successfully"
fi

if [ "$1" == "--update" ]; then
    updateNimbusFML
fi

if [ "$1" == "--test" ]; then
    configureFeatureName $2
fi
