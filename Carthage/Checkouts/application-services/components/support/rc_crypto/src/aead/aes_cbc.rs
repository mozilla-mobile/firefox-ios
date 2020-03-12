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

use crate::{aead, digest, error::*, hmac};
use nss::aes;

/// AES-256 in CBC mode with HMAC-SHA256 tags and 128 bit nonces.
/// This is a Sync 1.5 specific encryption scheme, do not use for new
/// applications, there are better options out there nowadays.
/// Important note: The HMAC tag verification is done against the
/// base64 representation of the ciphertext.
/// More details here: https://mozilla-services.readthedocs.io/en/latest/sync/storageformat5.html#record-encryption
pub static LEGACY_SYNC_AES_256_CBC_HMAC_SHA256: aead::Algorithm = aead::Algorithm {
    key_len: 64, // 32 bytes for the AES key, 32 bytes for the HMAC key.
    tag_len: 32,
    nonce_len: 128 / 8,
    open,
    seal,
};

// Warning: This does not run in constant time (which is fine for our usage).
pub(crate) fn open(
    key: &aead::Key,
    nonce: aead::Nonce,
    aad: &aead::Aad<'_>,
    ciphertext_and_tag: &[u8],
) -> Result<Vec<u8>> {
    let ciphertext_len = ciphertext_and_tag
        .len()
        .checked_sub(key.algorithm().tag_len())
        .ok_or_else(|| ErrorKind::InternalError)?;
    let (ciphertext, hmac_signature) = ciphertext_and_tag.split_at(ciphertext_len);
    let (aes_key, hmac_key_bytes) = extract_keys(&key);
    // 1. Tag (HMAC signature) check.
    let hmac_key = hmac::VerificationKey::new(&digest::SHA256, &hmac_key_bytes);
    let hmac_res = hmac::verify(
        &hmac_key,
        base64::encode(ciphertext).as_bytes(),
        hmac_signature,
    );
    // 2. Decryption.
    let cbc_res = aes_cbc(aes_key, nonce, aad, ciphertext, aead::Direction::Opening);
    // To make this function as constant-time as possible, we always try to run both
    // the hmac and the decryption operation.
    hmac_res.and(cbc_res)
}

pub(crate) fn seal(
    key: &aead::Key,
    nonce: aead::Nonce,
    aad: &aead::Aad<'_>,
    plaintext: &[u8],
) -> Result<Vec<u8>> {
    let (aes_key, hmac_key_bytes) = extract_keys(&key);
    // 1. Encryption.
    let mut ciphertext = aes_cbc(aes_key, nonce, aad, plaintext, aead::Direction::Sealing)?;
    // 2. Tag (HMAC signature) generation.
    let hmac_key = hmac::SigningKey::new(&digest::SHA256, &hmac_key_bytes);
    let signature = hmac::sign(&hmac_key, base64::encode(&ciphertext).as_bytes())?;
    ciphertext.extend(&signature.0.value);
    Ok(ciphertext)
}

fn extract_keys(key: &aead::Key) -> (&[u8], &[u8]) {
    // Always split at 32 since we only do AES 256 w/ HMAC 256 tag.
    let (aes_key, hmac_key_bytes) = key.key_value.split_at(32);
    (aes_key, hmac_key_bytes)
}

fn aes_cbc(
    aes_key: &[u8],
    nonce: aead::Nonce,
    aad: &aead::Aad<'_>,
    data: &[u8],
    direction: aead::Direction,
) -> Result<Vec<u8>> {
    if !aad.0.is_empty() {
        // CBC mode does not support AAD.
        return Err(ErrorKind::InternalError.into());
    }
    Ok(aes::aes_cbc_crypt(
        aes_key,
        &nonce.0,
        data,
        direction.to_nss_operation(),
    )?)
}

#[cfg(test)]
mod test {
    use super::*;

    // These are the test vectors used by the sync15 crate, but concatenated
    // together rather than split into individual pieces.
    const IV_B64: &str = "GX8L37AAb2FZJMzIoXlX8w==";

    const KEY_B64: &str = "9K/wLdXdw+nrTtXo4ZpECyHFNr4d7aYHqeg3KW9+m6Qwye0R+62At\
                           NzwWVMtAWazz/Ew+YKV2o+Wr9BBcSPHvQ==";

    const CIPHERTEXT_AND_TAG_B64: &str =
        "NMsdnRulLwQsVcwxKW9XwaUe7ouJk5Wn80QhbD80l0HEcZGCynh45qIbeYBik0lgcHbKm\
         lIxTJNwU+OeqipN+/j7MqhjKOGIlvbpiPQQLC6/ffF2vbzL0nzMUuSyvaQzyGGkSYM2xU\
         Ft06aNivoQTvU2GgGmUK6MvadoY38hhW2LCMkoZcNfgCqJ26lO1O0sEO6zHsk3IVz6vsK\
         iJ2Hq6VCo7hu123wNegmujHWQSGyf8JeudZjKzfi0OFRRvvm4QAKyBWf0MgrW1F8SFDnV\
         fkq8amCB7NhdwhgLWbN+21NitNwWYknoEWe1m6hmGZDgDT32uxzWxCV8QqqrpH/ZggViE\
         r9uMgoy4lYaWqP7G5WKvvechc62aqnsNEYhH26A5QgzmlNyvB+KPFvPsYzxDnSCjOoRSL\
         x7GG86wT59QZyx5sGKww3rcCNrwNZaRvek3OO4sOAs+SGCuRTjr6XuvA==";

