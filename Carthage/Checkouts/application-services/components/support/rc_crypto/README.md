# rc_crypto

The `rc_crypto` crate, like its name implies, handles all of our cryptographic needs.

For consumers, it pretty much follows the very rust-idiomatic [ring crate API](https://briansmith.org/rustdoc/ring/) and
offers the following functionality:

* Cryptographically secure [pseudorandom number generation](./src/rand.rs).
* Cryptographic [digests](./src/digest.rs), [hmac](./src/hmac.rs), and [hkdf](./src/hkdf.rs).
* Authenticated encryption ([AEAD](./src/aead.rs)) routines.
* ECDH [key agreement](./src/agreement.rs).
* Constant-time [string comparison](./src/constant_time.rs).
* HTTP [Hawk Authentication](./src/hawk_crypto.rs) through the [rust-hawk crate](https://github.com/taskcluster/rust-hawk/).
* HTTP [Encrypted Content-Encoding](./src/ece.rs) through the [ece crate](https://github.com/mozilla/rust-ece).

Under the hood, it is backed by Mozilla's [NSS](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS) library,
through bindings in the [nss](./nss/) crate. This has a number of advantages for our use-case:

* Uses Mozilla-owned-and-audited crypto primitives.
* Decouples us from ring's fast-moving [versioning and stability
  policy](https://github.com/briansmith/ring#versioning--stability).
