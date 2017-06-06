#!/usr/bin/env bash

# Only setup virtualenv if we intend on localizing the app.
function setup_virtualenv {
  # Install Python tooling for localizations scripts
  echo password | sudo -S pip install --upgrade pip
  echo password | sudo -S pip install virtualenv
}

#
# Update dependencies that we always need
#

brew upgrade swiftlint

#
# Add a badge for FirefoxBeta
#

if [ "$BUDDYBUILD_SCHEME" = "FirefoxBeta" ]; then
  brew update && brew install imagemagick
  echo password | sudo -S gem install badge
  CF_BUNDLE_SHORT_VERSION_STRING=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Client/Info.plist)
  badge --no_badge --shield_no_resize --shield "$CF_BUNDLE_SHORT_VERSION_STRING-Build%20$BUDDYBUILD_BUILD_NUMBER-blue"
fi

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

