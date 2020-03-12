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

use crate::error::*;

pub use nss::pk11::context::HashAlgorithm::{self as Algorithm, *};

/// A calculated digest value.
#[derive(Clone)]
pub struct Digest {
    pub(crate) value: Vec<u8>,
    pub(crate) algorithm: Algorithm,
}

impl Digest {
    pub fn algorithm(&self) -> &Algorithm {
        &self.algorithm
    }
}

impl AsRef<[u8]> for Digest {
    fn as_ref(&self) -> &[u8] {
        self.value.as_ref()
    }
}

/// Returns the digest of data using the given digest algorithm.
pub fn digest(algorithm: &Algorithm, data: &[u8]) -> Result<Digest> {
    let value = nss::pk11::context::hash_buf(algorithm, data)?;
    Ok(Digest {
        value,
        algorithm: algorithm.clone(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use hex;

    const MESSAGE: &[u8] = b"bobo";
    const DIGEST_HEX: &str = "bf0c97708b849de696e7373508b13c5ea92bafa972fc941d694443e494a4b84d";

    #[test]
    fn sha256_digest() {
        assert_eq!(hex::encode(&digest(&SHA256, MESSAGE).unwrap()), DIGEST_HEX);
        assert_ne!(
            hex::encode(&digest(&SHA256, b"notbobo").unwrap()),
            DIGEST_HEX
        );
    }

    #[test]
    fn digest_cleanly_rejects_gigantic_messages() {
        let message = vec![0; (std::i32::MAX as usize) + 1];
        assert!(digest(&SHA256, &message).is_err());
    }
}
