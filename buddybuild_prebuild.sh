#!/usr/bin/env bash

bundle install
#
# Leanplum is included only for the Firefox and FirefoxBeta builds.
#

if [ "$BUDDYBUILD_SCHEME" = "Firefox" ] || [ "$BUDDYBUILD_SCHEME" = "FirefoxBeta" ]; then
  echo "Setting Leanplum environment to PRODUCTION for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set LeanplumAppId $LEANPLUM_APP_ID" "Client/Info.plist"
  /usr/libexec/PlistBuddy -c "Set LeanplumProductionKey $LEANPLUM_KEY_PRODUCTION" "Client/Info.plist"
  /usr/libexec/PlistBuddy -c "Set LeanplumDevelopmentKey $LEANPLUM_KEY_DEVELOPMENT" "Client/Info.plist"
fi

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
