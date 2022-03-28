#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#
# Use the --force option to force a re-build locales.
# Use the --importLocales option to fetch and update locales only

getLocale() {
  echo "Getting locale..."
  git clone https://github.com/boek/ios-l10n-scripts.git -b new_tool || exit 1

  echo "Creating firefoxios-l10n Git repo"
  rm -rf firefoxios-l10n
  git clone --depth 1 https://github.com/mozilla-l10n/firefoxios-l10n firefoxios-l10n || exit 1
}

if [ "$1" == "--force" ]; then
    rm -rf firefoxios-l10n
    rm -rf ios-l10n-scripts
fi

if [ "$1" == "--importLocales" ]; then
  # Import locales
  if [ -d "/firefoxios-l10n" ] && [ -d "/ios-l10n-scripts" ]; then
      echo "l10n directories found. Not downloading scripts."
  else
      echo "l10n directory not found. Downloading repo and scripts."
      getLocale
  fi

  ./ios-l10n-scripts/ios-l10n-tools --project-path Client.xcodeproj --l10n-project-path ./firefoxios-l10n --import
  exit 0
fi

# Run and update content blocker
./content_blocker_update.sh
