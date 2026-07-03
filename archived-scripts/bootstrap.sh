#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#
# Pass either 'firefox' (default) or 'focus' to specify which product
# Use the --force option to force a re-build locales.

# Default argument is "firefox"
PRODUCT="${1:-firefox}"

if [[ "$PRODUCT" == "firefox" ]]; then
    echo "Running Firefox bootstrap..."
    
    if [ "$2" == "--force" ]; then
        rm -rf build
    fi

    # Delete all virtual envs folders.
    find . -type d -name ".venv" -exec rm -rf {} +

    # Download the nimbus-fml.sh script from application-services.
    NIMBUS_FML_FILE=./firefox-ios/nimbus.fml.yaml
    curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/mozilla/application-services/main/components/nimbus/ios/scripts/bootstrap.sh | bash -s -- --directory ./firefox-ios/bin $NIMBUS_FML_FILE

    # Move hooks from .githooks to .git/hooks
    cp -r .githooks/* .git/hooks/

    # Make the hooks are executable
    chmod +x .git/hooks/*

    # Install Node.js dependencies and build user scripts
    npm install
    npm run build
    
elif [[ "$PRODUCT" == "focus" ]]; then
    echo "Running Focus script..."

    set -x
    cd focus-ios

    # Version 107.0 hash
    SHAVAR_COMMIT_HASH="91cf7dd142fc69aabe334a1a6e0091a1db228203"

    # Download the nimbus-fml.sh script from application-services.
    NIMBUS_FML_FILE=./nimbus.fml.yaml
    curl --proto '=https' --tlsv1.2 -sSf  https://raw.githubusercontent.com/mozilla/application-services/main/components/nimbus/ios/scripts/bootstrap.sh | bash -s -- $NIMBUS_FML_FILE

    # Clone shavar prod list
    cd .. # Make sure we are at the root of the repo
    rm -rf shavar-prod-lists && git clone https://github.com/mozilla-services/shavar-prod-lists.git && git -C shavar-prod-lists checkout $SHAVAR_COMMIT_HASH

    cd BrowserKit
    swift run || true
    swift run

else
    echo "Unknown product: $PRODUCT"
    echo "Usage: $0 [firefox|focus]"
    exit 1
fi

