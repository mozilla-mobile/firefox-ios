# FFI Support

[![Docs](https://docs.rs/ffi-support/badge.svg)](https://docs.rs/ffi-support)

This crate implements a support library to simplify implementing the patterns that the [mozilla/application-services](https://github.com/mozilla/application-services) repository uses for it's "Rust Component" FFI libraries, which are used to share Rust code

In particular, it can assist with the following areas:

1. Avoiding throwing panics over the FFI (which is undefined behavior)
2. Translating rust errors (and panics) into errors that the caller on the other side of the FFI is able to handle.
3. Converting strings to/from rust str.
4. Passing non-string data (in a few ways, including exposing an opaque pointeer, marshalling data to JSON strings with serde, as well as arbitrary custom handling) back and forth between Rust and whatever the caller on the other side of the FFI is.

Additionally, it's documentation describes a number of the problems we've hit doing this to expose libraries to consumers on mobile platforms.

## Usage

Add the following to your Cargo.toml

```toml
ffi-support = "0.1.1"
```

For further examples, the examples in the docs is the best starting point, followed by the usage code in the [mozilla/application-services](https://github.com/mozilla/application-services) repo (for example [here](https://github.com/mozilla/application-services/blob/master/components/places/ffi/src/lib.rs) or [here](https://github.com/mozilla/application-services/blob/master/components/places/src/ffi.rs)).

## License

Dual licensed under the Apache License, Version 2.0 <LICENSE-APACHE> or
<http://www.apache.org/licenses/LICENSE-2.0> or the MIT license <LICENSE-MIT> or
<http://opensource.org/licenses/MIT>, at your option. All files in the project
carrying such notice may not be copied, modified, or distributed except
according to those terms.
