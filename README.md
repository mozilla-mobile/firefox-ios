# Ecosia for iOS

The iOS Browser that plants trees.

## Getting involved

**!!!** This project cannot be built by anyone outside of Ecosia (yet). **!!!**

There are dependencies that are not fully disclosed and thereby not available for the build. We are working on this. We'll update this note as soon we are able to ship the closed sources in binary form.

## Thank you note

Ecosia for iOS is based on a fork of the code of "Firefox for iOS". We want to express our gratitude to all the original contributors and Mozilla for releasing your code to the world.

## Requirements

- OSX
- Xcode 12.4
- Carthage
- Node
- Python3
- pip
- virtualenv
- gyp
- ninja
- rust
- protoc
- tcl
- uniffi-bindgen
- swift-protobuf

This branch works with [Xcode 12.4](https://developer.apple.com/download/more/?=xcode)

### Install Carthage and Node

```bash
brew update
brew install carthage
brew install node
```

### Install python3

Newer versions of macOS come with a compatibility version for python2.7 but it is recommended to upgrade to python3.
Newer versions of Xcode doesn't come with python anymore.
Options:

- Instal via brew
- Download from the [Official site](https://www.python.org/downloads/)

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

### Install virutalenv

```bash
sudo pip install virtualenv
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
git clone git clone git@github.com:ecosia/ios-browser.git
```

Clone the translation files inside your working dir and run the import script.

```bash
#change into folder
cd ios-browser
#clone the repo
git clone https://github.com/mozilla-mobile/ios-l10n-scripts.git
#run the script
./ios-l10n-scripts/import-locales-firefox.sh --release
```

Run npm to include the user scripts

```bash
npm install
npm run build
```

Setup content blocking scripts

```bash
cd content-blocker-lib-ios/ContentBlockerGen && swift run
```

### Building Application Services

To validate that application services can be build locally follow the guide [https://github.com/mozilla/application-services/blob/main/docs/building.md#ios-development](https://github.com/mozilla/application-services/blob/main/docs/building.md#ios-development)

Usually it should work to simply run:

```bash
./carthage_bootstrap_moz_services.sh
```

### Updating dependencies

To update dependencies run:

```bash
./carthage update [optional name] --platform iOS --cache-builds
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
tx pull -af
```

Test and commit the new translations. There exists schemes for testing other languages in the simulator.

### Adding new strings

#### Via CLI

1. Add the new strings to the English source file `Client/Ecosia/L10N/en.lproj/Ecosia.strings`
2. Push it to Transifex

```bash
tx push -s
```

#### Via Transifex Web-Interface

You can update source file in transifex [here](https://www.transifex.com/ecosia/ecosia-ios-search-app/ecosiastrings/). Then once those have been translated you can pull them using the above commands and commit them.
