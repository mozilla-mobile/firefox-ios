## Firefox Application Services Docs

This directory is the documentation root for all the products managed by the
Firefox Application Services Team.

The [./product-portal/](product-portal) directory contains the source docs for
the consumer-facing product portal website, which can be viewed here:

  * https://mozilla.github.io/application-services/
  
Everything else in this directory is contributor-facing documentation to help
you work on app-services projects.  We have:

  * A high-level guide to [Contributing to Application Services](./contributing.md)
  * A description of the [metrics](./metrics/README.md) gathered by each component
    (via the [glean](https://mozilla.github.io/glean/) framework).
  * The [Synconomicon](https://mozilla.github.io/application-services/synconomicon/), a deep dive into the internals of sync and storage for Firefox Applications.
  * The [Sync and Storage Handbook](https://mozilla.github.io/application-services/sync-storage-handbook/index.html), which provides a higher-level view of our sync and storage components.
  * Docs for various infrastructure pieces:
    * Our [Dependency Management Policies](./dependency-management.md)
    * Our [Build and Publish Pipeline](./build-and-publish-pipeline.md)
  * Architectural design docs:
    * How [megazording](./design/megazords.md) works, and why we do it.
    * The motivation and design of the [sync manager](./design/sync-manager.md).
  * Howtos for specific coding activities:
    * Code and architecture guidelines:
      * [Guide to Building a Rust Component](./howtos/building-a-rust-component.md)
      * [Guide to Testing a Rust Component](./howtos/testing-a-rust-component.md)
      * [How to expose your Rust Component to Kotlin](./howtos/exposing-rust-components-to-kotlin.md)
      * [How to expose your Rust Component to Swift](./howtos/exposing-rust-components-to-swift.md)
      * [How to pass data cross the FFI boundary](./howtos/when-to-use-what-in-the-ffi.md)
        * [How to do that specifically using protobuf](./howtos/passing-protobuf-data-over-ffi.md)
    * Development Tooling:
      * [How to set up your local android build environment](./howtos/setup-android-build-environment.md)
      * [How to try out local changes in Fenix](./howtos/locally-published-components-in-fenix.md)
      * [How to try out local changes in the Reference Browser](./howtos/working-with-reference-browser.md)
      * [How to try out local changes in Firefox for iOS](./howtos/locally-published-components-in-ios.md)
      * [How to access logs for debugging](./logging.md)
    * Process guidelines:
      * [How to cut a new release](./howtos/cut-a-new-release.md)
  * For consumers:
    * [Guide to Consuming Rust Components on Android](./howtos/consuming-rust-components-on-android.md)
    * [Guide to Consuming Rust Components on iOS](./howtos/consuming-rust-components-on-ios.md)
