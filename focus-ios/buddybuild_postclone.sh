#!/usr/bin/env bash

./build-disconnect.py

# Update existing locales. This will only update locales that are already
# imported to the application. It will not include new locales, that
# remains a manual action.

git clone --depth 1 https://github.com/mozilla-l10n/focusios-l10n.git \
    && ./import-locales -allowIncomplete focusios-l10n/{??,???,??-??}/focus-ios.xliff

brew update
