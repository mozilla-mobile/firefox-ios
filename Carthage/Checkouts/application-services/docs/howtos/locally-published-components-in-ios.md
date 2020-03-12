# Using locally-published components in Firefox for iOS

It's often important to test work-in-progress changes to this repo against a real-world
consumer project. Here are our current best-practices for approaching this on iOS:

1. Make a local build of the application-services framework using `./build-carthage.sh`.
1. Checkout and `carthage bootstrap` the consuming app (for example using [these instructions with Firefox for
   iOS](https://github.com/mozilla-mobile/firefox-ios#building-the-code)).
1. In the consuming app, replace the application-services framework with a symlink to your local build. For example:

   ```
   rm -rf Carthage/Build/iOS/MozillaAppServices.framework
   ln -s path/to/application-services/Carthage/Build/iOS/Static/MozillaAppServices.framework Carthage/Build/iOS
   ```
1. Open the consuming app project in XCode and build it from there.

After making changes to application-services code, re-run `./build-carthage.sh` and then rebuild
the consuming app. You may need to clear the XCode cache using Cmd+k if the app doesn't seem to pick up your changes.
