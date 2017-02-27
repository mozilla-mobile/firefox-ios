#!/bin/bash

if [ -d l10n-screenshots ]; then
  echo "The l10n-screenshots directory already exists. You decide."
  exit 1
fi

if [ ! -d firefox-ios-l10n ]; then
    echo "Did not find a firefox-ios-l10n checkout. Are you running this on a localized build?"
    exit 1
fi

mkdir l10n-screenshots

for d in firefox-ios-l10n/?? firefox-ios-l10n/??? firefox-ios-l10n/??-??; do
    lang=$(basename $d)
    if [ "$lang" != "ar" ]; then
        echo "$(date) Snapshotting $lang"
        mkdir "l10n-screenshots/$lang"
        fastlane snapshot --project Client.xcodeproj --scheme L10nSnapshotTests \
            --skip_open_summary \
            --derived_data_path l10n-screenshots-dd \
            --erase_simulator --number_of_retries 3 \
            --devices "iPhone SE" --languages "$lang" \
            --output_directory "l10n-screenshots/$lang" # > "l10n-screenshots/$lang/snapshot.log" 2>&1
    fi
done
