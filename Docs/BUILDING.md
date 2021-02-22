Building Firefox for iOS
========================

Prerequisites, as of *February 20, 2020*:

* Mac OS X 10.15
* Xcode 11.3, Swift 5.1.3, and the iOS 11 SDK (Betas not supported)
* Carthage 0.15 or newer

When running on a device:

* A device that supports iOS 9.3 GM or later
* One of the following:
 * A developer account and Admin access to the *Certificates, Identifiers & Profiles* section of the *iOS DevCenter*
 * A free developer account (create an Apple ID for free and add as an account in Xcode)

Get the Code
-----------

```
git clone https://github.com/mozilla/firefox-ios
cd firefox-ios
```

(If you have forked the repository, substitute the URL with your own repository location.)

Pull in Dependencies
--------------------

We use Carthage to manage projects that we depend on. __The build will currently only work with Carthage v0.15 or newer__. If you do not already have Carthage installed, you need to grab it via Homebrew. Assuming you have Homebrew installed, execute the following:

```
brew update
brew upgrade
brew install carthage
```

You can now execute our `bootstrap.sh` script:

```
./bootstrap.sh
```

At this point you have checked out the source code for both the Firefox for iOS project and built it's dependencies. You can now build and run the application.

Everything after this point is done from within Xcode.

Pointing to Local Rust Components (Application Services)
--------------------

