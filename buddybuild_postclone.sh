#!/usr/bin/env bash

# Only setup virtualenv if we intend on localizing the app.
function setup_virtualenv {
  # Install Python tooling for localizations scripts
  echo password | sudo easy_install pip
  echo password | sudo -S pip install --upgrade pip
  echo password | sudo -S pip install virtualenv
}

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
# Import only the shipping locales (from shipping_locales.txt) on our Beta and
# Release builds. Import all locales on Fennec_Enterprise, except for pull requests.
#

git clone https://github.com/mozilla-mobile/ios-l10n-scripts.git || exit 1

if [ "$BUDDYBUILD_SCHEME" = "Firefox" ] || [ "$BUDDYBUILD_SCHEME" = "FirefoxBeta" ]; then
  setup_virtualenv
  ./ios-l10n-scripts/import-locales-firefox.sh --release
fi

if [ "$BUDDYBUILD_SCHEME" = "Fennec_Enterprise" ] && [ "$BUDDYBUILD_PULL_REQUEST" = "" ]; then
  setup_virtualenv
  ./ios-l10n-scripts/import-locales-firefox.sh
fi

