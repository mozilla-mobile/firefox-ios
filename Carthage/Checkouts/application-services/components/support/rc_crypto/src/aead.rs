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

mod aes_cbc;
mod aes_gcm;

use crate::error::*;
pub use aes_cbc::LEGACY_SYNC_AES_256_CBC_HMAC_SHA256;
pub use aes_gcm::{AES_128_GCM, AES_256_GCM};
use nss::aes;

pub fn open(
    key: &OpeningKey,
    nonce: Nonce,
    aad: Aad<'_>,
    ciphertext_and_tag: &[u8],
) -> Result<Vec<u8>> {
    (key.algorithm().open)(&key.key, nonce, &aad, ciphertext_and_tag)
}

pub fn seal(key: &SealingKey, nonce: Nonce, aad: Aad<'_>, plaintext: &[u8]) -> Result<Vec<u8>> {
    (key.algorithm().seal)(&key.key, nonce, &aad, plaintext)
}

/// The additional authenticated data (AAD) for an opening or sealing
/// operation. This data is authenticated but is **not** encrypted.
/// This is a type-safe wrapper around the raw bytes designed to encourage
/// correct use of the API.
#[repr(transparent)]
pub struct Aad<'a>(&'a [u8]);

impl<'a> Aad<'a> {
    /// Construct the `Aad` by borrowing a contiguous sequence of bytes.
    #[inline]
    pub fn from(aad: &'a [u8]) -> Self {
        Aad(aad)
    }
}

impl Aad<'static> {
    /// Construct an empty `Aad`.
    pub fn empty() -> Self {
        Self::from(&[])
    }
}

/// The nonce for an opening or sealing operation.
/// This is a type-safe wrapper around the raw bytes designed to encourage
/// correct use of the API.
pub struct Nonce(Vec<u8>);

impl Nonce {
    #[inline]
    pub fn try_assume_unique_for_key(algorithm: &'static Algorithm, value: &[u8]) -> Result<Self> {
        if value.len() != algorithm.nonce_len() {
            return Err(ErrorKind::InternalError.into());
        }
        Ok(Self(value.to_vec()))
    }
}

pub struct OpeningKey {
    key: Key,
}

impl OpeningKey {
    /// Create a new opening key.
    ///
    /// `key_bytes` must be exactly `algorithm.key_len` bytes long.
    #[inline]
    pub fn new(algorithm: &'static Algorithm, key_bytes: &[u8]) -> Result<Self> {
        Ok(Self {
            key: Key::new(algorithm, key_bytes)?,
        })
    }

    /// The key's AEAD algorithm.
    #[inline]
    pub fn algorithm(&self) -> &'static Algorithm {
        self.key.algorithm()
    }
}

pub struct SealingKey {
    key: Key,
}

impl SealingKey {
    /// Create a new sealing key.
    ///
    /// `key_bytes` must be exactly `algorithm.key_len` bytes long.
    #[inline]
    pub fn new(algorithm: &'static Algorithm, key_bytes: &[u8]) -> Result<Self> {
        Ok(Self {
            key: Key::new(algorithm, key_bytes)?,
        })
    }

    /// The key's AEAD algorithm.
    #[inline]
    pub fn algorithm(&self) -> &'static Algorithm {
        self.key.algorithm()
    }
}

/// `OpeningKey` and `SealingKey` are type-safety wrappers around `Key`.
pub(crate) struct Key {
    key_value: Vec<u8>,
    algorithm: &'static Algorithm,
}

impl Key {
    fn new(algorithm: &'static Algorithm, key_bytes: &[u8]) -> Result<Self> {
        if key_bytes.len() != algorithm.key_len() {
            return Err(ErrorKind::InternalError.into());
        }
        Ok(Key {
            key_value: key_bytes.to_vec(),
            algorithm,
        })
    }

    #[inline]
    pub fn algorithm(&self) -> &'static Algorithm {
        self.algorithm
    }
}

