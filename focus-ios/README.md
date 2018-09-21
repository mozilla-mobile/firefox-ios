[![codecov](https://codecov.io/gh/mozilla-mobile/focus/branch/master/graph/badge.svg)](https://codecov.io/gh/mozilla-mobile/focus)

# Firefox Focus for iOS

_Browse like no one’s watching. The new Firefox Focus automatically blocks a wide range of online trackers — from the moment you launch it to the second you leave it. Easily erase your history, passwords and cookies, so you won’t get followed by things like unwanted ads._

Download on the [App Store](https://itunes.apple.com/app/id1055677337).

Getting Involved
----------------

We encourage you to participate in this open source project. We love Pull Requests, Bug Reports, ideas, (security) code reviews or any kind of positive contribution. Please read the [Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/).

* IRC:            See [#focus](https://wiki.mozilla.org/IRC) for general discussion; logs: https://mozilla.logbot.info/focus/; we're available Monday-Friday, PST working hours
* Mailing List:   [firefox-focus-public@](https://mail.mozilla.org/listinfo/firefox-focus-public)
* Bugs:           [File a new bug](https://github.com/mozilla-mobile/focus-ios/issues/new) • [Existing bugs](https://github.com/mozilla-mobile/focus-ios/issues)

If you're looking for a good way to get started contributing, check out out some [good first issues](https://github.com/mozilla-mobile/focus-ios/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22).

We also tag recommended bugs for contributions with [help wanted](https://github.com/mozilla-mobile/focus-ios/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22).

Master Branch
----------------

This branch works with Xcode 9.4 and supports iOS 11.

This branch is written in Swift 4.

For current development, see the V7.0 Development Branch section.

Build Instructions for Master
------------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
2. Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage).
3. Clone the repository:

  ```shell
  https://github.com/mozilla-mobile/focus-ios.git
  ```

4. Pull in the project dependencies:

  ```shell
  cd focus-ios
  ./checkout.sh
  ```

5. Open `Blockzilla.xcodeproj` in Xcode.
6. Build the `Focus` scheme in Xcode.

V7.0 Development Branch
----------------

For version 7.0 of Focus, we are working off of the v7.0-dev branch.

This branch only works with Xcode 10 and supports iOS 11 & 12. This means you will need the Xcode 10 beta (beta 3+ recommended).

This branch is written in Swift 4.2. Pull requests for this branch must also be written in Swift 4.2. 

In order to compile with Swift 4.2 & Xcode 10, you will need to follow separate build instructions (described below).

For bugs and features for the upcoming v7.0 release, please see the V7.0 milestone within the GitHub Issues.

Build Instructions for V7.0 Development
------------------

1. Quit Xcode
2. Install the latest [Xcode 10 beta developer tools](https://developer.apple.com/downloads/) from Apple. You should install it in your Applications folder with the default name 'Xcode-beta.app'.
3. Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage).
4. Clone the repository:

```shell
git clone https://github.com/mozilla-mobile/focus-ios.git
```

5. Checkout the development branch

```shell
git checkout v7.0-dev
```

6. Select the Xcode 10 command line tools.

```shell
sudo xcode-select -s /Applications/Xcode-beta.app
```
Alternatively, you can select the command line tools from Xcode-beta -> Preferences -> Locations -> Command Line Tools

7. Pull in the project dependencies:

```shell
cd focus-ios
./checkout.sh
```

8. Open `Blockzilla.xcodeproj` in Xcode.
9. Build the `Focus` scheme in Xcode.
