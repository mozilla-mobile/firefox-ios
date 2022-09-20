# Ecosia for iOS

The iOS Browser that plants trees.

## Getting involved

**!!!** This project cannot be built by anyone outside of Ecosia (yet). **!!!**

There are dependencies that are not fully disclosed and thereby not available for the build. We are working on this. We'll update this note as soon we are able to ship the closed sources in binary form.

## Thank you note

Ecosia for iOS is based on a fork of the code of "Firefox for iOS". We want to express our gratitude to all the original contributors and Mozilla for releasing your code to the world.

## Requirements

- OSX
- Xcode 13.0
- Carthage
- Node
- Python3
- pip
- virtualenv

### Optional to build MZ App Services
- gyp
- ninja
- rust
- protoc
- tcl
- uniffi-bindgen
- swift-protobuf

This branch works with [Xcode 13.0](https://developer.apple.com/download/more/?=xcode)

### Install Carthage, Node, VirtualEnv and python3 (mandatory)

```bash
brew update
brew install carthage
brew install node
brew install virtualenv
brew install python3
```

If you don't plan to build Mozilla App Services, skip to [Getting Started](#Getting-started).

### Install pip

Pip comes with python but it might not be found if you have multiple version of python installed.
Check if pip is found

```bash
python -m pip --version
```

If there is an error run

```bash
sudo python2.7 -m ensurepip --default-pip
```

### Install GYP

If building application-services dependency gyp needs to be installed [https://github.com/mogemimi/pomdog/wiki/How-to-Install-GYP](https://github.com/mogemimi/pomdog/wiki/How-to-Install-GYP)

### Install ninja

If building application-services dependency ninja needs to be installed [https://github.com/ninja-build/ninja](https://github.com/ninja-build/ninja)

### Install rust

If building application-services dependency rust needs to be installed [https://www.rust-lang.org/tools/install](https://www.rust-lang.org/tools/install)

### Install protoc

If building application-services dependency protoc needs to be installed [https://google.github.io/proto-lens/installing-protoc.html](https://google.github.io/proto-lens/installing-protoc.html)

### Install tcl

If building application-services dependency tcl needs to be installed [https://www.tcl.tk/software/tcltk/](https://www.tcl.tk/software/tcltk/)

### Install uniffi-bindgen

If building application-services dependency uniffi-bindgen needs to be installed

```bash
cargo install uniffi_bindgen
```

### Install swift-protobuf

If building application-services dependency swift-protobuf needs to be installed [https://github.com/apple/swift-protobuf](https://github.com/apple/swift-protobuf)

## Getting Started

Clone the project.

```bash
git clone git@github.com:ecosia/ios-browser.git
```

For the upcoming commands, cd into the checked out folder
```bash
cd ios-browser/
```

Run npm to include the user javascripts

```bash
npm install
npm run build
```

Setup content blocking scripts

```bash
(cd content-blocker-lib-ios/ContentBlockerGen && swift run)
```

### Building Application Services

To validate that application services can be build locally follow the guide [https://github.com/mozilla/application-services/blob/main/docs/building.md#ios-development](https://github.com/mozilla/application-services/blob/main/docs/building.md#ios-development)

Make sure to have XCode 13.0 installed and selected for command line builds

```bash
sudo xcode-select --switch /<path-to-XCode-13.0-folder>/Xcode-13.0.app
```

Then fetch Mozilla App Services via the script:

```bash
./carthage_bootstrap_moz_services.sh
```

### Updating dependencies (not needed on first run)

To update dependencies run:

```bash
./carthage update [optional name] --platform iOS --cache-builds
```

### Open the project

```bash
open Client.xcodeproj
```

## TRANSLATIONS

We are using [Transifex](https://docs.transifex.com/client/introduction) for managing our translations.

### Install the transifex client using pip

```bash
sudo pip3 install transifex-client
```

#### Configure your `.transifexrc` file

```bash
[https://www.transifex.com]
hostname = https://www.transifex.com
password = ...
username = ...
```

### Translations need to be pulled and commited manually

Pulling translation from the web

```bash
tx pull -afs
```

Test and commit the new translations. There exists schemes for testing other languages in the simulator.

### Adding new strings

#### Via CLI

1. Pull the source file
2. Add the new strings to the English source file `Client/Ecosia/L10N/en.lproj/Ecosia.strings`
3. Push it to Transifex

```bash
tx pull -afs
tx push -s
```

#### Via Transifex Web-Interface

You can update source file in transifex [here](https://www.transifex.com/ecosia/ecosia-ios-search-app/ecosiastrings/). Then once those have been translated you can pull them using the above commands and commit them.

### Update Mozilla Strings (if needed)

```bash
# clone the repo
git clone https://github.com/mozilla-mobile/ios-l10n-scripts.git
# run the script in project-dir
./ios-l10n-scripts/import-locales-firefox.sh --release
```

```bash
# brand all the files as they contain the term 'Firefox' a lot
python3 ecosify-strings.py Client
python3 ecosify-strings.py Extensions
python3 ecosify-strings.py Shared
```
## Release 🚀

Follow the instructions from our [confluence page](https://ecosia.atlassian.net/wiki/spaces/MOB/pages/2460680288/How+to+release)
