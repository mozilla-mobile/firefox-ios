#!/bin/sh

if [ ! -d Client.xcodeproj ]; then
  echo "Please run this from the project root that contains Client.xcodeproj"
  exit 1
fi

if [ -d firefox-ios-l10n ]; then
  echo "There already is a firefox-ios-l10n checkout. Aborting to let you decide what to do."
  exit 1
fi

svn co --non-interactive --trust-server-cert https://svn.mozilla.org/projects/l10n-misc/trunk/firefox-ios firefox-ios-l10n || exit 1

if [ "$1" == "--only-complete" ]; then
  # Get the list of incomplete locale (missing strings, errors) from the localization dashboard
  # https://l10n.mozilla-community.org/~flod/webstatus/api/?product=firefox-ios&type=incomplete&txt
  INCOMPLETE_LOCALES_LIST=$(wget -qO- https://l10n.mozilla-community.org/~flod/webstatus/api/?product=firefox-ios\&type=incomplete\&txt)
  INCOMPLETE_LOCALES=(${INCOMPLETE_LOCALES_LIST//$'\n'/ })

  # Extra locales excluded even if complete
  ADDITIONAL_LOCALES=(
      "da"
  )

  # Full list of locales to exclude
  EXCLUDED_LOCALES=(
      "${INCOMPLETE_LOCALES[@]}"
      "${ADDITIONAL_LOCALES[@]}"
  )

  for i in "${!EXCLUDED_LOCALES[@]}"; do
    echo "Removing incomplete locale ${EXCLUDED_LOCALES[$i]}"
    rm -rf "firefox-ios-l10n/${EXCLUDED_LOCALES[$i]}"
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

