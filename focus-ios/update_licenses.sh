#!/bin/bash

if ! type "license-plist" > /dev/null; then
    echo "You need to install license-plist!"
    echo "Available at: https://github.com/mono0926/LicensePlist/"
    exit 0
fi

license-plist --output-path ./Blockzilla/Settings.bundle --config-path ./license_plist.yml --suppress-opening-directory
