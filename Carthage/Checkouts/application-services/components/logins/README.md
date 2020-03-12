# Logins Component

![status-img](https://img.shields.io/static/v1?label=production&message=Lockwise,%20Firefox%20for%20iOS&color=darkgreen)
![status-img](https://img.shields.io/static/v1?label=beta&message=Firefox%20for%20Android&color=yellow)
![status-img](https://img.shields.io/static/v1?label=not%20implemented&message=Desktop&color=darkred)


The Logins component can be used to store website logins (i.e. usernames, passwords, and related metadata)
and to sync them between applications using [Firefox Sync](../sync_manager/README.md).

* [Features](#features)
* [Using the Logins component](#using-the-logins-component)
* [Working on the Logins component](#working-on-the-logins-component)

## Features

The Logins component offers:

1. Local encrypted storage of login records (including usernames, passwords, and website metadata).
1. Basic Create, Read, Update and Delete (CRUD) operations for login data.
1. Syncing of logins data between applications, via Firefox Sync.
1. Import functionality from existing login storage (ex: Fx Desktop or Fennec).
1. Data migration functionality from Fennec to Firefox Preview storage.

The Logins component ***does not*** offer, and we have no concrete plans to offer:

1. Any form-autofill of other UI-level functionality.
1. Storage of other secret data, such as credit card numbers.

If you'd like to see new capabilities added to this component, please file an issue for discussion,
but on the understanding that it may be a lengthy discussion.

## Using the Logins component

### Before using this component

Products sending telemetry and using this component *must request* a data-review following
[this process](https://wiki.mozilla.org/Firefox/Data_Collection).
This component provides data collection using the [Glean SDK](https://mozilla.github.io/glean/book/index.html).
The list of metrics being collected is available in the [metrics documentation](../../docs/metrics/logins/metrics.md).

### Prerequisites

To use this component for local storage of logins data, you will need to know how to integrate appservices components
into an application on your target platform:
* **Android**: integrate via the
  [sync-logins](https://github.com/mozilla-mobile/android-components/blob/master/components/service/sync-logins/README.md)
  component from android-components.
* **iOS**: start with the [guide to consuming rust components on
  iOS](https://github.com/mozilla/application-services/blob/master/docs/howtos/consuming-rust-components-on-ios.md).
* **Other Platforms**: we don't know yet; please reach out on slack to discuss!

To sync logins data between devices, you will additionally need to integrate the
[FxAClient component](../fxa-client/README.md) in order to obtain the necessary user credentials and encryption keys,
and the [SyncManager component](../sync_manager/README.md) in order to orchestrate the syncing process.

### Core Concepts

* A **login record** contains a single saved password along with other metadata about where it should be used.
Each record is uniquely identified by an opaque string id, and contains fields such as username, password and origin.
You can read about the fields on a login record in the code [here](./src/login.rs).
* A **logins store** is a syncable encrypted database containing login records. In order to use the logins store,
the application must first *unlock* it by providing a secret key (preferably obtained from an OS-level keystore
mechanism). It can then create, read, update and delete login records from the database.
  * If the application is connected to Firefox Sync, it can instruct the store to sync itself with the user's
    server-side logins data. This will upload any local modifications as well as download any new logins data
    from the server, automatically reconciling records in the case of conflict.

### Examples
- [Android integration](https://github.com/mozilla-mobile/android-components/blob/master/components/service/sync-logins/README.md)


### API Documentation
- TODO [Expand and update API docs](https://github.com/mozilla/application-services/issues/1747)


## Working on the Logins component

### Prerequisites

To effectively work on the Logins component, you will need to be familiar with:

* Our general [guidelines for contributors](../../docs/contributing.md).
* The [core concepts](#core-concepts) for users of the component, outlined above.
* The way we [generate ffi bindings](../../docs/howtos/building-a-rust-component.md) and expose them to
  [Kotlin](../../docs/howtos/exposing-rust-components-to-kotlin.md) and
  [Swift](../../docs/howtos/exposing-rust-components-to-swift.md).
* The key ideas behind [how Firefox Sync works](../../docs/synconomicon/) and the [sync15 crate](../sync15/README.md).

### Implementation Overview

Logins implements encrypted storage for login records on top of SQLcipher. The storage schema is based on the one
originally used in [Firefox for
iOS](https://github.com/mozilla-mobile/firefox-ios/blob/faa6a2839abf4da2c54ff1b3291174b50b31ab2c/Storage/SQL/SQLiteLogins.swift),
but with the following notable differences:
- the queries; they've been substantially modified for our needs here.
- how sync is performed; the version here allows syncs to complete with fewer database operations.
- timestamps; iOS uses microseconds, where the Logins component uses milliseconds.

See the header comment in [`src/schema.rs`](./src/schema.rs) for an overview of the schema.

### Directory structure
The relevant directories are as follows:

- [`src`](./src): The meat of the library. This contains cross-platform rust code that
  implements the actual storage and sync of login records.
- [`examples`](./examples): This contains example rust code that implements a command-line app
  for syncing, displaying, and editing logins using the code in `src`. You can run it via
  cargo like so: `cargo run --example sync_pass_sql`.
- [`ffi`](./ffi): The Rust public FFI bindings. This is a (memory-unsafe, by necessity)
  API that is exposed to Kotlin and Swift. It leverages the [`ffi_support`](../support/ffi/README.md) crate
  to avoid many issues and make it more safe than it otherwise would be. At the
  time of this writing, it uses JSON for marshalling data over the FFI, however
  in the future we will likely use protocol buffers.
- [`android`](./android): This contains android bindings to logins, written in Kotlin. These
  use JNA to call into to the code in `ffi`.
- [`ios`](./ios): This contains the iOS binding to logins, written in Swift. These use
  Swift's native support for calling code written in C to call into the code in
  `ffi`.

### Business Logic

#### Record storage

At any given time records can exist in 3 places, the local storage, the remote record, and the shared parent.  The shared parent refers to a record that has been synced previously and is referred to in the code as the mirror. Login records are encrypted and stored locally. For any record that does not have a shared parent the login component tracks that the record has never been synced.

Reference the [Logins chapter of the synconomicon](https://mozilla.github.io/application-services/synconomicon/ch01.1-logins.html) for detailed information on the record storage format.

#### Sign-out behavior
When the user signs out of their Firefox Account, we reset the storage and clear the shared parent.

#### Merging records
When records are added, the logins component performs a three-way merge between the local record, the remote record and the shared parent (last update on the server).  Details on the merging algorithm are contained in the [generic sync rfc](https://github.com/mozilla/application-services/blob/1e2ba102ee1709f51d200a2dd5e96155581a81b2/docs/design/remerge/rfc.md#three-way-merge-algorithm).

#### Record de-duplication

De-duplication compares the records for same the username and same url, but with different passwords.
Deduplication logic is based on age, the username and hostname:
- If the changes are more recent than the local record it performs an update.
- If the change is older than our local records, and you have changed the same field on both, the record is not updated.

### Testing

![status-img](https://img.shields.io/static/v1?label=test%20status&message=acceptable&color=darkgreen)

Our goal is to seek an _acceptable_ level of test coverage. When making changes in an area, make an effort to improve (or minimally not reduce) coverage. Test coverage assessment includes:
* [rust tests](https://github.com/mozilla/application-services/blob/master/testing/sync-test/src/logins.rs)
* [android tests](https://github.com/mozilla/application-services/tree/master/components/logins/android/src/test/java/mozilla/appservices/logins)
* [ios tests](https://github.com/mozilla/application-services/blob/master/megazords/ios/MozillaAppServicesTests/LoginsTests.swift)
* TODO [measure and report test coverage of logins component](https://github.com/mozilla/application-services/issues/1745)

### Telemetry
- TODO [implement logins sync ping telemety via glean](https://github.com/mozilla/application-services/issues/1867)
- TODO [Define instrument and measure success metrics](https://github.com/mozilla/application-services/issues/1749)
- TODO [Define instrument and measure quality metrics](https://github.com/mozilla/application-services/issues/1748)
