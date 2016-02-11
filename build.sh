#!/bin/sh

#
# Configuration
#
while [[ $# > 1 ]]
do
key="$1"
counter=$((counter+1))
echo $counter

case $key in
    -b|--branch)
    BRANCH="$2"
    shift # past argument
    ;;
    -c|--createbranch)
    BUILD_BRANCH="$2"
    shift # past argument
    ;;
    -n|--buildnumber)
    export BUILD_NUMBER="$2"
    shift # past argument
    ;;
    -v|--version)
    export APP_VERSION="$2"
    shift # past argument
    ;;
    l10n|aurora|beta|release)
    export BUILD_FLAVOUR=$key
    ;;
    *)
        echo "Unknown Option $key"    # unknown option
    ;;
esac
shift # past argument or value
done

echo BUILD_FLAVOUR = "${BUILD_FLAVOUR}"

DATESTAMP=`date '+%Y%m%d%H%M'`
export DATESTAMP=DATESTAMP

# Where to fetch the code
REPO=https://github.com/mozilla/firefox-ios.git

# Build ID - TODO Should be auto generated or come from the xcconfig file
BUILD_ID="$BUILD_FLAVOUR-build-$DATESTAMP"

if [ $BUILD_FLAVOUR == "aurora" ]; then
	echo "Aurora builds are not yet covered by this script"
	exit 1
elif [ $BUILD_FLAVOUR == "beta" ]; then
	echo "Beta builds are not yet covered by this script"
	exit 1
elif [ $BUILD_FLAVOUR == "release" ]; then
	echo "Release builds are not yet covered by this script"
	exit 1
fi

REPO_NAME="firefox-ios-$build_type"


# checkout $BRANCH
if [ -d $BRANCH && $BRANCH != "master" ]; then
	echo "Checking out $BRANCH"
	git checkout $BRANCH || exit 1
fi

#
# Checkout our Carthage dependencies
#
echo "Updating Carthage dependencies"
./checkout.sh || exit 1

# if $BUILD_BRANCH if specified, checkout or create
# if no build branch specified, make one up and check it out
# we have to ensure that we never build directly off master
if [ -d $BUILD_BRANCH && $BUILD_BRANCH != "master" ]; then
	git checkout $BUILD_BRANCH || git checkout -t -b $BUILD_BRANCH || exit 1
else
	BUILD_BRANCH=$BUILD_ID
	git checkout $BUILD_BRANCH || git checkout -t -b $BUILD_BRANCH || exit 1
fi

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
scripts/import-locales.sh || exit 1

echo "Deactivating virtualenv"
deactivate

#
# Create builds directory if not already present
#
if [ ! -d builds ]; then
	mkdir builds || exit 1
fi

#
# Create provisioning profile directory if not already present
#
if [ ! -d provisioning-profiles ]; then
	mkdir provisioning-profiles || exit 1
fi

#
# if we are doing a release or l10n build then make a folder for storing screenshots
#
if [ $BUILD_FLAVOUR == "l10n" || $BUILD_FLAVOUR == "release" ]; then
	if [! -d screenshots ]; then
		mkdir screenshots || exit 1
	fi
fi

# run fastlane
fastlane $BUILD_FLAVOUR || exit 1