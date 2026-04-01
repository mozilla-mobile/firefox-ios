# Contribution guidelines

We welcome contributions of all kinds, including bug fixes, improvements, and new ideas. Thank you for taking the time to contribute to Firefox iOS.

Note: If you are not choosing to work on one of our `contributor-friendly` issues, you should first receive approval from a maintainer before starting work on something else. Otherwise, your work may be rejected. Please see more information below.

Before getting started, please make sure your work aligns with how we collaborate in this repository.

## Submitting an Issue

If you find a bug or a documentation issue, please [open an issue](https://github.com/mozilla-mobile/firefox-ios/issues/new/choose) in the repository.

Before submitting:
* Search existing open and closed issues to avoid duplicates  
* Provide clear steps to reproduce the problem when applicable  

## Code Contribution

There are two supported ways to contribute:

### 1. Work on `Contributor OK` issues (recommended)
These issues are specifically scoped for external contributors and do not require prior approval.

* Browse Contributor OK issues [here](https://github.com/mozilla-mobile/firefox-ios/labels/Contributor%20OK)
* Leave a comment to let others know you're working on it. If the last activity is older than 3 weeks, leave a comment before picking it up.
* A reference person is usually available if you need guidance

#### Issue Categories by Difficulty
We’ve categorized Contributor OK issues by difficulty to help you get started:

- `Good First Issue`: Beginner-friendly tasks such as simple bug fixes or minor UX improvements.
- `Intermediate`: These involve tasks like small feature development, simple pattern implementations, or bug/UI adjustments that require some familiarity with the codebase.
- `Advanced`: These tasks demand a deeper understanding of the project. They often include complex implementations, significant refactoring, or intricate bug fixes. 

### 2. Propose to work on other issues (requires coordination with a maintainer)
If you want to work on something that is **not labeled `Contributor OK`**, please coordinate with the team first.

* Comment on the issue and wait for confirmation before starting work.
* For new ideas, open an issue first to discuss feasibility and priority.

> ⚠️ Pull requests for unapproved work may be declined.
> Our roadmap is planned in collaboration with our Product and Design teams, and not all changes can be accepted.

We absolutely welcome ideas and contributions. We just ask that larger or unscoped work be discussed first so we can collaborate effectively.  

### Contributor Fix
We add the "Contributor Fix" label on tasks that have a PR opened for it, or if a PR has been merged to fix this task. This means if you see this label on a task, it's probably fixed and cannot be picked up. Note that tasks still stay opened before we close them as it's the Quality Assurance team that will close those tasks once they approve the changes.

## Coding Rules

### Swift style

* Follow the conventions from the [Swift style guide](https://github.com/raywenderlich/swift-style-guide).
* Use 4-space indentation instead of 2  
* Follow existing patterns in the codebase when in doubt  

We use [Swiftlint rules](https://github.com/mozilla-mobile/firefox-ios/blob/main/.swiftlint.yml) in both local and CI builds to ensure conformance to accepted rules. You can run Swiftlint by installing it [locally with Homebrew](https://github.com/realm/SwiftLint#using-homebrew). Swiftlint will then be run through Xcode Build Phases on the Client target.

### Quality expectations for pull requests

To help reviewers give useful feedback and keep the project maintainable, pull requests should meet the following baseline before review:

* The change is scoped and purposeful. A PR should solve one issue clearly, without unrelated refactors or drive-by changes.
* The code is maintainable and consistent. Changes should follow the project’s existing patterns, naming, structure, and style rules.
* The PR is reviewable. The description should explain what changed and why, and the diff should be small and clear enough for a reviewer to understand without reconstructing intent.
* The change is validated. Code should build cleanly, pass relevant checks, and include testing or manual verification steps appropriate to the change.
* The contribution is complete. Partial, experimental, or AI-generated changes that the author cannot explain, validate, or finish cannot be approved.

Pull requests that do not meet this baseline may be closed until they meet our code quality expectations.

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

## Getting Support

### Reference Person
Each `Contributor OK` issue typically has a reference person assigned. If you need help or clarification:

- Reach out on [Mozilla Matrix chat](#reaching-out-for-help-and-questions).
- Alternatively, comment directly on the issue for assistance.

### Missing Reference Person
If no reference person is assigned, or you have not received a response to your comment, feel free to directly contact:

- @FilippoZazzeroni
- @Foxbolts 

---

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

---

# Reaching out for help and questions
If more information is required or contributors have any questions then we suggestion reaching out to us via:
- Chat: See Matrix channel [#fx-ios](https://chat.mozilla.org/#/room/#fx-ios:mozilla.org) for general discussion. You can also write DMs to specific teammates on it. (For more information on how to get started with Matrix, see [Mozilla Matrix wiki page](https://wiki.mozilla.org/Matrix).)
