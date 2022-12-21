#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# Current shavar version
CURRENT_SHAVAR_LIST_VERSION="107"

# Download shavar prod list
echo "shavar-lists-v${CURRENT_SHAVAR_LIST_VERSION}"
rm -rf shavar-prod-lists && mkdir shavar-prod-lists && mkdir shavar-prod-lists/normalized-lists

# Install Node.js dependencies and build user scripts
npm install
npm run build

# Download shavar prod list
files="ads-track-digest256.json analytics-track-digest256.json base-cryptomining-track-digest256.json base-fingerprinting-track-digest256.json content-track-digest256.json social-track-digest256.json disconnect-entitylist.json"

for file in $files
do
	echo "$file"
	curl "https://storage.googleapis.com/shavar-lists-ios-public/Public/shavar-lists-v${CURRENT_SHAVAR_LIST_VERSION}/${file}" -o "shavar-prod-lists/normalized-lists/${file}"
done

cp shavar-prod-lists/normalized-lists/disconnect-entitylist.json shavar-prod-lists/

(cd content-blocker-lib-ios/ContentBlockerGenerator && swift run)
