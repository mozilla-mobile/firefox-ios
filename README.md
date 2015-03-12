Firefox for iOS
===============

Getting involved
----------------

* IRC:            [#mobile](https://wiki.mozilla.org/IRC).
* Mailing list:   [mobile-firefox-dev@mozilla.org](https://mail.mozilla.org/listinfo/mobile-firefox-dev).
* Bugs:           [File a new bug](https://bugzilla.mozilla.org/enter_bug.cgi?bug_file_loc=http%3A%2F%2F&bug_ignored=0&op_sys=iOS%207&product=Firefox%20for%20iOS&rep_platform=All) • [Existing bugs](https://bugzilla.mozilla.org/describecomponents.cgi?product=Firefox%20for%20iOS)

This is a work in progress on some early ideas.  Don't get too attached to this code. Tomorrow everything will be different.

Likewise, the design and UX is still in flux. Don't get attached to them. They will change tomorrow!
https://mozilla.invisionapp.com/share/HA254M642#/screens/63057282?maintainScrollPosition=false

*GitHub issues are enabled* on this repository, but we encourage you to file a bug (see above). We'll accept issues to track work items that don't yet have a pull request, and also as an early funnel for bug reports, but Bugzilla is the source of truth for lots of good reasons — issues will be shifted into Bugzilla, and pull requests need a bug number.

Building the code
-----------------

> __As of March 10, 2015, this project requires Xcode 6.2. Make sure you upgrade, the App Store should offer you 6.2 already.__

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage).
1. Clone the repository:

  ```
  git clone https://github.com/mozilla/firefox-ios
  ```

1. Pull in the project dependencies:

  ```
  cd firefox-ios
  sh ./checkout.sh
  ```

1. Open `Client.xcodeproj` in Xcode.
1. Build the `Client` scheme in Xcode.

It is possible to use [App Code](https://www.jetbrains.com/objc/download/) instead of Xcode, but you will still require the Xcode developer tools.

Contributor guidelines
----------------------

### Swift style
* Swift code should generally follow the conventions listed at https://github.com/raywenderlich/swift-style-guide.
  * Exception: we use 4-space indentation instead of 2.

### Whitespace
* New code should not contain any trailing whitespace.
* We recommend enabling both the "Automatically trim trailing whitespace" and "Including whitespace-only lines" preferences in Xcode (under Text Editing).
* <code>git rebase --whitespace=fix</code> can also be used to remove whitespace from your commits before issuing a pull request.

### Commits
* Each commit should have a single clear purpose. If a commit contains multiple unrelated changes, those changes should be split into separate commits.
* If a commit requires another commit to build properly, those commits should be squashed.
* Follow-up commits for any review comments should be squashed. Do not include "Fixed PR comments", merge commits, or other "temporary" commits in pull requests.

Adding new dependencies with Carthage
-------------------------------------

Notes from Stefan:

Usually Carthage is used to compile frameworks and then include the (compiled) binary frameworks in your app. When you do this, the frameworks do not need to be signed by Carthage. Instead, at the end of building the your application, xcode will simply sign all the embedded resources, frameworks included. So as long as signing works for your app, it will work for frameworks imported with Carthage.

But, because not all Carthage dependencies can be compiled to frameworks yet, we currently include them as source. This means they become dependent projects of our application, which in turn means that they are built *and signed* individually as part of the build process of our app.

Now this is where it gets tricky. Because code signing on iOS can get really tedious to get right. Small mistakes in dependent projects can turn into issues about code signing identities, missing provisioning profiles, etc.

For example:

If a dependent project has a team identifier set, Xcode will complain that it cannot find signin identities of that team. It is best to set the team to None.

If a dependent project is configured to use a Distribution Code Signing Identity for a Release build, Xcode will complain that such a profile is not available. (Since we only have development profiles on our workstations). It is best to configure both Debug and Release Build Configurations to use the automatic "iPhone Developer" Code Signing Identity. This will pick the right thing on your local build.

Most if this is fixable and can be reported upstream.

If you add a new dependency, ping @st3fan and he'll make sure things work correctly on our integration (xcode server) and dogfood builders.

A command exists to make adding dependencies less painful: `./update.sh`.
.
