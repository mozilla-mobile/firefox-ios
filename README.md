Firefox for iOS
===============

Download on the [App Store](https://itunes.apple.com/app/firefox-web-browser/id989804926).

This branch
-----------

This branch is targeting iOS 9, uses Swift 2.0, and is slated to become v1.1 and later. See the __v1.0__ branch if you're doing work for a 1.0.\* release.

Please make sure you aim your pull requests in the right direction.

Getting involved
----------------

We encourage you to participate in this open source project. We love Pull Requests, Bug Reports, ideas, (security) code reviews or any kind of positive contribution. Please read the [Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/).

* IRC:            [#mobile](https://wiki.mozilla.org/IRC) for general discussion and [#mobistatus](https://wiki.mozilla.org/IRC) for team status updates.
* Mailing list:   [mobile-firefox-dev@mozilla.org](https://mail.mozilla.org/listinfo/mobile-firefox-dev).
* Bugs:           [File a new bug](https://bugzilla.mozilla.org/enter_bug.cgi?bug_file_loc=http%3A%2F%2F&bug_ignored=0&op_sys=iOS%20&product=Firefox%20for%20iOS&rep_platform=All) • [Existing bugs](https://bugzilla.mozilla.org/describecomponents.cgi?product=Firefox%20for%20iOS)

This is a work in progress on some early ideas.  Don't get too attached to this code. Tomorrow everything will be different.

Likewise, the design and UX is still in flux. Don't get attached to them. They will change tomorrow!
https://mozilla.invisionapp.com/share/HA254M642#/screens/63057282?maintainScrollPosition=false

*GitHub issues are enabled* on this repository, but we encourage you to file a bug (see above). We'll accept issues to track work items that don't yet have a pull request, and also as an early funnel for bug reports, but Bugzilla is the source of truth for lots of good reasons — issues will be shifted into Bugzilla, and pull requests need a bug number.

Building the code
-----------------

> __As of August 28, 2015, this project requires Xcode 7 beta 6.__

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage).
1. Clone the repository:

  ```shell
  git clone https://github.com/mozilla/firefox-ios
  ```

1. Pull in the project dependencies:

  ```shell
  cd firefox-ios
  sh ./checkout.sh
  ```

1. Open `Client.xcodeproj` in Xcode.
1. Build the `Client` scheme in Xcode.

It is possible to use [App Code](https://www.jetbrains.com/objc/download/) instead of Xcode, but you will still require the Xcode developer tools.

## Contributor guidelines

### Creating a pull request
* All pull requests must be associated with a specific bug in [Bugzilla](http://bugzilla.mozilla.org).
 * If a bug corresponding to the fix does not yet exist, please [file it](https://bugzilla.mozilla.org/enter_bug.cgi?op_sys=iOS&product=Firefox%20for%20iOS&rep_platform=All).
 * You'll need to be logged in to create/update bugs, but note that Bugzilla allows you to sign in with your GitHub account.
* Use the bug number/title as the name of pull request. For example, a pull request for [bug 1135920](https://bugzilla.mozilla.org/show_bug.cgi?id=1135920) would be titled "Bug 1135920 - Create a top sites panel".
* Finally, upload an attachment to the bug pointing to the GitHub pull request.
 1. Click <b>Add an attachment</b>.
 2. Next to <b>File</b>, click <b>Paste text as attachment</b>.
 3. Paste the URL of the GitHub pull request.
 4. Enter "Pull request" as the description.
 5. Finally, flag the pull request for review. Set the <b>review</b> field to "?", then enter the name of the person you'd like to review your patch. If you don't know whom to add as the reviewer, click <b>suggested reviewers</b> and select a name from the dropdown list.

<b>Pro tip: To simplify the attachment step, install the [Github Bugzilla Tweaks](https://github.com/autonome/Github-Bugzilla-Tweaks) addon. This will add a button that takes care of the first four attachment steps for you.</b>

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

Most of this is fixable and can be reported upstream.

If you add a new dependency, ping @st3fan and he'll make sure things work correctly on our integration (xcode server) and dogfood builders.

A command exists to make adding dependencies less painful: `./update.sh`.
