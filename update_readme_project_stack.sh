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
    COLOR=$3
    LOGO=$4
    APP=$5
    echo "<img src=\"https:\/\/img.shields.io\/badge\/$ICON-$VERSION-$COLOR\?logo=$LOGO\&logoColor=white\" alt=\"$APP\"><\/td>"
}

function sed_into_readme() {
    APP=$1
    DEPLOYMENT_TARGET=$2
    VERSION_GREP="[0-9.].*"
    XCODE_GREP=$(build_sed_string "Xcode" $VERSION_GREP "blue" "Xcode" $APP)
    XCODE=$(build_sed_string "Xcode" $XCODE_VERSION "blue" "Xcode" $APP)
    SWIFT_GREP=$(build_sed_string "Swift" $VERSION_GREP "red" "Swift" $APP)
    SWIFT=$(build_sed_string "Swift" $SWIFT_VERSION "red" "Swift" $APP)
    IOS_GREP=$(build_sed_string "iOS" "$VERSION_GREP+" "green" "apple" $APP)
    IOS=$(build_sed_string "iOS" "$DEPLOYMENT_TARGET+" "green" "apple" $APP)

    sed -i "" "s/$XCODE_GREP/$XCODE/" $README_FILE
    sed -i "" "s/$SWIFT_GREP/$SWIFT/" $README_FILE
    sed -i "" "s/$IOS_GREP/$IOS/" $README_FILE
}

PROJECT_FIREFOX_FILE="firefox-ios/Client.xcodeproj/project.pbxproj"
PROJECT_FOCUS_FILE="focus-ios/Blockzilla.xcodeproj/project.pbxproj"
BIT_RISE_FILE="bitrise.yml"
# Grepping the tail of Bitrise file since contains the correct Xcode version
XCODE_VERSION=$(grep "stack:" $BIT_RISE_FILE | tail -n 1 | grep -o '\d\d.\d')
DEPLOYMENT_TARGET_FIREFOX=$(deployment_target $PROJECT_FIREFOX_FILE)
DEPLOYMENT_TARGET_FOCUS=$(deployment_target $PROJECT_FOCUS_FILE)
README_FILE="README.md"
BROWSER_KIT_SWIFT_PACKAGE_FILE="BrowserKit/Package.swift"
SWIFT_VERSION=$(head -n 1 $BROWSER_KIT_SWIFT_PACKAGE_FILE | grep -o '\d.\d')

sed_into_readme "Firefox-iOS" $DEPLOYMENT_TARGET_FIREFOX
sed_into_readme "Focus-iOS" $DEPLOYMENT_TARGET_FOCUS