# Firefox for iOS and Focus iOS

Download [Firefox iOS](https://apps.apple.com/app/firefox-web-browser/id989804926) and [Focus iOS](https://itunes.apple.com/app/id1055677337) on the App Store.

<table>
  <tr>
    <th style="border: none;"><strong>Firefox iOS</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-26.2-blue?logo=Xcode&logoColor=white" alt="Firefox-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-6.2-red?logo=Swift&logoColor=white" alt="Firefox-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-15.0+-green?logo=apple&logoColor=white" alt="Firefox-iOS"></td>
  </tr>
  <tr>
    <th style="border: none;"><strong>Focus iOS</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-26.2-blue?logo=Xcode&logoColor=white" alt="Focus-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-6.2-red?logo=Swift&logoColor=white" alt="Focus-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-15.0+-green?logo=apple&logoColor=white" alt="Focus-iOS"></td>
  </tr>
</table>

## Building the code

This is a monolithic-repository, containing both the Firefox and Focus iOS projects.

As this is an iOS project, it is required to have Xcode on your system, and you should check that `xcode-select -p` points to `/Applications/Xcode.app/Contents/Developer` (or however you've named your `Xcode.app`).

### Automatic Installation

The recommended way of setting up the repo is through the [fxios](https://github.com/mozilla-mobile/fxios-ctl) tool. This tool provides multiple helpful commands to help manage the repo. Check out its documentation, or the repo, if you'd like to find out more. Setup allows cloning from an https or an ssh url.

Note that, if you're using a fork, you'll have to use the `--with-fork <fork-url>` option. This will set your fork as `origin` and the main firefox-ios repo as `upstream`. `fork-url` can be either the ssh or the https version.

```bash
brew tap mozilla-mobile/fxios
brew install fxios

# Installing from the main repo
# You must specific if you want the https or ssh version of the mozilla-mobile repo
fxios setup --https # this will both download the repo & bootstrap both projects

# Installing with a fork workflow
fxios setup --ssh --with-fork <fork-url>
```

For more options for setup, please run `fxios setup --help`.
Please note, this is a decently sized repo, so downloading might take a while depending on your connection.

#### Firefox Instructions

1. Open the `Client.xcodeproj`, under the `firefox-ios/firefox-ios` folder, in Xcode.
1. Make sure to select the `Fennec` scheme in Xcode.

⚠️ Important: In case you have dependencies issues with SPM, please try the following:

    Xcode -> File -> Packages -> Reset Package Caches

#### Focus Instructions

1. Open `Blockzilla.xcodeproj`, under the `firefox-ios/focus-ios` folder, in Xcode.
1. Build the `Focus` scheme in Xcode.

### Manual Installation

1. Clone the repo locally
1. For their related build instructions, please follow the respective project readmes:

- [Firefox for iOS](./firefox-ios/README.md)
- [Focus iOS](./focus-ios/README.md)

## Getting involved

We encourage you to participate in those open source projects. We love Pull Requests, Issue Reports, Feature Requests or any kind of positive contribution. Please read the [Mozilla Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/) and our [Contributing guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md) first.

- You can [file a new issue](https://github.com/mozilla-mobile/firefox-ios/issues/new/choose) or research [existing bugs](https://github.com/mozilla-mobile/firefox-ios/issues)

If more information is required or you have any questions then we suggest reaching out to us via:

- Chat on Element channel [#fx-ios](https://chat.mozilla.org/#/room/#fx-ios:mozilla.org) and [#focus-ios](https://chat.mozilla.org/#/room/#focus-ios:mozilla.org) for general discussion, or write DMs to specific teammates for questions.
- Open a [Github discussion](https://github.com/mozilla-mobile/firefox-ios/discussions) which can be used for general questions.

Want to contribute on the codebase but don't know where to start? Here is a list of [issues that are contributor friendly](https://github.com/mozilla-mobile/firefox-ios/labels/Contributor%20OK), but make sure to read the [Contributing guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md) first.

## License

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/
