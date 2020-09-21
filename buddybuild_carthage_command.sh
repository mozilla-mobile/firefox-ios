#!/bin/bash
# use 0.34.0 because of cross-volume bug with 0.35.0 on BuddyBuild
brew uninstall carthage
wget https://github.com/Carthage/Carthage/releases/download/0.34.0/Carthage.pkg
installer -pkg Carthage.pkg -target CurrentUserHomeDirectory
cd /usr/local/bin && ln -s ~/usr/local/bin/carthage .
cd -

carthage version
./carthage_command.sh
