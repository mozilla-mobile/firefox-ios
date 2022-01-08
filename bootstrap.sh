#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#
# Bootstrap the Carthage dependencies. If the Carthage directory
# already exists then nothing is done. This speeds up builds on
# CI services where the Carthage directory can be cached.
#
# Use the --force option to force a rebuild of the dependencies.
# Use the --importLocales option to fetch and update locales only
#

getLocale() {
  echo "Getting locale..."
  git clone https://github.com/boek/ios-l10n-scripts.git -b new_tool || exit 1

  echo "Creating firefoxios-l10n Git repo"
  rm -rf firefoxios-l10n
  git clone --depth 1 https://github.com/mozilla-l10n/firefoxios-l10n firefoxios-l10n || exit 1
}

# Useful to check if previous command was successful - quit if it wasn't
# Pass the error message as a parameter of the function with 'verifyExitCode "message"'
verifyExitCode() {
  EXIT_CODE=$?
  if [ $EXIT_CODE == 0 ]; then
    echo "$1"
    exit 0
  fi
}

if [ "$1" == "--force" ]; then
    rm -rf firefoxios-l10n
    rm -rf ios-l10n-scripts
    rm -rf Carthage/*
    rm -rf ~/Library/Caches/org.carthage.CarthageKit
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

# Run carthage
./carthage_command.sh
verifyExitCode "Exit due to carthage_command.sh"

# Install Node.js dependencies and build user scripts
npm install
npm run build

(cd content-blocker-lib-ios/ContentBlockerGen && swift run)
