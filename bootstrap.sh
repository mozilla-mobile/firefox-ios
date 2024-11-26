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
  rm -rf LocalizationTools
  git clone https://github.com/mozilla-mobile/LocalizationTools.git || exit 1

  echo "Creating firefoxios-l10n Git repo"
  rm -rf firefoxios-l10n
  git clone --depth 1 https://github.com/mozilla-l10n/firefoxios-l10n firefoxios-l10n || exit 1
}

if [ "$1" == "--force" ]; then
    rm -rf firefoxios-l10n
    rm -rf LocalizationTools
    rm -rf build
fi

if [ "$1" == "--importLocales" ]; then
  # Import locales
  if [ -d "/firefoxios-l10n" ] && [ -d "/LocalizationTools" ]; then
      echo "l10n directories found. Not downloading scripts."
  else
      echo "l10n directory not found. Downloading repo and scripts."
      getLocale
  fi

  ./firefox-ios/import-strings.sh
  exit 0
fi

# Download the nimbus-fml.sh script from application-services.
NIMBUS_FML_FILE=./firefox-ios/nimbus.fml.yaml
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/mozilla/application-services/main/components/nimbus/ios/scripts/bootstrap.sh | bash -s -- --directory ./firefox-ios/bin $NIMBUS_FML_FILE

# Move hooks from .githooks to .git/hooks
cp -r .githooks/* .git/hooks/

# Make the hooks are executable
chmod +x .git/hooks/*

# Install Node.js dependencies and build user scripts
npm install
npm run build
