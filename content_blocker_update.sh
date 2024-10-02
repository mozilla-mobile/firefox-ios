#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# Version 107.0 hash
SHAVAR_COMMIT_HASH="91cf7dd142fc69aabe334a1a6e0091a1db228203"

# Install Node.js dependencies and build user scripts
npm install
npm run build

# Clone shavar prod list
rm -rf shavar-prod-lists && git clone https://github.com/mozilla-services/shavar-prod-lists.git && git -C shavar-prod-lists checkout $SHAVAR_COMMIT_HASH

(cd BrowserKit && swift run)