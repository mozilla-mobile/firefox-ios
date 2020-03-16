# Building Application Services

## Introduction

First of all, let us remind the reader that were are not dealing with a classic Rust project where you can run `cargo build` and you are ready to go. Sorry.  
In fact, the project involves multiple build systems: `autoconf` for dependencies such as NSS or SQLCipher, `cargo` for the Rust common code, then either `gradle` (Android) or `XCode` (iOS) for the platform-specific wrappers.
The guide will make sure your system is configured appropriately to run these build systems without issues.

## Rust-only (desktop) development

This part assumes you are not interested in building the Android or iOS wrappers and only want to do rust development/run tests.  
The following command will ensure your environment variables are set properly and build the dependencies needed by the project:

```
./libs/verify-desktop-environment.sh
```

You can then run the Rust tests using:

```
cargo test
```

## Android development

Roughly you need Java 8, the Android SDK, the NDK R20 and a bunch of environment variables.  
Your best friend is the following command:

```
./libs/verify-android-environment.sh
````

This script has built-in and helpful messages to ensure you will be able to compile for Android properly.
We also have a deprecated detailed Android build guide in [setup-android-build-environment.md](howtos/setup-android-build-environment.md).

You can try building using:

```
./gradlew assembleDebug
```

## iOS development

You will need Carthage, swift-protobuf and xcpretty.
The following command will ensure your environment is ready to build the project for iOS:

```
./libs/verify-ios-environment.sh
````

The Xcode project is located at `megazords/ios/MozillaAppServices.xcodeproj`.
