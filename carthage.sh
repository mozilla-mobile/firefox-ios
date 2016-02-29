#!/usr/bin/env sh

if [ ! -f "/usr/local/bin/carthage" ]; then
    echo "Cannot find Carthage at /usr/local/bin/carthage - See https://github.com/mozilla/firefox-ios/blob/master/BUILDING.md"
    exit 1
fi

if [[ "$(/usr/local/bin/carthage version)" != "0.15" ]]; then
    echo "Only Carthage 0.15 is currently supported"
    exit 1
fi

