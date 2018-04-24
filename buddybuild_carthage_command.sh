#!/bin/bash

echo "[Rome script] installing rome "
brew install blender/homebrew-tap/rome

mkdir -p ~/.aws
echo "[default]
region = us-west-2" > ~/.aws/config

echo "[Rome script] download missing frameworks"
rome download --platform iOS

echo "[Rome script] list what is missing and update/build if needed"
rome list --missing --platform ios | awk '{print $1}' | xargs carthage update --platform ios

echo "[Rome script] upload what is missing"
rome list --missing --platform ios | awk '{print $1}' | xargs rome upload --platform ios

echo "[Rome script] build Fuzi, it is exempt from Rome"
carthage update --platform ios Fuzi
