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

/// Returns `Ok(())` if `a == b` and `Error` otherwise.
/// The comparison of `a` and `b` is done in constant time with respect to the
/// contents of each, but NOT in constant time with respect to the lengths of
/// `a` and `b`.
pub fn verify_slices_are_equal(a: &[u8], b: &[u8]) -> Result<()> {
    if nss::secport::secure_memcmp(a, b) {
        Ok(())
    } else {
        Err(ErrorKind::InternalError.into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn does_compare() {
        assert!(verify_slices_are_equal(b"bobo", b"bobo").is_ok());
        assert!(verify_slices_are_equal(b"bobo", b"obob").is_err());
        assert!(verify_slices_are_equal(b"bobo", b"notbobo").is_err());
    }
}
