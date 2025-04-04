#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#
# Use the --force option to force a re-build locales.

if [ "$1" == "--force" ]; then
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