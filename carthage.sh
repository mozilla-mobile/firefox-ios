#!/usr/bin/env sh
CARTHAGE_VERSION=$(carthage version)
if which carthage ==/dev/null || [[ $CARTHAGE_VERSION<0.11.0 || $CARTHAGE_VERSION>0.11.0 ]]; then
	echo "Installing Carthage 0.11"
	brew update
	brew install https://raw.githubusercontent.com/Homebrew/homebrew/09c09d73779d3854cd54206c41e38668cd4d2d0c/Library/Formula/carthage.rb
fi

if [[ ! -e "Carthage/Checkouts/google-breakpad-ios/Breakpad.xcodeproj" ]]; then 
	echo "Breakpad needs to be deleted" 
	rm -rf "Carthage/Checkouts/google-breakpad-ios"
fi
