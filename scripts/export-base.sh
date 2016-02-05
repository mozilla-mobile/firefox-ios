#!/bin/sh

if [ ! -d Client.xcodeproj ]; then
  echo "Please run this from the project root that contains Client.xcodeproj"
  exit 1
fi

if [ -d firefox-ios-l10n ]; then
  echo "There already is a firefox-ios-l10n checkout. Aborting to let you decide what to do."
  exit 1
fi

# Check out a clean copy of the l10n repo
git clone https://github.com/mozilla-l10n/firefoxios-l10n firefox-ios-l10n

# Export English base to /tmp/en.xliff
rm -f /tmp/en.xliff
xcodebuild -exportLocalizations -localizationPath /tmp -project Client.xcodeproj -exportLanguage en

if [ ! -f /tmp/en.xliff ]; then
  echo "Export failed. No /tmp/en.xliff generated."
  exit 1
fi

# Copy the english base back into the repo
cp /tmp/en.xliff firefox-ios-l10n/en-US/firefox-ios.xliff

# Show what has changed
(cd firefox-ios-l10n && git status)
