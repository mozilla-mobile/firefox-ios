cd ..
echo "Activating virtualenv"
# create/activate virtualenv
virtualenv -p /usr/bin/python2.7 python-env || exit 1
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
git add Client/*.lproj Extensions/*/*.lproj Client.xcodeproj/project.pbxproj || exit 1
git commit -m 'Import localized files' || exit 1


cd fastlane