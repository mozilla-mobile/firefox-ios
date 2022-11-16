## Contributor guidelines
We'd love for you to contribute to this repository. Before you start, we'd like you to take a look and follow these guidelines:
  - [Submitting an Issue](#submitting-an-issue)
  - [Creating a pull request](#creating-a-pull-request)
  - [Coding Rules](#coding-rules)
    - [Swift style](#swift-style)
  - [Pull Requests](#pull-requests)
    - [Commits](#commits)
    - [Commenting Etiquette](#commenting-etiquette)

### Submitting an Issue
If you find a bug in the source code or a mistake in the documentation, you can help us by submitting an issue to our repository. Before you submit your issue, search open and closed issues, as it's possible that your question was already answered, or a ticket for the issue already exists.

### Creating a pull request
* All pull requests must be associated with a specific Issue. If an issue doesn't exist, please first create it.
* Before you submit your pull request, search the repository for an open or closed Pull Request that relates to your submission. You don't want to duplicate effort. 
* For commiting in your Pull Request, You can checkout [Commits](#commits) for more.

### Coding Rules

#### Swift style
* iOS engineers at Mozilla are still in the process of defining Mozilla's Swift guidelines. Currently, we're working through Swiftlint rules that members on the team agree should be enabled. Then we will pursue further rules we'd like to implement.
* In general, as of 2022, Swift code should follow the conventions listed at https://github.com/raywenderlich/swift-style-guide, with the understanding that this is a loose standard.
  * Exception: we use 4-space indentation instead of 2.

### Pull Requests
PR's should be made from your personal branch to the `main` branch. Please see the [PR Naming Guidelines](https://github.com/mozilla-mobile/firefox-ios/wiki/Pull-Request-Naming-Guide) for how to name PRs. 

#### Commits
* All of a PR's commits will be squashed to keep a clean git history in `main`. This means that technically, individual commit names are not particularly relevant. However, for an easier review process, we should keep the following rueles of thumb in mind:
  * Each commit should have a single clear purpose. If a commit contains multiple unrelated changes, those changes should be split into separate commits.
  * If a commit requires another commit to build properly, those commits should be squashed.

#### Commenting Etiquette
* Please remember that all comments should adhere to the [Mozilla Community Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/)
* Please keep comments related to the PR.
