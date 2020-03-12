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

use crate::{aead, error::*};
use nss::aes;

/// AES-128 in GCM mode with 128-bit tags and 96 bit nonces.
pub static AES_128_GCM: aead::Algorithm = aead::Algorithm {
    key_len: 16,
    tag_len: 16,
    nonce_len: 96 / 8,
    open,
    seal,
};

/// AES-256 in GCM mode with 128-bit tags and 96 bit nonces.
pub static AES_256_GCM: aead::Algorithm = aead::Algorithm {
    key_len: 32,
    tag_len: 16,
    nonce_len: 96 / 8,
    open,
    seal,
};

pub(crate) fn open(
    key: &aead::Key,
    nonce: aead::Nonce,
    aad: &aead::Aad<'_>,
    ciphertext_and_tag: &[u8],
) -> Result<Vec<u8>> {
    aes_gcm(
        key,
        nonce,
        aad,
        ciphertext_and_tag,
        aead::Direction::Opening,
    )
}

pub(crate) fn seal(
    key: &aead::Key,
    nonce: aead::Nonce,
    aad: &aead::Aad<'_>,
    plaintext: &[u8],
) -> Result<Vec<u8>> {
    aes_gcm(key, nonce, aad, plaintext, aead::Direction::Sealing)
}

fn aes_gcm(
    key: &aead::Key,
    nonce: aead::Nonce,
    aad: &aead::Aad<'_>,
    data: &[u8],
    direction: aead::Direction,
) -> Result<Vec<u8>> {
    Ok(aes::aes_gcm_crypt(
        &key.key_value,
        &nonce.0,
        &aad.0,
        data,
        direction.to_nss_operation(),
    )?)
}

#[cfg(test)]
mod test {
    use super::*;

    // Test vector from the AES-GCM spec.
    const NONCE_HEX: &str = "cafebabefacedbaddecaf888";
    const KEY_HEX: &str = "feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308";
    const AAD_HEX: &str = "feedfacedeadbeeffeedfacedeadbeefabaddad2";
    const TAG_HEX: &str = "76fc6ece0f4e1768cddf8853bb2d551b";
    const CIPHERTEXT_HEX: &str =
        "522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662";
    const CLEARTEXT_HEX: &str =
        "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39";

    #[test]
    fn test_decrypt() {
        let key_bytes = hex::decode(KEY_HEX).unwrap();
        let key = aead::Key::new(&AES_256_GCM, &key_bytes).unwrap();
        let mut ciphertext_and_tag = hex::decode(&CIPHERTEXT_HEX).unwrap();
        let tag = hex::decode(&TAG_HEX).unwrap();
        ciphertext_and_tag.extend(&tag);

        let iv = hex::decode(NONCE_HEX).unwrap();
        let nonce = aead::Nonce::try_assume_unique_for_key(&AES_256_GCM, &iv).unwrap();
        let aad_bytes = hex::decode(AAD_HEX).unwrap();
        let aad = aead::Aad::from(&aad_bytes);
        let cleartext_bytes = open(&key, nonce, &aad, &ciphertext_and_tag).unwrap();
        let encoded_cleartext = hex::encode(cleartext_bytes);
        assert_eq!(&CLEARTEXT_HEX, &encoded_cleartext);
    }

    #[test]
    fn test_encrypt() {
        let key_bytes = hex::decode(KEY_HEX).unwrap();
        let key = aead::Key::new(&AES_256_GCM, &key_bytes).unwrap();
        let cleartext = hex::decode(&CLEARTEXT_HEX).unwrap();

        let iv = hex::decode(NONCE_HEX).unwrap();
        let nonce = aead::Nonce::try_assume_unique_for_key(&AES_256_GCM, &iv).unwrap();
        let aad_bytes = hex::decode(AAD_HEX).unwrap();
        let aad = aead::Aad::from(&aad_bytes);
        let ciphertext_bytes = seal(&key, nonce, &aad, &cleartext).unwrap();

        let expected_tag = hex::decode(&TAG_HEX).unwrap();
        let mut expected_ciphertext = hex::decode(&CIPHERTEXT_HEX).unwrap();
        expected_ciphertext.extend(&expected_tag);
        assert_eq!(&expected_ciphertext, &ciphertext_bytes);
    }

    #[test]
    fn test_roundtrip() {
        let key_bytes = hex::decode(KEY_HEX).unwrap();
        let key = aead::Key::new(&AES_256_GCM, &key_bytes).unwrap();
        let cleartext = hex::decode(&CLEARTEXT_HEX).unwrap();

        let iv = hex::decode(NONCE_HEX).unwrap();
        let nonce = aead::Nonce::try_assume_unique_for_key(&AES_256_GCM, &iv).unwrap();
        let ciphertext_bytes = seal(&key, nonce, &aead::Aad::empty(), &cleartext).unwrap();
        let nonce = aead::Nonce::try_assume_unique_for_key(&AES_256_GCM, &iv).unwrap();
        let roundtriped_cleartext_bytes =
            open(&key, nonce, &aead::Aad::empty(), &ciphertext_bytes).unwrap();
        assert_eq!(roundtriped_cleartext_bytes, cleartext);
    }
}