// An AEAD algorithm.
#[allow(clippy::type_complexity)]
pub struct Algorithm {
    tag_len: usize,
    key_len: usize,
    nonce_len: usize,
    open: fn(key: &Key, nonce: Nonce, aad: &Aad<'_>, ciphertext_and_tag: &[u8]) -> Result<Vec<u8>>,
    seal: fn(key: &Key, nonce: Nonce, aad: &Aad<'_>, plaintext: &[u8]) -> Result<Vec<u8>>,
}

impl Algorithm {
    /// The length of the key.
    #[inline]
    pub const fn key_len(&self) -> usize {
        self.key_len
    }

    /// The length of a tag.
    #[inline]
    pub const fn tag_len(&self) -> usize {
        self.tag_len
    }

    /// The length of the nonces.
    #[inline]
    pub const fn nonce_len(&self) -> usize {
        self.nonce_len
    }
}

pub(crate) enum Direction {
    Opening,
    Sealing,
}

impl Direction {
    fn to_nss_operation(&self) -> aes::Operation {
        match self {
            Direction::Opening => aes::Operation::Decrypt,
            Direction::Sealing => aes::Operation::Encrypt,
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    static ALL_ALGORITHMS: &[&Algorithm] = &[
        &LEGACY_SYNC_AES_256_CBC_HMAC_SHA256,
        &AES_128_GCM,
        &AES_256_GCM,
    ];
    static ALL_ALGORITHMS_THAT_SUPPORT_AAD: &[&Algorithm] = &[&AES_128_GCM, &AES_256_GCM];

    #[test]
    fn test_roundtrip() {
        for algorithm in ALL_ALGORITHMS {
            let mut cleartext_bytes = vec![0u8; 127];
            crate::rand::fill(&mut cleartext_bytes).unwrap();

            let mut key_bytes = vec![0u8; algorithm.key_len()];
            crate::rand::fill(&mut key_bytes).unwrap();

            let nonce_bytes = vec![0u8; algorithm.nonce_len()];

            let key = SealingKey::new(algorithm, &key_bytes).unwrap();
            let nonce = Nonce::try_assume_unique_for_key(algorithm, &nonce_bytes).unwrap();
            let ciphertext_bytes = seal(&key, nonce, Aad::empty(), &cleartext_bytes).unwrap();

            let key = OpeningKey::new(algorithm, &key_bytes).unwrap();
            let nonce = Nonce::try_assume_unique_for_key(algorithm, &nonce_bytes).unwrap();
            let roundtriped_cleartext_bytes =
                open(&key, nonce, Aad::empty(), &ciphertext_bytes).unwrap();
            assert_eq!(roundtriped_cleartext_bytes, cleartext_bytes);
        }
    }

    #[test]
    fn test_cant_open_with_mismatched_key() {
        let mut key_bytes_1 = vec![0u8; AES_256_GCM.key_len()];
        crate::rand::fill(&mut key_bytes_1).unwrap();

        let mut key_bytes_2 = vec![0u8; AES_128_GCM.key_len()];
        crate::rand::fill(&mut key_bytes_2).unwrap();

        let nonce_bytes = vec![0u8; AES_256_GCM.nonce_len()];

        let key = SealingKey::new(&AES_256_GCM, &key_bytes_1).unwrap();
        let nonce = Nonce::try_assume_unique_for_key(&AES_256_GCM, &nonce_bytes).unwrap();
        let ciphertext_bytes = seal(&key, nonce, Aad::empty(), &[0u8; 0]).unwrap();

        let key = OpeningKey::new(&AES_128_GCM, &key_bytes_2).unwrap();
        let nonce = Nonce::try_assume_unique_for_key(&AES_128_GCM, &nonce_bytes).unwrap();
        let result = open(&key, nonce, Aad::empty(), &ciphertext_bytes);
        assert!(result.is_err());
    }

    #[test]
    fn test_cant_open_modified_ciphertext() {
        for algorithm in ALL_ALGORITHMS {
            let mut key_bytes = vec![0u8; algorithm.key_len()];
            crate::rand::fill(&mut key_bytes).unwrap();

            let nonce_bytes = vec![0u8; algorithm.nonce_len()];

            let key = SealingKey::new(algorithm, &key_bytes).unwrap();
            let nonce = Nonce::try_assume_unique_for_key(algorithm, &nonce_bytes).unwrap();
            let ciphertext_bytes = seal(&key, nonce, Aad::empty(), &[0u8; 0]).unwrap();

            for i in 0..ciphertext_bytes.len() {
                let mut modified_ciphertext = ciphertext_bytes.clone();
                modified_ciphertext[i] = modified_ciphertext[i].wrapping_add(1);

                let key = OpeningKey::new(algorithm, &key_bytes).unwrap();
                let nonce = Nonce::try_assume_unique_for_key(algorithm, &nonce_bytes).unwrap();
                let result = open(&key, nonce, Aad::empty(), &modified_ciphertext);
                assert!(result.is_err());
            }
        }
    }

    #[test]
    fn test_cant_open_with_incorrect_associated_data() {
        for algorithm in ALL_ALGORITHMS_THAT_SUPPORT_AAD {
            let mut key_bytes = vec![0u8; algorithm.key_len()];
            crate::rand::fill(&mut key_bytes).unwrap();

            let nonce_bytes = vec![0u8; algorithm.nonce_len()];

            let key = SealingKey::new(algorithm, &key_bytes).unwrap();
            let nonce = Nonce::try_assume_unique_for_key(algorithm, &nonce_bytes).unwrap();
            let ciphertext_bytes = seal(&key, nonce, Aad::from(&[1, 2, 3]), &[0u8; 0]).unwrap();

            let key = OpeningKey::new(algorithm, &key_bytes).unwrap();
            let nonce = Nonce::try_assume_unique_for_key(algorithm, &nonce_bytes).unwrap();
            let result = open(&key, nonce, Aad::empty(), &ciphertext_bytes);
            assert!(result.is_err());

            let nonce = Nonce::try_assume_unique_for_key(&AES_256_GCM, &nonce_bytes).unwrap();
            let result = open(&key, nonce, Aad::from(&[2, 3, 4]), &ciphertext_bytes);
            assert!(result.is_err());
        }
    }

    #[test]
    fn test_cant_use_incorrectly_sized_key() {
        for algorithm in ALL_ALGORITHMS {
            let key_bytes = vec![0u8; algorithm.key_len() - 1];
            let result = Key::new(&algorithm, &key_bytes);
            assert!(result.is_err());

            let key_bytes = vec![0u8; algorithm.key_len() + 1];
            let result = Key::new(&algorithm, &key_bytes);
            assert!(result.is_err());
        }
    }

    #[test]
    fn test_cant_use_incorrectly_sized_nonce() {
        for algorithm in ALL_ALGORITHMS {
            let nonce_bytes = vec![0u8; algorithm.nonce_len() - 1];
            let result = Nonce::try_assume_unique_for_key(&algorithm, &nonce_bytes);
            assert!(result.is_err());

            let nonce_bytes = vec![0u8; algorithm.nonce_len() + 1];
            let result = Nonce::try_assume_unique_for_key(&algorithm, &nonce_bytes);
            assert!(result.is_err());
        }
    }
}
