#!/usr/bin/env bash

# Only setup virtualenv if we intend on localizing the app.
function setup_virtualenv {
  # Install Python tooling for localizations scripts
  echo password | sudo easy_install pip
  echo password | sudo -S pip install --upgrade pip
  echo password | sudo -S pip install virtualenv
}

#
# Import the final locales on our Beta and Release builds
#

if [ "$BUDDYBUILD_SCHEME" = "Firefox" ] || [ "$BUDDYBUILD_SCHEME" = "FirefoxBeta" ]; then
  setup_virtualenv
  ./scripts/import-locales.sh --release
fi

#
# Import all the locales on our Fennec_Enterprise builds except for pull requests.
#

if [ "$BUDDYBUILD_SCHEME" = "Fennec_Enterprise" ] && [ "$BUDDYBUILD_PULL_REQUEST" = "" ]; then
  setup_virtualenv
  ./scripts/import-locales.sh
fi
