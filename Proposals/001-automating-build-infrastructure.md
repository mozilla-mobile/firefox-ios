# Automating the Firefox for iOS Build Infrastructure

* Proposal: 001
* Authors: [sleroux](https://github.com/sleroux)
* Status: **Awaiting review**

## Introduction

Producing release builds for Firefox for iOS has always been difficult and usually includes a mix of Python, Fastlane, and the Arcane. Every time we produce builds for our Beta and Release audience, we go through an ever-changing manual process of putting together the archives and sending them out for distribution. I want to de-magic-ify the build process and make it no one's job to produce builds.

Last year, we started to use Buddybuild to generate our development and 'nightly' binaries. It provides a fully automated, zero-configuration way of running our test suites and distributing builds to a limited audience. Unfortunately we are still using our old way of using Fastlane to produce our builds because of the various changes we make to the binary such as icon changes, including our locales, and tagging of releases. 

## Motivation

The current manual process isn't scalable. As we scale our contributors and increase the frequency at which we want to produce releases, the cost of generating a build starts to cut into time which could be used for development. I'd like to see us move to a fully continuous release process where we're producing binaries for review in an automated way to eliminate the review period bottleneck.

It's also not very clear where builds are coming from and where they are going. We currently have 'some' releases tagged on Github but we don't have a place that contains a snapshot of our releases (besides my laptop). If we ever want to improve our crash reporting and error handling we'll need a place to go to for older snapshots of code.

## Proposed solution

### Changes to Localization

Before moving onto Buddybuild, we need a better way of importing our locales into the project. Currently, the localization process takes place inside our Fastlane scripts and performs the following tasks:

1. Setup a Python environment using `virtualenv`
2. Run a SVN export of the current HEAD of the firefox-ios-l10n repo
3. Clean up/remove not-needed locales
4. Convert the `.xliff` files into Xcode `.strings`
5. Modifying the project file to include the new `.strings` files

Steps 3-5 are all done in Python scripts where as 1 and 2 are done through shell scripts.

Part of the reason for this process is when Firefox for iOS was first being developed, the l10n team used SVN for storing their translations. Since then, they've moved to Github and have a release and development branch for in-progress locales. With that in mind, I believe we can now directly include the locales into the project _even during development_ instead of having the locales pulled down only when producing a release.

I propose that we include the `firefox-ios-l10n` repo as a git submodule of our project, add the `.xliff` to `.strings` conversion to our `bootstrap.sh`, and have the locales be referenced in Xcode using groups. This gives us a few wins:

* No longer need to re-download an export of the l10n repo everytime we want new locales.
* The update process for grabbing new locales just uses `git submodule update`
* Developers can use different locales during development to test/debug with
* Eliminates the need for a Python script to cobble up the project file to include our localizations.

In practice, there would be a new root folder in the project named `Locales` with the a subfolder being the l10n submodule and an another folder named `Strings` that contains all of the converted `.xliff` files. Inside Xcode, the `.strings` files would be referenced through a group named `Locales` inside each target folder (`Client/Locales`, `SendTo/Locales`, etc..).

### Using Custom Scripts on Buddybuild

Hidden in the documentation, Buddybuild supports custom scripts that can be run at different times during the build process. These include:

* _buddybuild\_postclone.sh_ - Ran after cloning the project, before Carthage dependencies are downloaded
* _buddybuild\_prebuild.sh_ - Ran after Carthage and just before the build is started
* _buddybuild\_postbuild.sh_ - Ran after the build is complete

Additional information on these scripts can be found here: http://docs.buddybuild.com/docs/custom-prebuild-and-postbuild-steps

Having the ability to run custom scripts on Buddybuild allows us to run some of the custom steps Fastlane performed for us in an automated way. Specifically, I would adapt our current Fastlane lanes to do the following:

* _postclone_
	* Run `update` to fetch updated locales
	* Transform our `.xliffs` into `.strings`
	* Update the app icon with build type, number, commit hash

* _postbuild_
	* Upload the built archive and symbols to a Mozilla archive server 
	* Send a Slack/IRC notification

### Scheme/Project Changes 

The only major change I would make is rename the current `FennecEnterprise` scheme to `Fennec` and eliminate the old `Fennec` scheme. The only difference between the two is the team they are built from. As long as everyone on the team is part of the enterprise account this shouldn't change anything.

I'd also like to remove some of the magic from the build and either reduce or eliminate our `.xcconfig` file usage. Buddybuild has a way to store custom user variables [securely](http://docs.buddybuild.com/docs/custom-prebuild-and-postbuild-steps#section-user-defined-variables). We could store our API keys on there and have them injected at build time and move the remaining keys back into the project settings.

Lastly, I would also migrate the project to use manual management of provisioning profiles. Our profiles keep getting invalidated on the developer portal everytime an admin builds and changes schemes because Xcode will automatically try to fix which app group the target is using. This usually results in all of our profiles using the Fennec app group. Moving to manual profile management would require explicit invalidating and re-generating of profiles when new devices are added but since we use an enterprise cert for Buddybuild and Test Flight for Beta users, I don't see us updating our device list frequently. It would also be nice to know exactly what caused an invalidation of the profile instead of Xcode doing it behind the scenes.

### Scheduling

With those pieces in place, we would be able to use Buddybuild's scheduling to produce builds automatically with no developer intervention. I would setup various scheduled builds on given dates to give us some predicatiblity when a build is available. Additionally, we can produce release builds on a weekly cadence and have them automatically sent to the app store for review. By continuously submitting, we'll always have a build ready to go in the queue when we feel like releasing and have piece-of-mind that the code we produced passed review.

## Alternatives considered

* Using Fastlane. This would require us to setup crontabs and manage the scripts with newer Xcode releases which we get for free on Buddybuild. We get the benefit of having more customization but with the cost of upkeep.
* Xcode Server. Would also require more custom scripts and build management. Also requires dedicated hardware for running the server on.
* Ask Steph to make a build :(
