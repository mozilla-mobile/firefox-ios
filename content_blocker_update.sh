#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# Version 107.0 hash
SHAVAR_COMMIT_HASH="1d71be25893b05ba85850078b1ccedc0824ca958"

# Install Node.js dependencies and build user scripts
npm install
npm run build

# Clone shavar prod list
cd firefox-ios
rm -rf shavar-prod-lists && git clone https://github.com/mozilla-services/shavar-prod-lists.git && git -C shavar-prod-lists checkout $SHAVAR_COMMIT_HASH

(cd Client/ContentBlocker/ContentBlockerGenerator && swift run)
