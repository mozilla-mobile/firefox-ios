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

/// Fill a buffer with cryptographically secure pseudo-random data.
pub fn fill(dest: &mut [u8]) -> Result<()> {
    Ok(nss::pk11::slot::generate_random(dest)?)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn random_fill() {
        let mut out = vec![0u8; 64];
        assert!(fill(&mut out).is_ok());
        // This check could *in theory* fail if we randomly generate all zeroes
        // but we're treating that probability as negligible in practice.
        assert_ne!(out, vec![0u8; 64]);

        let mut out2 = vec![0u8; 64];
        assert!(fill(&mut out2).is_ok());
        assert_ne!(out, vec![0u8; 64]);
        assert_ne!(out2, out);
    }

    #[test]
    fn random_fill_empty() {
        let mut out = vec![0u8; 0];
        assert!(fill(&mut out).is_ok());
        assert_eq!(out, vec![0u8; 0]);
    }

    #[test]
    fn random_fill_oddly_sized_arrays() {
        let sizes: [usize; 4] = [61, 63, 65, 67];
        for size in &sizes {
            let mut out = vec![0u8; *size];
            assert!(fill(&mut out).is_ok());
            assert_ne!(out, vec![0u8; *size]);
        }
    }

    #[test]
    fn random_fill_rejects_attempts_to_fill_gigantic_arrays() {
        let max_size: usize = std::i32::MAX as usize;
        let mut out = vec![0u8; max_size + 1];
        assert!(fill(&mut out).is_err());
    }
}
