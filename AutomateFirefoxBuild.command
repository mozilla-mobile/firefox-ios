#!/bin/bash

echo -en '\033[1mWhich directory do you want to download to? -> \033[0m' 
read -r DESIRED_DIRECTORY
sudo xcode-select --install
sudo xcode-select -switch /Library/DeveloperCommandLineTools
brew update
brew install carthage node virtualenv
cd $DESIRED_DIRECTORY
git clone https://github.com/mozilla-mobile/firefox-ios
cd firefox-ios
sh ./bootstrap.sh
open -a Xcode Client.xcodeproj
