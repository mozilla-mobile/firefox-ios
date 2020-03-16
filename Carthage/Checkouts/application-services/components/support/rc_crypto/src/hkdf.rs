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

use crate::{error::*, hmac};

pub fn extract_and_expand(
    salt: &hmac::SigningKey,
    secret: &[u8],
    info: &[u8],
    out: &mut [u8],
) -> Result<()> {
    let prk = extract(salt, secret)?;
    expand(&prk, info, out)?;
    Ok(())
}

pub fn extract(salt: &hmac::SigningKey, secret: &[u8]) -> Result<hmac::SigningKey> {
    let prk = hmac::sign(salt, secret)?;
    Ok(hmac::SigningKey::new(salt.digest_algorithm(), prk.as_ref()))
}

pub fn expand(prk: &hmac::SigningKey, info: &[u8], out: &mut [u8]) -> Result<()> {
    let mut derived =
        nss::pk11::sym_key::hkdf_expand(prk.digest_alg, &prk.key_value, info, out.len())?;
    out.swap_with_slice(&mut derived[0..out.len()]);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::digest;
    use hex;

    // NSS limits the size of derived key material to 576 bytes due to fixed-size `key_block` buffer here:
    // https://dxr.mozilla.org/mozilla-central/rev/3c0f78074b727fbae112b6eda111d4c4d30cc3ec/security/nss/lib/softoken/pkcs11c.c#7758
    const NSS_MAX_DERIVED_KEY_MATERIAL: usize = 576;

    #[test]
    fn hkdf_produces_correct_result() {
        let secret = hex::decode("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b").unwrap();
        let salt = hex::decode("000102030405060708090a0b0c").unwrap();
        let info = hex::decode("f0f1f2f3f4f5f6f7f8f9").unwrap();
        let expected_out = hex::decode(
            "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865",
        )
        .unwrap();
        let salt = hmac::SigningKey::new(&digest::SHA256, &salt);
        let mut out = vec![0u8; expected_out.len()];
        extract_and_expand(&salt, &secret, &info, &mut out).unwrap();
        assert_eq!(out, expected_out);
    }

    #[test]
    fn hkdf_rejects_gigantic_salt() {
        if (std::u32::MAX as usize) < std::usize::MAX {
            let salt_bytes = vec![0; (std::u32::MAX as usize) + 1];
            let salt = hmac::SigningKey {
                digest_alg: &digest::SHA256,
                key_value: salt_bytes,
            };
            let mut out = vec![0u8; 8];
            assert!(extract_and_expand(&salt, b"secret", b"info", &mut out).is_err());
        }
    }

    #[test]
    fn hkdf_rejects_gigantic_secret() {
        if (std::u32::MAX as usize) < std::usize::MAX {
            let salt = hmac::SigningKey::new(&digest::SHA256, b"salt");
            let secret = vec![0; (std::u32::MAX as usize) + 1];
            let mut out = vec![0u8; 8];
            assert!(extract_and_expand(&salt, secret.as_slice(), b"info", &mut out).is_err());
        }
    }

    // N.B. the `info `parameter is a `c_ulong`, and I can't figure out how to check whether
    // `c_ulong` is smaller than `usize` in order to write a `hkdf_rejects_gigantic_info` test.

    #[test]
    fn hkdf_rejects_gigantic_output_buffers() {
        let salt = hmac::SigningKey::new(&digest::SHA256, b"salt");
        let mut out = vec![0u8; NSS_MAX_DERIVED_KEY_MATERIAL + 1];
        assert!(extract_and_expand(&salt, b"secret", b"info", &mut out).is_err());
    }

    #[test]
    fn hkdf_rejects_zero_length_output_buffer() {
        let salt = hmac::SigningKey::new(&digest::SHA256, b"salt");
        let mut out = vec![0u8; 0];
        assert!(extract_and_expand(&salt, b"secret", b"info", &mut out).is_err());
    }

    #[test]
    fn hkdf_can_produce_small_output() {
        let salt = hmac::SigningKey::new(&digest::SHA256, b"salt");
        let mut out = vec![0u8; 1];
        assert!(extract_and_expand(&salt, b"secret", b"info", &mut out).is_ok());
    }

    #[test]
    fn hkdf_accepts_zero_length_info() {
        let salt = hmac::SigningKey::new(&digest::SHA256, b"salt");
        let mut out = vec![0u8; 32];
        assert!(extract_and_expand(&salt, b"secret", b"", &mut out).is_ok());
    }

    #[test]
    fn hkdf_expand_rejects_short_prk() {
        let prk = hmac::SigningKey::new(&digest::SHA256, b"too short"); // must be >= HashLen
        let mut out = vec![0u8; 8];
        assert!(expand(&prk, b"info", &mut out).is_ok());
    }
}
