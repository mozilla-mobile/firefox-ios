# Firefox Focus for iOS

_Browse like no one’s watching. The new Firefox Focus automatically blocks a wide range of online trackers — from the moment you launch it to the second you leave it. Easily erase your history, passwords and cookies, so you won’t get followed by things like unwanted ads._

Download on the [App Store](https://itunes.apple.com/app/id1055677337).

Getting Involved
----------------

We encourage you to participate in this open source project. We love Pull Requests, Bug Reports, ideas, (security) code reviews or any kind of positive contribution. Please read the [Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/).

* IRC:            See [#mobile](https://wiki.mozilla.org/IRC) for general discussion.
* Bugs:           [File a new bug](https://bugzilla.mozilla.org/enter_bug.cgi?bug_file_loc=http%3A%2F%2F&bug_ignored=0&op_sys=iOS%20&product=Focus&rep_platform=All) • [Existing bugs](https://bugzilla.mozilla.org/describecomponents.cgi?product=Focus)


Build Instructions
------------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
2. Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage).
3. Clone the repository:

  ```shell
  git clone https://github.com/mozilla-mobile/focus
  ```

4. Pull in the project dependencies:

  ```shell
  cd focus
  ./checkout.sh
  ```

5. Open `Blockzilla.xcodeproj` in Xcode.
6. Build the `Focus` scheme in Xcode.
