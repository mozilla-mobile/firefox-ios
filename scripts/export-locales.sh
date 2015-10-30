#!/bin/sh

#
# Assumes the following is installed:
#
#  svn
#  brew
#  python via brew
#  virtualenv via pip in brew
#
# We can probably check all that for the sake of running this hands-free
# in an automated manner.
#

if [ ! -d Client.xcodeproj ]; then
  echo "Please run this from the project root that contains Client.xcodeproj"
  exit 1
fi

if [ -d firefox-ios-l10n ]; then
  echo "There already is a firefox-ios-l10n checkout. Aborting to let you decide what to do."
  exit 1
fi

# Create a virtualenv with the python modules that we need
rm -rf export-locales-env || exit 1
virtualenv export-locales-env || exit 1
source export-locales-env/bin/activate || exit 1
brew install libxml2 || exit 1
STATIC_DEPS=true pip install lxml || exit 1

# Check out a clean copy of the l10n repo
svn co https://svn.mozilla.org/projects/l10n-misc/trunk/firefox-ios firefox-ios-l10n || exit 1

# Export English base to /tmp/en.xliff
rm -f /tmp/en.xliff || exit 1
xcodebuild -exportLocalizations -localizationPath /tmp -project Client.xcodeproj -exportLanguage en || exit 1

if [ ! -f /tmp/en.xliff ]; then
  echo "Export failed. No /tmp/en.xliff generated."
  exit 1
fi

# Copy the english base back into the repo
cp /tmp/en.xliff firefox-ios-l10n/en-US/firefox-ios.xliff || exit 1

# Copy the english base back into the templates and clean it up
cp /tmp/en.xliff firefox-ios-l10n/templates/firefox-ios.xliff || exit 1

# Update all locales (including 'templates')
scripts/update-xliff.py firefox-ios-l10n || exit 1

# Clean up /templates removing target-language and translations
scripts/clean-xliff.py firefox-ios-l10n/templates || exit 1
