## Contributor guidelines
We'd love for you to contribute to this repository. Before you start, we'd like you to take a look and follow these guidelines:
  - [Submitting an Issue](#submitting-an-issue)
  - [Coding Rules](#coding-rules)
    - [Swift style](#swift-style)
  - [Pull Requests](#pull-requests)
    - [Commits](#commits)
    - [Commenting Etiquette](#commenting-etiquette)

### Submitting an Issue
If you find a bug in the source code or a mistake in the documentation, you can help us by submitting an issue to our repository. Before you submit your issue, search open and closed issues, as it's possible that your question was already answered, or a ticket for the issue already exists.

### Coding Rules

#### Swift style
* iOS engineers at Mozilla are still in the process of defining Mozilla's Swift guidelines. Currently, we're working through Swiftlint rules that members on the team agree should be enabled. Then we will pursue further rules we'd like to implement.
* In general, as of 2023, Swift code should follow the conventions listed at https://github.com/raywenderlich/swift-style-guide, with the understanding that this is a loose standard.
  * Exception: we use 4-space indentation instead of 2.
* We use [Swiftlint rules](https://github.com/mozilla-mobile/firefox-ios/blob/main/.swiftlint.yml) in both local and CI builds to ensure comformance to accepted rules. You can run Swiftlint locally by installing it [locally with Homebrew](https://github.com/realm/SwiftLint#using-homebrew). Swiftlint will then be run through Xcode Build Phases on the Client target.

### Pull Requests
* All pull requests must be associated with a specific Issue. If an issue doesn't exist, please first create it.
* Before you submit your pull request, search the repository for an open or closed Pull Request that relates to your submission. We don't want to duplicate effort. 
* PR's should be made from a branch on your personal fork to the `mozilla-mobile:main` branch. Please see the [PR Naming Guidelines](https://github.com/mozilla-mobile/firefox-ios/wiki/Pull-Request-Naming-Guide) for how to name PRs.
* For commiting in your Pull Request, You can checkout [Commits](#commits) for more info.

#### Commits
* All of a PR's commits will be squashed to keep a clean git history in `main`. This means that technically, individual commit names are not particularly relevant. However, for an easier review process, we should keep the following rules of thumb in mind:
  * Each commit should have a single clear purpose. If a commit contains multiple unrelated changes, those changes should be split into separate commits.
  * If a commit requires another commit to build properly, those commits should be squashed.

#### Commenting Etiquette
* Please remember that all comments should adhere to the [Mozilla Community Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/)
* If a comment does not apply to the code review on the PR, please post it on the related issue.
