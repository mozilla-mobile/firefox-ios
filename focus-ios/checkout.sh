#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

if ! hash python; then
    echo "python is not installed"
    exit 1
fi

ver=$(python -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
if [ "$ver" -lt "27" ]; then
    echo "This script requires python 2.7 or greater"
    exit 1
elif [ "$ver" -eq "27" ]; then
    echo "Python 27 detected. Running build-disconnect2.py"
    ./build-disconnect2.py
elif [ "$ver" -gt "27" ]; then
    echo "Python ${ver} detected. Running build-disconnect3.py"
    ./build-disconnect3.py
fi

carthage bootstrap --platform iOS
