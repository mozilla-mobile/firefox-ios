# Ecosia for iOS

The iOS Browser that plants trees.

## Getting involved

**!!!** This project cannot be built by anyone outside of Ecosia (yet). **!!!**

There are dependencies that are not fully disclosed and thereby not available for the build. We are working on this. We'll update this note as soon we are able to ship the closed sources in binary form.

## Thank you note

Ecosia for iOS is based on a fork of the code of "Firefox for iOS". We want to express our gratitude to all the original contributors and Mozilla for releasing your code to the world.

## Building

-----------------
This branch works with [Xcode 14.2](https://developer.apple.com/download/more/?=xcode)

1. Install the latest [Xcode developer tools](https://developer.apple.com/download/applications/) from Apple.
1. Install, [Brew](https://brew.sh), Node, and a Python3 virtualenv for localization scripts:

    ```shell
    brew update
    brew install node
    pip3 install virtualenv
    ```

1. Clone the repository:

    ```shell
    git clone git@github.com:ecosia/ios-browser.git
    ```

1. Install Node.js dependencies, build user scripts and update content blocker:

    ```shell
    cd ios-browser
    sh ./bootstrap.sh
    ```

1. Open the project

    ```bash
    open Client.xcodeproj
    ```

### CI/CD

Fastlane is used to push builds to the Appstore and to manage our certs and profiles. Follow the [docs](https://docs.fastlane.tools/getting-started/ios/setup/) to install. We recommend to use fastlane with bundler.

```shell
gem install bundler
bundle update
```

#### Get certificates and profiles

Our certs and profiles are managed centrally by [fastlane match](https://docs.fastlane.tools/actions/match/).

Find the repo is [here](https://github.com/ecosia/IosSearchSigning)

Run `bundle exec fastlane match --readonly` to add certs and profiles to your system. You can append  `-p "keychain password"` to avoid keychain prompts during the proces

#### Adding your own device

As we use `fastlane match` to hardwire profiles it gets a bit tricky to add a new device and run the app via your machine.

1. Plugin your device and add it to the portal via XCode-Prompt.
2. Login into [AppDeveloper Portal](https://developer.apple.com/account/)
3. Navigate to `Certificates, Identifiers & Profiles`
4. Select `Profiles`-Tab and find `match Development com.ecosia.ecosiaapp`
5. Edit it and make sure your device is selected
6. Save, download and double click the Profile
7. Now XCode should find it as it's in your keychain
8. Run on Device!

## TRANSLATIONS

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

### Update Mozilla Strings (only needed after upgrade)

We do a rebrand of the Strings from Mozilla. Usually this step is only needed after an upgrade as we keep our changes in version control (as of opposite to Mozilla).
First we need to import all the strings via the scripts:

```bash
# clone the repo
git clone https://github.com/mozilla-mobile/ios-l10n-scripts.git
# run the script in project-dir
./ios-l10n-scripts/import-locales-firefox.sh --release
```

After import we rebrand (aka "ecosify")

```bash
# brand all the files as they contain the term 'Firefox' a lot
python3 ecosify-strings.py Client
python3 ecosify-strings.py Extensions
python3 ecosify-strings.py Shared
```

## Release 🚀

Follow the instructions from our [confluence page](https://ecosia.atlassian.net/wiki/spaces/MOB/pages/2460680288/How+to+release)
