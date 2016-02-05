cd ..
echo "Activating virtualenv"
# create/activate virtualenv
virtualenv python-env || exit 1
source python-env/bin/activate || exit 1
# install libxml2
STATIC_DEPS=true LIBXML2_VERSION=2.9.2 pip install lxml || exit 1
#
# Import locales
#
echo "Importing Locales"
scripts/import-locales.sh $1 || exit 1

echo "Deactivating virtualenv"
deactivate

echo "Committing localised files"
git status
git add Client/*.lproj Extensions/*/*.lproj Client.xcodeproj/project.pbxproj firefox-ios-l10n --force || exit 1
git commit -m 'Import localized files' || exit 1
git status

cd fastlane
