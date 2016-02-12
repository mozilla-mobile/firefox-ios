#!/usr/bin/env sh
CARTHAGE_VERSION=$(carthage version)
if which carthage ==/dev/null || [[ $CARTHAGE_VERSION<0.11.0 || $CARTHAGE_VERSION>0.11.0 ]]; then
	echo "Installing Carthage 0.11"
	brew update
	brew install https://github.com/Carthage/Carthage/releases/tag/0.11
fi

if [[ ! -e "Carthage/Checkouts/google-breakpad-ios/Breakpad.xcodeproj" ]]; then 
	echo "Breakpad needs to be deleted" 
	rm -rf "Carthage/Checkouts/google-breakpad-ios"
fi