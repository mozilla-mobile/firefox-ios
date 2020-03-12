## Firefox Application Services

_A platform for building cloud-powered applications that target Firefox users_

### What's this all about?

This repository hosts the code and docs needed to integrate with the products offered by the Firefox
[Application Services](https://mana.mozilla.org/wiki/display/CLOUDSERVICES/Application+Services+Home)
team.

If you are interested in getting involved in the development of those products
then you're in the right place! Please review the more detailed guide on
[how to contribute](docs/contributing.md) to this project as well as
the [Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/).

If that's not why you're here, then instead you might enjoy:

* The [Application Services Product
  Portal](https://mozilla.github.io/application-services/), if you're looking to
  use those products in your application.
* The [Application Services Team Home](https://mana.mozilla.org/wiki/display/CLOUDSERVICES/Application+Services+Home)
  on Mana, if you're trying to find out more about how we build them.


### Overview

This repository is used to build client-side libraries for integrating with
Firefox Application services such as Firefox Accounts, Firefox Sync and Push.
Each of these is called a "component" and is built using a core of shared code
written in Rust, wrapped with native language bindings for different platforms.

The end result is an application that can be assembled from re-usable components
that are largely shared across platforms, like this:

[![component diagram](https://docs.google.com/drawings/d/e/2PACX-1vTPOIIBsqvkWfecYOziEnv-hrkB9QbpZwcHyeyUB-p3-eP1w9L87vwnJMiGt-eO5r-K-XcHPl_YwjvU/pub?w=727&h=546)](https://docs.google.com/drawings/d/1WRv2AaOsutNdL8_E5UDsYg1sC6FKRJ9P0bBSoI7E19s/)

The code for these components is organized as follows:

* [./libs/](libs) contains infratructure for building some native dependencies,
  such as NSS.
* [./components/](components) contains the source for each component, and its
  FFI bindings.
  * See [./components/logins/](components/logins) for an example, where you can
    find:
    * The shared [rust code](components/logins/src).
    * The mapping into a [C FFI](components/logins/ffi).
    * The [Kotlin bindings](components/logins/android) for use by Android
      applications.
    * The [Swift bindings](components/logins/ios) for use by iOS applications.
* [./megazords/](megazords) contains infrastructure for bundling multiple rust
  components into a single build artifact called a "[megazord library](docs/design/megazords.md)"
  for easy consumption by applications.

For more details on how the client libraries are built and published, please see
the [Guide to Building a Rust Component](docs/howtos/building-a-rust-component.md).

This repository also hosts the [website source](website) for the [Application
Services Product Portal](https://mozilla.github.io/application-services/), which
provides consumer-facing documentation on how to integrate with various
Application services products.

The [./docs/](docs) directory holds intenal documentation about working with the
code in this repository, and is most likely only of interest to contributors.

### Components

The currently-available Rust Components in this repo are:

* [fxa-client](components/fxa-client) - for applications that need to sign in
  with FxA, access encryption keys for sync, and more.
* [sync15](components/sync15) - shared library for accessing data in Firefox
  Sync
* [logins](components/logins) - for storage and syncing of a user's saved login
  credentials
* [places](components/places) - for storage and syncing of a user's saved
  browsing history
* [push](components/push) - for applications to receive real-time updates via
  WebPush
* [rc_log](components/rc_log) - for connecting component log output to the
  application's log stream
* [support](components/support) - low-level utility libraries
  * [support/ffi](components/support/ffi) - utilities for building a component's
    FFI bindings
  * [support/sql](components/support/sql) - utilities for storing data locally
    with SQL
