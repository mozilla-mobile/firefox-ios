## nss

This crate provides various cryptographic routines backed by
[NSS](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS).

The API is designed to operate at approximately the same level of abstraction as the
[`crypto.subtle`](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto) API, although the details are obviously
different given the different host language.  It provides:

* Cryptographically secure [pseudorandom number generation](./src/pk11/slot.rs).
* Cryptographic [digests](./src/pk11/context.rs) and [hkdf](./src/pk11/sym_key.rs).
* [AES encryption and decryption](./src/aes.rs) in various modes.
* Generation, import and export of [elliptic-curve keys](./src/ec.rs).
* ECDH [key agreement](./src/ecdh.rs).
* Constant-time [string comparison](./src/secport.rs).

Like the `crypto.subtle` API, these primitives are quite low-level and involve some subtlety in order to use correctly.
Consumers should prefer the higher-level abstractions offered by the [rc_crypto](../) crate where possible.

These features are in turn built on even-lower-level bindings to the raw NSS API, provided by the [nss_sys](./nss_sys)
crate.
