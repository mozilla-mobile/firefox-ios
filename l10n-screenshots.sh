#!/bin/bash

if [ -d l10n-screenshots ]; then
  echo "The l10n-screenshots directory already exists. You decide."
  exit 1
fi

if [ ! -d firefoxios-l10n ]; then
    echo "Did not find a firefox-ios-l10n checkout. Are you running this on a localized build?"
    exit 1
fi

mkdir l10n-screenshots

LOCALES=$*
if [ $# -eq 0 ]; then
  LOCALES="af ar ast az bg bn br bs ca cs cy da de dsb el en-GB en-US eo es es-CL es-MX eu fa fr ga-IE gd gl he hi-IN hsb hu hy-AM id is it ja kab kk km kn ko lo lt lv ml ms my nb-NO ne-NP nl nn-NO or pa-IN pl pt-BR pt-PT rm ro ru ses si sk sl sq sv-SE te th tl tn tr uk ur uz zh-CN zh-TW"
fi

for lang in $LOCALES; do
    echo "$(date) Snapshotting $lang"
    mkdir "l10n-screenshots/$lang"
    fastlane snapshot --project Client.xcodeproj --scheme L10nSnapshotTests \
        --skip_open_summary \
        --derived_data_path l10n-screenshots-dd \
        --erase_simulator --localize_simulator \
        -i "11.0.1" --devices "iPhone SE" --languages "$lang" \
        --output_directory "l10n-screenshots/$lang" > "l10n-screenshots/$lang/snapshot.log" 2>&1
done