Firefox for iOS depends internally on some of the [shared Rust components](https://github.com/mozilla/application-services). Sometimes, you may want to also point to your local Rust components when building locally. You can do so by:

1. First ensure you can [build application-services](https://github.com/mozilla/application-services/blob/main/docs/building.md) locally.
2. Next, `carthage build --no-skip-current --platform iOS --verbose --configuration Debug --cache-builds`.
3. Now back in firefox-ios, after `carthage bootstrap`, replace the application-services library with a symlink:

  ```
  rm -rf Carthage/Build/iOS/MozillaAppServices.framework
  ln -s ~/REPLACE_WITH_PATH_TO_YOUR_LOCAL_CHECKOUT/application-services/Carthage/Build/iOS/MozillaAppServices.framework Carthage/Build/iOS
  ```

4. Build firefox-ios.

Every time you make a change to application-services, re-run the carthage build command shown in step #2.

Run on the Simulator
-----------------

* Open `Client.xcodeproj` and make sure you have the *Fennec* scheme and a simulated device selected. The app should run on any simulator. We just have not tested very well on the *Resizable iPad* and *Resizable iPhone* simulators.
* Select *Product -> Run* and the application should build and run on the selected simulator.

Run on a Device with Xcode 11.3 and a Free Developer Account
---------------

> Only follow these instructions if you are using the free personal developer accounts. Simply add your Apple ID as an account in Xcode.

Since the bundle identifier we use for Firefox is tied to our developer account, you'll need to generate your own identifier and update the existing configuration.

1. Open Client/Configuration/Fennec.xcconfig
2. Change MOZ_BUNDLE_ID to your own bundle identifier. Just think of something unique: e.g., com.your_github_id.Fennec
3. Open the project editor in Xcode.
4. For the 'Client' target, in the 'Capabilities' section, turn off the capabilities 'Push Notifications' and 'Wallet'.
5. For each target, in the 'General' section, under 'Signing', select your personal development account.

If you submit a patch, be sure to exclude these files because they are only relevant for your personal build.

> If after building, Xcode fails to run the app with a vague `Security` error, open Settings -> Profiles on your iOS Device and Trust your personal developer profile. This may only happen on iOS 9.

Run on a Device
---------------

These are instructions for development. Not production / distribution.

> Before you try to run the application on a device, it is highly recommended that you first make sure that you can run applications on device in general. Just create one of the built-in iOS templates that Xcode provides and make sure you can run that on your device. If you can then it means you have done the basic setup like pairing your device, registering its UDID in the dev center, etc.

Before you can run the application on your device, you need to setup a few things in the *Certificates, Identifiers & Profiles* section of the iOS Developer Center.

> _Note_: When we mention `YOURREVERSEDOMAIN` below, use your own domain in reverse notation like `com.example` or if you do not have your own domain, just use something unique and personal like `io.github.yourgithubusername`. Please do not use existing domain names which you do not own.

1. Create a Application Group. Name this group 'Fennec' and for its Identifier use `group.YOURREVERSEDOMAIN.Fennec`
2. Create a new App Id. Name it 'Fennec'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.Fennec`. In the App Services section, select *App Groups*.
3. Create a new App Id. Name it 'Fennec ShareTo'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.Fennec.ShareTo`. In the App Services section, select *App Groups*.
4. Create a new App Id. Name it 'Fennec SendTo'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.Fennec.SendTo`. In the App Services section, select *App Groups*.
5. Create a new App Id. Name it 'Fennec ViewLater'. Give it an Explicit App ID and set its Bundle Identifier to `YOURREVERSEDOMAIN.Fennec.ViewLater`. In the App Services section, select *App Groups*.
6. For all App Ids that you just created, edit their App Groups and make sure they are all part of the Fennec App Group that you created in step 1.

Now we are going to create three Provisioning Profiles that are linked to the App Ids that we just created:

1. Create a new *Development Provisioning Profile* and link it to the *Fennec* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *Fennec*.
2. Create a new *Development Provisioning Profile* and link it to the *Fennec SendTo* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *Fennec SendTo*.
3. Create a new *Development Provisioning Profile* and link it to the *Fennec ShareTo* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *Fennec ShareTo*.
4. Create a new *Development Provisioning Profile* and link it to the *Fennec ViewLater* App ID that you created. Select the *Developer Certificates* and *Devices* that you wish to include in this profile. Finally, name this profile *Fennec ViewLater*.

Now go to Xcode, *Preferences -> Accounts* and select your developer account. Hit the *View Details* button and then press the little reload button in the bottom left corner. This should sync the Provisioning Profiles and you should see the three profiles appear that you creates earlier.

Almost done. The one thing missing is that we need to adjust the build configuration to use your new bundle identifier.

1. Open Client/Configuration/Fennec.xcconfig
2. Change MOZ_BUNDLE_ID to `YOURREVERSEDOMAIN`.
3. Navigate to each of the application targets (Client/SendTo/ShareTo/ViewLater) and your developer account.

Before building, do *Product -> Clean Build Folder* (option-shift-command-k)

You should now be able to build the *Fennec* scheme and run on your device.

We would love a Pull Request for a smarter Xcode project configuration or even a shell script that makes this process simpler.


Random notes
------------

## Updating SQLCipher.

As of [Bug 1182620](https://bugzilla.mozilla.org/show_bug.cgi?id=1182620) we do not run the SQLCipher 'amalgamation' phase anymore. Instead we have simply included generated copies of `sqlite3.c`, `sqlite3.h` and `sqlite3ext.h` in the project. This works around problems where the amalgamation phase did not work for production builds. It also speeds up things.

To update to a newer version of SQLCipher: check out the original SQLCipher project and build it. Do not copy the project or anything in the Firefox project. Just follow their instructions. Then copy the above three `.c` and `.h` files back into the Firefox project. Also update the `README`, `VERION` and `CHANGELOG` files from the original distribution so that we know what version we have included.

Building involves:

```
$ brew install openssl              # Or upgrade.
$ ./configure --enable-tempstore=yes \
CFLAGS="-I/usr/local/Cellar/openssl/1.0.2n/include -DSQLITE_HAS_CODEC" \
LDFLAGS="-lcrypto"
$ make
$ cp sqlite3{.c,.h,ext.h} README.md VERSION CHANGELOG.md ~/path/to/firefox-ios/ThirdParty/sqlcipher
```
