#!/usr/bin/env bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# USAGE: ./resigner.sh IPA_PATH PROFILES_DIR BUNDLE_ID TEAM_ID CERT_NAME

IPA=$1
PROFILES_DIR=$2
BUNDLE_ID=$3
TEAM_ID=$4
CERT_NAME=$5

UNZIPPED="temp_${IPA%.ipa}"
DEVELOPER_DIR=$(xcode-select -p)

# 1. 'Unzip' the .ipa file to get access to it's contents.
function unzip_ipa {
  unzip -q "$IPA" -d "$UNZIPPED"
}

# 2. Export the entitlements for each target into a .plist for later.
function export_entitlements {
  codesign -d --entitlements :- "$UNZIPPED/Payload/Client.app" > ClientEntitlements.plist
  codesign -d --entitlements :- "$UNZIPPED/Payload/Client.app/PlugIns/Today.appex" > TodayEntitlements.plist 
  codesign -d --entitlements :- "$UNZIPPED/Payload/Client.app/PlugIns/SendTo.appex" > SendToEntitlements.plist
  codesign -d --entitlements :- "$UNZIPPED/Payload/Client.app/PlugIns/ShareTo.appex" > ShareToEntitlements.plist
  codesign -d --entitlements :- "$UNZIPPED/Payload/Client.app/PlugIns/ViewLater.appex" > ViewLaterEntitlements.plist
}

# 3. Update the entitlements to use the new team/bundle identifiers.
function update_extension_entitlements {
  /usr/libexec/PlistBuddy -c "Set application-identifier $TEAM_ID.$BUNDLE_ID.$2" "$1"
  /usr/libexec/PlistBuddy -c "Set com.apple.developer.team-identifier $TEAM_ID" "$1"

  # Delete other groups and only be left with one
  /usr/libexec/PlistBuddy -c "Delete com.apple.security.application-groups:1" "$1"
  /usr/libexec/PlistBuddy -c "Delete com.apple.security.application-groups:1" "$1"

  /usr/libexec/PlistBuddy -c "Delete keychain-access-groups:1" "$1"
  /usr/libexec/PlistBuddy -c "Delete keychain-access-groups:1" "$1"

  /usr/libexec/PlistBuddy -c "Set com.apple.security.application-groups:0 group.$BUNDLE_ID" "$1"
  /usr/libexec/PlistBuddy -c "Set keychain-access-groups:0 $TEAM_ID.$BUNDLE_ID" "$1"
  /usr/libexec/PlistBuddy -c "Add beta-reports-active bool true" "$1"
}

function update_client_entitlements {
  /usr/libexec/PlistBuddy -c "Set application-identifier $TEAM_ID.$BUNDLE_ID" "$1"
  /usr/libexec/PlistBuddy -c "Set com.apple.developer.team-identifier $TEAM_ID" "$1"

  # Delete other groups and only be left with one
  /usr/libexec/PlistBuddy -c "Delete com.apple.security.application-groups:1" "$1"
  /usr/libexec/PlistBuddy -c "Delete com.apple.security.application-groups:1" "$1"

  /usr/libexec/PlistBuddy -c "Delete keychain-access-groups:1" "$1"
  /usr/libexec/PlistBuddy -c "Delete keychain-access-groups:1" "$1"

  /usr/libexec/PlistBuddy -c "Set com.apple.security.application-groups:0 group.$BUNDLE_ID" "$1"
  /usr/libexec/PlistBuddy -c "Set keychain-access-groups:0 $TEAM_ID.$BUNDLE_ID" "$1"

  /usr/libexec/PlistBuddy -c "Add beta-reports-active bool true" "$1"
}

# 4. Replace the bundle identifier in each Info.plist.
function replace_bundle_identifiers {
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" \
    "$UNZIPPED/Payload/Client.app/Info.plist"
  /usr/libexec/PlistBuddy -c "Set AppIdentifierPrefix $TEAM_ID" \
    "$UNZIPPED/Payload/Client.app/Info.plist"

  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID.Today" \
    "$UNZIPPED/Payload/Client.app/Plugins/Today.appex/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID.SendTo" \
    "$UNZIPPED/Payload/Client.app/Plugins/SendTo.appex/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID.ShareTo" \
    "$UNZIPPED/Payload/Client.app/Plugins/ShareTo.appex/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID.ViewLater" \
    "$UNZIPPED/Payload/Client.app/Plugins/ViewLater.appex/Info.plist"
}

