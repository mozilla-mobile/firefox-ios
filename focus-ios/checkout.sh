#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

git clone https://github.com/mozilla-services/shavar-prod-lists.git || exit 1

# This revision is taken from the original Cartfile.resolved
(cd shavar-prod-lists && git checkout -q c938da47c4880a48ac40d535caff74dac1d4d77b)

(cd content-blocker-lib-ios/ContentBlockerGen && swift run)
