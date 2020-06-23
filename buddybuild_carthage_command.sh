#!/bin/bash
#carthage bootstrap $CARTHAGE_VERBOSE --platform ios --color auto --cache-builds

# Workaround to Carthage issue with latest version 0.35.0
# https://github.com/Carthage/Carthage/issues/3003
brew uninstall --force carthage
brew install https://github.com/Homebrew/homebrew-core/raw/09ceff6c1de7ebbfedb42c0941a48bfdca932c0f/Formula/carthage.rb

carthage version

brew tap tmspzz/tap https://github.com/tmspzz/homebrew-tap.git
brew install tmspzz/homebrew-tap/rome
rome download --platform iOS | grep -v 'specified key' | grep -v 'in local cache' 
rome list --missing --platform iOS | awk '{print $1}' | xargs -I {} carthage bootstrap "{}" $CARTHAGE_VERBOSE --platform iOS
carthage checkout shavar-prod-lists