# 5. Copy over the new provisioning profiles into each target.
function copy_profiles {
  cp "$PROFILES_DIR/Firefox_Beta_Distribution.mobileprovision" \
    "$UNZIPPED/Payload/Client.app/embedded.mobileprovision"
  cp "$PROFILES_DIR/Firefox_Beta_Today_Distribution.mobileprovision" \
    "$UNZIPPED/Payload/Client.app/Plugins/Today.appex/embedded.mobileprovision"
  cp "$PROFILES_DIR/Firefox_Beta_SendTo_Distribution.mobileprovision" \
    "$UNZIPPED/Payload/Client.app/Plugins/SendTo.appex/embedded.mobileprovision"
  cp "$PROFILES_DIR/Firefox_Beta_ShareTo_Distribution.mobileprovision" \
    "$UNZIPPED/Payload/Client.app/Plugins/ShareTo.appex/embedded.mobileprovision"
  cp "$PROFILES_DIR/Firefox_Beta_ViewLater_Distribution.mobileprovision" \
    "$UNZIPPED/Payload/Client.app/Plugins/ViewLater.appex/embedded.mobileprovision"
}

# 6. Resign each target from deepest in the folder hierarchy to most shallow.
function resign {
  codesign -f -s "$CERT_NAME" \
    --entitlements TodayEntitlements.plist \
    "$UNZIPPED/Payload/Client.app/PlugIns/Today.appex"

  codesign -f -s "$CERT_NAME" \
    --entitlements SendToEntitlements.plist \
    "$UNZIPPED/Payload/Client.app/PlugIns/SendTo.appex"

  codesign -f -s "$CERT_NAME" \
    --entitlements ShareToEntitlements.plist \
    "$UNZIPPED/Payload/Client.app/PlugIns/ShareTo.appex"

  codesign -f -s "$CERT_NAME" \
    --entitlements ViewLaterEntitlements.plist \
    "$UNZIPPED/Payload/Client.app/PlugIns/ViewLater.appex"

  codesign -f -s "$CERT_NAME" \
    --entitlements ClientEntitlements.plist \
    "$UNZIPPED/Payload/Client.app"
}

function resign_frameworks {
  find "$UNZIPPED/Payload/Client.app/Frameworks" -name '*.framework' -d 1 | while read -r line; do
    codesign -f -s "$CERT_NAME" \
      "$line"
  done
}

# 7. Copy over the libswift*.dylib libraries into the SwiftSupport library.
function copy_swift_support {
  mkdir -p "$UNZIPPED/SwiftSupport"
  find "$UNZIPPED/Payload/Client.app/Frameworks" -name 'libswift*.dylib' -exec basename {} \; | while read -r line; do
    echo "-- Copying over $line"
    cp "$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos/$line" "$UNZIPPED/SwiftSupport"
  done
}

# 8. Put it all back together into a new .ipa
function rezip_ipa {
  cd "$UNZIPPED" || exit
  zip -qr "../$IPA" .
  cd ..
}

# 9. Tidy up the temp files we created
function tidy_up {
  rm TodayEntitlements.plist
  rm SendToEntitlements.plist
  rm ShareToEntitlements.plist
  rm ViewLaterEntitlements.plist
  rm ClientEntitlements.plist
  rm -r "$UNZIPPED"
}

echo "Resigning $IPA using profiles from $PROFILES_DIR"
echo "================================================"
echo "> Unzipping IPA to ---> $UNZIPPED"
unzip_ipa

echo "> Exporting entitlements for all targets"
export_entitlements

echo "> Updating entitlements to use new team/bundle identifiers"
update_client_entitlements ClientEntitlements.plist
update_extension_entitlements TodayEntitlements.plist Today
update_extension_entitlements SendToEntitlements.plist SendTo
update_extension_entitlements ShareToEntitlements.plist ShareTo
update_extension_entitlements ViewLaterEntitlements.plist ViewLater

echo "> Update bundle identifiers in Info.plist files for all targets"
replace_bundle_identifiers

echo "> Copying over the new profiles into targets"
copy_profiles

echo "> Resigning each target and linked framework (deepest -> shallow-est in folder hierarchy)"
resign_frameworks
resign

echo "> Copying over libswift* libraries into SwiftSupport folder"
copy_swift_support

echo "> Putting together new, signed .ipa"
rezip_ipa

echo "> Tidying up.."
tidy_up

echo "DONE"