    const CLEARTEXT_B64: &str =
        "eyJpZCI6IjVxUnNnWFdSSlpYciIsImhpc3RVcmkiOiJmaWxlOi8vL1VzZXJzL2phc29u\
         L0xpYnJhcnkvQXBwbGljYXRpb24lMjBTdXBwb3J0L0ZpcmVmb3gvUHJvZmlsZXMva3Nn\
         ZDd3cGsuTG9jYWxTeW5jU2VydmVyL3dlYXZlL2xvZ3MvIiwidGl0bGUiOiJJbmRleCBv\
         ZiBmaWxlOi8vL1VzZXJzL2phc29uL0xpYnJhcnkvQXBwbGljYXRpb24gU3VwcG9ydC9G\
         aXJlZm94L1Byb2ZpbGVzL2tzZ2Q3d3BrLkxvY2FsU3luY1NlcnZlci93ZWF2ZS9sb2dz\
         LyIsInZpc2l0cyI6W3siZGF0ZSI6MTMxOTE0OTAxMjM3MjQyNSwidHlwZSI6MX1dfQ==";

    #[test]
    fn test_decrypt() {
        let key_bytes = base64::decode(KEY_B64).unwrap();
        let key = aead::Key::new(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes).unwrap();
        let ciphertext_and_tag = base64::decode(&CIPHERTEXT_AND_TAG_B64).unwrap();

        let iv = base64::decode(IV_B64).unwrap();
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &iv)
                .unwrap();
        let cleartext_bytes = open(&key, nonce, &aead::Aad::empty(), &ciphertext_and_tag).unwrap();

        let expected_cleartext_bytes = base64::decode(&CLEARTEXT_B64).unwrap();
        assert_eq!(&expected_cleartext_bytes, &cleartext_bytes);
    }

    #[test]
    fn test_encrypt() {
        let key_bytes = base64::decode(KEY_B64).unwrap();
        let key = aead::Key::new(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes).unwrap();
        let cleartext = base64::decode(&CLEARTEXT_B64).unwrap();

        let iv = base64::decode(IV_B64).unwrap();
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &iv)
                .unwrap();
        let ciphertext_bytes = seal(&key, nonce, &aead::Aad::empty(), &cleartext).unwrap();

        let expected_ciphertext_bytes = base64::decode(&CIPHERTEXT_AND_TAG_B64).unwrap();
        assert_eq!(&expected_ciphertext_bytes, &ciphertext_bytes);
    }

    #[test]
    fn test_roundtrip() {
        let key_bytes = base64::decode(KEY_B64).unwrap();
        let key = aead::Key::new(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes).unwrap();
        let cleartext = base64::decode(&CLEARTEXT_B64).unwrap();

        let iv = base64::decode(IV_B64).unwrap();
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &iv)
                .unwrap();
        let ciphertext_bytes = seal(&key, nonce, &aead::Aad::empty(), &cleartext).unwrap();
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &iv)
                .unwrap();
        let roundtriped_cleartext_bytes =
            open(&key, nonce, &aead::Aad::empty(), &ciphertext_bytes).unwrap();
        assert_eq!(roundtriped_cleartext_bytes, cleartext);
    }

    #[test]
    fn test_decrypt_fails_with_wrong_aes_key() {
        let mut key_bytes = base64::decode(KEY_B64).unwrap();
        key_bytes[1] = b'X';

        let key = aead::Key::new(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes).unwrap();
        let ciphertext_and_tag = base64::decode(&CIPHERTEXT_AND_TAG_B64).unwrap();
        let iv = base64::decode(IV_B64).unwrap();
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &iv)
                .unwrap();

        let err = open(&key, nonce, &aead::Aad::empty(), &ciphertext_and_tag).unwrap_err();
        match err.kind() {
            ErrorKind::NSSError(_) | ErrorKind::InternalError => {}
            _ => panic!("unexpected error kind"),
        }
    }

    #[test]
    fn test_decrypt_fails_with_wrong_hmac_key() {
        let mut key_bytes = base64::decode(KEY_B64).unwrap();
        key_bytes[60] = b'X';

        let key = aead::Key::new(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes).unwrap();
        let ciphertext_and_tag = base64::decode(&CIPHERTEXT_AND_TAG_B64).unwrap();
        let iv = base64::decode(IV_B64).unwrap();
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &iv)
                .unwrap();

        let err = open(&key, nonce, &aead::Aad::empty(), &ciphertext_and_tag).unwrap_err();
        match err.kind() {
            ErrorKind::InternalError => {}
            _ => panic!("unexpected error kind"),
        }
    }

    #[test]
    fn test_decrypt_fails_with_modified_ciphertext() {
        let key_bytes = base64::decode(KEY_B64).unwrap();
        let key = aead::Key::new(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes).unwrap();
        let iv = base64::decode(IV_B64).unwrap();
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &iv)
                .unwrap();

        let mut ciphertext_and_tag = base64::decode(&CIPHERTEXT_AND_TAG_B64).unwrap();
        ciphertext_and_tag[4] = b'Z';

        let err = open(&key, nonce, &aead::Aad::empty(), &ciphertext_and_tag).unwrap_err();
        match err.kind() {
            ErrorKind::InternalError => {}
            _ => panic!("unexpected error kind"),
        }
    }

    #[test]
    fn test_decrypt_fails_with_modified_tag() {
        let key_bytes = base64::decode(KEY_B64).unwrap();
        let key = aead::Key::new(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes).unwrap();
        let iv = base64::decode(IV_B64).unwrap();
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &iv)
                .unwrap();

        let mut ciphertext_and_tag = base64::decode(&CIPHERTEXT_AND_TAG_B64).unwrap();
        let end = ciphertext_and_tag.len();
        ciphertext_and_tag[end - 4] = b'Z';

        let err = open(&key, nonce, &aead::Aad::empty(), &ciphertext_and_tag).unwrap_err();
        match err.kind() {
            ErrorKind::InternalError => {}
            _ => panic!("unexpected error kind"),
        }
    }
}
