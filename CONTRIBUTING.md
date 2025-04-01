# Contribution guidelines
We encourage you to participate in this open source project. We love Pull Requests, Issue Reports, Feature Requests or any kind of positive contribution. Please read the following guidelines first.

## Submitting an Issue
If you find a bug in the source code or a mistake in the documentation, you can help us by submitting an issue to our repository. Before you submit your issue, search open and closed issues, as it's possible that your question was already answered, or a ticket for the issue already exists.

## Coding Rules

### Swift style
* iOS engineers at Mozilla are still in the process of defining Mozilla's Swift guidelines. Currently, we're working through Swiftlint rules that members on the team agree should be enabled. Then we will pursue further rules we'd like to implement.
* In general, as of 2023, Swift code should follow the conventions listed at [Swift style guide](https://github.com/raywenderlich/swift-style-guide), with the understanding that this is a loose standard.
  * Exception: we use 4-space indentation instead of 2.
* We use [Swiftlint rules](https://github.com/mozilla-mobile/firefox-ios/blob/main/.swiftlint.yml) in both local and CI builds to ensure conformance to accepted rules. You can run Swiftlint locally by installing it [locally with Homebrew](https://github.com/realm/SwiftLint#using-homebrew). Swiftlint will then be run through Xcode Build Phases on the Client target.

# Looking for issues
Want to contribute to the codebase but don't know where to start? Here is a list of [issues that are contributor friendly](https://github.com/mozilla-mobile/firefox-ios/labels/Contributor%20OK).

## Guidelines for Contributing

1. **Check if the Issue is Currently Being Worked On**:
Before starting, check for:
    - `Open PRs`: Ensure no PRs are already addressing the issue.
    - `Comments from Contributors`: Look for recent comments. If the most recent comment from another contributor wanting to work on the issue is older than `3 weeks`, 
    feel free to write a message saying that you are going to work on it.

2. **Working on Contributor OK Issues**:
For a smooth collaboration process, start with issues labeled `Contributor OK`.
    - These issues are designed specifically for contributors and do not require prior approval from team members.
    - Simply leave a **`comment`** on the issue saying that you’ll work on it.

3. **Working on Non-Contributor OK Issues**:
If you’d like to work on an issue that isn’t labeled Contributor OK, please contact a team member to confirm whether it’s available for contributors.

## Getting Support

### Reference Person
Each `Contributor OK` issue typically has a reference person assigned. If you need help or clarification:

- Reach out on [Mozilla Matrix chat](#reaching-out-for-help-and-questions).
- Alternatively, comment directly on the issue for assistance.

### Missing Reference Person
If no reference person is assigned, feel free to contact:

- @FilippoZazzeroni
- @Foxbolts

### Issue Categories by Difficulty
We’ve categorized Contributor OK issues by difficulty to help you get started:

- `Good First Issue`: Beginner-friendly tasks such as simple bug fixes or minor UX improvements.
- `Intermediate`: These involve tasks like small feature development, simple pattern implementations, or bug/UI adjustments that require some familiarity with the codebase.
- `Advanced`: These tasks demand a deeper understanding of the project. They often include complex implementations, significant refactoring, or intricate bug fixes.

## Pull Requests
* All pull requests must be associated with a specific issue. If an issue doesn't exist, please create it first.
* Before you submit your pull request, search the repository for open or closed PRs that relate to your submission. We don't want to duplicate effort. 
* PRs should be made from a branch on your personal fork to the `mozilla-mobile:main` branch. Please see the [Pull Request Naming Guidelines](https://github.com/mozilla-mobile/firefox-ios/wiki/Pull-Request-Naming-Guide) for how to name PRs.

### Commits
* All of a PR's commits will be squashed to keep a clean git history in `main`. This means that technically, individual commit names are not particularly relevant. However, for an easier review process, we should keep the following rules of thumb in mind:
  * Each commit should have a single clear purpose. If a commit contains multiple unrelated changes, those changes should be split into separate commits.
  * If a commit requires another commit to build properly, those commits should be squashed.

### Commenting Etiquette
* Please remember that all comments should adhere to the [Mozilla Community Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/)
* If a comment does not apply to the code review on the PR, please post it on the related issue.

# Building the code
- Fork and clone the project from the [repository](https://github.com/mozilla-mobile/firefox-ios).
- Use the provided build instructions in the [Readme](https://github.com/mozilla-mobile/firefox-ios/blob/main/README.md) of the repository to build the project. 

## Run on a Device with a Free Developer Account

> [!IMPORTANT]  
> Only follow these instructions if you are using the free personal developer accounts. Simply add your Apple ID as an account in Xcode.

Since the bundle identifier we use for Firefox is tied to our developer account, you'll need to generate your own identifier and update the existing configuration.

1. Open `firefox-ios/Client/Configuration/Fennec.xcconfig`
2. Change MOZ_BUNDLE_ID to your own bundle identifier. Just think of something unique: e.g., com.your_github_id.Fennec
3. Open the project editor in Xcode.
4. For the 'Client' target, in the 'Capabilities' section, turn off the capabilities 'Push Notifications' and 'Wallet'.
5. For each target, in the 'General' section, under 'Signing', select your personal development account.

If you submit a patch, be sure to exclude these files because they are only relevant for your personal build.

## Contributor Fix
We add the "Contributor Fix" label on tasks that have a PR opened for it, or if a PR has been merged to fix this task. This means if you see this label on a task it's probably fixed and cannot be picked up. Note that tasks still stay opened before we close them as it's the Quality Assurance people that will close those tasks with their final approval of the work.

# Reaching out for help and questions
If more information is required or contributors have any questions then we suggestion reaching out to us via:
- Chat: See Matrix channel [#fx-ios](https://chat.mozilla.org/#/room/#fx-ios:mozilla.org) for general discussion. You can also write DMs to specific teammates on it. (For more information on how to get started with Matrix, see [Mozilla Matrix wiki page](https://wiki.mozilla.org/Matrix).)
- Open a [GitHub discussion](https://github.com/mozilla-mobile/firefox-ios/discussions).
