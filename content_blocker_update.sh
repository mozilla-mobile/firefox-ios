#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# Update commit hash when you need to update shavar prod list
# Note: we can update this to use a tag / branch in future
SHAVAR_COMMIT_HASH="3910527004252af3aa9dd701566a2cb3b78e5c3a"

# Install Node.js dependencies and build user scripts
npm install
npm run build

# Clone shavar prod list
rm -rf shavar-prod-lists && git clone https://github.com/mozilla-services/shavar-prod-lists.git && git -C shavar-prod-lists checkout $SHAVAR_COMMIT_HASH

(cd content-blocker-lib-ios/ContentBlockerGen && swift run)
