#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#
# Bootstrap the Carthage dependencies. If the Carthage directory
# already exists then nothing is done. This speeds up builds on
# CI services where the Carthage directory can be cached.
#
# Use the --force option to force a rebuild of the dependencies.
#

if [ "$1" == "--force" ]; then
    rm -rf Carthage/*
    rm -rf ~/Library/Caches/org.carthage.CarthageKit
fi

# Only enable this on the Xcode Server because it times out if it does not
# get any output for some time while building the dependencies.

CARTHAGE_VERBOSE=""
if [ ! -z "$XCS_BOT_ID"  ]; then
  CARTHAGE_VERBOSE="--verbose"
fi

# if rome is installed and is pointed at the bucket with glean in it
if [ -x "$(command -v rome)" ] && rome list | grep -q glean; then
  rome download --platform iOS | grep -v 'specified key' | grep -v 'in local cache' 
  rome list --missing --platform iOS | awk '{print $1}' | xargs -I {} carthage bootstrap "{}" $CARTHAGE_VERBOSE --platform iOS --cache-builds
  # upload in background
  rome list --missing --platform ios | awk '{print $1}' | xargs rome upload --platform ios &
  carthage checkout shavar-prod-lists
else
  carthage bootstrap $CARTHAGE_VERBOSE --platform ios --color auto --cache-builds
fi

# Install Node.js dependencies and build user scripts

npm install
npm run build

(cd content-blocker-lib-ios/ContentBlockerGen && swift run)
