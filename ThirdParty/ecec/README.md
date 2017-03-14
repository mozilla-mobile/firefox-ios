# ecec

[![Build Status](https://travis-ci.org/kitcambridge/ecec.svg?branch=master)](https://travis-ci.org/kitcambridge/ecec)
[![Coverage](https://img.shields.io/codecov/c/github/kitcambridge/ecec/master.svg)](https://codecov.io/github/kitcambridge/ecec)

**ecec** is a C implementation of the [HTTP Encrypted Content-Encoding](http://httpwg.org/http-extensions/draft-ietf-httpbis-encryption-encoding.html) draft. It's a port of the reference [JavaScript implementation](https://github.com/martinthomson/encrypted-content-encoding).

Currently, **ecec** only implements enough to support decrypting [Web Push messages](http://webpush-wg.github.io/webpush-encryption/), which use a shared secret derived using elliptic-curve Diffie-Hellman.

Encryption and usage without ECDH are planned for future releases. In the meantime, please have a look at `tools/ece-decrypt` for an example of how to use the library, or read on.

## Table of Contents

- [Usage](#usage)
  * [Generating subscription keys](#generating-subscription-keys)
  * [`aes128gcm`](#aes128gcm)
  * [`aesgcm`](#aesgcm)
- [Building](#building)
  * [Dependencies](#dependencies)
  * [macOS and \*nix](#macos-and-nix)
  * [Windows](#windows)
- [What is encrypted content-coding?](#what-is-encrypted-content-coding)
  * [Web Push](#web-push)
  * [`aes128gcm`](#aes128gcm-1)
  * [`aesgcm`](#aesgcm-1)
- [License](#license)

## Usage

### Generating subscription keys

```c
#include <ece.h>
#include <openssl/ec.h>
#include <openssl/ecdh.h>
#include <openssl/rand.h>

// Generate a public-private ECDH key pair for the push subscription.
EC_KEY* subKey = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
assert(subKey);
assert(EC_KEY_generate_key(subKey) > 0);

// Export the generated private key. The private key should never be sent to
// the app server. It should be persisted with the endpoint and auth secret,
// and used to decrypt all messages sent to the subscription.
size_t subPrivKeyLen = EC_KEY_priv2oct(subKey, NULL, 0);
assert(subPrivKeyLen);
ece_buf_t rawSubPrivKey;
assert(ece_buf_alloc(&rawSubPrivKey, subPrivKeyLen));
assert(EC_KEY_priv2oct(subKey, rawSubPrivKey.bytes, rawSubPrivKey.length) ==
       rawSubPrivKey.length);

// Export the subscription public key in uncompressed form. The public key
// should be sent to the app server, and used to encrypt messages.
ece_buf_t rawSubPubKey;
const EC_GROUP* subGrp = EC_KEY_get0_group(subKey);
const EC_POINT* subPubKeyPt = EC_KEY_get0_public_key(subKey);
size_t subPubKeyLen = EC_POINT_point2oct(subGrp, subPubKeyPt,
                                         POINT_CONVERSION_UNCOMPRESSED, NULL,
                                         0);
assert(subPubKeyLen);
assert(ece_buf_alloc(&rawSubPubKey, subPubKeyLen));
assert(EC_POINT_point2oct(subGrp, subPubKeyPt, POINT_CONVERSION_UNCOMPRESSED,
                          rawSubPubKey.bytes,
                          rawSubPubKey.length) == rawSubPubKey.length);

// Release the key once we're finished with it.
EC_KEY_free(subKey);

// Generate the authentication secret. The auth secret should be persisted
// with the subscription information, and sent to the app server.
ece_buf_t authSecret;
assert(ece_buf_alloc(&authSecret, 16));
assert(RAND_bytes(authSecret.bytes, authSecret.length) > 0);
```

### `aes128gcm`

This is the scheme from the latest version of the encrypted content-coding draft. It's not currently supported by any encryption library or browser, but will eventually replace `aesgcm`. This scheme removes the `Crypto-Key` and `Encryption` headers. Instead, the salt, record size, and sender public key are included in the payload as a binary header block.

```c
ece_buf_t payload;
// Set `bytes` and `length` to the contents of the encrypted payload.
// ecec does not take ownership of the contents; it's safe for the caller to
// free the contents after decryption.
payload.bytes = NULL;
payload.length = 0;

// The plaintext is reset before decryption, and freed on error. If decryption
// succeeds, we take ownership of the contents. The contents are allocated with
// `malloc`, so it's safe to transfer ownership to functions that call
// `free(plaintext.bytes)`.
ece_buf_t plaintext;

int err =
  ece_aes128gcm_decrypt(&rawSubPrivKey, &authSecret, &payload, &plaintext);

assert(!err);
ece_buf_free(&plaintext);
```

### `aesgcm`

All [Web Push libraries](https://github.com/web-push-libs) support the "aesgcm" scheme, as well as Firefox 46+ and Chrome 50+. The app server includes its public key in the `Crypto-Key` HTTP header, the salt and record size in the `Encryption` header, and the encrypted payload in the body of the `POST` request.

* The `Crypto-Key` header comprises one or more comma-delimited parameters. The first parameter must include a `dh` name-value pair, containing the sender's Base64url-encoded public key.
* The `Encryption` header must include a `salt` name-value pair containing the sender's Base64url-encoded salt, and an optional `rs` pair specifying the record size.

If the `Crypto-Key` header contains multiple keys, the sender must also include a `keyid` to match the encryption parameters to the key. The drafts have examples for [a single key without a `keyid`](https://tools.ietf.org/html/draft-ietf-webpush-encryption-04#section-5), and [multiple keys with `keyid`s](https://tools.ietf.org/html/draft-ietf-httpbis-encryption-encoding-02#section-5.6).

**ecec** will extract the relevant parameters from the `Crypto-Key` and `Encryption` headers before decrypting the message. You don't need to parse the headers yourself.

```c
const char* cryptoKeyHeader = "dh=...";
const char* encryptionHeader = "salt=...; rs=...";

// The same ownership rules apply as for `ece_aes128gcm_decrypt`.
ece_buf_t ciphertext;
ciphertext.bytes = NULL;
ciphertext.length = 0;

ece_buf_t plaintext;

int err = ece_aesgcm_decrypt(&rawSubPrivKey, &authSecret, cryptoKeyHeader,
                             encryptionHeader, &ciphertext, &plaintext);

assert(!err);
ece_buf_free(&plaintext);
```

## Building

### Dependencies

* [OpenSSL](https://www.openssl.org/) 1.1.0 or higher
* [CMake](https://cmake.org/) 3.1 or higher
* A C99-capable compiler, like [Clang](https://clang.llvm.org/) 3.4, [GCC](https://gcc.gnu.org/) 4.6, or [Visual Studio](https://www.visualstudio.com/vs/community/) 2015

### macOS and \*nix

OpenSSL 1.1.0 is new, and backward-incompatible with 1.0.x. If your package manager ([MacPorts](https://www.macports.org/), [Homebrew](https://brew.sh/), [APT](https://help.ubuntu.com/community/AptGet/Howto), [DNF](https://dnf.readthedocs.io/en/latest/), [yum](http://yum.baseurl.org/)) doesn't have 1.1.0 yet, you'll need to compile it yourself. **ecec** does this to run its tests on [Travis CI](https://docs.travis-ci.com/user/ci-environment/); please see `.travis.yml` for the commands.

In particular, you'll need to set the `OPENSSL_ROOT_DIR` cache entry for CMake to find your compiled version. To build the library:

```shell
> mkdir build
> cd build
> cmake -DOPENSSL_ROOT_DIR=/usr/local ..
> make
```

To build the decryption tool:

```shell
> make ece-decrypt
> ./ece-decrypt
```

To run the tests:

```shell
> make check
```

### Windows

[Shining Light](https://slproweb.com/products/Win32OpenSSL.html) provides OpenSSL binaries for Windows. The installer will ask if you want to copy the OpenSSL DLLs into the system directory, or the OpenSSL binaries directory. If you choose the binaries directory, you'll need to add it to your `Path`.

To do so, right-click the Start button, navigate to "System" > "Advanced system settings" > "Environment Variables...", find `Path` under "System variables", click "Edit" > "New", and enter the directory name. This will be `C:\OpenSSL-Win64\bin` if you've installed the 64-bit version in the default location.

You can then build the library like so:

```powershell
> mkdir build
> cd build
> cmake -G "Visual Studio 14 2015 Win64" -DOPENSSL_ROOT_DIR=C:\OpenSSL-Win64 ..
> cmake --build .
```

To build the decryption tool:

```powershell
> cmake --build . --target ece-decrypt
> .\Debug\ece-decrypt
```

To run the tests:

```powershell
> cmake --build . --target check
```

## What is encrypted content-coding?

Like [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security), encrypted content-coding uses Diffie-Hellman key exchange to derive a shared secret, which, in turn, is used to derive a symmetric encryption key for a block cipher. This encoding uses [ECDH](https://en.wikipedia.org/wiki/Elliptic_curve_Diffie-Hellman) for key exchange, and [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) [GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode) for the block cipher.

Key exchange is a process where a sender and a receiver generate public-private key pairs, then exchange public keys. The sender combines the receiver's public key with its own private key to obtain a secret. Meanwhile, the receiver combines the sender's public key with its private key to obtain the same secret. [Wikipedia](https://en.wikipedia.org/wiki/Diffie–Hellman_key_exchange) has a good visual explanation.

The shared ECDH secret isn't directly usable as an encryption key. Instead, both the sender and receiver combine the shared ECDH secret with an [authentication secret](https://tools.ietf.org/html/draft-ietf-webpush-encryption-08#section-3.2), to produce a 32-byte pseudorandom key (PRK). The auth secret is a random 16-byte array generated by the receiver, and shared with the sender along with the receiver's public key. Both parties use [HKDF](https://tools.ietf.org/html/rfc5869) to derive the PRK from the ECDH secret, using the formula `PRK = HKDF-Expand(HKDF-Extract(authSecret, sharedSecret), prkInfo, 32)`. RFC 5869 describes the inputs to `HKDF-Expand` and `HKDF-Extract`, and how they work. `prkInfo` is different depending on the encryption scheme used; more on that later.

Next, the sender and receiver combine the PRK with a random 16-byte salt. The salt is generated by the sender, and shared with the receiver as part of the message payload. The PRK undergoes two rounds of HKDF to derive the symmetric key and nonce: `key = HKDF-Expand(HKDF-Extract(salt, PRK), keyInfo, 16)`, and `nonce = HKDF-Expand(HKDF-Extract(salt, PRK), nonceInfo, 12)`. As with `prkInfo` above, `keyInfo` and `nonceInfo` are different depending on the exact scheme.

Finally, the sender chunks the plaintext into fixed-size records, and includes this size in the message payload as the `rs`. The chunks are numbered 0 to N; this is called the sequence number (SEQ), and is used to derive the [IV](https://en.wikipedia.org/wiki/Initialization_vector). All chunks should be `rs` bytes long, but the final chunk can be smaller if needed.

Each plaintext chunk is padded, then encrypted with AES using the 16-byte symmetric key and a 12-byte IV. The IV is [generated](https://tools.ietf.org/html/draft-ietf-httpbis-encryption-encoding-07#section-2.3) from the nonce by [XOR-ing](https://en.wikipedia.org/wiki/Exclusive_or) the last 6 bytes of the 12-byte nonce with the sequence number. Afterward, the sender appends the GCM authentication tag to the encrypted chunk, producing the final encrypted record.

To decrypt the message, the receiver chunks the ciphertext into N encrypted records, decrypts each chunk, validates the auth tag, and removes the padding.

### Web Push

In Web Push, the app server is the sender, and the browser ("user agent") is the receiver. The browser generates a public-private ECDH key pair and 16-byte auth secret for each push subscription. These keys are static; they're used to decrypt all messages sent to this subscription. The browser exposes the subscription endpoint, public key, and auth secret to the web app via the [Push DOM API](https://w3c.github.io/push-api/). The web app then delivers the endpoint and keys to the app server.

When the app server wants to send a push message, it generates its own public-private key pair, and computes the shared ECDH secret using the subscription public key. This key pair is ephemeral: it should be discarded after the message is sent, and a new key pair used for the next message. The app server encrypts the payload using the process outlined above, and includes the salt, sender public key, and ciphertext in a `POST` request to the endpoint. The push endpoint relays the encrypted payload to the browser. Finally, the browser decrypts the payload with the subscription private key, and delivers the plaintext to the web app. Because the endpoint doesn't know the private key, it can't decrypt or tamper with the message.

### `aes128gcm`

* `prkInfo` is the string `"WebPush: info\0"`, followed by the receiver and sender public keys in uncompressed form. Unlike `aesgcm`, these are not length-prefixed.
* `keyInfo` is the static string `"Content-Encoding: aes128gcm\0"`.
* `nonceInfo` is the static string `"Content-Encoding: nonce\0"`.
* Padding is at the end of each plaintext chunk. The padding block comprises the delimiter, which is `0x02` for the last chunk, and `0x01` for the other chunks. Up to `rs - 16` bytes of `0x0` padding can follow the delimiter.

### `aesgcm`

* `prkInfo` is the static string `"Content-Encoding: auth\0"`.
* `keyInfo` is `"Content-Encoding: aesgcm\0P-256\0"`, followed by the length-prefixed (unsigned 16-bit integers) receiver and sender public keys in uncompressed form.
* `nonceInfo` is `"Content-Encoding: nonce\0P-256\0"`, followed by the length-prefixed public keys in the same form as `keyInfo`.
* Padding is at the beginning of each plaintext chunk. The padding block comprises the number (unsigned 16-bit integer) of padding bytes, followed by that many `0x0`-valued bytes.

## License

MIT.
