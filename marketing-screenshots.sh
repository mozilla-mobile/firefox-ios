#!/bin/sh

if [ ! -d firefox-ios-l10n ]; then
    echo "Did not find a firefox-ios-l10n checkout. Are you running this on a localized build?"
    exit 1
fi

if [ -d marketing-screenshots ]; then
  echo "The marketing-screenshots directory already exists. You decide."
  exit 1
fi

mkdir marketing-screenshots

DEVICES="iPhone 5s, iPhone 6sPlus,iPhone 6s Plus,iPhone 5s,iPad Air,iPad Pro"
DEVICES="iPhone 5s"

LANGUAGES="en-US,de,fr"
LANGUAGES="en-US"

SNAPSHOT=/Users/sarentz/Projects/fastlane/snapshot/bin/snapshot
SNAPSHOT=snapshot

echo "`date` Snapshotting $lang"
$SNAPSHOT --project Client.xcodeproj --scheme MarketingUITests \
    --derived_data_path marketing-screenshots-dd \
    --erase_simulator \
    --number_of_retries 3 \
    --devices "$DEVICES" \
    --languages "$LANGUAGES" \
    --output_directory marketing-screenshots # > marketing-screenshots.log 2>&1

