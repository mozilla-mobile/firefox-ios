Firefox for iOS
===============

Getting involved
----------------

* IRC:            [#mobile](https://wiki.mozilla.org/IRC).
* Mailing list:   [mobile-firefox-dev@mozilla.org](https://mail.mozilla.org/listinfo/mobile-firefox-dev).
* Bugs:           [File a new bug](https://bugzilla.mozilla.org/enter_bug.cgi?bug_file_loc=http%3A%2F%2F&bug_ignored=0&op_sys=iOS%207&product=Firefox%20for%20iOS&rep_platform=All) • [Existing bugs](https://bugzilla.mozilla.org/describecomponents.cgi?product=Firefox%20for%20iOS)

This is a work in progress on some early ideas.  Don't get too attached to this code. Tomorrow everything will be different.

Contributor guidelines
----------------------

* Swift code should follow the conventions listed at https://github.com/raywenderlich/swift-style-guide.
  * The only exception is that we use 4-space indentation instead of 2.
* Make sure each commit has a clear purpose.
  * If a single commit contains multiple unrelated changes, those changes should be split into separate commits.
  * If a commit requires another commit to build properly, those commits should be squashed.
  * Follow-up commits for any review comments should be squashed. Do not include "Fixed PR comments", merge commits, or other "temporary" commits in pull requests.
* Make sure not to commit any trailing whitespace.
  * We recommend enabling both the "Automatically trim trailing whitespace" and "Including whitespace-only lines" preferences in Xcode (under Text Editing).
  * "git rebase --whitespace=fix" can also be used to remove whitespace from your commits before issuing a pull request.
