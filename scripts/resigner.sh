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
IS_BETA=$6

UNZIPPED="temp_${IPA%.ipa}"
DEVELOPER_DIR=$(xcode-select -p)

EXTENSIONS=(Today ViewLater SendTo ShareTo)

# 1. 'Unzip' the .ipa file to get access to it's contents.
function unzip_ipa {
  unzip -q "$IPA" -d "$UNZIPPED"
}

# 2. Export the entitlements for each target into a .plist for later.
function export_entitlements {
  codesign -d --entitlements :- "$UNZIPPED/Payload/Client.app" > ClientEntitlements.plist

  for EXTEN in "${EXTENSIONS[@]}"; do
    codesign -d --entitlements :- "$UNZIPPED/Payload/Client.app/PlugIns/$EXTEN.appex" > "${EXTEN}Entitlements.plist"
  done
}

# 3. Update the entitlements to use the new team/bundle identifiers.
function update_app_security_groups {
  # Clear out the app groups and security groups and set them to only the given identifier.
  /usr/libexec/PlistBuddy -c "Delete com.apple.security.application-groups" "$1"
  /usr/libexec/PlistBuddy -c "Delete keychain-access-groups" "$1"

  /usr/libexec/PlistBuddy -c "Add com.apple.security.application-groups array" "$1"
  /usr/libexec/PlistBuddy -c "Add com.apple.security.application-groups: string group.$BUNDLE_ID" "$1"

  /usr/libexec/PlistBuddy -c "Add keychain-access-groups array" "$1"
  /usr/libexec/PlistBuddy -c "Add keychain-access-groups: string $TEAM_ID.$BUNDLE_ID" "$1"
}

function update_extension_entitlements {
  /usr/libexec/PlistBuddy -c "Set application-identifier $TEAM_ID.$BUNDLE_ID.$2" "$1"
  /usr/libexec/PlistBuddy -c "Set com.apple.developer.team-identifier $TEAM_ID" "$1"

  update_app_security_groups "$1"

  /usr/libexec/PlistBuddy -c "Add beta-reports-active bool true" "$1"
}

function update_client_entitlements {
  /usr/libexec/PlistBuddy -c "Set application-identifier $TEAM_ID.$BUNDLE_ID" "$1"
  /usr/libexec/PlistBuddy -c "Set com.apple.developer.team-identifier $TEAM_ID" "$1"

  update_app_security_groups "$1"

  /usr/libexec/PlistBuddy -c "Add beta-reports-active bool true" "$1"
}

# 4. Replace the bundle identifier in each Info.plist.
function replace_bundle_identifiers {
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $1" "$2"
  /usr/libexec/PlistBuddy -c "Set AppIdentifierPrefix $TEAM_ID" "$2"
}

function replace_shortcut_items {
 /usr/libexec/PlistBuddy -c "Set :UIApplicationShortcutItems:0:UIApplicationShortcutItemType ${1}.NewTab" $2
 /usr/libexec/PlistBuddy -c "Set :UIApplicationShortcutItems:1:UIApplicationShortcutItemType ${1}.NewPrivateTab" $2
}

# 5. Copy over the new provisioning profiles into each target.
function copy_beta_profiles {
  cp "$PROFILES_DIR/Firefox_Beta_Distribution.mobileprovision" \
    "$UNZIPPED/Payload/Client.app/embedded.mobileprovision"

  for EXTEN in "${EXTENSIONS[@]}"; do
    cp "$PROFILES_DIR/Firefox_Beta_${EXTEN}_Distribution.mobileprovision" \
      "$UNZIPPED/Payload/Client.app/Plugins/${EXTEN}.appex/embedded.mobileprovision"
  done
}

function copy_production_profiles {
  cp "$PROFILES_DIR/Firefox_Distribution.mobileprovision" \
    "$UNZIPPED/Payload/Client.app/embedded.mobileprovision"

  for EXTEN in "${EXTENSIONS[@]}"; do
    cp "$PROFILES_DIR/Firefox_${EXTEN}_Distribution.mobileprovision" \
      "$UNZIPPED/Payload/Client.app/Plugins/${EXTEN}.appex/embedded.mobileprovision"
  done
}

# 6. Resign each target from deepest in the folder hierarchy to most shallow.
function resign {
  for EXTEN in "${EXTENSIONS[@]}"; do
    codesign -f -s "$CERT_NAME" \
      --entitlements "${EXTEN}Entitlements.plist" \
      "$UNZIPPED/Payload/Client.app/PlugIns/$EXTEN.appex"
  done

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
  for EXTEN in "${EXTENSIONS[@]}"; do
    rm "${EXTEN}Entitlements.plist"
  done
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

for EXTEN in "${EXTENSIONS[@]}"; do
  update_extension_entitlements "${EXTEN}Entitlements.plist" "$EXTEN" 
done

echo "> Update bundle identifiers in Info.plist files for all targets"
replace_bundle_identifiers "$BUNDLE_ID" "$UNZIPPED/Payload/Client.app/Info.plist"

echo "> Update UIApplicationShortcutItems in Info.plist"
replace_shortcut_items "$BUNDLE_ID" "$UNZIPPED/Payload/Client.app/Info.plist"

for EXTEN in "${EXTENSIONS[@]}"; do
  replace_bundle_identifiers "$BUNDLE_ID.$EXTEN" "$UNZIPPED/Payload/Client.app/Plugins/$EXTEN.appex/Info.plist"
done

echo "> Copying over the new profiles into targets"
if [ "$IS_BETA" = "true" ]; then
  copy_beta_profiles
else 
  copy_production_profiles
fi

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


