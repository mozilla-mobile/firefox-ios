/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This file contains code that was copied from the ring crate which is under
// the ISC license, reproduced below:

// Copyright 2015-2017 Brian Smith.

// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.

// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHORS DISCLAIM ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
// OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
// CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use crate::{constant_time, digest, error::*};

/// A calculated signature value.
/// This is a type-safe wrappper that discourages attempts at comparing signatures
/// for equality, which might naively be done using a non-constant-time comparison.
#[derive(Clone)]
pub struct Signature(pub(crate) digest::Digest);

impl AsRef<[u8]> for Signature {
    #[inline]
    fn as_ref(&self) -> &[u8] {
        self.0.as_ref()
    }
}

/// A key to use for HMAC signing.
pub struct SigningKey {
    pub(crate) digest_alg: &'static digest::Algorithm,
    pub(crate) key_value: Vec<u8>,
}

impl SigningKey {
    pub fn new(digest_alg: &'static digest::Algorithm, key_value: &[u8]) -> Self {
        SigningKey {
            digest_alg,
            key_value: key_value.to_vec(),
        }
    }

    #[inline]
    pub fn digest_algorithm(&self) -> &'static digest::Algorithm {
        self.digest_alg
    }
}

/// A key to use for HMAC authentication.
pub struct VerificationKey {
    wrapped: SigningKey,
}

impl VerificationKey {
    pub fn new(digest_alg: &'static digest::Algorithm, key_value: &[u8]) -> Self {
        VerificationKey {
            wrapped: SigningKey::new(digest_alg, key_value),
        }
    }

    #[inline]
    pub fn digest_algorithm(&self) -> &'static digest::Algorithm {
        self.wrapped.digest_algorithm()
    }
}

/// Calculate the HMAC of `data` using `key` and verify it corresponds to the provided signature.
pub fn verify(key: &VerificationKey, data: &[u8], signature: &[u8]) -> Result<()> {
    verify_with_own_key(&key.wrapped, data, signature)
}

/// Equivalent to `verify` but allows the consumer to pass a `SigningKey`.
pub fn verify_with_own_key(key: &SigningKey, data: &[u8], signature: &[u8]) -> Result<()> {
    constant_time::verify_slices_are_equal(sign(key, data)?.as_ref(), signature)
}

/// Calculate the HMAC of `data` using `key`.
pub fn sign(key: &SigningKey, data: &[u8]) -> Result<Signature> {
    let value = nss::pk11::context::hmac_sign(key.digest_alg, &key.key_value, data)?;
    Ok(Signature(digest::Digest {
        value,
        algorithm: key.digest_alg.clone(),
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use hex;

    const KEY: &[u8] = b"key";
    const MESSAGE: &[u8] = b"The quick brown fox jumps over the lazy dog";
    const SIGNATURE_HEX: &str = "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8";

    #[test]
    fn hmac_sign() {
        let key = SigningKey::new(&digest::SHA256, KEY);
        let signature = sign(&key, MESSAGE).unwrap();
        let expected_signature = hex::decode(SIGNATURE_HEX).unwrap();
        assert_eq!(signature.as_ref(), expected_signature.as_slice());
        assert!(verify_with_own_key(&key, MESSAGE, &expected_signature).is_ok());
    }

    #[test]
    fn hmac_sign_gives_different_signatures_for_different_keys() {
        let key = SigningKey::new(&digest::SHA256, b"another key");
        let signature = sign(&key, MESSAGE).unwrap();
        let expected_signature = hex::decode(SIGNATURE_HEX).unwrap();
        assert_ne!(signature.as_ref(), expected_signature.as_slice());
    }

    #[test]
    fn hmac_sign_gives_different_signatures_for_different_messages() {
        let key = SigningKey::new(&digest::SHA256, KEY);
        let signature = sign(&key, b"a different message").unwrap();
        let expected_signature = hex::decode(SIGNATURE_HEX).unwrap();
        assert_ne!(signature.as_ref(), expected_signature.as_slice());
    }

    #[test]
    fn hmac_verify() {
        let key = VerificationKey::new(&digest::SHA256, KEY);
        let expected_signature = hex::decode(SIGNATURE_HEX).unwrap();
        assert!(verify(&key, MESSAGE, &expected_signature).is_ok());
    }

    #[test]
    fn hmac_verify_fails_with_incorrect_signature() {
        let key = VerificationKey::new(&digest::SHA256, KEY);
        let signature = hex::decode(SIGNATURE_HEX).unwrap();
        for i in 0..signature.len() {
            let mut wrong_signature = signature.clone();
            wrong_signature[i] = wrong_signature[i].wrapping_add(1);
            assert!(verify(&key, MESSAGE, &wrong_signature).is_err());
        }
    }

    #[test]
    fn hmac_verify_fails_with_incorrect_key() {
        let key = VerificationKey::new(&digest::SHA256, b"wrong key");
        let signature = hex::decode(SIGNATURE_HEX).unwrap();
        assert!(verify(&key, MESSAGE, &signature).is_err());
    }

    #[test]
    fn hmac_sign_cleanly_rejects_gigantic_keys() {
        if (std::u32::MAX as usize) < std::usize::MAX {
            let key_bytes = vec![0; (std::u32::MAX as usize) + 1];
            // Direct construction of SigningKey to avoid instantiating the array.
            let key = SigningKey {
                digest_alg: &digest::SHA256,
                key_value: key_bytes,
            };
            assert!(sign(&key, MESSAGE).is_err());
        }
    }

    #[test]
    fn hmac_verify_cleanly_rejects_gigantic_keys() {
        if (std::u32::MAX as usize) < std::usize::MAX {
            let key_bytes = vec![0; (std::u32::MAX as usize) + 1];
            // Direct construction of VerificationKey to avoid instantiating the array.
            let key = VerificationKey {
                wrapped: SigningKey {
                    digest_alg: &digest::SHA256,
                    key_value: key_bytes,
                },
            };
            let signature = hex::decode(SIGNATURE_HEX).unwrap();
            assert!(verify(&key, MESSAGE, &signature).is_err());
        }
    }

    #[test]
    fn hmac_sign_cleanly_rejects_gigantic_messages() {
        if (std::u32::MAX as usize) < std::usize::MAX {
            let key = SigningKey::new(&digest::SHA256, KEY);
            let message = vec![0; (std::u32::MAX as usize) + 1];
            assert!(sign(&key, &message).is_err());
        }
    }

    #[test]
    fn hmac_verify_cleanly_rejects_gigantic_messages() {
        if (std::u32::MAX as usize) < std::usize::MAX {
            let key = VerificationKey::new(&digest::SHA256, KEY);
            let signature = hex::decode(SIGNATURE_HEX).unwrap();
            let message = vec![0; (std::u32::MAX as usize) + 1];
            assert!(verify(&key, &message, &signature).is_err());
        }
    }
}
