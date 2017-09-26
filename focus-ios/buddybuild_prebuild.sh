#!/usr/bin/env bash

# This script inserts the private Adjust tokens into the two property lists that
# contain the Adjust settings for both Focus and Klar. It depends on two environment
# variables to be set in BuddyBuild: ADJUST_TOKEN_FOCUS and ADJUST_TOKEN_KLAR.

if [ -f "$BUDDYBUILD_WORKSPACE/Blockzilla/Adjust-Focus.plist" ]; then
    /usr/libexec/PlistBuddy -c "Set AppToken $ADJUST_TOKEN_FOCUS" "$BUDDYBUILD_WORKSPACE/Blockzilla/Adjust-Focus.plist"
fi

if [ -f "$BUDDYBUILD_WORKSPACE/Blockzilla/Adjust-Klar.plist" ]; then
    /usr/libexec/PlistBuddy -c "Set AppToken $ADJUST_TOKEN_KLAR" "$BUDDYBUILD_WORKSPACE/Blockzilla/Adjust-Klar.plist"
fi

# Add Sentry DSN to Info.plist
/usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN_BETA" "Blockzilla/Info.plist"

# Set the build number to match the Buddybuild number
agvtool new-version -all "$BUDDYBUILD_BUILD_NUMBER"
