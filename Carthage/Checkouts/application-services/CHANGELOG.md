# v0.54.0 (_2020-03-10_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.53.2...v0.54.0)

## General

### What's changed

- iOS: Xcode version changed to 11.3.1 from 11.3.0.

## Rust

### What's New

- Sourcing `libs/bootstrap-desktop.sh` is not a thing anymore. Please run `./libs/verify-desktop-environment.sh` at least once instead. ([#2769](https://github.com/mozilla/application-services/pull/2769))

## Push

### Breaking changes

- Android: The `PushManager.verifyConnection` now returns a `List<PushSubscriptionChanged>` that contain the channel ID and scope of the subscriptions that have expired. ([#2632](https://github.com/mozilla/application-services/pull/2632))
  See [`onpushsubscriptionchange`][0] events on how this change can be propagated to notify web content.

[0]: https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerGlobalScope/onpushsubscriptionchange

## Places

### What's fixed

- Improve handling of tags for bookmarks with the same URL. These bookmarks no
  longer cause syncs to fail ([#2750](https://github.com/mozilla/application-services/pull/2750)),
  and bookmarks with duplicate or mismatched tags are reuploaded
  ([#2774](https://github.com/mozilla/application-services/pull/2774)).

### Breaking changes

- Synced items with unknown types now fail the sync, instead of being silently
  ignored. We'll monitor this error in telemetry, and add logic to delete these
  items on the server if needed
  ([#2780](https://github.com/mozilla/application-services/pull/2780)).

# v0.53.2 (_2020-03-05_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.53.1...v0.53.2)

## FxA Client

### What's fixed

- iOS: `FxAccountManager.logout` will now properly clear the persisted account state. ([#2755](https://github.com/mozilla/application-services/issues/2755))
- iOS: `FxAccountManager.getAccessToken` now runs in a background thread. ([#2755](https://github.com/mozilla/application-services/issues/2755))

# v0.53.1 (_2020-03-05_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.53.0...v0.53.1)

## Android

### What's changed

- A megazord loading failure will throw as soon as possible rather than at call time.
  ([#2739](https://github.com/mozilla/application-services/issues/2739))

## iOS

### What's New

- Developers can now run `./libs/verify-ios-environment.sh` to ensure their machine is ready to build the iOS Xcode project smoothly. ([#2737](https://github.com/mozilla/application-services/pull/2737))

## FxA Client

### What's new

- Added `FxAConfig.china` helper function to use FxA/Sync chinese servers. ([#2736](https://github.com/mozilla/application-services/issues/2736))
- iOS: Added `FxAccountManager.handlePasswordChanged` method that should be called after... a password change! ([#2744](https://github.com/mozilla/application-services/issues/2744))

# v0.53.0 (_2020-02-27_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.52.0...v0.53.0)

## Megazords

### What's changed

- The fenix megazord is no more! ([#2565](https://github.com/mozilla/application-services/pull/2565))

  The full megazord should be used instead. The two are functionally identical,
  however this should reduce the configuration surface required to use the
  application-services code.

  An example PR showing the changes typically required for this is available
  here: https://github.com/MozillaReality/FirefoxReality/pull/2867. Please feel
  free to reach out if you have any issues.

## Sync

### What's fixed

- Rust sync code is now more robust in the face of corrupt meta/global
  records. ([#2688](https://github.com/mozilla/application-services/pull/2688))

- In v0.52.0 we reported some network related fixes. We lied. This time
  we promise they are actually fixed. ([#2616](https://github.com/mozilla/application-services/issues/2616),
  [#2617](https://github.com/mozilla/application-services/issues/2617)
  [#2623](https://github.com/mozilla/application-services/issues/2623))

### What's changed

- Fewer updates to the 'clients' collection will be made. ([#2624](https://github.com/mozilla/application-services/issues/2624))

## FxA Client

### What's changed

- The `ensureCapabilities` method will not perform any network requests if the
  given capabilities are already registered with the server.
  ([#2681](https://github.com/mozilla/application-services/pull/2681))

### What's fixed

- Ensure an offline migration recovery succeeding does not happen multiple times.
  ([#2706](https://github.com/mozilla/application-services/pull/2706))

## Places

### What's fixed

- `storage::history::apply_observation` and `storage::bookmarks::update_bookmark`
  now flush pending origin and frecency updates. This fixes a bug where origins
  might be flushed at surprising times, like right after clearing history.
  ([#2693](https://github.com/mozilla/application-services/issues/2693))

## Push

### What's fixed

- `PushManager.dispatchInfoForChid` does not throw `KotlinNullPointerException` anymore if the method returned nothing. ([#2703](https://github.com/mozilla/application-services/issues/2703))


# v0.52.0 (_2020-02-19_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.51.1...v0.52.0)

## Sync

### What's changed

- Better caching of the tokenserver token and info/configuration response. ([#2616](https://github.com/mozilla/application-services/issues/2616))

- Less network requests will be made in the case nothing has changed on the server. ([#2623](https://github.com/mozilla/application-services/issues/2623))

## Places

### What's changed

- Added a new field `reasons` which is a `List` of `SearchResultReason`s in `SearchResult`. ([#2564](https://github.com/mozilla/application-services/pull/2564))

- Some places import related issues fixed ([#2536](https://github.com/mozilla/application-services/issues/2536),
  [#2607](https://github.com/mozilla/application-services/issues/2607))

### Breaking changes

- Android: The `PlacesWriterConnection.resetHistorySyncMetadata` and `PlacesWriterConnection.resetBookmarkSyncMetadata` methods have been moved to the `PlacesApi` class. ([#2668](https://github.com/mozilla/application-services/pull/2668))
- iOS: The `PlacesWriteConnection.resetHistorySyncMetadata` method has been moved to the `PlacesAPI` class. ([#2668](https://github.com/mozilla/application-services/pull/2668))

## FxA Client

### What's New

- Android: `FirefoxAccount.handlePushMessage` now handles all possible FxA push payloads and will return new `AccountEvent`s ([#2522](https://github.com/mozilla/application-services/pull/2522)):
  - `.ProfileUpdated` which should be handled by fetching the newest profile.
  - `.AccountAuthStateChanged` should be handled by checking if the authentication state is still valid.
  - `.AccountDestroyed` should be handled by removing the account information (no need to call `FirefoxAccount.disconnect`) from the device.
  - `.DeviceConnected` can be handled by showing a "<Device name> is connected to this account" notification.
  - `.DeviceDisconnected` should be handled by showing a "re-auth" state to the user if `isLocalDevice` is true. There is no need to call `FirefoxAccount.disconnect` as it will fail.

- iOS: Added `FxAccountManager.getSessionToken`. Note that you should request the `.session` scope in the constructor for this to work properly. ([#2638](https://github.com/mozilla/application-services/pull/2638))
- iOS: Added `FxAccountManager.getManageAccountURL`. ([#2658](https://github.com/mozilla/application-services/pull/2658))
- iOS: Added `FxAccountManager.getTokenServerEndpointURL`. ([#2658](https://github.com/mozilla/application-services/pull/2658))
- iOS: Added migration methods to `FxAccountManager` ([#2637](https://github.com/mozilla/application-services/pull/2637)):
  - `authenticateViaMigration` will try to authenticate an account without any user interaction using previously stored account information.
  - `accountMigrationInFlight` and `retryMigration` should be used in conjunction to handle cases where the migration could not be completed but is still recoverable.
- Added a `deviceId` property to the `AccountEvent.deviceDisconnected` enum case. ([#2645](https://github.com/mozilla/application-services/pull/2645))
- Added `context=oauth_webchannel_v1` in `getManageDevicesURL` methods for WebChannel redirect URLs. ([#2658](https://github.com/mozilla/application-services/pull/2658))

### Breaking changes

- Android: A few changes were made in order to decouple device commands from "account events" ([#2522](https://github.com/mozilla/application-services/pull/2522)):
  - The `AccountEvent` enum has been refactored: `.TabReceived` has been replaced by `.IncomingDeviceCommand(IncomingDeviceCommand)`, `IncomingDeviceCommand` itself is another enum that contains `TabReceived`.
  - `FirefoxAccount.pollDeviceCommands` now returns an array of `IncomingDeviceCommand`.

- iOS: The `FxaAccountManager` class has been renamed to `FxAccountManager`. ([#2637](https://github.com/mozilla/application-services/pull/2637))
- iOS: The `FxAccountManager` default applications scopes do not include `.oldSync` anymore. ([#2638](https://github.com/mozilla/application-services/pull/2638))
- iOS: `FxaAccountManager.getTokenServerEndpointURL` now returns the full token server URL such as `https://token.services.mozilla.com/1.0/sync/1.5`. ([#2676](https://github.com/mozilla/application-services/pull/2676))

## Push

### What's New

- Android: Exposed `GeneralError` to the Kotlin layer.

# v0.51.1 (_2020-02-07_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.51.0...v0.51.1)

## Android

### What's new

- Updated android gradle plugin version to 3.5.3 ([#2600](https://github.com/mozilla/application-services/pull/2600))


# v0.51.0 (_2020-02-06_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.50.2...v0.51.0)

## FxA Client

### What's New

- `FirefoxAccount` is now deprecated ([#2454](https://github.com/mozilla/application-services/pull/2454)).
- Introducing `FxAccountManager` which provides a higher-level interface to Firefox Accounts. Among other things, this class handles (and can recover from) authentication errors, exposes device-related account methods, handles its own keychain storage and fires observer notifications for important account events ([#2454](https://github.com/mozilla/application-services/pull/2454)).

### Breaking changes

- `FirefoxAccount.fromJSON(json: String)` has been replaced by the `FirefoxAccount(fromJsonState: String)` constructor ([#2454](https://github.com/mozilla/application-services/pull/2454)).


# v0.50.2 (_2020-02-06_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.50.1...v0.50.2)

### What's changed

- Re-releasing to fix misconfigured build options in v0.50.1.


# v0.50.1 (_2020-02-06_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.50.0...v0.50.1)

## FxA Client

### What's changed

- Fixed a potentially-unsafe use of a boolean in the FFI interface for `migrateFromSessionToken`.
  ([#2592](https://github.com/mozilla/application-services/pull/2592)).


# v0.50.0 (_2020-02-05_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.49.0...v0.50.0)

## FxA Client

### What's changed

- Android: `migrateFromSessionToken` now correctly persists in-flight migration state even
  when throwing an error ([#2586](https://github.com/mozilla/application-services/pull/2586)).

### Breaking changes

- `isInMigrationState` now returns an enum rather than a boolean, to indicate whether
  the migration will re-use or duplicate the underlying sessionToken.
  ([#2586](https://github.com/mozilla/application-services/pull/2586))


# v0.49.0 (_2020-02-03_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.48.3...v0.49.0)

## FxA Client

### What's New

- Android: `migrateFromSessionToken` now handles offline use cases. It caches the data the consumers
  originally provide. If there's no network connectivity then the migration could be retried using the
  new `retryMigrateFromSessionToken` method. Consumers may also use the `isInMigrationState` method
  to check if there's a migration in progress. ([#2492](https://github.com/mozilla/application-services/pull/2492))

### Breaking changes

- `migrateFromSessionToken` now returns a metrics JSON object if the migration succeeded.
  ([#2492](https://github.com/mozilla/application-services/pull/2492))


# v0.48.3 (_2020-01-23_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.48.2...v0.48.3)

## Places

## What's new

- The Dogear library for merging synced bookmarks has been updated to the latest version.
  ([#2469](https://github.com/mozilla/application-services/pull/2469))
- Places now exposes `resetHistorySyncMetadata` and `resetBookmarkSyncMetadata`
  methods, which cleans up all Sync state, including tracking flags and change
  counters. These methods should be called by consumers when the user signs out,
  to avoid tracking changes and causing unexpected behavior the next time they
  sign in.
  ([#2447](https://github.com/mozilla/application-services/pull/2447))

## What's changed

- Ensure we do the right thing with timestamps, tags and keywords on first sync after migration.
  ([#2472](https://github.com/mozilla/application-services/pull/2472))
- Don't count Fennec bookmarks we know we don't import in success metrics.
  ([#2488](https://github.com/mozilla/application-services/pull/2488))
- Don't fail if the Fennec database has negative positions when importing top-sites
  ([#2462](https://github.com/mozilla/application-services/pull/2462))
- Fix issue with bookmark tags when syncing
  ([#2480](https://github.com/mozilla/application-services/pull/2480))
- Quality and usage metrics are recorded (ditto for logins)
- Fix some swift warnings
  ([#2491](https://github.com/mozilla/application-services/pull/2491))

### Breaking Changes

- The Android bindings now collect some basic performance and quality metrics via Glean.
  Applications that submit telemetry via Glean must request a data review for these metrics
  before integrating the places component. See the component README.md for more details.
  ([#2431](https://github.com/mozilla/application-services/pull/2431))
- iOS only: `PlacesAPI.resetBookmarksMetadata` has been renamed to
  `PlacesAPI.resetBookmarkSyncMetadata`, for consistency with history. The functionality
  remains the same.


# v0.48.2 (_2020-01-13_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.48.1...v0.48.2)

## FxA Client

### What's changed

* Fixed a bug in deserializing FxA objects from JSON when the new `introspection_endpoint`
  field is not present.


# v0.48.1 (_2020-01-08_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.48.0...v0.48.1)

## General

- Revert NSS to version 3.46.

## Logins

### What's changed

* The error strings returned by `LoginsStorage.importLogins` as part of the migration metrics bundle,
  no longer include potentially-sensitive information such as guids.

# v0.48.0 (_2020-01-03_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.47.0...v0.48.0)

## Logins

### Breaking Changes

- `LoginsStorage.importLogins` returns logins migration metrics as JSON object. ([#2382](https://github.com/mozilla/application-services/issues/2382))

- iOS only: Added a migration path for apps to convert the encrypted database headers to plaintext([#2100](https://github.com/mozilla/application-services/issues/2100)).  
New databases must be opened using `LoginsStorage.unlockWithKeyAndSalt` instead of `LoginsStorage.unlock` which is now deprecated.
To migrate current users databases, it is required to call `LoginsStorage.migrateToPlaintextHeader` before opening the database. This new method requires a salt. The salt persistence is now the responsibility of the application, which should be stored alongside the encryption key. For an existing database, the salt can be obtained using `LoginsStorage.getDbSaltForKey`.

### What's new

- Android: Added ability to rekey the database via `rekeyDatabase`. [[#2228](https://github.com/mozilla/application-services/pull/2228)]

## FxA Client

### Breaking Changes

* Android: `migrateFromSessionToken` now reuses the existing 'sessionToken' instead of creating a new session token.

### What's new

* Android: New method `copyFromSessionToken` will create a new 'sessionToken' state, this is what `migrateFromSessionToken` used to do,
before this release.

## Places

### Breaking Changes

- - `PlacesApi.importVisitsFromFennec` return history migration metrics as JSON object. ([#2414](https://github.com/mozilla/application-services/issues/2414))
- - `PlacesApi.importBookmarksFromFennec` no longer returns pinned bookmarks, it now returns migration metrics as JSON object. ([#2427](https://github.com/mozilla/application-services/issues/2427))

### What's new

* Android: New method `PlacesApi.importPinnedSitesFromFennec` returns a list of pinned bookmarks from Fennec. ([#2427](https://github.com/mozilla/application-services/issues/2427))

# v0.47.0 (_2019-12-18_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.46.0...v0.47.0)

## General

- Updated NSS to version 3.48. ([#2379](https://github.com/mozilla/application-services/issues/2379))
- Our iOS framework is now built using Swift version 5.0. ([#2383](https://github.com/mozilla/application-services/issues/2383))
- Our iOS framework binaries are now built using XCode 11.3. ([#2383](https://github.com/mozilla/application-services/issues/2383))

## Logins

### Breaking Changes

- `LoginsStorage.getByHostname` has been removed. ([#2152](https://github.com/mozilla/application-services/issues/2152))

### What's new

- `LoginsStorage.getByBaseDomain` has been added. ([#2152](https://github.com/mozilla/application-services/issues/2152))
- Removed hard deletion of `SyncStatus::New` records in `delete` and `wipe` logins database functions. ([#2362](https://github.com/mozilla/application-services/pull/2362))
- Android: The `MemoryLoginsStorage` class has been deprecated, because it behaviour has already started to
  diverge from that of `DatabaseLoginStorage`. To replace previous uses of this class in tests, please either
  explicitly mock the `LoginsStorage` interface or use a `DatabaseLoginStorage` with a tempfile or `":memory:"`
  as the `dbPath` argument. ([#2389](https://github.com/mozilla/application-services/issues/2389))

# v0.46.0 (_2019-12-12_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.45.1...v0.46.0)

## Logins

### Breaking Changes

- The Android bindings now collect some basic performance and quality metrics via Glean.
  Applications that submit telemetry via Glean must request a data review for these metrics
  before integrating the logins component. See the component README.md for more details.
  ([#2225](https://github.com/mozilla/application-services/pull/2225))
- `username`, `usernameField`, and `passwordField` are no longer
  serialized as `null` in the case where they are empty strings. ([#2252](https://github.com/mozilla/application-services/pull/2252))
  - Android: `ServerPassword` fields `username`, `usernameField`, and
    `passwordField` are now required fields -- `null` is not acceptable,
    but empty strings are OK.
  - iOS: `LoginRecord` fields `username`, `usernameField` and
    `passwordField` are no longer nullable.

# v0.45.1 (_2019-12-10_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.45.0...v0.45.1)

This release exists only to rectify a publishing error that occurred with v0.45.0.

# v0.45.0 (_2019-12-10_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.44.0...v0.45.0)

## Places

### What's new

- Added `PlacesReaderConnection.getVisitPageWithBound` which performs
  faster history visits pagination by first skipping directly to a `bound` timestamp and then
  skipping over `offset` items from `bound`. ([#1019](https://github.com/mozilla/application-services/issues/1019))

## Push

### Breaking Changes

- `PushManager.decrypt` will now throw a `RecordNotFoundError` exception instead of `StorageError` if a matching subscription could not be found. ([#2355](https://github.com/mozilla/application-services/pull/2355))

## FxA Client

### What's new

- `FirefoxAccount.checkAuthorizationStatus` will check the status of the currently stored refresh token. ([#2332](https://github.com/mozilla/application-services/pull/2332))

## Logins

### Breaking Changes

- Login records with a `httpRealm` attribute will now have their `usernameField` and `passwordField`
  properties silently cleared, to help ensure data consistency. ([#2158](https://github.com/mozilla/application-services/pull/2158))

### What's new

- Added invalid character checks from Desktop to `LoginsStorage.ensureValid` and introduced `INVALID_LOGIN_ILLEGAL_FIELD_VALUE` error. ([#2262](https://github.com/mozilla/application-services/pull/2262))

## Sync Manager

### Breaking Changes

- When asked to sync all engines, SyncManager will now sync all engines for which a handle has been set.
  Previously it would sync all known engines, panicking if a handle had not been set for some engine.
  While *technically* a breaking change, we expect that the new behaviour is almost certainly what
  consuming applications actually want in practice. ([#2313](https://github.com/mozilla/application-services/pull/2313))

# v0.44.0 (_2019-11-21_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.43.1...v0.44.0)

## Logins

### What's new

- Added ability to prevent insertion/updates from creating dupes via `LoginsStorage.ensureValid`. ([#2101](https://github.com/mozilla/application-services/pull/2101))

## Tabs

### Breaking Changes

- The `RemoteTabsProvider` class constructor does not take the `localDeviceId` argument anymore.
- The `RemoteTabsProvider.sync` method takes a `localDeviceId` argument.

# v0.43.1 (_2019-11-18_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.43.0...v0.43.1)

This release exists only to rectify a publishing error that occurred with v0.43.0.

# v0.43.0 (_2019-11-18_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.42.4...v0.43.0)

This release exists only to rectify a publishing error that occurred with v0.42.4.

# v0.42.4 (_2019-11-18_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.42.3...v0.42.4)

## General

### What's New

- Synced Tabs is available as an Android component in the `org.mozilla.appservices.experimental.remotetabs` maven package.

## Push Client

### What's new

- `PushManager.dispatchInfoForChid(channelID)` now also returns the
  `endpoint` and `appServerKey` from the subscription.

### Breaking Changes

- The `appServerKey` VAPID public key has moved from `PushConfig` to
  `PushManager.subscription(channelID, scope, appServerKey)`.

- The unused `regenerate_endpoints()` function has been removed.

# v0.42.3 (_2019-11-04_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.42.2...v0.42.3)

## General

### What's New

- On Android, our Megazord libraries now include license information for dependencies
  as part of their `.pom` file, making it easily available to tools such as the
   [oss-licenses-plugin](https://github.com/google/play-services-plugins/tree/master/oss-licenses-plugin)

- Our iOS framework binaries are now built using XCode 11.2.

# v0.42.2 (_2019-10-21_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.42.1...v0.42.2)

## Places

### What's new

- Android: Exposed `stroage::bookmarks::erase_everything`, which deletes all bookmarks without affecting history, through FFI. ([#2012](https://github.com/mozilla/application-services/pull/2012))

## FxA Client

### What's new

- Android: Add ability to get an OAuth code using a session token via the `authorizeOAuthCode` method. ([#2003](https://github.com/mozilla/application-services/pull/2003))


# v0.42.1 (_2019-10-21_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.42.0...v0.42.1)

## Places

### What's new

- Android: The Fennec bookmarks import method (`importBookmarksFromFennec`) will now return a list of pinned bookmarks. ([#1993](https://github.com/mozilla/application-services/pull/1993))

# v0.42.0 (_2019-10-10_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.41.0...v0.42.0)

## Places

### What's new

- Android: Fennec history import now supports microsecond timestamps for `date_visited`.

### Breaking changes

- The methods for importing places data from fenix have been moved from the writer connection to the PlacesAPI.

# v0.41.0 (_2019-10-02_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.40.0...v0.41.0)

## General

### What's New

- Our components are now built with the newer Android NDK r20 instead of r15c. This change will make it easier for contributors to set up their development environment since there's no need to generate Android toolchains anymore. ([#1916](https://github.com/mozilla/application-services/pull/1916))  
For existing contributors, here's what you need to do immediately:
  - Download and extract the [Android NDK r20](https://developer.android.com/ndk/downloads).
  - Change the `ANDROID_NDK_ROOT` and `ANDROID_NDK_HOME` environment variables to point to the newer NDK dir. You can also delete the now un-used `ANDROID_NDK_TOOLCHAIN_DIR` variable.
  - Delete `.cargo/config` at the root of the repository if you have it.
  - Regenerate the Android libs: `cd libs && rm -rf android && ./build-all.sh android`.

## Logins

### What's new

- Added ability to get logins by hostname by using `LoginsStorage.getByHostname`. ([#1782](https://github.com/mozilla/application-services/pull/1782))

# v0.40.0 (_2019-09-26_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.39.4...v0.40.0)

## Logins

### Breaking Changes

- getHandle has been moved to the LoginsStorage interface. All implementers other than DatabaseLoginsStorage should implement this by throwing a `UnsupportedOperationException`.

# v0.39.4 (_2019-09-25_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.39.3...v0.39.4)

## Sync Manager

### What's fixed

- Engines which are disabled will not have engine records in meta/global. ([#1866](https://github.com/mozilla/application-services/pull/1866))
- The FxA access token is no longer logged at the debug level. ([#1866](https://github.com/mozilla/application-services/pull/1866))

# v0.39.3 (_2019-09-24_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.39.2...v0.39.3)

## FxA Client

### What's new

- The OAuth access token cache is now persisted as part of the account state data,
  which should reduce the number of times callers need to fetch a fresh access token
  from the server.

# v0.39.2 (_2019-09-24_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.39.1...v0.39.2)

## Sync Manager

### What's fixed

- Clients with missing engines in meta/global should have the engines repopulated. ([#1847](https://github.com/mozilla/application-services/pull/1847))

# v0.39.1 (_2019-09-17_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.39.0...v0.39.1)

## FxA Client

### What's new

Add ability to get the current device id in Kotlin via `getCurrentDeviceId` method.

# v0.39.0 (_2019-09-17_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.38.2...v0.39.0)

## FxA Client

### What's new

* New `getSessionToken` method on the FxA Client that returns the stored session_token from state.
Also we now store the session_token into the state from the 'https://identity.mozilla.com/tokens/session' scope.

## Places

### What's fixed

- Hidden URLs (redirect sources, or links visited in frames) are no longer
  synced or returned in `get_visit_infos` or `get_visit_page`. Additionally,
  a new `is_hidden` flag is added to `HistoryVisitInfo`, though it's currently
  always `false`, since those visits are excluded.
  ([#1715](https://github.com/mozilla/application-services/pull/1715))

## Sync Manager

- The new sync manager component is now available for integration ([#1447](https://github.com/mozilla/application-services/pull/1447)).
    - This should include no breaking changes at the moment, but in the future
      we will deprecate the non-sync manager sync APIs on android.
    - Note: Currently, the sync manager is only available in the `full` and
      `fenix` megazords.

# v0.38.2 (_2019-09-04_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.38.1...v0.38.2)

## Android

### What's new

- The Gradle Android Plugin has been updated to 3.5.0. ([#1680](https://github.com/mozilla/application-services/pull/1680))

## iOS

### What's new

- Releases are now built with Xcode 11.0.0. ([#1719](https://github.com/mozilla/application-services/pull/1719))

# v0.38.1 (_2019-08-26_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.38.0...v0.38.1)

## FxA Client

### What's new

-  Added support for a webchannel redirect behaviour. ([#1608](https://github.com/mozilla/application-services/pull/1608))

## Android

### What's new

- Initial versions of Fennec data import methods have landed:
  - Bookmarks and history visits can be imported by calling `PlacesWriterConnection.importBookmarksFromFennec` and `PlacesWriterConnection.importVisitsFromFennec` respectively. ([#1595](https://github.com/mozilla/application-services/pull/1595), [#1461](https://github.com/mozilla/application-services/pull/1461))
  - Logins can be imported with `LoginsStorage.importLogins`. ([#1614](https://github.com/mozilla/application-services/pull/1614))

# v0.38.0 (_2019-08-19_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.37.1...v0.38.0)

## General

- Our OpenSSL dependency has been removed for all platforms other than
  desktop-linux (used when running local rust unit tests and the android
  -forUnitTests artifact). All other platforms use NSS.
  ([#1570](https://github.com/mozilla/application-services/pull/1570))

## Places

### What's Fixed

* Tags containing embedded whitespace are no longer marked as invalid and
  removed. ([#1616](https://github.com/mozilla/application-services/issues/1616))

# v0.37.1 (_2019-08-09_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.37.0...v0.37.1)

## Android

### What's fixed

- Published artifacts should now correctly declare their `packaging` type in
  their pom files. ([#1564](https://github.com/mozilla/application-services/pull/1564))

## FxA Client

### What's fixed

- `FirefoxAccount.handlePushMessage` will not return an error on unknown push payloads.

# v0.37.0 (_2019-08-08_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.36.0...v0.37.0)

## FxA Client

### What's new

- The Tablet, VR and TV devices types have been added.

### What's fixed

- The `FirefoxAccount.disconnect` method should now properly dispose of the associated device record.

### Breaking changes

- The `FirefoxAccount.beginOAuthFlow` method does not require the `wantsKeys` argument anymore
  as it will always do the right thing based on the requested scopes.

# v0.36.0 (_2019-07-30_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.35.4...v0.36.0)

## General

### What's New

- The Fenix megazord now supports Logins. ([#1465](https://github.com/mozilla/application-services/pull/1465))

- For maintainers only: please delete the `libs/{desktop, ios, android}` folders and start over using `./build-all.sh [android|desktop|ios]`.

### What's fixed

- Android x86_64 crashes involving the `intel_aes_encrypt_cbc_128` missing symbol have been fixed. ([#1495](https://github.com/mozilla/application-services/pull/1495))

## Places

### What's New

- Added a `getBookmarkURLForKeyword` method that retrieves a URL associated to a keyword. ([#1345](https://github.com/mozilla/application-services/pull/1345))

## Push

### Breaking changes

- `PushManager.dispatchForChid` method has been renamed to `dispatchInfoForChid` and its result type is now Nullable. ([#1490](https://github.com/mozilla/application-services/pull/1490))

# v0.35.4 (_2019-07-24_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.35.3...v0.35.4)

This release exists only to rectify a publishing error that occurred with v0.35.3.

# v0.35.3 (_2019-07-24_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.35.2...v0.35.3)

This release exists only to rectify a publishing error that occurred with v0.35.2.

# v0.35.2 (_2019-07-24_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.35.1...v0.35.2)

This release exists only to rectify a publishing error that occurred with v0.35.1.

# v0.35.1 (_2019-07-24_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.35.0...v0.35.1)

## FxA Client

### What's Fixed

* Android: `migrateFromSessionToken` will not leave the account in a broken state if
  network errors happen during the migration process.

## Push

### What's Fixed

* Updated the default server host for the push service to match the production server.

# v0.35.0 (_2019-07-16_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.34.0...v0.35.0)

## General

### Megazords

The long-awaited android [megazord changes](./docs/design/megazords) have
arrived. This has a large number of changes, many of them breaking:
([#1103](https://github.com/mozilla/application-services/pull/1103))

- Consumers who depend on network features of application-services, but
  which were not using a megazord, will no longer be able to use a legacy
  HTTP stack by default.

- Consumers who depend on network features and *do* use a megazord, can no
  longer initialize HTTP in the same call as the megazord.

- Both of these cases should import the `org.mozilla.appservices:httpconfig`
  package, and call `RustHttpConfig.setClient(lazy { /* client to use */ })`
  before calling functions which make HTTP requests.

- For custom megazord users, the name of your megazord is now always
  `mozilla.appservices.Megazord`. You no longer need to load it by reflection,
  since the swapped-out version always has the same name as your custom version.

- The reference-browser megazord has effectively been replaced by the
  full-megazord, which is also the megazord used by default

- The steps to swap-out a custom megazord have changed. The specific steps are
  slightly different in various cases, and we will file PRs to help make the
  transition.

- Substitution builds once again work, except for running unit tests against
  Rust code.

## FxA Client

### What's Fixed

- The state persistence callback is now correctly triggered after a call
  to `FirefoxAccount.getProfile`.

### Breaking changes

- The `FirefoxAccount.destroyDevice` method has been removed in favor of the
  more general `FirefoxAccount.disconnect` method which will ensure a full
  disconnection by invalidating OAuth tokens and destroying the device record
  if it exists. ([#1397](https://github.com/mozilla/application-services/issues/1397))
- The `FirefoxAccount.disconnect` method has been added to the Swift bindings as well.
- The `FirefoxAccount.beginOAuthFlow` method will redirect to a content page that
  forces the user to connect to the last seen user email. To avoid this behavior,
  a new `FirefoxAccount` instance with a new persisted state must be created.

# v0.34.0 (_2019-07-10_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.33.2...v0.34.0)

## General

- All of our cryptographic primitives are now backed by NSS ([#1349](https://github.com/mozilla/application-services/pull/1349)). This change should be transparent our customers.

  If you build application-services, it is recommended to delete the `libs/{desktop, ios, android}` folders and start over using `./build-all.sh [android|desktop|ios]`. [GYP](https://github.com/mogemimi/pomdog/wiki/How-to-Install-GYP) and [ninja](https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages) are required to build these libraries.

## Places

### What's New

- Added `WritableHistoryConnection.acceptResult(searchString, url)` for marking
  an awesomebar result as accepted.
  ([#1332](https://github.com/mozilla/application-services/pull/1332))
    - Specifically, `queryAutocomplete` calls for searches that contain
      frequently accepted results are more highly ranked.

### Breaking changes

- Android only: The addition of `acceptResult` to `WritableHistoryConnection` is
  a breaking change for any custom implementations of `WritableHistoryConnection`
  ([#1332](https://github.com/mozilla/application-services/pull/1332))

## Push

### Breaking Changes

- `OpenSSLError` has been renamed to the more general `CryptoError`. ([#1349](https://github.com/mozilla/application-services/pull/1349))

# v0.33.2 (_2019-07-04_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.33.1...v0.33.2)

This release exists only to rectify a publishing error that occurred with v0.33.1.

# v0.33.1 (_2019-07-04_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.33.0...v0.33.1)

This release exists only to rectify a publishing error that occurred with v0.33.0.

# v0.33.0 (_2019-07-04_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.32.3...v0.33.0)

## FxA Client

### Breaking Changes

- iOS: FirefoxAccountError enum variants have their name `lowerCamelCased`
  instead of `UpperCamelCased`, to better fit with common Swift code style.
  ([#1324](https://github.com/mozilla/application-services/issues/1324))

# v0.32.3 (_2019-07-02_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.32.2...v0.32.3)

## Places

### What's Fixed

- `PlacesReaderConnection.queryAutocomplete` should return unique results. ([#970](https://github.com/mozilla/application-services/issues/970))

- Ensures bookmark sync doesn't fail if a bookmark or query is missing or has an invalid URL. ([#1325](https://github.com/mozilla/application-services/issues/1325))

# v0.32.2 (_2019-06-28_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.32.1...v0.32.2)

## General

- This is a release that aims to test infrastructure changes (ci-admin).

- OpenSSL dependency updated. ([#1328](https://github.com/mozilla/application-services/pull/1328))

# v0.32.1 (_2019-06-26_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.32.0...v0.32.1)

## FxA Client

### What's Fixed

- Fixes SendTab initializeDevice in Android to use the proper device type ([#1314](https://github.com/mozilla/application-services/pull/1314))

## iOS Bindings

### What's Fixed

- Errors emitted from the rust code should now all properly output their description. ([#1323](https://github.com/mozilla/application-services/pull/1323))

## Logins

### What's Fixed

- Remote login records which cannot be parsed are now ignored (and reported in telemetry). [#1253](https://github.com/mozilla/application-services/issues/1253)

# v0.32.0 (_2019-06-14_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.31.2...v0.32.0)

## Places

### What's fixed

- Fix an error that could happen when the place database is closed.
  ([#1304](https://github.com/mozilla/application-services/pull/1304))

- iOS only: Ensure interruption errors don't come through as network errors.
  ([#1304](https://github.com/mozilla/application-services/pull/1304))

# v0.31.3 (_2019-07-02_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.31.2...v0.31.3)

## General

- (Backport) Update `smallvec` dependency to pick up a security fix ([#1353](https://github.com/mozilla/application-services/pull/1353))

## Places

- (Backport) Ensures bookmark sync doesn't fail if a bookmark or query is missing or has an invalid URL ([#1325](https://github.com/mozilla/application-services/issues/1325))

## FxA Client

- (Backport) Fixes SendTab initializeDevice in Android to use the proper device type ([#1314](https://github.com/mozilla/application-services/pull/1314))

# v0.31.2 (_2019-06-10_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.31.1...v0.31.2)

## Sync

### What's fixed

- Fixes an edge case introduced in v0.31.1 where a users set of declined engines
  (aka the "Choose what to Sync" preferences) could be forgotten.
  ([#1273](https://github.com/mozilla/application-services/pull/1273))

# v0.31.1 (_2019-06-10_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.31.0...v0.31.1)

## Sync

### What's fixed

- Fixes an issue where a stale sync key will be used in cases where a user signs
  out and signs in to another account. ([#1256](https://github.com/mozilla/application-services/pull/1256))

## FxA Client

### What's new

- Added a new method to help recover from invalid access tokens.
  ([#1244](https://github.com/mozilla/application-services/pull/1244)) If the
  application receives an an authentication exception while using a token
  obtained through `FirefoxAccount.getAccessToken`, it should:
  - Call `FirefoxAccount.clearAccessTokenCache` to remove the invalid token from the internal cache.
  - Retry the operation after obtaining fresh access token via `FirefoxAccount.getAccessToken`.
  - If the retry also fails with an authentication exception, then the user will need to reconnect
    their account via a fresh OAuth flow.
- `FirefoxAccount.getProfile` now performs the above retry logic automagically.
  An authentication error while calling `getProfile` indicates that the user
  needs to reconnect their account.
  ([#1244](https://github.com/mozilla/application-services/pull/1244)

# v0.31.0 (_2019-06-07_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.30.0...v0.31.0)

## Sync

- Android: A new `sync15` package defines Kotlin data classes for the Sync
  telemetry ping. ([#1112](https://github.com/mozilla/application-services/pull/1112))
- Android: `PlacesApi.syncHistory` and `PlacesApi.syncBookmarks` now return a
  `SyncTelemetryPing`. ([#1112](https://github.com/mozilla/application-services/pull/1112))
- iOS: `PlacesAPI.syncBookmarks` now returns a JSON string with the contents of
  the Sync ping. This should be posted to the legacy telemetry submission
  endpoint. ([#1112](https://github.com/mozilla/application-services/pull/1112))

## Places

### What's fixed

- Deduping synced bookmarks with newer server timestamps no longer throws
  unique constraint violations. ([#1259](https://github.com/mozilla/application-services/pull/1259))

## Logins

### Breaking Changes

- iOS: LoginsStoreError enum variants have their name `lowerCamelCased`
  instead of `UpperCamelCased`, to better fit with common Swift code style.
  ([#1042](https://github.com/mozilla/application-services/issues/1042))

# v0.30.0 (_2019-05-30_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.29.0...v0.30.0)

## Push

### Breaking Changes

* Changed the internal serialization format of the Push Keys.

## FxA Client

### Breaking Changes

* Changed the internal serialization format of the Send Tab Keys. Calling `ensureCapabilities` will re-generate them.

### Features

* Added `migrateFromSessionToken` to allow creating a refreshToken from an existing sessionToken.
Useful for Fennec to Fenix bootstrap flow, where the user can just reuse the existing sessionToken to 
create a new session with a refreshToken.

# v0.29.0 (_2019-05-23_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.28.1...v0.29.0)

## Places

### What's New

- A new `getRecentBookmarks` API was added to return the list of most recently
  added bookmark items ([#1129](https://github.com/mozilla/application-services/issues/1129)).

### Breaking Changes
- The addition of `getRecentBookmarks` is a breaking change for custom
  implementation of `ReadableBookmarksConnection` on Android
  ([#1129](https://github.com/mozilla/application-services/issues/1129)).

# v0.28.1 (_2019-05-21_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.28.0...v0.28.1)

This release exists only to rectify a publishing error that occurred with v0.28.0.

# v0.28.0 (_2019-05-17_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.27.2...v0.28.0)

## FxA

### Breaking Changes

- `FirefoxAccount.ensureCapabilities` now takes a set of capabilities
   as a parameter. All the device registered "capabilities" such as Send
   Tab will be replaced by the passed set of new capabilities.

## Push

### Breaking Changes

- `PushManager.verifyConnection()` now returns a boolean. `true`
  indicates the connection is valid and no action required, `false`
indicates that the connection is invalid. All existing subscriptions
have been dropped. The caller should send a `pushsubscriptionchange`
to all known apps. (This is due to the fact that the Push API does
not have a way to send just the new endpoint to the client PWA.)
[#1114](https://github.com/mozilla/application-services/issues/1114)

- `PushManager.unsubscribe(...)` now will only unsubscribe a single
  channel. It will return `false` if no channel is specified or if the
channel was already deleted. To delete all channels for a given user,
call `PushManager.unsubscribeAll()`.
[#889](https://github.com/mozilla/application-services/issues/889)

## General

### What's Fixed

- Native libraries should now have debug symbols stripped by default,
  resulting in significantly smaller package size for consuming
  applications. A test was also added to CI to ensure that this
  does not regress in future.
  ([1107](https://github.com/mozilla/application-services/issues/1107))


# v0.27.2 (_2019-05-08_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.27.1...v0.27.2)

## Logins

### What's new

- iOS only: Logins store has a new (static) `numOpenConnections` function, which can be used to detect leaks. ([#1070](https://github.com/mozilla/application-services/pull/1070))

## Places

### What's New

- iOS only: PlacesApi can now migrate bookmark data from a `browser.db` database
  via the `migrateBookmarksFromBrowserDb` function. It is recommended that this
  only be called for non-sync users, as syncing the bookmarks over will result
  in better handling of sync metadata, among other things.
  ([#1078](https://github.com/mozilla/application-services/pull/1078))
- iOS: Sync can now be interrupted using the `interrupt` method
  ([#1092](https://github.com/mozilla/application-services/pull/1092))
- iOS: Sync metadata can be reset using the `resetBookmarksMetadata` method
  ([#1092](https://github.com/mozilla/application-services/pull/1092))


# v0.27.1 (_2019-04-26_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.27.0...v0.27.1)

## FxA

### What's New

- Added `destroyDevice` support to existing Send Tab capabilities. ([#821](https://github.com/mozilla/application-services/pull/821))

## Places

### What's New

- Frecencies are now recalculated for bookmarked URLs after a sync.
  ([#847](https://github.com/mozilla/application-services/issues/847))

## Push

### What's Fixed

- Authentication failures with the autopush server should be fixed. ([#1080](https://github.com/mozilla/application-services/pull/1080))

# v0.27.0 (_2019-04-22_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.26.2...v0.27.0)

## General

- JNA has been updated to version 5.2.0 (previously 4.5.2) ([#1057](https://github.com/mozilla/application-services/pull/1057))

- SQLCipher has been updated to version 4.1.0 (previously 4.0.0) ([#1060](https://github.com/mozilla/application-services/pull/1060))

- `android-components` has been updated to 0.50.0 (previously 0.49.0) ([#1062](https://github.com/mozilla/application-services/pull/1062))

- SQLCipher should no longer be required in megazords which do not contain `logins`. ([#996](https://github.com/mozilla/application-services/pull/996))

- Non-megazord builds should once again work ([#1046](https://github.com/mozilla/application-services/pull/1046))

## FxA

### What's New

- New methods `getManageAccountURL` and `getManageDevicesURL` have been added,
  which the application can use to direct the user to manage their account on the web.
  ([#984](https://github.com/mozilla/application-services/pull/984))
- Android only: Added device registration and Firefox Send Tab capability support. Your app can opt into this by calling the `FirefoxAccount.initializeDevice` method. ([#676](https://github.com/mozilla/application-services/pull/676))

- Switched to use the new fxa-auth-server token endpoint which generates device records, email and push notifications
 for connected clients([#1055](https://github.com/mozilla/application-services/pull/1055))

## Places

### Breaking Changes

- It is no longer possible to create an encrypted places database. ([#950](https://github.com/mozilla/application-services/issues/950))
- `syncBookmarks()` API is now marked `open` to be accessible outside the framework. ([#1058](https://github.com/mozilla/application-services/issues/1058))

### What's Fixed

- Non-megazord builds should once again function. ([#1045](https://github.com/mozilla/application-services/issues/1045))

# v0.26.2 (_2019-04-18_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.26.1...v0.26.2)

## iOS Framework

### What's Fixed

- iOS temporarially no longer uses NSS for crypto. This is a short term fix to
  allow firefox-ios to release an update.

# v0.26.1 (_2019-04-18_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.26.0...v0.26.1)

## iOS Framework

### What's Fixed

- iOS networking should use the reqwest backend, instead of failing ([#1032](https://github.com/mozilla/application-services/pull/1032))

# v0.26.0 (_2019-04-17_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.25.2...v0.26.0)

## Gradle plugin

- Removed the appservices bintray repo from the plugin ([#899](https://github.com/mozilla/application-services/issues/899))

## Push

### Breaking Change

- `PushAPI.subscribe()` now returns a `SubscriptionResponse` that contains the server supplied `channelID` and the
   `subscriptionInfo` block previously returned. Please note: the server supplied `channelID` may differ from the
   supplied `channelID` argument. This is definitely true when an empty channelID value is provided to `subscribe()`,
   or if the channelID is not a proper UUID.
   The returned `channelID` value is authoritative and will be the value associated with the subscription and future
   subscription updates. As before, the `subscriptionResponse.subscriptionInfo` can be JSON serialized and returned to the application.
   ([#988](https://github.com/mozilla/application-services/pull/988))

## Places

### What's new

- Bookmarks may now be synced using the `syncBookmarks` method on `PlacesApi`
  (and on Android, the interface it implements, `SyncManager`).
  ([#850](https://github.com/mozilla/application-services/issues/850))
- Android only: New methods for querying paginated history have been added:
  `getVisitCount` and `getVisitPage`
  ([#992](https://github.com/mozilla/application-services/issues/992))
- Android only: `getVisitInfos` now takes a list of visit types to exclude.
  ([#920](https://github.com/mozilla/application-services/issues/920))

### Breaking Changes

- Android only: The addition of `syncBookmarks` on the `PlacesManager` interface
  is a breaking change. ([#850](https://github.com/mozilla/application-services/issues/850))
- Android only: `sync` has been renamed to `syncHistory` for clarity given the
  existence of `syncBookmarks`.
  ([#850](https://github.com/mozilla/application-services/issues/850))
- Android only: `getVisitInfos` has changed, which is breaking for implementors
  of `ReadableHistoryConnection`.
  ([#920](https://github.com/mozilla/application-services/issues/920))
- Android only: New methods on `ReadableHistoryConnection`: `getVisitCount` and
  `getVisitPage`.
  ([#992](https://github.com/mozilla/application-services/issues/992))

## Logins

### What's new

- iOS only: Logins operations may now be interrupted via the `interrupt()`
  method on LoginsDb, which may be called from any thread.
  ([#884](https://github.com/mozilla/application-services/issues/884))
    - This is currently only implemented for iOS due to lack of interest on the
      Android side, please let us know if this is desirable in the Android API
      as well. Feel free to indicate support for exposing this in the Android API
      [here](https://github.com/mozilla/application-services/issues/1020).

# v0.25.2 (_2019-04-11_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.24.0...v0.25.2)

## General

- Some cryptographic primitives are now backed by NSS. On reference-browser and fenix megazords the GeckoView NSS libs are used, otherwise these libraries are bundled. ([#891](https://github.com/mozilla/application-services/pull/891))

### What's Fixed

- Megazords and requests should work again. ([#946](https://github.com/mozilla/application-services/pull/946))
- The vestigial `reqwest` backend is no longer compiled into the megazords ([#937](https://github.com/mozilla/application-services/pull/937)).
    - Note that prior to this it was present, but unused.

## iOS

- The individual components projects have been removed, please use the MozillaAppServices framework from now on. ([#932](https://github.com/mozilla/application-services/pull/932))
- The NSS .dylibs must be included in your application project, see [instructions](https://github.com/mozilla/application-services/blob/30a1a57917c6e243c0c5d59fba24caa8de8f6b3a/docs/howtos/consuming-rust-components-on-ios.md#nss)

## Push

### What's fixed

- PushAPI now stores some metadata information across restarts ([#905](https://github.com/mozilla/application-services/issues/905))

# v0.24.0 (_2019-04-08_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.23.0...v0.24.0)

## Megazords

## Breaking Changes

- Megazord initialization has changed. Megazords' init() function now takes a
  `Lazy<mozilla.components.concept.fetch.Client>` (from
  [concept-fetch](https://github.com/mozilla-mobile/android-components/tree/master/components/concept/fetch/)),
  which will be used to proxy all HTTP requests through. It will not be accessed
  until a method is called on rust code which requires the network. This
  functionality is not present in non-megazords. ([#835](https://github.com/mozilla/application-services/pull/835))

    An example of how to initialize this follows:

    ```kotlin
    val megazordClass = Class.forName("mozilla.appservices.MyCoolMegazord")
    val megazordInitMethod = megazordClass.getDeclaredMethod("init", Lazy::class.java)
    val lazyClient: Lazy<Client> = lazy { components.core.client }
    megazordInitMethod.invoke(megazordClass, lazyClient)
    ```

    Or (if you don't have GeckoView available, e.g. in the case of lockbox):

    ```kotlin
    val megazordClass = Class.forName("mozilla.appservices.MyCoolMegazord")
    val megazordInitMethod = megazordClass.getDeclaredMethod("init", Lazy::class.java)
    // HttpURLConnectionClient is from mozilla.components.lib.fetch.httpurlconnection
    val lazyClient: Lazy<Client> = lazy { HttpURLConnectionClient() }
    megazordInitMethod.invoke(megazordClass, lazyClient)
    ```

## General

- Native code builds are now stripped by default, reducing size by almost an
  order of magnitude. ([#913](https://github.com/mozilla/application-services/issues/913))
    - This is done rather than relying on consumers to strip them, which proved
      more difficult than anticipated.

## Push

### What's new

- PushAPI now defines a number of default parameters for functions ([#868](https://github.com/mozilla/application-services/issues/868))

### Breaking changes

- `mozilla.appservices.push.BridgeTypes` is now
  `mozilla.appservices.push.BridgeType`
([#885](https://github.com/mozilla/application-services/issues/885))

## Places

### What's Fixed

- Swift PlacesAPI methods are not externally accessible
  ([#928](https://github.com/mozilla/application-services/issues/928))

# v0.23.0 (_2019-03-29_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.22.1...v0.23.0)

## Places

### What's Fixed

- createBookmarkItem on android will now create the correct type of bookmark.
  ([#880](https://github.com/mozilla/application-services/issues/880))

## Push

### Breaking changes

- the `PushManager` argument `socket_protocol` is now `http_protocol`
  to correctly map its role. `socket_protocol` is reserved.

# v0.22.1 (_2019-03-27_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.22.0...v0.22.1)

## Logins

### What's New

- iOS Logins storage now has `ensureLocked`, `ensureUnlocked`, and `wipeLocal`
  methods, equivalent to those provided in the android API.
  ([#854](https://github.com/mozilla/application-services/issues/854))

## Places

### What's Fixed

- PlacesAPIs should now be closed when all references to them are no longer used.
  ([#749](https://github.com/mozilla/application-services/issues/749))

# v0.22.0 (_2019-03-22_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.21.0...v0.22.0)

## Logins

- Added a disableMemSecurity function to turn off some dubious behaviors of SQLcipher. ([#838](https://github.com/mozilla/application-services/pull/838))
- The iOS SQLCipher build configuration has been adjusted ([#837](https://github.com/mozilla/application-services/pull/837))

## Push

### Breaking changes

- `PushManager`'s `dispatch_for_chid` method has been renamed to `dispatchForChid`.
- `PushManager` constructor arguments are now camelCased.

## `org.mozilla.appservices` Gradle plugin

- Artifacts are now to be published to the `mozilla-appservices` bintray organization.  This necessitates version 0.4.3 of the Gradle plugin.  ([#843](https://github.com/mozilla/application-services/issues/843))

# v0.21.0 (_2019-03-20_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.20.2...v0.21.0)

## General

- Breakpad symbols should be available for android now ([#741](https://github.com/mozilla/application-services/pull/741))

## Places

- Places now is available on iOS, however support is limited to Bookmarks. ([#743](https://github.com/mozilla/application-services/pull/743))
- Places now has bookmarks support enabled in the FFI. This addition is too large to include in the changelog, however both Swift and Kotlin APIs for this are fairly well documented. ([#743](https://github.com/mozilla/application-services/pull/743))


# v0.20.2 (_2019-03-15_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.20.1...v0.20.2)

- An automation problem with the previous release, forcing a version bump. No functional changes.
- Local development: non-megazord builds are now `debug` be default, improving local build times
and working around subtle build issues.
- Override this via a flag in `local.properties`: `application-services.nonmegazord-profile=release`

# v0.20.1 (_2019-03-15_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.20.0...v0.20.1)

- A error in the build.gradle file caused the v0.20.0 release to fail, this
  release should not be meaningfully different from it.

# v0.20.0 (_2019-03-14_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.19.0...v0.20.0)

## General

- The previous release had an issue with the megazords, and so another
  release was needed. This is version 0.4.2 of the megazord plugin.
  ([#775](https://github.com/mozilla/application-services/pull/775))

### Breaking Changes

- All package names have been normalized. The gradle packages should all be
  `org.mozilla.appservices:component`, and the java namespaces should be
  `mozilla.appservices.component`. ([#776](https://github.com/mozilla/application-services/pull/776))

## Logins

### Breaking Changes

- The gradle package for logins has been changed from
  `'org.mozilla.sync15:logins'` to `org.mozilla.appservices:logins`.
  ([#776](https://github.com/mozilla/application-services/pull/776))

## Places

### Breaking Changes

- Several classes and interfaces have been renamed after feedback from consumers
  to avoid `Interface` in the name, and better reflect what they provide.
    - `PlacesApiInterface` => `PlacesManager`
    - `PlacesConnectionInterface` => `InterruptibleConnection`
    - `ReadablePlacesConnectionInterface` => `ReadableHistoryConnection`
    - `WritablePlacesConnectionInterface` => `WritableHistoryConnection`
    - `ReadablePlacesConnection` => `PlacesReaderConnection`
    - `WritablePlacesConnection` => `PlacesWriterConnection`

- The java namespace used in places has changed from `org.mozilla.places` to
  `mozilla.appservices.places`
  ([#776](https://github.com/mozilla/application-services/pull/776))

- The gradle package for places has been changed from
  `'org.mozilla.places:places'` to `org.mozilla.appservices:places`.
  ([#776](https://github.com/mozilla/application-services/pull/776))

## FxA

### Breaking Changes

- The gradle package for fxa-client has been changed from
  `'org.mozilla.fxaclient:fxaclient'` to `org.mozilla.appservices:fxaclient`.
  ([#776](https://github.com/mozilla/application-services/pull/776))

# 0.19.0 (_2019-03-13_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.18.0...v0.19.0)

## General

### What's New

- Initial support for the new Push component landed, however it's not yet ready
  for widespread use ([#683](https://github.com/mozilla/application-services/pull/683))

## Places

### What's New

- A massive rewrite of the Kotlin API has been completed. This distinguishes
  reader and writer connections. A brief description of the new types follows.
  Note that all the types have corresponding interfaces that allow for them to
  be mocked during testing as needed. ([#718](https://github.com/mozilla/application-services/pull/718))
    - `PlacesApi`: This is similar to a connection pool, it exists to give out
      reader and writer connections via the functions `openReader` and
      `getWriter`. The naming distinction is due to there only being a single
      writer connection (which is actually opened when the `PlacesApi` is
      created). This class generally should be a singleton.
        - In addition to `openReader` and `getWriter`, this also includes the
        `sync()` method, as that requires a special type of connection.
    - `ReadablePlacesConnection`: This is a read-only connection to the places
      database, implements all the methods of the API that do not require write
      access.
        - Specifically, `getVisited`, `matchUrl`, `queryAutocomplete`, `interrupt`,
          `getVisitedUrlsInRange`, and `getVisitInfos` all exist on this object.
    - `WritablePlacesConnection`: This is a read-write connection, and as such,
      contains not only the all reader methods mentioned above, but also the
      methods requiring write access, such as:
        - `noteObservation`, `wipeLocal`, `runMaintenance`, `pruneDestructively`,
          `deleteEverything`, `deletePlace`, `deleteVisitsSince`, `deleteVisitsBetween`,
          and `deleteVisit`.
    - Note that the semantics of the various methods have not been changed, only
      their location.

### Breaking Changes

- Almost the entire API has been rewritten. See "What's New" for
  details. ([#718](https://github.com/mozilla/application-services/pull/718))

# 0.18.0 (_2019-02-27_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.17.0...v0.18.0)

## FxA

### Breaking Changes

- Swift: `FxAError` has been renamed to `FirefoxAccountError` ([#713](https://github.com/mozilla/application-services/pull/713))

## Places

### What's Fixed

- Autocomplete should no longer return an error when encountering certain emoji ([#691](https://github.com/mozilla/application-services/pull/691))

## Logging

### What's New

- The `rc_log` component now has support for iOS. It is only available as part of the
  MozillaAppServices megazord. ([#618](https://github.com/mozilla/application-services/issues/618))

# 0.17.0 (_2019-02-19_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.16.1...v0.17.0)

## FxA

### What's New

- We are now using [Protocol Buffers](https://developers.google.com/protocol-buffers/) to pass the Profile data across the FFI boundaries, both on Android and iOS. On Android there should be no breaking changes.
- Kotlin: `Profile` is now a [Data Class](https://kotlinlang.org/docs/reference/data-classes.html).

### Breaking changes

- iOS: You now have to include the `SwiftProtobuf` framework in your projects for FxAClient to work (otherwise you'll get a runtime error when fetching the user profile). It is built into `Carthage/Build/iOS` just like `FxAClient.framework`.
- iOS: In order to build FxAClient from source, you need [swift-protobuf](https://github.com/apple/swift-protobuf) installed. Simply run `brew install swift-protobuf` if you have Homebrew.
- iOS: You need to run `carthage bootstrap` at the root of the repository at least once before building the FxAClient project: this will build the `SwiftProtobuf.framework` file needed by the project.
- iOS: the `Profile` class now inherits from `RustProtobuf`. Nothing should change in practice for you.

## Places

### What's New

- New methods on PlacesConnection (Breaking changes for classes implementing PlacesAPI):
    - `fun deleteVisit(url: String, timestamp: Long)`: If a visit exists at the specified timestamp for the specified URL, delete it. This change will be synced if it is the last remaining visit (standard caveat for partial visit deletion). ([#621](https://github.com/mozilla/application-services/issues/621))
    - `fun deleteVisitsBetween(start: Long, end: Long)`: Similar to `deleteVisitsSince(start)`, but takes an end date. ([#621](https://github.com/mozilla/application-services/issues/621))
    - `fun getVisitInfos(start: Long, end: Long = Long.MAX_VALUE): List<VisitInfo>`: Returns a more detailed set of information about the visits that occured. ([#619](https://github.com/mozilla/application-services/issues/619))
        - `VisitInfo` is a new data class that contains a visit's url, title, timestamp, and type.
    - `fun wipeLocal()`: Deletes all history entries without recording any sync information. ([#611](https://github.com/mozilla/application-services/issues/611)).

        This means that these visits are likely to start slowly trickling back
        in over time, and many of them will come back entirely if a full sync
        is performed (which may not happen for some time, admittedly). The
        intention here is that this is a method that's used if data should be
        discarded when disconnecting sync, assuming that it would be desirable
        for the data to show up again if sync is reconnected.

        For more permanent local deletions, see `deleteEverything`, also added
        in this version.

    - `fun runMaintenance()`: Perform automatic maintenance. ([#611](https://github.com/mozilla/application-services/issues/611))

        This should be called at least once per day, however that is a
        recommendation and not a requirement, and nothing dire happens if it is
        not called.

        The maintenance it may perform potentially includes, but is not limited to:

        - Running `VACUUM`.
        - Requesting that SQLite optimize our indices.
        - Expiring old visits.
        - Deleting or fixing corrupt or invalid rows.
        - Etc.

        However not all of these are currently implemented.

    - `fun pruneDestructively()`: Aggressively prune history visits. ([#611](https://github.com/mozilla/application-services/issues/611))

        These deletions are not intended to be synced, however due to the way
        history sync works, this can still cause data loss.

        As a result, this should only be called if a low disk space notification
        is received from the OS, and things like the network cache have already
        been cleared.

    - `fun deleteEverything()`: Delete all history visits. ([#647](https://github.com/mozilla/application-services/issues/647))

        For sync users, this will not cause the visits to disappear from the
        users remote devices, however it will prevent them from ever showing
        up again, even across full syncs, or sync sign-in and sign-out.

        See also `wipeLocal`, also added in this version, which is less
        permanent with respect to sync data (a full sync is likely to bring
        most of it back).


### Breaking Changes

- The new `PlacesConnection` methods listed in the "What's New" all need to be implemented (or stubbed) by any class that implements `PlacesAPI`. (multiple bugs, see "What's New" for specifics).

### What's fixed

- Locally deleted visits deleted using `deleteVisitsSince` should not be resurrected on future syncs. ([#621](https://github.com/mozilla/application-services/issues/621))
- Places now properly updates frecency for origins, and generally supports
  origins in a way more in line with how they're implemented on desktop. ([#429](https://github.com/mozilla/application-services/pull/429))

# 0.16.1 (_2019-02-08_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.16.0...v0.16.1)

## Logins

### What's Fixed

- iOS `LoginRecord`s will no longer use empty strings for `httpRealm` and `formSubmitUrl` in cases where they claim to use nil. ([#623](https://github.com/mozilla/application-services/issues/623))
    - More broadly, all optional strings in LoginRecords were were being represented as empty strings (instead of nil) unintentionally. This is fixed.
- iOS: Errors that were being accidentally swallowed should now be properly reported. ([#640](https://github.com/mozilla/application-services/issues/640))
- Schema initialization/upgrade now happen in a transaction. This should avoid corruption if some unexpected error occurs during the first unlock() call. ([#642](https://github.com/mozilla/application-services/issues/642))

### Breaking changes

- iOS: Code that expects empty strings (and not nil) for optional strings should be updated to check for nil instead. ([#623](https://github.com/mozilla/application-services/issues/623))
    - Note that this went out in a non-major release, as it doesn't cause compilation failure, and manually reading all our dependents determined that nobody was relying on this behavior.

## FxA

### What's Fixed

- iOS: Some errors that were being accidentally swallowed should now be properly reported. ([#640](https://github.com/mozilla/application-services/issues/640))

# 0.16.0 (_2019-02-06_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.15.0...v0.16.0)

## General

### What's New

- iOS builds now target v11.0. ([#614](https://github.com/mozilla/application-services/pull/614))
- Preparatory infrastructure for megazording iOS builds has landed.([#625](https://github.com/mozilla/application-services/pull/625))

## Places

### Breaking Changes

- Several new methods on PlacesConnection (Breaking changes for classes implementing PlacesAPI):
    -  `fun interrupt()`. Cancels any calls to `queryAutocomplete` or `matchUrl` that are running on other threads. Those threads will throw an `OperationInterrupted` exception. ([#597](https://github.com/mozilla/application-services/pull/597))
        - Note: Using `interrupt()` during the execution of other methods may work, but will have mixed results (it will work if we're currently executing a SQL query, and not if we're running rust code). This limitation may be lifted in the future.
    - `fun deletePlace(url: String)`: Deletes all visits associated with the provided URL ([#591](https://github.com/mozilla/application-services/pull/591))
        - Note that these deletions are synced!
    - `fun deleteVisitsSince(since: Long)`: Deletes all visits between the given unix timestamp (in milliseconds) and the present ([#591](https://github.com/mozilla/application-services/pull/591)).
        - Note that these deletions are synced!

### What's New

- Initial support for storing bookmarks has been added, but is not yet exposed over the FFI. ([#525](https://github.com/mozilla/application-services/pull/525))

## FxA

### What's Fixed

- iOS Framework: Members of Avatar struct are now public. ([#615](https://github.com/mozilla/application-services/pull/615))


# 0.15.0 (_2019-02-01_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.14.0...v0.15.0)

## General

### What's New

- A new megazord was added, named `fenix-megazord`. It contains the components for FxA and Places (and logging). ([#585](https://github.com/mozilla/application-services/issues/585))
    - Note: To use this, you must be on version 0.3.1 of the gradle plugin.

## Logins

### What's Fixed

- Fix an issue where unexpected errors would become panics. ([#593](https://github.com/mozilla/application-services/pull/593))
- Fix an issue where syncing with invalid credentials would be reported as the wrong kind of error (and cause a panic because of the previous issue). ([#593](https://github.com/mozilla/application-services/pull/593))

## Places

### What's New

- New method on PlacesConnection (breaking change for classes implementing PlacesAPI): `fun matchUrl(query: String): String?`. This is similar to `queryAutocomplete`, but only searches for URL and Origin matches, and only returns (a portion of) the matching url (if found), or null (if not). ([#595](https://github.com/mozilla/application-services/pull/595))

### What's Fixed

- Autocomplete will no longer return an error when asked to match a unicode string. ([#298](https://github.com/mozilla/application-services/issues/298))

- Autocomplete is now much faster for non-matching queries and queries that look like URLs. ([#589](https://github.com/mozilla/application-services/issues/589))

## FxA

### What's New

- It is now possible to know whether a profile avatar has been set by the user. ([#579](https://github.com/mozilla/application-services/pull/579))

### Breaking Changes

- The `avatar` accessor from the `Profile` class in the Swift framework now returns an optional `Avatar` struct instead of a `String`. ([#579](https://github.com/mozilla/application-services/pull/579))

# 0.14.0 (_2019-01-23_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.13.3...v0.14.0)

## General

### What's New

- A new component was added for customizing how our Rust logging is handled. It allows Android code to get a callback whenever a log is emitted from Rust (Most users will not need to use this directly, but instead will consume it via the forthcoming helper that hooks it directly into android-components Log system in [android-components PR #1765](https://github.com/mozilla-mobile/android-components/pull/1765)). ([#472](https://github.com/mozilla/application-services/pull/472))

- The gradle megazord plugin updated to version 0.3.0, in support of the logging library. Please update when you update your version of android-components. ([#472](https://github.com/mozilla/application-services/pull/472))

- In most cases, opaque integer handles are now used to pass data over the FFI ([#567](https://github.com/mozilla/application-services/issues/567)). This should be more robust, and allow detection of many types of errors that would previously cause silent memory corruption.

  This should be mostly transparent, but is a semi-breaking semantic change in the case that something throws an exception indicating that the Rust code paniced (which should only occur due to bugs anyway). If this occurs, all subsequent operations on that object (except `close`/`lock`) will cause errors. It is "poisoned", in Rust terminology. (In the future, this may be handled automatically)

  This may seem inconvenient, but it should be an improvement over the previous version, where we instead would simply carry on despite potentially having corrupted internal state.

- Build settings were changed to reduce binary size of Android `.so` by around 200kB (per library). ([#567](https://github.com/mozilla/application-services/issues/567))

- Rust was updated to 1.32.0, which means we no longer use jemalloc as our allocator. This should reduce binary size some, but at the cost of some performance. (No bug as this happens automatically as part of CI, see the rust-lang [release notes](https://blog.rust-lang.org/2019/01/17/Rust-1.32.0.html#jemalloc-is-removed-by-default) for more details).

### Breaking Changes

- Megazord builds will no longer log anything by default. Logging must be enabled as described "What's New". ([#472](https://github.com/mozilla/application-services/pull/472))

## Places

### What's Fixed

- PlacesConnection.getVisited will now return that invalid URLs have not been visited, instead of throwing. ([#552](https://github.com/mozilla/application-services/issues/552))
- PlacesConnection.noteObservation will correctly identify url parse failures as such. ([#571](https://github.com/mozilla/application-services/issues/571))
- PlacesConnections not utilizing encryption will not make calls to mlock/munlock on every allocation/free. This improves performance up to 6x on some machines. ([#563](https://github.com/mozilla/application-services/pull/563))
- PlacesConnections now use WAL mode. ([#555](https://github.com/mozilla/application-services/pull/563))

## FxA

### Breaking Changes

Some APIs which are semantically internal (but exposed for various reasons) have changed.

- Android: Some `protected` methods on `org.mozilla.fxaclient.internal.RustObject` have been changed (`destroy` now takes a `Long`, as it is an opaque integer handle). This object should not be considered part of the public API of FxA, but it is still available. Users using it are recommended not to do so. ([#567](https://github.com/mozilla/application-services/issues/567))
- iOS: The type `RustOpaquePointer` was replaced by `RustHandle`, which is a `RustPointer<UInt64>`. While these are technically part of the public API, they may be removed in the future and users are discouraged from using them. ([#567](https://github.com/mozilla/application-services/issues/567))

# 0.13.3 (_2019-01-11_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.13.2...v0.13.3)

## Places

### What's Fixed

- Places will no longer log PII. ([#540](https://github.com/mozilla/application-services/pull/540))

# 0.13.2 (_2019-01-11_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.13.1...v0.13.2)

## Firefox Accounts

### What's New

- The fxa-client android library will now write logs to logcat. ([#533](https://github.com/mozilla/application-services/pull/533))
- The fxa-client Android and iOS librairies will throw a differentiated exception for general network errors. ([#535](https://github.com/mozilla/application-services/pull/535))

# 0.13.1 (_2019-01-10_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.13.0...v0.13.1)

Note: This is a patch release that works around a bug introduced by a dependency. No functionality has been changed.

## General

### What's New

N/A

### What's Fixed

- Network requests on Android. Due to a [bug in `reqwest`](https://github.com/seanmonstar/reqwest/issues/427), it's version has been pinned until we can resolve this issue. ([#530](https://github.com/mozilla/application-services/pull/530))

# 0.13.0 (_2019-01-09_)

[Full Changelog](https://github.com/mozilla/application-services/compare/v0.12.1...v0.13.0)

## General

### What's New

- Upgraded openssl to 1.1.1a ([#474](https://github.com/mozilla/application-services/pull/474))

### What's Fixed

- Fixed issue where backtraces were still enabled, causing crashes on some android devices ([#509](https://github.com/mozilla/application-services/pull/509))
- Fixed some panics that may occur in corrupt databases or unexpected data. ([#488](https://github.com/mozilla/application-services/pull/488))

## Places

### What's New

N/A

### What's fixed

- Autocomplete no longer returns more results than requested ([#489](https://github.com/mozilla/application-services/pull/489))

## Logins

### Deprecated or Breaking Changes

- Deprecated the `reset` method, which does not perform any useful action (it clears sync metadata, such as last sync timestamps and the mirror table). Instead, use the new `wipeLocal` method, or delete the database file. ([#497](https://github.com/mozilla/application-services/pull/497))

### What's New

- Added the `wipeLocal` method for deleting all local state while leaving remote state untouched. ([#497](https://github.com/mozilla/application-services/pull/497))
- Added `ensureLocked` / `ensureUnlocked` methods which are identical to `lock`/`unlock`, except that they do not throw if the state change would be a no-op (e.g. they do not require that you check `isLocked` first). ([#495](https://github.com/mozilla/application-services/pull/495))
- Added an overload to `unlock` and `ensureUnlocked` that takes the key as a ByteArray. Note that this is identical to hex-encoding (with lower-case hex characters) the byte array prior to providing it to the string overload. ([#499](https://github.com/mozilla/application-services/issues/499))

### What's Fixed

- Clarified which exceptions are thrown in documentation in cases where it was unclear. ([#495](https://github.com/mozilla/application-services/pull/495))
- Added `@Throws` annotations to all methods which can throw. ([#495](https://github.com/mozilla/application-services/pull/495))
