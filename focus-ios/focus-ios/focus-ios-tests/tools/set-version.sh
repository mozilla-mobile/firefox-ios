#!/bin/sh

if [ $# -eq 0 ]; then
  echo "usage: set-version.sh <version-number>"
  exit 1
fi


for plist in Blockzilla/Info.plist ContentBlocker/Info.plist FocusIntentExtension/Info.plist OpenInFocus/Info.plist Widgets/Info.plist; do
  current=`/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist"`
  echo "Changing CFBundleShortVersionString in $plist from $current to $1"
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $1" "$plist"
done


