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

This branch works with Xcode 10.0 and supports iOS 11.0+.

This branch is written in Swift 4.2.

Pull requests should be submitted with master as the base branch and should also be written in Swift 4.2.

Build Instructions for Master
------------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
2. Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage).
3. Install [SwiftLint](https://github.com/realm/SwiftLint).
4. Clone the repository:

  ```shell
  https://github.com/mozilla-mobile/focus-ios.git
  ```

5. Pull in the project dependencies:

  ```shell
  cd focus-ios
  ./checkout.sh
  ```

6. Open `Blockzilla.xcodeproj` in Xcode.
7. Build the `Focus` scheme in Xcode.

Upcoming Release (Version 8.0)
------------------

Features planned for the next release can be found in the [V8.0 milestone](https://github.com/mozilla-mobile/focus-ios/milestone/29). 
