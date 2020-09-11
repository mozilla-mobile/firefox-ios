#!/bin/bash
#carthage bootstrap $CARTHAGE_VERBOSE --platform ios --color auto --cache-builds

# Workaround to Carthage issue with latest version 0.35.0
# https://github.com/Carthage/Carthage/issues/3003
brew uninstall --force carthage
# use 0.34.0 because of cross-volume bug with 0.35.0 on BuddyBuild
wget https://github.com/Carthage/Carthage/releases/download/0.34.0/Carthage.pkg
installer -pkg Carthage.pkg -target CurrentUserHomeDirectory
cd /usr/local/bin && ln -s ~/usr/local/bin/carthage .
cd -

carthage version

carthage bootstrap $CARTHAGE_VERBOSE --platform ios
