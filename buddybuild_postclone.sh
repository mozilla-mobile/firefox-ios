#!/usr/bin/env bash

# Only setup virtualenv if we intend on localizing the app.
function setup_virtualenv {
  # Install Python tooling for localizations scripts
  echo password | sudo -S pip install --upgrade pip
  echo password | sudo -S pip install virtualenv
}

brew upgrade swiftlint

# Install tooling for Badging.
brew update && brew install imagemagick
echo password | sudo -S gem install badge

# Add badge to app icon.
badge --no_badge --shield_no_resize --shield "7.0-Build%20$BUDDYBUILD_BUILD_NUMBER-blue"

# Import the localize for our distribution builds.
if [ $BUDDYBUILD_SCHEME = FirefoxBeta ]; then
  setup_virtualenv
  ./scripts/import-locales.sh
elif [ $BUDDYBUILD_SCHEME = Firefox ]; then
  setup_virtualenv
  ./scripts/import-locales.sh --release
fi
