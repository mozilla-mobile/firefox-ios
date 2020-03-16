# Components

We currently provide two components.

**Logins** manage saved usernames and passwords. This component exposes APIs for creating and updating logins, and supports "unlocking" and "locking" a store by opening or closing its database connection. Internally, it tracks metadata like the use count, last use date, and last change date. This component is currently used in [Lockbox](https://mozilla-lockbox.github.io/) and [Firefox for iOS](https://github.com/mozilla-mobile/firefox-ios/).

**Places** manages bookmarks and history. This component provides high-level APIs for common use cases, like recording history visits, autocompleting visited URLs, clearing and expiring history, and managing bookmarks. Places is based on the Firefox Desktop implementation, and uses a mostly backward-compatible storage schema. It can either be consumed directly, as in Firefox for iOS, or through a layer like [Mozilla Android Components](https://mozac.org/). It's used in the [Android Reference Browser](https://github.com/mozilla-mobile/reference-browser/) and [Fenix](https://github.com/mozilla-mobile/fenix/).

## Anatomy of a Component

All components share a similar architecture.

* The **database** layer persists data to disk.
* The **domain** layer defines data types and the operations on them.
* The **FFI layer** is the glue between the application and storage.
* The **binding layer** exposes an idiomatic, platform-specific API for the application.

We'll take a closer look at each of the layers in the following sections.
