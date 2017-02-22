#!/usr/bin/env bash

brew upgrade swiftlint

# Install tooling for Badging
brew update && brew install imagemagick
echo password | sudo -S gem install badge

# Install Python tooling for localizations scripts
echo password | sudo -S pip install --upgrade pip
echo password | sudo -S pip install virtualenv

# Add badge to app icon
badge --no_badge --shield_no_resize --shield "7.0-Build%2024-blue"

# Localize the app
./scripts/import-locales.sh





