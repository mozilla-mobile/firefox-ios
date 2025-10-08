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

### 🧼 SwiftLint

We use [SwiftLint](https://github.com/realm/SwiftLint) to enforce Swift style and conventions. Make sure to install it so that linting runs correctly when building.

`brew install swiftlint`

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
2. Install, [Brew](https://brew.sh), Node, and a Python3 virtualenv for localization scripts:
    ```shell
    brew update
    brew install node
    pip3 install virtualenv
    ```
3. Clone the repository:
    ```shell
    git clone https://github.com/ecosia/ios-browser
    ```
4. Install Node.js dependencies, build user scripts and update content blocker:
    ```shell
    cd ios-browser
    sh ./bootstrap.sh
    ```
5. Open `./firefox-ios/Client.xcodeproj` in Xcode.
6. Make sure to select the `Ecosia` [scheme](https://developer.apple.com/documentation/xcode/build-system?changes=_2) in Xcode.
7. Select the destination device you want to build on.
8. Run the app with `Cmd + R` or by pressing the `build and run` button.

⚠️ Important: In case you have dependencies issues with SPM, please try the following:
- Xcode -> File -> Packages -> Reset Package Caches
- This will also require you to have a working github integration set up in xcode (see Settings > Accounts > Source Control Accounts)

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

Our certs and profiles are managed centrally by [fastlane match](https://docs.fastlane.tools/actions/match/). Find the repo [here](https://github.com/ecosia/IosSearchSigning)

Run `bundle exec fastlane match --readonly` to add certs and profiles to your system. You can append  `-p "keychain password"` to avoid keychain prompts during the process. The passphrase to decrypt the repo can be found in LastPass.

### Adding your own device

As we use `fastlane match` to hardwire profiles it gets a bit tricky to add a new device and run the app via your machine.

1. Plugin your device and add it to the portal via XCode-Prompt.
2. Login into [AppDeveloper Portal](https://developer.apple.com/account/)
3. Navigate to `Certificates, Identifiers & Profiles`
4. Select `Profiles`-Tab and find `match Development com.ecosia.ecosiaapp`
5. Edit it and make sure your device is selected
6. Save, download and double click the Profile
7. Now XCode should find it as it's in your keychain
8. Run on Device!

## 🗣️ Translations

We are using [Transifex](https://docs.transifex.com/client/introduction) for managing our translations.

### Install the transifex client using pip

```bash
curl -o- https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash
```

#### Configure your `~/.transifexrc` file

```bash
[https://www.transifex.com]
api_hostname  = https://api.transifex.com
hostname      = https://www.transifex.com
username      = <vault secret>
password      = <vault secret>
rest_hostname = https://rest.api.transifex.com
token         = <vault secret>
```

### Translations need to be pulled and commited manually

Pulling translation from the web

```bash
tx pull -fs
```

Test and commit the new translations. There exists schemes for testing other languages in the simulator.

### Adding new strings

#### Via CLI

1. Pull the source file
2. Add the new strings to the English source file `Client/Ecosia/L10N/en.lproj/Ecosia.strings`
3. Push it to Transifex

```bash
tx pull -fs
tx push -s
```

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

## 📸 Snapshot Testing

We built our snapshot testing setup with `SnapshotTestHelper` to streamline UI checks. Here’s the gist:

- **Dynamic Setup**: We create UI components on-the-fly for testing, ensuring they're set up with current data and state.
  
- **Config Flexibility**: The tool handles multiple themes and devices, simulating how UI looks across different environments.

- **Localization**: It supports testing in various languages by adjusting the app’s locale dynamically, crucial for ensuring the UI displays correctly in all supported languages.

- **Comparison**: We capture snapshots of the UI and compare them to reference images to spot any unintended changes.

More details [here](SNAPSHOT_TESTING_WIKI.md)
