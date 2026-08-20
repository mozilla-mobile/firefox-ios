# 🌳 Ecosia for iOS

<table>
  <tr>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-16.2-blue?logo=Xcode&logoColor=white" alt="Ecosia-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-5.6-red?logo=Swift&logoColor=white" alt="Ecosia-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-15.0+-green?logo=apple&logoColor=white" alt="Ecosia-iOS"></td>
  </tr>
</table>

This is the entry point of all-things Ecosia.
It contains info on the way we got the project structure, how we interface it with Firefox, how we release and keep localizations aligned.

## 🧰 Ecosia Framework 

The Ecosia Framework aims to be a wrapper of all our Ecosia isolated implementation and logic.
Some of the Ecosia codebase still lives under the main project `Client/Ecosia` but the goal is to bring as much codebase as possible as part of this dedicated framework.

### 🎨 New Tab Page (NTP)

The Ecosia NTP features a custom wallpaper background (a nature photograph), glassmorphism impact tiles, shortcut tiles, and a daily rotating title fetched from the CDN.

**Background Asset:**
- Located in `Ecosia/UI/Common.xcassets/ntpBackground.imageset/` (Ecosia framework bundle — loaded via `UIImage.ecosia(named:)`)
- A single universal asset used in both light and dark mode (no appearance variants)
- The `WallpaperBackgroundView` is pinned to the parent `BrowserViewController` view on iPad so the card fills the full screen height with a consistent 16pt margin on all sides

**Impact Tiles:**
- `NTPImpactCell` / `NTPImpactCellViewModel` — glassmorphism rows (trees planted + money invested) driven by `TreesProjection` and `InvestmentsProjection`
- Rotating title fetched from `RotatingTitlesService` (CDN-backed, one title per UTC day, mirrors web); `UserDefaults` cache respects `frequency_days` from the CDN response; offline fallback: "Search. Find. Save the planet."

**Shortcut Tiles:**
- `TopSiteCell` updated with glassmorphism background matching Figma spec

**Toolbar:**
- Fixed order: back → forward → new-tab (plus) → tabs → menu (ellipsis)
- New-tab button uses the Ecosia-owned `nav-add` asset and is always visible even on the homepage
- Menu button uses the Ecosia-owned `elipsis` asset

## 🤝 Getting involved

We encourage you to participate in those open source projects. We love Pull Requests, Issue Reports, Feature Requests or any kind of positive contribution. Please read the [Mozilla Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/) and our [Contributing guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md) first. 

