# Dependency Management Guidelines

This repo uses third-party code from a variety of sources, so we need to be mindful
of how these dependencies will affect our consumers.  Considerations include:

* General code quality.
* [Licensing compatibility](https://www.mozilla.org/en-US/MPL/license-policy/#Licenses_Compatible_with_the_MPL).
* Handling of security vulnerabilities.
* The potential for [supply-chain compromise](https://medium.com/intrinsic/compromised-npm-package-event-stream-d47d08605502).

We're still evolving our policies in this area, but these are the
guidelines we've developed so far.

## Rust Code

Unlike [Firefox](https://firefox-source-docs.mozilla.org/build/buildsystem/rust.html),
we do not vendor third-party source code directly into the repo.  Instead we rely on
`Cargo.lock` and its hash validation to ensure that each build uses an identical copy
of all third-party crates.  These are the measures we use for ongoing maintence of our
existing dependencies:

* Check `Cargo.lock` into the repository.
* Generate built artifacts using the `--locked` flag to `cargo build`, as an additional
  assurance that the existing `Cargo.lock` will be respected.
    * TODO: how to actually make this happen via rust-android-gradle plugin?
* Regularly run [cargo-audit](https://github.com/RustSec/cargo-audit) in CI to alert us to
  security problems in our dependencies.
    * It runs on every PR, and once per hour as a scheduled job with failures reported to slack.
* Use [a home-grown tool](../tools/dependency_summary.py) to generate a summary of dependency licenses
  and to check them for compatibility with MPL-2.0.
    * Check these summaries into the repository and have CI alert on unexpected changes,
      to guard against pulling in new versions of a dependency under a different license.

Adding a new dependency, whether we like it or not, is a big deal - that dependency and everything
it brings with it will become part of Firefox-branded products that we ship to end users.
We try to balance this responsibility against the many benefits of using existing code, as follows:

* In general, be conservative in adding new third-party dependencies.
  * For trivial functionality, consider just writing it yourself.
    Remember the cautionary tale of [left-pad](https://www.theregister.co.uk/2016/03/23/npm_left_pad_chaos/).
  * Check if we already have a crate in our dependency tree that can provide the needed functionality.
* Prefer crates that have a a high level of due-dilligence already applied, such as:
  * Crates that are [already vendored into Firefox](https://dxr.mozilla.org/mozilla-central/source/third_party/rust).
  * Crates from [rust-lang-nursery](https://github.com/rust-lang-nursery).
  * Crates that appear to be widely used in the rust community.
* Check that it is clearly licensed and is [MPL-2.0 compatible](https://www.mozilla.org/en-US/MPL/license-policy/#Licenses_Compatible_with_the_MPL).
* Take the time to investigate the crate's source and ensure it is suitably high-quality.
  * Be especially wary of uses of `unsafe`, or of code that is unusually resource-intensive to build.
  * Dev dependencies do not require as much scrutiny as dependencies that will ship in consuming applications,
    but should still be given some thought.
    * There is still the potential for supply-chain compromise with dev dependencies!
* As part of the PR that introduces the new dependency:
    * Regenerate dependency summary files using the [regenerate_dependency_summaries.sh](../tools/regenerate_dependency_summaries.sh).
    * Explicitly describe your consideration of the above points.

Updating to new versions of existing dependencies is a normal part of software development
and is not accompanied by any particular ceremony.

## Android/Kotlin Code

We currently depend only on the following Kotlin dependencies:

* [JNA](https://github.com/java-native-access/jna)
* [protobuf-gradle-plugin](https://github.com/google/protobuf-gradle-plugin)

We currently depend on the following **developer** dependencies in the Kotlin codebase,
but they do not get included in built distribution files:

* detekt
* ktlint

No additional Kotlin dependencies should be added to the project unless absolutely necessary.

## iOS/Swift Code

We currently depend only on the [following dependencies](https://github.com/mozilla/application-services/blob/master/Cartfile):

* [swift-protobuf](https://github.com/apple/swift-protobuf)
* [SwiftKeychainWrapper](https://github.com/jrendel/SwiftKeychainWrapper/)

No additional Swift dependencies should be added to the project unless absolutely necessary.

## Other Code

We currently depend on local builds of the following system dependencies:

* [NSS](https://hg.mozilla.org/projects/nss) and [NSPR](https://hg.mozilla.org/projects/nspr)
* [SQLCipher](https://github.com/sqlcipher/sqlcipher)
* [Protobuf](https://github.com/protocolbuffers/protobuf)

No additional system dependencies should be added to the project unless absolutely necessary.
