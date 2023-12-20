
echo "\n\n[*] Building tools/Localizations"
(cd LocalizationTools && swift build)

echo "\n\n[*] Importing Strings - takes a minute. (output in import-strings.log)"
(cd LocalizationTools && swift run LocalizationTools \
  --import \
  --project-path "$PWD/../firefox-ios/Client.xcodeproj" \
  --l10n-project-path "$PWD/../firefoxios-l10n") > import-strings.log 2>&1

echo "\n\n[!] Strings have been imported. You can now create a PR."
