#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

command -v swiftlint > /dev/null 2>&1 || { echo >&2 "swiftlint is not installed"; exit 1; }
cp swiftlint.sh .git/hooks/pre-commit

carthage bootstrap --platform iOS

(cd content-blocker-lib-ios/ContentBlockerGen && swift run)