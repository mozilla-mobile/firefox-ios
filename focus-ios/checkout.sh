#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

if [ "$1" == "--force" ]; then
    rm -rf Carthage/*
    rm -rf ~/Library/Caches/org.carthage.CarthageKit
fi

./carthage_command.sh

(cd content-blocker-lib-ios/ContentBlockerGen && swift run)
