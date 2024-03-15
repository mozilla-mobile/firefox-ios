#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -x
cd focus-ios

# Version 107.0 hash
SHAVAR_COMMIT_HASH="1d71be25893b05ba85850078b1ccedc0824ca958"

# Download the nimbus-fml.sh script from application-services.
NIMBUS_FML_FILE=./nimbus.fml.yaml
curl --proto '=https' --tlsv1.2 -sSf  https://raw.githubusercontent.com/mozilla/application-services/main/components/nimbus/ios/scripts/bootstrap.sh | bash -s -- $NIMBUS_FML_FILE

# Clone shavar prod list
cd .. # Make sure we are at the root of the repo
rm -rf shavar-prod-lists && git clone https://github.com/mozilla-services/shavar-prod-lists.git && git -C shavar-prod-lists checkout $SHAVAR_COMMIT_HASH

(cd BrowserKit && swift run)
