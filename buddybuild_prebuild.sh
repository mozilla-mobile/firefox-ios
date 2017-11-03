#!/usr/bin/env bash

chruby 2.3.1
bundle install  
bundle exec danger --fail-on-errors=false  

#
# Add our Adjust keys to the build depending on the scheme. We use the sandbox for beta so
# that we have some insight in beta usage.
#

if [ "$BUDDYBUILD_SCHEME" == FirefoxBeta ]; then
  echo "Setting Adjust environment to SANDBOX for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set AdjustAppToken $ADJUST_KEY_BETA" "Client/Info.plist"
  /usr/libexec/PlistBuddy -c "Set AdjustEnvironment production" "Client/Info.plist"
elif [ "$BUDDYBUILD_SCHEME" == Firefox ]; then
  echo "Setting Adjust environment to PRODUCTION for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set AdjustAppToken $ADJUST_KEY_PRODUCTION" "Client/Info.plist"
  /usr/libexec/PlistBuddy -c "Set AdjustEnvironment production" "Client/Info.plist"
fi

#
# Enable File Sharing on all builds except release
#

if [ "$BUDDYBUILD_SCHEME" != "Firefox" ]; then
  /usr/libexec/PlistBuddy -c "Add UIFileSharingEnabled bool true" "Client/Info.plist"
fi

#
# Leanplum is included only for the Firefox and FirefoxBeta builds.
#

if [ "$BUDDYBUILD_SCHEME" = "Firefox" ] || [ "$BUDDYBUILD_SCHEME" = "FirefoxBeta" ]; then
  echo "Setting Leanplum environment to PRODUCTION for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set LeanplumAppId $LEANPLUM_APP_ID" "Client/Info.plist"
  /usr/libexec/PlistBuddy -c "Set LeanplumEnvironment production" "Client/Info.plist"
  /usr/libexec/PlistBuddy -c "Set LeanplumKey $LEANPLUM_KEY_PRODUCTION" "Client/Info.plist"
fi

echo "Setting up Pocket Stories API Key"
if [ "$BUDDYBUILD_SCHEME" == Firefox ]; then
  /usr/libexec/PlistBuddy -c "Set PocketEnvironmentAPIKey $POCKET_PRODUCTION_API_KEY" "Client/Info.plist"
else
  /usr/libexec/PlistBuddy -c "Set PocketEnvironmentAPIKey $POCKET_STAGING_API_KEY" "Client/Info.plist"
fi

#
# Setup Sentry. We have different DSNs for Beta and Production.
#

if [ "$BUDDYBUILD_SCHEME" == FirefoxBeta ]; then
  echo "Setting SentryDSN to $SENTRY_DSN_BETA"
  /usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN_BETA" "Client/Info.plist"
elif [ "$BUDDYBUILD_SCHEME" == Firefox ]; then
  echo "Setting SentryDSN to $SENTRY_DSN_RELEASE"
  /usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN_RELEASE" "Client/Info.plist"
fi

#
# Set the build number to match the Buddybuild number
#

agvtool new-version -all "$BUDDYBUILD_BUILD_NUMBER"

