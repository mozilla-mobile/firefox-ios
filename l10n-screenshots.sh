#!/bin/sh

if [ -d l10n-screenshots ]; then
  echo "The l10n-screenshots directory already exists. You decide."
  exit 1
fi

mkdir l10n-screenshots

for lang in en-US de nl fr it es da se pl; do
    echo "Snapshotting $lang"
    mkdir "l10n-screenshots/$lang"
    snapshot --project Client.xcodeproj --erase_simulator --number_of_retries 3 --devices "iPhone 4s,iPhone 6s" --languages "$lang" --scheme L10nSnapshotTests  --output_directory "l10n-screenshots/$lang" > "l10n-screenshots/$lang/snapshot.log" 2>&1
done

