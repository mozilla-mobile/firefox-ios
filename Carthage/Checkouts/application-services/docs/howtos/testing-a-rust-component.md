
# Guide to Testing a Rust Component

This document gives a high-level overview of how we test components in application-services.
It will be useful to you if you're adding a new component, or working on increasing the test
coverage of an existing component.

If you are only interested in running the existing test suite, please consult the
[contributor docs](../contributing.md) and the [all_tests.sh](../../automation/all_tests.sh) script.

## Unit and Functional Tests

### Rust code

Since the core implementation of our components lives in rust, so does the core of our testing strategy.

Each rust component should be accompanied by a suite of unittests, following the [guidelines for writing
tests](https://doc.rust-lang.org/book/ch11-00-testing.html) from the [Rust
Book](https://doc.rust-lang.org/book/title-page.html).
Some additional tips:

* Where possible, it's better use use the Rust typesystem to make bugs impossible than to write
  tests to assert that they don't occur in practice. But given that the ultimate consumers of our
  code are not in Rust, that's sometimes not possible. The best idiomatic Rust API for a feature
  is not necessarily the best API for consuming it over an FFI boundary!

* Rust's builtin assertion macros are pretty spartan; we use the [more_asserts](https://crates.io/crates/more_asserts)
  for some additional helpers.

* Rust's strict typing can make test mocks difficult. If there's something you need to mock out in tests,
  make it a Trait and use the [mockiato](https://crates.io/crates/mockiato) crate to mock it out.

The Rust tests for a component should be runnable via `cargo test`.

### FFI Layer code

We currently do not test the FFI-layer Rust code for our components, since it's generally a very thin
wrapper around the underlying (and in theory well-tested!) Rust component code. If you find yourself
adding a particularly complex bit of code in an FFI-layer crate, add unittests in the same style as
for other Rust code.

(Editor's note: I remain hopeful that one day we'll autogenerate most of the FFI-layer code, and in
such a world we don't need to invest in tests for it.)

### Kotlin code

The Kotlin wrapper code for a component should have its own test suite, which should follow the general guidelines for
[testing Android code in Mozilla projects](https://github.com/mozilla-mobile/shared-docs/blob/master/android/testing.md#jvm-testing).
In practice that means we use
[JUnit](https://github.com/mozilla-mobile/shared-docs/blob/master/android/testing.md#junit-testing-framework)
as the test framework and
[Robolectric](https://github.com/mozilla-mobile/shared-docs/blob/master/android/testing.md#robolectric-android-api-shadows)
to provide implementations of Android-specific APIs.

The Kotlin tests for a component should be runnable via `./gradlew <component>:test`.

The tests at this layer are designed to ensure that the API binding code is working as intended,
and should not repeat tests for functionality that is already well tested at the Rust level.
But given that the Kotlin bindings involve a non-trivial amount of hand-written boilerplate code,
it's important to exercise that code throughly.

One complication with running Kotlin tests is that the code needs to run on your local development machine,
but the Kotlin code's native dependencies are typically compiled and packaged for Android devices. The
tests need to ensure that an appropriate version of JNA and of the compiled Rust code is available in
their library search path at runtime. Our `build.gradle` files contain a collection of hackery that ensures
this, which should be copied into any new components.

(Editor's note: I remain hopeful that one day we'll autogenerate most of the Kotlin binding code, and in
such a world we don't need to invest in tests for it.)

XXX TODO: talk about proguard? I don't really understand it...

XXX TODO: any additional tips here, such as mocking out storage etc?

### Swift code

The Swift wrapper code for a component should have its own test suite, using Apple's
[XCode unittest framework](https://developer.apple.com/documentation/xctest).

Due to the way that all rust components need to be compiled together into a single ["megazord"](../design/megazords.md)
framework, this entire respository is a single XCode project. The Swift tests for each component
thus need to live under `megazords/ios/MozillaAppServicesTests/` rather than in the directory
for the corresponding component. (XXX TODO: is this true? it would be nice to find a way to avoid havining
them live separately because it makes them easy to overlook).

The tests at this layer are designed to ensure that the API binding code is working as intended,
and should not repeat tests for functionality that is already well tested at the Rust level.
But given that the Swift bindings involve a non-trivial amount of hand-written boilerplate code,
it's important to exercise that code throughly.

(Editor's note: I remain hopeful that one day we'll autogenerate most of the Swift binding code, and in
such a world we don't need to invest in tests for it.)

XXX TODO: any additional tips here, such as mocking out storage etc?

## Integration tests

### End-to-end Sync Tests

The [`testing/sync-test`](../../testing/sync-test) directory contains a test harness for running sync-related
Rust components against a live Firefox Sync infrastructure, so that we can verifying the functionality
end-to-end.

Each component that implements a sync engine should have a corresponding suite of tests in this directory.

* XXX TODO: places doesn't.
* XXX TODO: send-tab doesn't (not technically a sync engine, but still, it's related)
* XXX TODO: sync-manager doesn't

### Android Components Test Suite

It's important that changes in application-services are tested against upstream consumer code in the
[android-components](https://github.com/mozilla-mobile/android-components/) repo. This is currently
a manual process involving:

* Configuring your local checkout of android-components to [use your local application-services
  build](./working-with-reference-browser.md).
* Running the android-components test suite via `./gradle test`.
* Manually building and running the android-components sample apps to verify that they're still working.

Ideally some or all of this would be automated and run in CI, but we have not yet invested in such automation.

## Test Coverage

Lamentably, we do not measure or report on code test coverage.
See [this github issue](https://github.com/mozilla/application-services/issues/1745) for some early explorations.

The rust ecosystem for code coverage is still maturing, with [cargo-tarpaulin](https://github.com/xd009642/tarpaulin)
appearing to be a promising candidate.  However, such tools will only report code that is exercised by the rust
unittests, not code that is exercised by the Kotlin or Swift tests or the end-to-end integration test suite.

For code coverage to be useful to us, we need to either:

* Commit to ensuring high coverage via rust-level tests alone, or
* Figure out how to measure it for code being driven by non-rust test suites.

## Ideas for Improvement

* ASan, Memsan, and maybe other sanitizer checks, especially around the points where we cross FFI boundaries.
* General-purpose fuzzing, such as via https://github.com/jakubadamw/arbitrary-model-tests
* We could consider making a mocking backend for viaduct, which would also be mockable from Kotlin/Swift.
* Add more end-to-end integration tests!
* Live device tests, e.g. actual Fenixes running in an emulator and syncing to each other.
* Run consumer integration tests in CI against master.
