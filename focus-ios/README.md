# Focus iOS

This is the subdirectory that contains the Focus iOS application.

For details on compatible Xcode and Swift versions used to build this project, as well as the minimum iOS version, refer to the root [README](../README.md).

## Getting Involved

For information on how to contribute to this project, including communication channels, coding style, PR naming guidelines and more, visit the [Contribution guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md).

## Build Instructions

1. Install the version of [Xcode](https://developer.apple.com/download/applications/) from Apple that matches what this project uses, as listed in the root [README](../README.md).
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
