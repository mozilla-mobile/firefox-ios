cd ..
echo "Activating virtualenv"
# create/activate virtualenv
if [ -d python-env ]; then
  source python-env/bin/activate || exit 1
else
  virtualenv python-env || exit 1
  source python-env/bin/activate || exit 1
  # install libxml2
  brew install libxml2 || exit 1
  STATIC_DEPS=true pip install lxml || exit 1
fi

#
# Import locales
#
echo "Importing Locales"
scripts/import-locales.sh --only-complete || exit 1

echo "Deactivating virtualenv"
deactivate

git add firefox-ios-l10n Client/*.lproj Extensions/*/*.lproj Client.xcodeproj/project.pbxproj || exit 1
git commit -m 'Import localized files' || exit 1

cd fastlane