Want to contribute? Great! First, read this page (including the small print at the end).

## Before you contribute
Before we can use your code, you must sign the
[Google Individual Contributor License Agreement](https://cla.developers.google.com/about/google-individual)
(CLA), which you can do online. The CLA is necessary mainly because you own the
copyright to your changes, even after your contribution becomes part of our
codebase, so we need your permission to use and distribute your code. We also
need to be sure of various other things—for instance that you'll tell us if you
know that your code infringes on other people's patents. You don't have to sign
the CLA until after you've submitted your code for review and a member has
approved it, but you must do it before we can put your code into our codebase.
Before you start working on a larger contribution, you should get in touch with
us first through the issue tracker with your idea so that we can help out and
possibly guide you. Coordinating up front makes it much easier to avoid
frustration later on.

## Code reviews

All submissions, including submissions by project members, require review. We
use Github pull requests for this purpose.

The submitted code should adhere to the following:

### Do's

* Keep pull requests focused on addressing one issue or feature. If multiple separate issues
  are fixed by a pull request, prefer committing the fixes under multiple commits, one for each
  issue.
* A Pull Request **must** have a [Github Issue](https://github.com/google/EarlGrey/issues) filed
  for it except in the case of trivial spelling/formatting fixes. For a Pull Request without a
  corresponding issue, please create the issue first and discuss it with the community to ascertain
  the severity of the issue. This allows us to prioritize your Pull Request and focus on the
  most pressing issues at hand. Without a proper context for why the change is being made, we
  cannot guarantee an expedient review or a merge.
* Before submitting any code changes, please ensure that the [Unit Tests](https://github.com/google/EarlGrey/tree/master/Tests/UnitTests)
  and [Functional Tests](https://github.com/google/EarlGrey/tree/master/Tests/FunctionalTests)
  projects build and all tests pass. If you believe that the test failures are due to bugs in the
  framework then please [file an issue](https://github.com/google/EarlGrey/issues).
* If a pull request looks good then we'll wait for Travis to run all the Unit and
  Functional tests on the changes. We also trigger an internal test to check for
  further breakages. For each stage, appropriate labels will be set on the pull request.
  In case any of the tests are broken, we will let you know.
* If your pull request does not touch any code, then you could skip the Travis Continuous
  Integration check by adding [[ci skip]](https://docs.travis-ci.com/user/customizing-the-build/#Skipping-a-build)
  to your git commit message. This helps prevent over-encumbering the CI.
* Any PR marked as experiment will not be merged. You can indicate that either in the title of the PR or by labelling the PR  with `experiment`. Use it to share a prototype for which you want to get more feedback from the core team.
* If a new custom API is being proposed to be added to EarlGrey, but is still in the
  experimental phase, then please add it to the [EarlGreyContribs](https://github.com/google/EarlGrey/tree/master/Demo/EarlGreyContribs)
  project for vetting out. Also, any example code that is added must first
  be vetted in the EarlGreyContribs project.
* Please use [Github's Markdown Formatting](https://help.github.com/articles/getting-started-with-writing-and-formatting-on-github/)
  for formatting your comments and issues.
* Refer to the [Google Objective-C style guide][objc_style] and the [Google Swift style guide][swift_style] for our code conventions.

[objc_style]: https://github.com/google/styleguide/blob/gh-pages/objcguide.md
[swift_style]: https://google.github.io/swift/

### Don'ts

* Consider not adding LGTM's or +1's unless you're specifically asked to do so, since they
  add noise to the conversation.
* Refrain from providing small and granular pull requests for changes that could easily be
  consolidated into one.
* A vague description for a pull request adds to the review time because we now have to analyze
  what the code does. A more descriptive description will help the reviewers understand what
  they're reviewing.
* Refrain from sending us a pull request with a large refactor / feature change with a
  vague/negligible description or no issue attached.

## Github Issues

### Do's

* Ensure you've searched extensively through the documentation before filing a Github Issue. As
  a developer, please provide us issue descriptions that you yourself would like to read.
* Please be as verbose in your comments and descriptions as possible. For each issue, add in the
  type of project, language used, Xcode version, error trace etc. While we love the fact that
  you're helping us improve the project, it would be nice for us not to have to ask for debugging
  clarifications for every issue created.
* For in-depth discussions please use the [EarlGrey Google Group](https://groups.google.com/forum/#!forum/earlgrey-discuss)
  instead of starting a Github Issue.
* In case of an API update, please make sure the changes are documented in the [cheatsheet.html](./docs/cheatsheet/cheatsheet.html)
  file. The PDF and .PNG cheatsheet files are to be updated only when we update the EarlGrey CocoaPod.

### Don'ts

* Any vaguely worded issue will be immediately closed.
* If there is inactivity on an issue for an extended period of time, it will be closed. Please update the issue and reopen it in case you find that it still persists.

## The small print
Contributions made by corporations are covered by a different agreement than
the one above, the
[Software Grant and Corporate Contributor License Agreement](https://cla.developers.google.com/about/google-corporate).

