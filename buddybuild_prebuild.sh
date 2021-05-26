#!/usr/bin/env bash

bundle install

echo "Setting up Pocket Stories API Key"
if [ "$BUDDYBUILD_SCHEME" == Firefox ]; then
  /usr/libexec/PlistBuddy -c "Set PocketEnvironmentAPIKey $POCKET_PRODUCTION_API_KEY" "Client/Info.plist"
else
  /usr/libexec/PlistBuddy -c "Set PocketEnvironmentAPIKey $POCKET_STAGING_API_KEY" "Client/Info.plist"
fi

#
# Set the build number to match the Buddybuild number
#

agvtool new-version -all "$BUDDYBUILD_BUILD_NUMBER"
