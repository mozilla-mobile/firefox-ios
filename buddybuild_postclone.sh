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

# Import the localize for our distribution builds.
if [ "$BUDDYBUILD_SCHEME" = FirefoxBeta ]; then
  # Add badge to app icon.
  CF_BUNDLE_SHORT_VERSION_STRING=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Client/Info.plist)
  badge --no_badge --shield_no_resize --shield "$CF_BUNDLE_SHORT_VERSION_STRING-Build%20$BUDDYBUILD_BUILD_NUMBER-blue"

  setup_virtualenv
  ./scripts/import-locales.sh
elif [ "$BUDDYBUILD_SCHEME" = Firefox ]; then
  setup_virtualenv
  ./scripts/import-locales.sh --release
fi
