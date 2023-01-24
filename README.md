# Ecosia for iOS

The iOS Browser that plants trees.

## Getting involved

**!!!** This project cannot be built by anyone outside of Ecosia (yet). **!!!**

There are dependencies that are not fully disclosed and thereby not available for the build. We are working on this. We'll update this note as soon we are able to ship the closed sources in binary form.

## Thank you note

Ecosia for iOS is based on a fork of the code of "Firefox for iOS". We want to express our gratitude to all the original contributors and Mozilla for releasing your code to the world.

## Requirements

- OSX
- Xcode 14.2
- Node

### Optional to build MZ App Services
- Python3
- pip
- virtualenvgyp
- ninja
- rust
- protoc
- tcl
- uniffi-bindgen
- swift-protobuf

This branch works with [Xcode 14.2](https://developer.apple.com/download/more/?=xcode)

## Getting Started

Clone the project.

```bash
git clone git@github.com:ecosia/ios-browser.git
```

For the upcoming commands, cd into the checked out folder
```bash
cd ios-browser/
```

Setup content blocking scripts

```bash
./content_blocker_update.sh
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
