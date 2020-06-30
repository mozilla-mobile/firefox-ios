#!/bin/bash

set -ex


function get_abs_path {
    local file_path="$1"
    echo "$( cd "$(dirname "$file_path")" >/dev/null 2>&1 ; pwd -P )"
}

CURRENT_DIR="$(get_abs_path $0)"
PROJECT_DIR="$(get_abs_path $CURRENT_DIR/../../../..)"


if [ -d l10n-screenshots ]; then
    echo "The l10n-screenshots directory already exists. You decide."
    exit 1
fi

if [ ! -d firefoxios-l10n ]; then
    echo "Did not find a firefox-ios-l10n checkout. Are you running this on a localized build?"
    exit 1
fi

mkdir -p l10n-screenshots

if [ "$1" = '--test-without-building' ]; then
    EXTRA_FAST_LANE_ARGS='--test_without_building'
    shift
fi

LOCALES=$*
if [ $# -eq 0 ]; then
    echo "Please provide locales to test. Available locales live in 'l10n-screenshots-config.yml'. E.g.: $0 af an anp ar"
    exit 1
fi

for lang in $LOCALES; do
    echo "$(date) Snapshotting $lang"
    mkdir "l10n-screenshots/$lang"
    fastlane snapshot --project Client.xcodeproj --scheme L10nSnapshotTests \
        --skip_open_summary \
        --derived_data_path l10n-screenshots-dd \
        --erase_simulator --localize_simulator \
        --devices "iPhone 8" --languages "$lang" \
        --output_directory "l10n-screenshots/$lang" \
        $EXTRA_FAST_LANE_ARGS
    echo "Fastlane exited with code: $?"
done
