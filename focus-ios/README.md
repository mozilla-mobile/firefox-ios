# Firefox Focus for iOS

_Browse like no one’s watching. The new Firefox Focus automatically blocks a wide range of online trackers — from the moment you launch it to the second you leave it. Easily erase your history, passwords and cookies, so you won’t get followed by things like unwanted ads._

Download on the [App Store](https://itunes.apple.com/app/id1055677337).

Getting Involved
----------------

We encourage you to participate in this open source project. We love Pull Requests, Bug Reports, ideas, (security) code reviews or any kind of positive contribution. Please read the [Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/).

* Chat:           See [#focus-ios](https://chat.mozilla.org/#/room/#focus-ios:mozilla.org) for general discussion
* Bugs:           [File a new bug](https://github.com/mozilla-mobile/focus-ios/issues/new) • [Existing bugs](https://github.com/mozilla-mobile/focus-ios/issues)

If you're looking for a good way to get started contributing, check out some [good first issues](https://github.com/mozilla-mobile/focus-ios/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22).

We also tag recommended bugs for contributions with [help wanted](https://github.com/mozilla-mobile/focus-ios/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22).

Main Branch
----------------

This branch works with Xcode 12.5.1 and supports iOS 11.4+.

Pull requests should be submitted with `main` as the base branch.

Build Instructions
------------------

1. Install Xcode 12.5 [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
2. Clone the repository:

  ```shell
  git clone https://github.com/mozilla-mobile/focus-ios.git
  ```

3. Pull in the project dependencies:

  ```shell
  cd focus-ios
  ./checkout.sh
  ```

4. Open `Blockzilla.xcodeproj` in Xcode.
5. Build the `Focus` scheme in Xcode.


