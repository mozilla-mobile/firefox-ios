# Focus iOS

This is the subdirectory that contains the Focus iOS application.

> Browse like no one’s watching. The new Firefox Focus automatically blocks a wide range of online trackers — from the moment you launch it to the second you leave it. Easily erase your history, passwords and cookies, so you won’t get followed by things like unwanted ads.
> [Download on the App Store](https://itunes.apple.com/app/id1055677337).

For versions of Xcode and Swift this branch of Focus iOS works with, and the minimum iOS supported version, see [readme](../README.md) at the root of the project.

## Getting Involved

For information about participation, communication channels, instructions how to run on devices using free personal developer accounts, coding standards or PR rules, see the [guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md) on how to contribute to this project.

## Build Instructions

1. Install the version of [Xcode](https://developer.apple.com/download/applications/) from Apple that matches what this project uses, as listed in the [table](../README.md) at repository root.
1. Clone the repository:
   ```shell
   git clone https://github.com/mozilla-mobile/firefox-ios.git
   ```
1. Change directories to the project root:
    ```shell
    cd firefox-ios
    ```
1. Pull in the project dependencies:
   ```shell
   ./checkout.sh
   ```
1. Open `Blockzilla.xcodeproj` under the `focus-ios` folder in Xcode.
1. Build the `Focus` scheme in Xcode.
