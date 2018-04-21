#!/bin/bash

brew install blender/homebrew-tap/rome

mkdir -p ~/.aws
echo "[default]
region = us-west-2" > ~/.aws/config

# download missing frameworks
rome download --platform iOS

# list what is missing and update/build if needed
rome list --missing --platform ios | awk '{print $1}' | xargs carthage update --platform ios

# upload what is missing
rome list --missing --platform ios | awk '{print $1}' | xargs rome upload --platform ios

