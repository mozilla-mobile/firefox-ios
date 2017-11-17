#!/usr/bin/env bash

#
# Add our Adjust keys to the build depending on the scheme. We use the sandbox for beta so
# that we have some insight in beta usage.
#

if [ "$BUDDYBUILD_SCHEME" == "Focus (Enterprise)" ]; then
  echo "Setting Adjust token to SANDBOX for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set AppToken $ADJUST_TOKEN_RELEASE" "$BUDDYBUILD_WORKSPACE/Blockzilla/Adjust-Focus.plist"
elif [ "$BUDDYBUILD_SCHEME" == "Focus" ]; then
  echo "Setting Adjust token to RELEASE for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set AppToken $ADJUST_TOKEN_RELEASE" "$BUDDYBUILD_WORKSPACE/Blockzilla/Adjust-Focus.plist"
elif [ "$BUDDYBUILD_SCHEME" == "Klar" ]; then
  echo "Setting Adjust token to RELEASE for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set AppToken $ADJUST_TOKEN_RELEASE" "$BUDDYBUILD_WORKSPACE/Blockzilla/Adjust-Focus.plist"
fi

#
# Add our Sentry keys to the build depending on the scheme. We use the sandbox for beta so
# that we have some insight in beta usage.
#

if [ "$BUDDYBUILD_SCHEME" == "Focus (Enterprise)" ]; then
  echo "Setting Sentry DSN to BETA for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN_BETA" "Blockzilla/Info.plist"
elif [ "$BUDDYBUILD_SCHEME" == "Focus" ]; then
  echo "Setting Sentry DSN to PRODUCTION for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN_RELEASE" "Blockzilla/Info.plist"
elif [ "$BUDDYBUILD_SCHEME" == "Klar" ]; then
  echo "Setting Sentry DSN to PRODUCTION for $BUDDYBUILD_SCHEME"
  /usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN_RELEASE" "Blockzilla/Info.plist"
fi


# Set the build number to match the Buddybuild number
agvtool new-version -all "$BUDDYBUILD_BUILD_NUMBER"


# Set the build number to match the Buddybuild number
agvtool new-version -all "$BUDDYBUILD_BUILD_NUMBER"