#!/bin/sh

scripts/xliff-cleanup.py ../firefox-ios-l10n/*/*.xliff

rm -rf imported-locales
mkdir imported-locales

scripts/xliff-to-strings.py ../firefox-ios-l10n imported-locales

scripts/strings-import.py Client.xcodeproj imported-locales

