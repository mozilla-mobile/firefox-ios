#!/bin/sh

if [ ! -d Client.xcodeproj ]; then
  echo "Please run this from the project root that contains Client.xcodeproj"
  exit 1
fi

# using svn export to get a version of the git repo so we can use --force to make rerunning easy
# and it also allows us to ensure that the repo doesn't get treated as a submodule byt git
echo "Creating firefox-ios-l10n Git repo"
svn export --force https://github.com/mozilla-l10n/firefoxios-l10n/trunk firefox-ios-l10n || exit 1

#
# TODO Add incomplete locales here that are NOT to be included.
# TODO Look at https://l10n.mozilla-community.org/~flod/webstatus/?product=firefox-ios to find out which locales are not at 100%
#

INCOMPLETE_LOCALES=(
    "ar"
    "bn-IN"
    "da"
    "el"
    "gl"
    "ml"
    "ms"
    "my"
    "or"
)

if [ "$1" == "--only-complete" ]; then
  for i in "${!INCOMPLETE_LOCALES[@]}"; do
    echo "Removing incomplete locale ${INCOMPLETE_LOCALES[$i]}"
    rm -rf "firefox-ios-l10n/${INCOMPLETE_LOCALES[$i]}"
  done
fi

# Cleanup files (remove unwanted sections, map sv-SE to sv)
scripts/update-xliff.py firefox-ios-l10n || exit 1

# Remove unwanted sections like Info.plist files and $(VARIABLES)
scripts/xliff-cleanup.py firefox-ios-l10n/*/*.xliff || exit 1

# Export xliff files to individual .strings files
rm -rf localized-strings || exit 1
mkdir localized-strings || exit 1
scripts/xliff-to-strings.py firefox-ios-l10n localized-strings|| exit 1

# Modify the Xcode project to reference the strings files we just created
scripts/strings-import.py Client.xcodeproj localized-strings || exit 1
