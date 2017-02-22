cd ..
echo "Activating virtualenv"
# create/activate virtualenv
virtualenv python-env --python=python2.7 || exit 1
source python-env/bin/activate || exit 1
# install libxml2
CFLAGS=-I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/usr/include/libxml2 LIBXML2_VERSION=2.9.2 pip install lxml || exit 1
#
# Import locales
#
echo "Importing Locales"
scripts/import-locales.sh $1 || exit 1

echo "Deactivating virtualenv"
deactivate

cd fastlane
