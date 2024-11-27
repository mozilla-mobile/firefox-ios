# Focus iOS

This is the subdirectory that contains the Focus iOS application.

_Browse like no one’s watching. The new Firefox Focus automatically blocks a wide range of online trackers — from the moment you launch it to the second you leave it. Easily erase your history, passwords and cookies, so you won’t get followed by things like unwanted ads._

Download on the [App Store](https://itunes.apple.com/app/id1055677337).

## Main Branch

This branch works with Xcode 16.1 and supports iOS 15.0 and newer.

Pull requests should be submitted with `main` as the base branch.

## Getting Involved

See readme at the root of the project for [the guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/README.md) on how to contribute to this project.

## Build Instructions

1. Install Xcode 15.3 [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
2. Clone the repository:

  ```shell
  git clone https://github.com/mozilla-mobile/firefox-ios.git
  ```

3. Pull in the project dependencies:

  ```shell
  cd firefox-ios
  ./checkout.sh
  ```

4. Open `Blockzilla.xcodeproj` in Xcode.
5. Build the `Focus` scheme in Xcode.