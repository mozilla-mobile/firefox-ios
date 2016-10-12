#!/usr/bin/env bash

# End script if one of the lines fails
set -e

# Go to root folder
cd ..

# Clean the folders
rm -rf Frameworks/Static
rm -rf Frameworks/Dynamic
rm -rf Frameworks/tvOS

# Create needed folders
mkdir -p Frameworks/Static
mkdir -p Frameworks/Dynamic
mkdir -p Frameworks/tvOS

# Build static AdjustSdk.framework
xcodebuild -target AdjustStatic -configuration Release clean build

# Build dynamic AdjustSdk.framework
xcodebuild -target AdjustSdk -configuration Release clean build

# Build tvOS AdjustSdkTV.framework
# Build it for simulator and device
xcodebuild -configuration Release -target AdjustSdkTv -arch x86_64 -sdk appletvsimulator clean build
xcodebuild -configuration Release -target AdjustSdkTv -arch arm64 -sdk appletvos clean build

# Copy tvOS framework to destination
cp -R build/Release-appletvos/AdjustSdkTv.framework Frameworks/tvOS

# Create universal tvOS framework
lipo -create -output Frameworks/tvOS/AdjustSdkTv.framework/AdjustSdkTv build/Release-appletvos/AdjustSdkTv.framework/AdjustSdkTv build/Release-appletvsimulator/AdjustSdkTv.framework/AdjustSdkTv

# Build Carthage AdjustSdk.framework
carthage build --no-skip-current

# Copy build Carthage framework to Frameworks folder
cp -R Carthage/Build/iOS/* Frameworks/Dynamic/

# Copy static framework into example iOS app
rm -rf examples/AdjustExample-iOS/AdjustExample-iOS/Adjust/AdjustSdk.framework
cp -R Frameworks/Static/AdjustSdk.framework examples/AdjustExample-iOS/AdjustExample-iOS/Adjust/

# Copy static framework into example Swift app
rm -rf examples/AdjustExample-Swift/AdjustExample-Swift/Adjust/AdjustSdk.framework
cp -R Frameworks/Static/AdjustSdk.framework examples/AdjustExample-Swift/AdjustExample-Swift/Adjust/

# Copy static framework into example WebView app
rm -rf examples/AdjustExample-WebView/AdjustExample-WebView/Adjust/AdjustSdk.framework
cp -R Frameworks/Static/AdjustSdk.framework examples/AdjustExample-WebView/AdjustExample-WebView/Adjust/

# Copy static framework into example iWatch app
rm -rf examples/AdjustExample-iWatch/AdjustExample-iWatch/Adjust/AdjustSdk.framework
cp -R Frameworks/Static/AdjustSdk.framework examples/AdjustExample-iWatch/AdjustExample-iWatch/Adjust/

# Copy static framework into example tvOS app
rm -rf examples/AdjustExample-tvOS/AdjustExample-tvOS/Adjust/AdjustSdkTv.framework
cp -R Frameworks/tvOS/AdjustSdkTv.framework examples/AdjustExample-tvOS/AdjustExample-tvOS/Adjust/
