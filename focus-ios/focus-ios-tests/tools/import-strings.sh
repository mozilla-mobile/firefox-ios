#!/bin/sh

#
# This script imports strings into the project. It does this by checking
# out the l10n repository and then running the Localizations tool. That
# tool pre-processes the XLIFF files from the l10n repository and then 
# basically runs xcodebuild -importLocales on those.
#
# The script does not create branches or pull requests so it is best
# to run this on a clean branch. You can then run a git diff to check
# the actual changes and create a new branch and pull request with
# those changes included if it all checks out.
#
# Basic workflow:
#
#  $ tools/import-strings.sh
#  $ git checkout -b string-import-YYMMDD
#  $ git push
#  $ gh pr create # (or manually)
#
# For the bigger picture on string import, export see the wiki.
#
#  https://github.com/mozilla-mobile/focus-ios/wiki/Importing-and-Exporting-Strings
#

set -e
cd focus-ios

if [ ! -d Blockzilla.xcodeproj ]; then
  echo "[E] Run this script from the project root as tools/export-strings.sh"
  exit 1
fi

echo "[*] Cloning mozilla-l10n/focusios-l10n"
[ -d focusios-l10n ] && rm -rf focusios-l10n
git clone https://github.com/mozilla-l10n/focusios-l10n.git focusios-l10n

echo "[*] Cloning mozilla-mobile/LocalizationTools"
[ -d focus-ios-tests/tools/Localizations ] && rm -rf focus-ios-tests/tools/Localizations
git clone https://github.com/mozilla-mobile/LocalizationTools.git focus-ios-tests/tools/Localizations

echo "[*] Building tools/Localizations"
(cd focus-ios-tests/tools/Localizations && swift build)

echo "[*] Replacing firefox with focus in swift task files"
sed -i '' 's/firefox-ios.xliff/focus-ios.xliff/g' focus-ios-tests/tools/Localizations/Sources/LocalizationTools/tasks/*.swift

echo "[*] Removing es-ES locale mapping from swift import task"
sed -i '' '/es-ES/d' focus-ios-tests/tools/Localizations/Sources/LocalizationTools/tasks/ImportTask.swift

echo "[*] Use en instead of en-US as developmentRegion in swift import task"
sed -i '' 's/"developmentRegion" : "en-US"/"developmentRegion" : "en"/' focus-ios-tests/tools/Localizations/Sources/LocalizationTools/tasks/ImportTask.swift

echo "[*] Removing WidgetKit/en-US.lproj/WidgetIntents.strings from swift import task"
# Match all text between a line containing 'ShortcutItemTitleQRCode' to ']' and delete them
sed -ri '' '/ShortcutItemTitleQRCode/,/\]/{/ShortcutItemTitleQRCode/!{/\]/!d;};}' focus-ios-tests/tools/Localizations/Sources/LocalizationTools/tasks/ImportTask.swift

echo "[*] Importing Strings - takes a minute. (output in import-strings.log)"
(cd focus-ios-tests/tools/Localizations && swift run LocalizationTools \
  --import \
  --project-path "$PWD/../../../Blockzilla.xcodeproj" \
  --l10n-project-path "$PWD/../../../focusios-l10n") > import-strings.log 2>&1

echo "[!] Strings have been imported. You can now create a PR."
