Firefox for iOS
===============

Getting involved
----------------

* IRC:            [#mobile](https://wiki.mozilla.org/IRC).
* Mailing list:   [mobile-firefox-dev@mozilla.org](https://mail.mozilla.org/listinfo/mobile-firefox-dev).
* Bugs:           [File a new bug](https://bugzilla.mozilla.org/enter_bug.cgi?bug_file_loc=http%3A%2F%2F&bug_ignored=0&op_sys=iOS%207&product=Firefox%20for%20iOS&rep_platform=All) • [Existing bugs](https://bugzilla.mozilla.org/describecomponents.cgi?product=Firefox%20for%20iOS)

This is a work in progress on some early ideas.  Don't get too attached to this code. Tomorrow everything will be different.

*GitHub issues are enabled* on this repository, but we encourage you to file a bug (see above). We'll accept issues to track work items that don't yet have a pull request, and also as an early funnel for bug reports, but Bugzilla is the source of truth for lots of good reasons — issues will be shifted into Bugzilla, and pull requests need a bug number.

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
