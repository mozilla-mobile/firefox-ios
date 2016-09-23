### Version 4.10.1 (12th September 2016)
#### Changed
- Revert deployment target to iOs 6.0 

#### Fixed
- Remove NSURLSessionConfiguration with backgroundSessionConfigurationWithIdentifier

--

### Version 4.10.0 (8th September 2016)
#### Changed
- SDK updated due to an update to the Apple App Store Review Guidelines (https://developer.apple.com/app-store/review/guidelines/ chapter 5.1.1 iv).
- Removed functionality of `sendAdWordsRequest` method because of the reason mentioned above.

### Version 4.9.0 (7th September 2016)
#### Added
- Added `ADJLogLevelSuppress` to disable all log output messages.
- Added possibility to delay the start of the first session.
- Added support for session parameters which are going to be sent with each session/event:
    - Callback parameters
    - Partner parameters
- Added sending of install receipt.
- Added iOS 10 compatibility.
- Added `AdjustSdkTv.framework` to releases page.

#### Changed
- Deferred deep link info is now delivered as part of the `attribution` answer from the backend.
- Removed optional `adjust_redirect` parameter from resulting URL string when using `convertUniversalLink:scheme` method.
- Normalized properties attributes.
- Changed naming of background blocks.
- Using `weakself strongself` pattern for background blocks.
- Moving log level to the ADJConfig object.
- Accessing private properties directly when copying.
- Removed static framework build with no Bitcode support from releases page.
- Updated docs.
 
#### Fixed
- Allow foreground/background timer to work in offline mode.
- Use `synchronized` blocks to prevent write deadlock/contention.
- Don't create/use background timer if the option is not configured.
- Replace strong references with weak when possible.
- Use background session configuration for `NSURLSession` when the option is set.

--

### Version 4.8.5 (30th August 2016)
#### Fixed
- Not using `SFSafariViewController` on iOS devices with iOS version lower than 9.

---

### Version 4.8.4 (18th August 2016)
#### Added
- Added support for making Google AdWords request in iOS 10.

---

### Version 4.8.3 (10th August 2016)
#### Added
- Added support to convert shorten universal links.

---

### Version 4.8.2 (5th August 2016)
#### Fixed
- Added initialisation of static vars to prevent dealloc.

---

### Version 4.8.1 (3rd August 2016)
#### Added
- Added Safari Framework in the example app.

### Fixed
- Replaced sleeping background thread with delayed execution.

---

### Version 4.8.0 (25th July 2016)
#### Added 
- Added tracking support for native web apps (no SDK version change).

### Changed
- Updated docs.

---

### Version 4.8.0 (18th July 2016)
#### Added 
- Added `sendAdWordsRequest` method on `Adjust` instance to support AdWords Search and Mobile Web tracking.

---

### Version 4.7.3 (12th July 2016)
#### Changed
- Added #define for `CPUFAMILY_INTEL_YONAH` due to its deprecation in iOS 10.
- Added #define for `CPUFAMILY_INTEL_MEROM` due to its deprecation in iOS 10.

---

### Version 4.7.2 (9th July 2016)
#### Changed
- Re-enabled SDK auto-start upon initialisation.

---

### Version 4.7.1 (20th June 2016)
#### Added
- Added `CHANGELOG.md` to repository.

#### Fixed
- Re-added support for `iOS 8.0` as minimal deployment target for dynamic framework.

---

### Version 4.7.0 (22nd May 2016)
#### Added
- Added `adjustDeeplinkResponse` method to `AdjustDelegate` to get info when deferred deep link info is received.
- Added possibility to choose with return value of `adjustDeeplinkResponse` whether deferred deep link should be launched or not.
- Added sending of full deep link with `sdk_click` package.

#### Changed
- Updated docs.
- Disabled SDK auto-start upon initialisation.
- Added separate handler for `sdk_click` which is sending those packages immediately after they are created.

#### Fixed
- Fixed situation where SDK does not start immediately when is put to enabled/disabled or online/offline mode.

---

### Version 4.6.0 (15th March 2016)
#### Added
- Added `adjustEventTrackingSucceeded` method to `AdjustDelegate` to get info when event is successfully tracked.
- Added `adjustEventTrackingFailed` method to `AdjustDelegate` to get info when event tracking failed.
- Added `adjustSessionTrackingSucceeded` method to `AdjustDelegate` to get info when session is successfully tracked.
- Added `adjustSessionTrackingFailed` method to `AdjustDelegate` to get info when session tracking failed.

#### Changed
- Updated docs.

---

### Version 4.5.4 (5th February 2016)
#### Added
- Added method for conversion from universal to old style custom URL scheme deep link.

#### Changed
- Updated docs.

#### Fixed
- Fixed documentation warning.
- Fixed `-fembed-bitcode` warnings.

---

### Version 4.5.3 (3rd February 2016)
#### Added
- Added Bitcode flag for static library.

---

### Version 4.5.2 (1st February 2016)
#### Added
- Added `idfa` method on `Adjust` instance to get access to device's `IDFA` value.

#### Changed
- Updated docs.

---

### Version 4.5.1 (20th January 2016)
#### Added
- Added decoding of deep link URL.

---

### Version 4.5.0 (9th December 2015)
#### Added
- Added support for `Carthage`.
- Added dynamic framework SDK target called `AdjustSdk.framework`.
- Added option to forget device from example apps in repository.

#### Changed
- Improved iAd logging.
- Changed name of static framework from `Adjust.framework` to `AdjustSdk.framework`.
- Changed `Adjust` podspec iOS deployment target from `iOS 5.0` to `iOS 6.0`.
- Updated and redesigned example apps in repository.
- Updated docs.

---

### Version 4.4.5 (7th December 2015)
#### Added
- Added support for `iAd v3`.

---

### Version 4.4.4 (30th November 2015)
#### Changed
- Updated `Criteo` plugin to send deep link information.
- Updated docs.

---

### Version 4.4.3 (16th November 2015)
#### Added
- Added support for `Trademob` plugin.

#### Changed
- Updated docs.

---

### Version 4.4.2 (13th November 2015)
#### Added
- Added `Bitcode` support by default.

#### Changed
- Changed minimal target for SDK to `iOS 6`.
- Removed reading of `MAC address`.

#### Fixed
- Fixed tvOS macro for iAd.

---

### Version 4.4.1 (23rd October 2015)
#### Fixed
- Replaced deprecated method `stringByAddingPercentEscapesUsingEncoding` in `Criteo` plugin due to `tvOS` platform.
- Added missing ADJLogger.h header to public headers in static framework.

---

### Version 4.4.0 (13th October 2015)
#### Added
- Added support for `tvOS apps`.
- Added new example apps to repository.

#### Changed
- Updated docs.

#### Fixed
- Removed duplicated ADJLogger.h header in static framework.
- Removed code warnings.

---

### Version 4.3.0 (11th September 2015)
#### Fixed
- Fixed errors on `pre iOS 8` due to accessing `calendarWithIdentifier` method.

---

### Version 4.2.9 (10th September 2015)
#### Changed
- Changed deployment target to `iOS 5.0`.
- Changed delegate reference to be `weak`.
- Replaced `NSURLConnection` with `NSURLSession` for iOS 9 compatibility.

#### Fixed
- Fixed errors with not default date settings.

---

### Version 4.2.8 (21st August 2015)
#### Added
- Added sending of short app version field.

#### Changed
- Updating deep linking handling to be comaptible with iOS 9.
- Updated docs.

#### Fixed
- Fixed memory leak caused by timer.

---

### Version 4.2.7 (30th June 2015)
#### Added
- Added `Sociomantic` plugin `partner ID` parameter.

#### Changed
- Updated docs.

#### Fixed
- Fixed display of revenue values in logs.

---

### Version 4.2.6 (24th June 2015)
#### Changed
- Refactoring to sync with the Android SDK.
- Renamed conditional compilation flag to ADJUST_NO_IAD
- Lowering number of requests to get attribution info.
- Various stability improvements.

---

### Version 4.2.5 (5th June 2015)
#### Added
- Added `Sociomantic` plugin parameters encoding.
- Added new optional `Criteo` plugin `partner ID` parameter.

#### Changed
- Moving `Criteo` and `Sociomantic` plugins in different subspecs.
- Updated docs.

---

### Version 4.2.4 (12th May 2015)
#### Added
- Support for Xamarin SDK bindings.

---

### Version 4.2.3 (30th April 2015)
#### Added
- Added sending of empty receipts.

#### Changed
- Added prefix to `Sociomantic` plugin parameters to avoid possible ambiguities.
- Updated `Criteo` plugin.
- Updated docs.

#### Fixed
- Remove warnings about missing iAd dependencies.

---

### Version 4.2.2 (22nd April 2015)
#### Added
- Added method `setDefaultTracker` to enable setting of default tracker for apps which were not distributed through App Store.

#### Changed
- Updated docs.

#### Fixed
- Removed XCode warnings issues (#96).
- Fixed Swift issue (#74).
- Fixed framework and static library builds.

---

### Version 4.2.1 (16th April 2015)
#### Fixed
- Preventing possible JSON string parsing exception.

---

### Version 4.2.0 (9th April 2015)
#### Added
- Added the click label parameter in attribution response object.

#### Changed
- Updated docs.

---

### Version 4.1.1 (31st March 2015)
#### Added
- Added support for `Sociomantic`.
- Added framework target with support for all architectures.

#### Changed
- Updated docs.

---

### Version 4.1.0 (27th March 2015)
#### Added
- Added server side In-App Purchase verification support.

#### Changed
- Updated docs.

---

### Version 4.0.8 (23rd March 2015)
#### Changed
- Updated `Criteo` plugin.

#### Changed
- Updated docs.

---

### Version 4.0.7 (2nd March 2015)
#### Added
- Added support for `Criteo`.

#### Changed
- Updated docs.

---

### Version 4.0.6 (6th February 2015)
#### Fixed
- Fixed deep link attribution.
- Fixed iAd attribution.

---

### Version 4.0.5 (5th January 2015)
#### Added
- Added `categories` to static SDK library.

#### Changed
- Improved iAd handling (check if iAd call is available instead of trying it with exception handling).

---

### Version 4.0.4 (15th December 2014)
#### Changed
- Removed iAd click sending from events.
- Removed warning when delegate methods are not being set.

#### Fixed
- Prevent errors once migrating class names.

---

### Version 4.0.3 (13th December 2014)
#### Added
- Added deep link click time.

#### Changed
- Changed `ADJConfig` fields `appToken` and `environment` to be `readonly`.
- Removed `CoreTelephony.framework` and `SystemConfiguration.framework`.
- Updated unit tests.
- Updated docs.

---

### Version 4.0.2 (10th December 2014)
#### Fixed
- Fixed problems with reading activity state.

---

### Version 4.0.1 (9th December 2014)
#### Fixed
- Fixed problems with adding callback and partner parameters to the events.

---

### Version 4.0.0 (8th December 2014)
#### Added
- Added config object used for SDK initialisation.
- Added possibility send currency together with revenue in the event.
- Added posibility to track parameters for client callbacks.
- Added posibility to track parameters for partner networks.
- Added `setOfflineMode` method to allow you to put SDK in offline mode.

#### Changed
- Replaced `Response Data delegate` with `Attribution changed delegate`.
- Updated docs.

---

### Version 3.4.0 (17th July 2014)
#### Added
- Added support for handling deferred deep links.

#### Changed
- Removed static dependancy on `ADClient`.

---

### Version 3.3.5 (3rd July 2014)
#### Added
- Added support to send push notification token.

#### Changed
- Updated docs.

---

### Version 3.3.4 (19th June 2014)
#### Added
- Added tracker information to response data.
- Addded support for `Mixpanel`.

#### Changed
- Updated docs.

---

### Version 3.3.3 (13th June 2014)
#### Fixed
- Re-added support to `iOS 5.0.1` devices by sending `vendor ID` only if possible.

---

### Version 3.3.2 (27th May 2014)
#### Added
- Added Javascript bridge for native web apps.

#### Changed
- Updated docs.

---

### Version 3.3.1 (2nd May 2014)
#### Added
- Added `iAd.framework` support.
- Added sending of `vendor ID`.

#### Changed
- Updated docs.

---

### Version 3.3.0 (16th April 2014)
#### Added
- Added handling of `deep link` parameters.

#### Changed
- Updated docs.

---

### Version 3.2.1 (9th April 2014)
#### Changed
- Dependency to `AdSupport.framework` is now set to `weak`.

---

### Version 3.2.0 (7th April 2014)
#### Added
- Added `setEnabled` method to enable/disable SDK.
- Added `isEnabled` method to check if SDK is enabled or disabled.

#### Changed
- Updated docs.

---

### Version 3.1.0 (4th March 2014)
#### Added
- Added possibility to pass `transactionId` to the event once tracking In-App Purchase revenue.

#### Changed
- Updated docs.

---

### Version 3.0.0 (14th February 2014)
#### Added
- Added delegate method to support in-app source access.
- Added unit tests.

#### Changed
- Renamed `AdjustIo` to `Adjust`.
- Refactored code.
- Various stability improvements.
- Updated docs.

---

### Version 2.2.0 (4th February 2014)
#### Added
- Added reading of `UUID`.

#### Changed
- Updated docs.

---

### Version 2.1.4 (15th January 2014)
#### Added
- Added method to disable `MAC MD5` tracking.

---

### Version 2.1.3 (13th January 2014)
#### Fixed
- Avoid crash on `iOS 5.0.1 and lower` due to lack of `NSURLIsExcludedFromBackupKey` presence.

---

### Version 2.1.2 (7th January 2014)
#### Changed
- `AILogger` is now static class.

#### Fixed
- Removed race condition.

---

### Version 2.1.1 (21th November 2013)
#### Added
- Added support for Unity and Adobe AIR SDKs.

#### Changed
- Removed local files from backups.
- Removed unused code.

---

### Version 2.1.0 (16th September 2013)
#### Added
- Added event buffering feature.
- Added `sandbox` environment.
- Added sending of `tracking_enabled` parameter.

---

### Version 2.0.1 (29th July 2013)
#### Added
- Added support for `Cocoapods`.

#### Changed
- Replaced `AFNetworking` with `NSMutableUrlRequests`.
- Removed `AFNetworking` dependency.

#### Fixed
- Re-added support `iOS 4.3` (recent AFNetworking required iOS 5.0).

---

### Version 2.0 (16th July 2013)
#### Added
- Added support for `iOS 7`.
- Added offline tracking.
- Added persisted storage.
- Addud multi threading.

---

### Version 1.6 (8th March 2013)
#### Added
- Added sending of `MAC MD5` and `MAC SHA1`.

---

### Version 1.5 (28th February 2013)
#### Added
- Added support for `HTTPS` protocol.

#### Changed
- Improved session tracking mechanism.

---

### Version 1.4 (17th January 2013)
#### Added
- Added session IDs and interval to last session event to session starts and ends.
- Added facebook attribution ID to installs for facebook install ads.

---

### Version 1.3 (8th January 2013)
#### Added
- Added tracking of session end.
- Added tracking of `IDFA`.
- Added tracking of `device type` and `device name`.
- Added tracking `AELogger` class.

#### Changed
- Improved revenue event tracking logs.
- Updated documentation.

---

### Version 1.2 (4th October 2012)
#### Added
- Added tracking of events with parameters.
- Added tracking of events with revenue.

#### Changed
- Updated documentation.

---

### Version 1.1 (6th August 2012)
#### Changed
- Replaced `ASIHTTPRequest` wih `AFNetworking`.
- Updated documentation.

---

### Version 1.0.0 (30th July 2012)
#### Added
- Initial release of the adjust SDK for iOS.
