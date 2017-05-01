#! /usr/bin/env bash

#
# Assumes the following is installed:
#
#  git
#  brew
#  python via brew
#  virtualenv via pip in brew
#
# Call as ./export-locale.sh clean to remove an existing virtual env
#
# We can probably check all that for the sake of running this hands-free
# in an automated manner.
#

clean_run=false
if [ $# -gt 0 ]
then
    if [ "$1" == "clean" ]
    then
        clean_run=true
    else
        echo "Unknown parameter: $1"
        exit 1
    fi
fi

if [ ! -d Client.xcodeproj ]
then
  echo "Please run this from the project root that contains Client.xcodeproj"
  exit 1
fi

if [ -d firefox-ios-l10n ]
then
  echo "There already is a firefox-ios-l10n checkout. Aborting to let you decide what to do."
  exit 1
fi

SDK_PATH=`xcrun --show-sdk-path`

# If the virtualenv with the Python modules that we need doesn't exist,
# or a clean run was requested, create the virtualenv.
if [ ! -d export-locales-env ] || [ "${clean_run}" = true ]
then
    rm -rf export-locales-env || exit 1
    echo "Setting up new virtualenv..."
    virtualenv export-locales-env --python=python2.7 || exit 1
    source export-locales-env/bin/activate || exit 1
    # install libxml2
    CFLAGS=-I"$SDK_PATH/usr/include/libxml2" LIBXML2_VERSION=2.9.2 pip install lxml || exit 1
else
    echo "Reusing existing virtualenv found in export-locales-env"
fi

# Check out a clean copy of the l10n repo
git clone https://github.com/mozilla-l10n/firefoxios-l10n firefox-ios-l10n || exit 1

# Export English base to /tmp/en.xliff
rm -f /tmp/en.xliff || exit 1
xcodebuild -exportLocalizations -localizationPath /tmp -project Client.xcodeproj -exportLanguage en || exit 1

if [ ! -f /tmp/en.xliff ]
then
  echo "Export failed. No /tmp/en.xliff generated."
  exit 1
fi

# Create a branch in the repository
cd firefox-ios-l10n
branch_name=$(date +"%Y%m%d_%H%M")
git branch ${branch_name}
git checkout ${branch_name}

# Copy the English XLIFF file into the repository and commit
cp /tmp/en.xliff en-US/firefox-ios.xliff || exit 1
git add en-US/firefox-ios.xliff
git commit -m "en-US: update firefox-ios.xliff"

# Update all locales
../../firefox-ios-build-tools/scripts/update-xliff.py . firefox-ios.xliff || exit 1

# Commit each locale separately
locale_list=$(find . -mindepth 1 -maxdepth 1 -type d  \( ! -iname ".*" \) | sed 's|^\./||g' | sort)
for locale in ${locale_list};
do
    # Exclude en-US and templates
    if [ "${locale}" != "en-US" ] && [ "${locale}" != "templates" ]
    then
        git add ${locale}/firefox-ios.xliff
        git commit -m "${locale}: Update firefox-ios.xliff"
    fi
done

# Copy the en-US file in /templates
cp en-US/firefox-ios.xliff templates/firefox-ios.xliff || exit 1
# Clean up /templates removing target-language and translations
../../firefox-ios-build-tools/scripts/clean-xliff.py templates || exit 1
git add templates/firefox-ios.xliff
git commit -m "templates: update firefox-ios.xliff"

echo
echo "NOTE"
echo "NOTE Use the following command to push the branch to Github where"
echo "NOTE you can create a Pull Request:"
echo "NOTE"
echo "NOTE   cd firefox-ios-l10n"
echo "NOTE   git push --set-upstream origin $branch_name"
echo "NOTE"
echo
