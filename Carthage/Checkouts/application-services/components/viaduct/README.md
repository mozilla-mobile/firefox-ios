# Viaduct

Viaduct is our HTTP request library, which can make requests either via a
rust-based (reqwest) networking stack (used on iOS and for local desktop use,
for tests and the like), or using a stack that calls a function passed into it
over the FFI (on android).

For usage info, you can run `cargo +nightly doc -p viaduct` (the `+nightly` is
optional, however some intra-doc links require it), it has several examples.

## Android/FFI Backend overview

On Android, the backend works as follows:

1. During megazord initialization, we are passed a `Lazy<Client>` (`Client` comes
   from the [concept-fetch](https://github.com/mozilla-mobile/android-components/tree/master/components/concept/fetch)
   android component, and `Lazy` is from the Kotlin stdlib).

    - It also sets a flag that indicates that even if the FFI backend never gets
      fully initialized (e.g. with a callback), we should error rather than use
      the reqwest backend (which should not be compiled in, however we've had
      trouble ensuring this in the past, although at this point we have checks
      in CI to ensure it is not present).

2. At this point, a JNA `Callback` instance is created and passed into Rust.
    - This serves to proxy the request made by Rust to the `Client`.
    - The `Callback` instance is never allowed to be GCed.
    - To Rust, it's just a `extern "C"` function pointer that get's stored in an
      atomic variable and never can be unset.

3. When Rust makes a request:
    1. We serialize the request info into a protobuf record
    2. This record is passed into the function pointer we should have by this
       point (erroring if it has not been set yet).
    3. The callback (on the Java side now) deserializes the protobuf record,
       converts it to a concept-fetch Request instance, and passes it to the
       client.
    4. The response (or error) is then converted into a protobuf record. The
       java code then asks Rust for a buffer big enough to hold the serialized
       response (or error).
    5. The response is written to the buffer, and returned to Rust.
    6. Rust then decodes the protobuf, and converts it to a
      `viaduct::Response` object that it returns to the caller.

Some notes:

- This "request flow" is entirely synchronous, simplifying the implementation
  considerably.

- Generally, this is the way the FFI backend is expected to work on any
  platform, but for concreteness (and because it's the only one currently using
  the FFI backend), we explained it for Android.

- Most of the code in `viaduct` is defining a ergonomic HTTP facade, and is
  unrelated to this (or to the reqwest backend). This code is more or less
  entirely (in the Kotlin layer and) in `src/backend/ffi.rs`.
