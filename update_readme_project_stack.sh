# This script updates the README file with updated Xcode, Swift, and
# iOS deployment target badges. It extracts relevant project
# information from Xcode project files, Bitrise configurations, and
# Swift package manager files.
# The script is designed to be run within a Github action.

function deployment_target() {
    PROJECT_FILE=$1
    echo $(grep -o 'IPHONEOS_DEPLOYMENT_TARGET = [0-9]*.[0-9]*;' "$PROJECT_FILE" | head -1 | cut -d'=' -f2 | tr -d ' ;')
}

function build_sed_string() {
    ICON=$1
    VERSION=$2
    BADGE=$3
    echo "!\[$ICON $VERSION\]($BADGE)"
}

function badge() {
    APP=$1
    VERSION=$2
    COLOR=$3
    LOGO=$4
    echo "https:\/\/img.shields.io\/badge\/$APP-$VERSION-$COLOR\?logo=$LOGO\&logoColor=white"
}

function sed_into_readme() {
    APP=$1
    DEPLOYMENT_TARGET=$2
    VERSION_GREP="[0-9.].*"
    XCODE_GREP=$(build_sed_string Xcode $VERSION_GREP $(badge Xcode $VERSION_GREP "blue" "Xcode"))
    SWIFT_GREP=$(build_sed_string Swift $VERSION_GREP $(badge Swift $VERSION_GREP "red" "Swift"))
    TARGET_GREP=$(build_sed_string iOS "$VERSION_GREP+" $(badge iOS "$VERSION_GREP+" "green" "apple"))

    XCODE=$(build_sed_string Xcode $XCODE_VERSION $(badge Xcode $XCODE_VERSION "blue" "Xcode"))
    SWIFT=$(build_sed_string Swift $SWIFT_VERSION $(badge Swift $SWIFT_VERSION "red" "Swift"))
    TARGET=$(build_sed_string iOS "$DEPLOYMENT_TARGET+" $(badge iOS "$DEPLOYMENT_TARGET+" "green" "apple"))

    echo "s/$APP\*\*\| $XCODE_GREP \| $SWIFT_GREP \| $TARGET_GREP/$APP\*\*\| $XCODE \| $SWIFT \| $TARGET/"
    sed -i "" "s/$APP\*\*\| $XCODE_GREP \| $SWIFT_GREP \| $TARGET_GREP/$APP\*\*\| $XCODE \| $SWIFT \| $TARGET/" $README_FILE
}

PROJECT_FIREFOX_FILE="firefox-ios/Client.xcodeproj/project.pbxproj"
PROJECT_FOCUS_FILE="focus-ios/Blockzilla.xcodeproj/project.pbxproj"
BIT_RISE_FILE="bitrise.yml"
XCODE_VERSION=$(grep "stack:" $BIT_RISE_FILE | head -n 1 | grep -o '\d\d.\d')
DEPLOYMENT_TARGET_FIREFOX=$(deployment_target $PROJECT_FIREFOX_FILE)
DEPLOYMENT_TARGET_FOCUS=$(deployment_target $PROJECT_FOCUS_FILE)
README_FILE="README.md"
BROWSER_KIT_SWIFT_PACKAGE_FILE="BrowserKit/Package.swift"
SWIFT_VERSION=$(head -n 1 $BROWSER_KIT_SWIFT_PACKAGE_FILE | grep -o '\d.\d')

sed_into_readme "Firefox-iOS" $DEPLOYMENT_TARGET_FIREFOX
sed_into_readme "Focus-iOS" $DEPLOYMENT_TARGET_FOCUS