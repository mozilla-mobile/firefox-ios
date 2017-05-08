#!/usr/bin/env bash

# Add our Adjust keys to the build depending on the scheme
if [ "$BUDDYBUILD_SCHEME" == FirefoxBeta ]; then
  echo "Setting Adjust environment to SANDBOX for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set AdjustAppToken $ADJUST_KEY_SANDBOX" "Client/Info.plist"
  /usr/libexec/PlistBuddy -c "Set AdjustEnvironment sandbox" "Client/Info.plist"
elif [ "$BUDDYBUILD_SCHEME" == Firefox ]; then
  echo "Setting Adjust environment to PRODUCTION for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set AdjustAppToken $ADJUST_KEY_PRODUCTION" "Client/Info.plist"
  /usr/libexec/PlistBuddy -c "Set AdjustEnvironment production" "Client/Info.plist"
fi

echo "Setting Sentry DSN to $SENTRY_DSN"
/usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN" "Client/Info.plist"

# Set the build number to match the Buddybuild number
agvtool new-version -all "$BUDDYBUILD_BUILD_NUMBER"