- You can [file a new issue](https://github.com/mozilla-mobile/firefox-ios/issues/new/choose) or research [existing bugs](https://github.com/mozilla-mobile/firefox-ios/issues)

If more information is required or you have any questions then we suggest reaching out to us via:
- Chat on Element channel [#fx-ios](https://chat.mozilla.org/#/room/#fx-ios:mozilla.org) and [#focus-ios](https://chat.mozilla.org/#/room/#focus-ios:mozilla.org) for general discussion, or write DMs to specific teammates for questions.
- Open a [Github discussion](https://github.com/mozilla-mobile/firefox-ios/discussions) which can be used for general questions.

Want to contribute on the codebase but don't know where to start? Here is a list of [issues that are contributor friendly](https://github.com/mozilla-mobile/firefox-ios/labels/Contributor%20OK), but make sure to read the [Contributing guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md) first.

### ⁒ Update Ecosia Comments

To ensure consistency when commenting code in Firefox for Ecosia updates, you could document the following approach:

Commenting Guidelines for Ecosia Code in Firefox:
    1.	One-liner Comments:
Use `//` for introducing new code or brief explanations.

```
// Ecosia: Update appversion predicate
let appVersionPredicate = (appVersionString?.contains("Ecosia") ?? false) == true
```

    2.	Block Comments:
Use `/* */` when commenting out existing Firefox code for easier readability and conflict resolution.

```
/* Ecosia: Update appversion predicate
let appVersionPredicate = (appVersionString?.contains("Firefox") ?? false) == true
*/
let appVersionPredicate = (appVersionString?.contains("Ecosia") ?? false) == true
```

### After cloning (for Ecosians)
-----------

#### 🪝 Git Hooks

This project uses custom Git hooks to enforce commit message formatting and other automated tasks. 
To ensure that these hooks are installed correctly in your local `.git/hooks` directory, you need to run the provided setup script after cloning the repository.

- Navigate into the project directory
- Run the setup script to install the Git hooks: `./setup_hooks.sh`

This script will copy all the necessary hooks (such as `prepare-commit-msg`) to your local `.git/hooks` directory, ensuring they are executable.

## ⚙️ Building the code

### Tuist

We use [Tuist](https://tuist.dev) to generate the Xcode project and manage the build setup. Tuist is an iOS tooling platform that generates workspaces and projects from Swift-based manifests, keeping the project structure consistent and making dependency management easier. 

The `Client.xcodeproj` is generated by Tuist — do not edit it by hand; use the Tuist manifests (e.g. [Project.swift](../../Project.swift)`) and run the setup script when you need to regenerate. [See a chart of how the configs are organised here](./project-configs-map.mmd)

### 🧼 SwiftLint

We use [SwiftLint](https://github.com/realm/SwiftLint) to enforce Swift style and conventions. Make sure to install it so that linting runs correctly when building.

#### Installation & Version Pinning

We pin SwiftLint to **version 0.63.2** to ensure consistent linting behavior across all developers and CI. This version is specified in [`.github/workflows/swift_lint.yml`](/.github/workflows/swift_lint.yml).

```shell
brew install swiftlint
brew pin swiftlint
```

The `brew pin` command prevents SwiftLint from being automatically upgraded when you run `brew upgrade`. This ensures everyone on the team uses version 0.63.2.

**To verify the pinned version:**
```shell
swiftlint version
brew list --pinned
```

#### Baseline Approach

SwiftLint's baseline feature (`swiftlint_baseline.json`) is used **temporarily** during Firefox upstream merges when SwiftLint version updates introduce new violations. Key principles:
- ✅ **Main branch must have an empty baseline** — all violations must be fixed before the upgrade is complete
- ⚠️ The baseline is only for Ecosia files during the transition period when updating SwiftLint versions
- 🔄 New code you write must always be lint-clean, regardless of baseline state

#### Version Updates

SwiftLint version is evaluated during upstream Firefox merges. Since Firefox doesn't pin versions (they use the latest), we assess whether to upgrade when merging their changes.

### First-time setup and building

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
2. Install [Homebrew](https://brew.sh), Node, and a Python3 virtualenv for localization scripts:
    ```shell
    brew update
    brew install node
    pip3 install virtualenv
    ```
3. Clone the repository:
    ```shell
    git clone https://github.com/ecosia/ios-browser
    cd ios-browser
    ```
3. Setup environment variables
In order to run against staging you will need Cloudflare tokens. These are injected into Staging.xcconfig when tuist generates the project.
Either set the environment variables in your terminal or prepend them to the `tuist-setup.sh` call.
The required variables can be found in Bitwarden under "[iOS Dev] Staging.xcconfig"

4. Run the Tuist setup script from the **workspace root** (`ios-browser`). It installs Tuist if needed, runs the bootstrap (Node dependencies, user scripts, content blocker), installs SPM dependencies, and generates `firefox-ios/Client.xcodeproj` (and opens Xcode by default):

    If you have the environment variables set in your terminal:
    ```shell
    ./tuist-setup.sh
    ```
    or you can prepend them:
    ```
    CF_ACCESS_CLIENT_ID="xxx" CF_ACCESS_CLIENT_SECRET="xxx" ./tuist-setup.sh
    ```
    Options:
    - `--no-open`: Generate the project but do not open Xcode.
    - `--skip-bootstrap`: Skip `bootstrap.sh` (use only if dependencies are already set up).

    _NOTE_ for subsequent runs, appending --skip-bootstrap is faster because it will skip the dependencies
5. In Xcode, select the `Ecosia` or `EcosiaBeta` [scheme](https://developer.apple.com/documentation/xcode/build-system?changes=_2).
6. Select the destination device you want to build on.
7. Run the app with `Cmd + R` or by pressing the **Build and Run** button.

After pulling changes that touch Tuist manifests or dependencies, regenerate the project from the workspace root:

```shell
./tuist-setup.sh --skip-bootstrap --no-open
```

Or from `firefox-ios`: `tuist install --force-resolved-versions` then `tuist generate`.

⚠️ **Important:** If you see dependency issues with SPM:
- Xcode → File → Packages → Reset Package Caches
- Ensure GitHub integration is set up in Xcode (Settings → Accounts → Source Control Accounts).

### 📝 Building User Scripts
-----------------

User Scripts (JavaScript injected into the `WKWebView`) are compiled, concatenated, and minified using [webpack](https://webpack.js.org/). User Scripts to be aggregated are placed in the following directories:

```none
/Client
|-- /Frontend
    |-- /UserContent
        |-- /UserScripts
            |-- /AllFrames
            |   |-- /AtDocumentEnd
            |   |-- /AtDocumentStart
            |-- /MainFrame
                |-- /AtDocumentEnd
                |-- /AtDocumentStart
```

This reduces the total possible number of User Scripts down to four. The compiled output from concatenating and minifying the User Scripts placed in these folders resides in `/Client/Assets` and are named accordingly:

* `AllFramesAtDocumentEnd.js`
* `AllFramesAtDocumentStart.js`
* `MainFrameAtDocumentEnd.js`
* `MainFrameAtDocumentStart.js`

To simplify the build process, these compiled files are checked-in to this repository. When adding or editing User Scripts, these files can be re-compiled with `webpack` manually. This requires Node.js to be installed, and all required `npm` packages can be installed by running `npm install` in the project's root directory. User Scripts can be compiled by running the following `npm` command in the root directory of the project:

```shell
npm run build
```

The `CURRENT_PROJECT_VERSION` being set to `0` indicates that it is not being used for local testing. The outcoming build number is updated by the CI, matching the CI run number (e.g. `8023`).

## 🏅 Get certificates and profiles

```
brew install fastlane
```

Our certs and profiles are managed centrally by [fastlane match](https://docs.fastlane.tools/actions/match/). Find the repo [here](https://github.com/ecosia/IosSearchSigning)

You might need to set up your Ruby stack:
```
sudo gem install bundler:2.3.4
bundle install

# you may need to link your ruby if you have a ruby from brew
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc

# you may need to install a ruby <4
# https://formulae.brew.sh/formula/rbenv
brew install rbenv
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc

rbenv install 3.4.10
rbenv global 3.4.10

```
Run `bundle exec fastlane match --readonly` to add certs and profiles to your system. You can append  `-p "keychain password"` to avoid keychain prompts during the process. The passphrase to decrypt the repo is in Bitwarden under the name: `iOS Fastlane match passphrase`.

**Command:**
```shell
bundle exec fastlane match --readonly
```

**Expected output:**
```text
[...]
[14:22:17]: Passphrase for Match storage: [get the password from the password manager]
```

### Registering new devices

To run the app on a new device, register it on the Apple Developer Portal and re-generate the provisioning profiles using `fastlane match`.

1. Plug in your device and register it via the [`register_devices`](https://docs.fastlane.tools/actions/register_devices/) action. You will be prompted for the device name and UDID:
    ```shell
    bundle exec fastlane run register_device
    ```
2. Re-generate the provisioning profiles to include the new device by running `match` with `--force_for_new_devices` for both **development** (for local development) and **ad hoc** (for Firebase releases):
    ```shell
    bundle exec fastlane match development --force_for_new_devices
    bundle exec fastlane match adhoc --force_for_new_devices
    ```
   This flag makes `match` check whether the device count has changed since the last run and automatically re-generate the provisioning profiles if necessary. See the [fastlane match docs](https://docs.fastlane.tools/actions/match/#registering-new-devices) for more details.
3. Open Xcode, select the **EcosiaBeta** (or **Ecosia**) scheme, choose your device and run (`Cmd + R`).

## Translations

We manage translations using [Transifex](https://docs.transifex.com/client/introduction) and leverage the [Transifex GitHub Integration](https://help.transifex.com/en/articles/6265125-github-installation-and-configuration).

### Workflow

1. **Source Strings:** The engineer adds new English strings to the iOS project and creates a PR.
   > **Tip:** Open the PR early during feature development to kick off translation promptly.
2. **Sync:** Once merged to `main`, Transifex automatically detects and pulls the new strings.
3. **Translation:**
   - **German & French:** Follow [#translations-tier1](https://ecosia-team.slack.com/archives/C04EVKG7MV3).
   - **Other Languages:** Handled via regular Transifex translators or Transifex AI.
4. **Integration:** When a language reaches 100% completion, Transifex automatically opens a PR.
   - The engineer who added the initial source strings should monitor, review, and merge this PR.
   - Translation completeness is also validated during the release flow via CI check.

### Ecosify Mozilla Strings (only needed after upgrade)

We do a rebrand of the Strings from Mozilla. Usually this step is only needed after an upgrade as we keep our changes in version control (as of opposite to Mozilla).
Firefox already imports and versions their strings, which means they will have been added to our codebase once we rebase.
After that, you can use the existing python script to update all strings on the folder containing the project file.

```bash
# brand all the files as they contain the term 'Firefox' a lot
python3 ecosify-strings.py firefox-ios
```

## 🚀 Release

Follow the instructions from our [confluence page](https://ecosia.atlassian.net/wiki/spaces/MOB/pages/2460680288/How+to+release)

### How to update the release notes

Make sure that `fastlane` and `transifex`-cli is installed.

### Add source release notes to transifex (en-US)

> ℹ️ Updating the source file in the project and merging it into `main` will automatically push it to Transifex as well since the Github integration is in place.

> 🔔 Make sure that an _inflight_ version exists in AppStore Connect. If not, create one.

- Create a new branch off `main` and modify the English release notes [here](/fastlane/metadata/en-US/release_notes.txt)
- Open a PR with the modified English release note text file against `main` branch
- Once approved, *Squash and Merge* the code to `main`. (The transifex integration will pick up the push)
- Transifex will create a PR and update it with the release notes in all available languages :hourglass_flowing_sand:
- *Squash and Merge* the code to `main` via a PR and a GitHubAction workflow will be triggered to upload the newly translated release notes 

### Add language translations

- Make sure that all languages are translated in the transifex [web interface](https://app.transifex.com/ecosia/ecosia-ios-search-app/release_notestxt/) and found their way to `main`

- Verify the translations in the Transifex-made PR

- Squash and Merge the PR

- The GitHub Action Workflow `Upload release notes to AppStore` will take care of the upload

#### In case you need a manual update

- Push via the update translation via `deliver` to the AppStore

    ```bash
    bundle exec fastlane deliver --app-version 8.2.0
    ```

### 🌍 L10N Translation Completeness Check

As part of the release pipeline, a quality gate verifies that all localization keys defined in the English source file (`en.lproj/Ecosia.strings`) have corresponding translations for every supported language (German, French, Dutch, Spanish, and Italian). This prevents shipping a release candidate with missing translations that would result in users seeing untranslated English strings.

The check runs automatically in CI before the TestFlight build. If any keys are missing, the pipeline fails with a descriptive error listing the missing keys grouped by language.

**Running the check locally:**

```bash
# From the repository root
bash firefox-ios/Ecosia/L10N/check_translations.sh
```

To run in dry-run mode (report missing translations without failing):

```bash
DRY_RUN=true bash firefox-ios/Ecosia/L10N/check_translations.sh
```

## 🧪 Unit tests

* Run tests against `EcosiaBeta` scheme. With the standard CMD+U it picks the test plan (Xcode)

## ✅ Acceptance testing

Check https://github.com/ecosia/mobile-acceptance-testing for details

## 📸 Snapshot Testing

We built our snapshot testing setup with `SnapshotTestHelper` to streamline UI checks. Here’s the gist:

- **Dynamic Setup**: We create UI components on-the-fly for testing, ensuring they're set up with current data and state.
  
- **Config Flexibility**: The tool handles multiple themes and devices, simulating how UI looks across different environments.

- **Localization**: It supports testing in various languages by adjusting the app’s locale dynamically, crucial for ensuring the UI displays correctly in all supported languages.

- **Comparison**: We capture snapshots of the UI and compare them to reference images to spot any unintended changes.

More details [here](SNAPSHOT_TESTING_WIKI.md)

## Accounts / Signing in

[See our documentation here](https://ecosia.atlassian.net/wiki/spaces/MOB/pages/4800118791/iOS+-+Accounts+integration+setup)
