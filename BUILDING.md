Building Firefox for iOS
========================

Prerequisites, as of *May 11 2015*:

* Mac OS X 10.10.3
* Xcode 6.3.1 with the iOS 8.3 SDK
* Carthage 0.7.1 via Homebrew

(We try to keep up to date with the most recent production versions of OS X, Xcode and the iOS SDK.)

When running on a device:

* A device that supports iOS8 or newer
* A developer account and Admin access to the *Certificates, Identifiers & Profiles* section of the *iOS Dev Center*

Get the Code
-----------

```
git clone https://github.com/mozilla/firefox-ios
cd firefox-ios
```

(If you have forked the repository, substitute the URL with your own repository location.)

Pull in Dependencies
--------------------

We use Carthage to manage projects that we depend on. If you do not already have Carthage installed, you need to grab it via Homebrew. Assuming you have Homebrew installed, execute the following:

```
brew update
brew upgrade
brew install carthage
```

You can now execute our `checkout.sh` script:

```
sh ./checkout.sh
```

At this point you have checked out the source code for both the Firefox for iOS project and it's dependencies. You can now build and run the application.

Everything after this point is done from within Xcode.

Run on the Simulator
-----------------

* Open `Client.xcodeproj` and make sure you have the Client scheme and a simulated device selected. The app should run on any simulator. We just have not tested very well on the *Resizable iPad* and *Resizable iPhone* simulators.
* Select *Product -> Run* and the application should build and run on the selected simulator.

Run on a Device
---------------

> Before you try to run the application on a device, it is highly recommended that you first make sure that you can run applications on device in general. Just create one of the built-in iOS templates that Xcode provides and make sure you can run that on your device. If you can then it means you have done the basic setup like pairing your device, registering its UDID in the dev center, etc.

Before you can run the application on your device, you need to setup a few things in the *Certificates, Identifiers & Profiles* section of the iOS Developer Center.


