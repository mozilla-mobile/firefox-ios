> Some info in this README has not been updated for the current version of Firefox Focus (and Firefox Klar) 3.0. We will do that soon. The code in this repository however is fully up to date and represents the code of the Firefox Focus and Klar applications that are found on the iOS App Store.

Download on the [App Store](https://itunes.apple.com/app/id1055677337).

We welcome your [feedback](https://input.mozilla.org/feedback/focus) as we explore ways to offer more features in the future.

Getting Involved
----------------

We encourage you to participate in this open source project. We love Pull Requests, Bug Reports, ideas, (security) code reviews or any kind of positive contribution. Please read the [Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/).

* IRC:            [#mobile](https://wiki.mozilla.org/IRC) for general discussion and [#mobistatus](https://wiki.mozilla.org/IRC) for team status updates.
* Bugs:           [File a new bug](https://bugzilla.mozilla.org/enter_bug.cgi?bug_file_loc=http%3A%2F%2F&bug_ignored=0&op_sys=iOS%20&product=Focus&rep_platform=All) • [Existing bugs](https://bugzilla.mozilla.org/describecomponents.cgi?product=Focus)


Build Instructions
------------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage).
1. Clone the repository:

  ```shell
  git clone https://github.com/mozilla/focus
  ```

1. Pull in the project dependencies:

  ```shell
  cd focus
  ./checkout.sh
  ```

1. Open `Blockzilla.xcodeproj` in Xcode.
1. Build the `Focus` scheme in Xcode.
