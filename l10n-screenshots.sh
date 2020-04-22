#!/bin/bash

set -ex

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
  LOCALES="af an anp ar ast az bg bn bo br bs ca co cs cy da de dsb el en-CA en-GB en-US eo es-AR es-CL es-MX es eu fa fi fr ga-IE gd gl gu-IN he hi-IN hr hsb hu hy-AM ia id is it ja jv ka kab kk km kn ko lo lt lv ml mr ms my nb-NO ne-NP nl nn-NO oc or pa-IN pl pt-BR pt-PT rm ro ru ses si sk sl sq su sv-SE ta te th tl tr uk ur uz vi zgh zh-CN zh-TW"
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
