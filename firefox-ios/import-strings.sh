
echo "\n\n[*] Cloning required repo to import strings"
rm -rf LocalizationTools
rm -rf firefoxios-l10n
git clone https://github.com/mozilla-mobile/LocalizationTools.git || exit 1
git clone --depth 1 https://github.com/mozilla-l10n/firefoxios-l10n || exit 1

pip install -r firefoxios-l10n/.github/scripts/requirements.txt
python3 "firefoxios-l10n/.github/scripts/rewrite_original_attribute.py" --path "firefoxios-l10n"

echo "\n\n[*] Building tools/Localizations"
(cd LocalizationTools && swift build)

echo "\n\n[*] Importing Strings - takes a minute. (output in import-strings.log)"
(cd LocalizationTools && swift run LocalizationTools \
  --import \
  --project-path "$PWD/../firefox-ios/Client.xcodeproj" \
  --l10n-project-path "$PWD/../firefoxios-l10n") > import-strings.log 2>&1

echo "\n\n[!] Strings have been imported. You can now create a PR."
