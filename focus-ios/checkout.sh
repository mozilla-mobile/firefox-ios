#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -x

git clone https://github.com/mozilla-services/shavar-prod-lists.git || exit 1

# Grab the las known (pinned) commit on the 93.0 branch
(cd shavar-prod-lists && git checkout -q 352f772269f13e70893d0d112d26aed1f079ce6e)

(cd content-blocker-lib-ios/ContentBlockerGen && swift run)
