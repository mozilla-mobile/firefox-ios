#!/usr/bin/env sh
CARTHAGE_VERSION=$(carthage version)
if [[ $CARTHAGE_VERSION<0.11.0 ]]; then
	echo "Carthage requires upgrade"
	brew upgrade carthage
fi

if [[ ! -e "Carthage/Checkouts/google-breakpad-ios/Breakpad.xcodeproj" ]]; then 
	echo "Breakpad needs to be deleted" 
	rm -rf "Carthage/Checkouts/google-breakpad-ios"
fi