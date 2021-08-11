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

if [ ! -d Blockzilla.xcodeproj ]; then
  echo "[E] Run this script from the project root as tools/export-strings.sh"
  exit 1
fi

echo "[*] Cloning mozilla-l10n/focusios-l10n"
git clone git@github.com:mozilla-l10n/focusios-l10n.git

echo "\n\n[*] Building tools/Localizations"
(cd tools/Localizations && swift build)

echo "\n\n[*] Importing Strings - takes a minute. (output in import-strings.log)"
tools/Localizations/.build/arm64-apple-macosx/debug/Localizations \
  --import \
  --project-path "$PWD/Blockzilla.xcodeproj" \
  --l10n-project-path "$PWD/focusios-l10n" > export-strings.log 2>&1

echo "\n\n[!] Strings have been imported. You can now create a PR."

