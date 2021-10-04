# Localization

The following document gives a step by step guide for the string localization process. This process has a lot of quirks: it is a work in progress - both this document and the process itself.

## Overview

These are the steps to take for localization. Setup, requirements, and more details on importing & exporting can be found below.

1. Pull `firefoxios-l10n` so the `master` branch is up to date
2. Create separate branch off `main` in `firefox-ios` repo
3. Import strings using localization tools
4. Make a PR to `main` and merge when approved
5. Create a new branch from `main` and therein add new strings
6. Create a new branch from `master` and then export using localization tools
7. Make a PR to `master` in `firefox-l10n` from your fork
8. After comments are addressed, admin will merge
9. Wait for translations to come in and be notified
10. Pull master from `firefoxios-l10n'
11. In your string branch on the `firefox-ios` repo, do an import
12. Make a PR to `main`

## Topics

### Requirements
This following repos are the required to run the localization process.

* [firefoxios-l10n](https://github.com/mozilla-l10n/firefoxios-l10n) - you'll need both the main repo as well as your own fork
* [LocalizationTools](https://github.com/mozilla-mobile/LocalizationTools)
* [Firefox iOS](https://github.com/mozilla-mobile/firefox-ios)

A note on this process. If you run `sh ./bootstrap.sh --importLocales` this will bootstrap the main Firefox-iOS repo *and* also download the localization tools and l10n repo in the firefox-ios folder and you don't have to do it manually.

You can also do this manually, of course, and place theme wherever is comfortable for you. Either way, note the location of the l10n repo as you will need it later.

### Setup

Now that you have everything you need, here are the steps you need to take for localization.

* When you begin the process always pull the latest `firefoxios-l10n` `master` branch. This ensures that you have the latest strings from translators before you do an export and prevents discrepancies when we're exporting.
* Open the LocalizationTools project. If you have an error, you might need to adjust the `swift-tools-version`, located in ``Package.swift``. Either upgrade or downgrade it depending on your `swift-tools-version`. As of Sep 2021, 5.4 will work fine.
* Now, click `Edit scheme...` and select the `Run` scheme.
* Add arguments to the scheme (show below) to configure what you're doing

    --project-path <project-path> Sets the project path to firefox-ios. This should point to wherever your Client.xcodeproj is, and specify the project file in the path as well.
    --l10n-project-path <l10n-project-path> Sets the path to the firefoxios-l10n repo.
    --export/import Depending on whether you want to run an export/import task
    --version show the version
    --help show help information


### Imports

*Note: Even if your goal is to export, you still need to import first. This ensure that string translation fixes for existing strings are present during the export.*

After setting the arguments above, let it run with the `--import` argument. Importing will take a while. Be aware that you'll see lots of errors & warnings in the console. You can ignore these - it won't affect your import process.

After the process is complete, you'll see a list of files modified in your `firefox-ios` repo. If your goal was to import newly available/translated strings, you can commit the necessary files and create a PR on `firefox-ios`.

### Exports

*Note: Imports need to happen before you do an export! Follow the process above and come back here after.*

* Be sure that new string comments are understandable to localizers. Make sure comments are descriptive and don't rely on knowing the context of the new string.
* Here, we'll switch to the `--export` argument
    * Note: Importing will result in changes in `firefox-ios`. Exporting will result in changes in `firefoxios-l10n`.
* Each locale modification will need a separate commit. You can use this bash script (for now)

```
#! /usr/bin/env bash

locale_list=$(find . -mindepth 1 -maxdepth 1 -type d  \( ! -iname ".*" \) | sed 's|^\./||g' | sort)
for locale in ${locale_list};
do
    git add ${locale}/${l10n_file}
    git commit -m "${locale}: Update ${l10n_file}"
done
```

* Push your branch to your fork
* Make a PR to FireFoxiOS-l10n repo master
* Once the PR has been approved, merge
* Once we are notified that the strings have been translated, we'll have to do another import on a branch off of main in the firefox-ios repo
* Make a PR and double check that everything shows up correctly

### Addressing Comments

The L10N team may give you some edits and you're wondering what's the best way to fix and push? The gist is that you have to redo the export process and force push. Here are steps:

* Find the last commit on master before all your commits were added.
* To delete commits up to that commit, run git reset --hard <commit-hash>.
* With your fixes now ready, run the export and the bash script again.
* Force push to your branch.

Finally, make sure to notify the L10N team about updates!
