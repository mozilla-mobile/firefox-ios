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

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]
/// This crate provides all the cryptographic primitives required by
/// this workspace, backed by the NSS library.
/// The exposed API is pretty much the same as the `ring` crate.
pub mod aead;
pub mod agreement;
pub mod constant_time;
pub mod digest;
#[cfg(feature = "ece")]
pub mod ece_crypto;
mod error;
#[cfg(feature = "hawk")]
mod hawk_crypto;
pub mod hkdf;
pub mod hmac;
pub mod rand;

// Expose `hawk` if the hawk feature is on. This avoids consumers needing to
// configure this separately, which is more or less trivial to do incorrectly.
#[cfg(feature = "hawk")]
pub use hawk;

// Expose `ece` if the ece feature is on. This avoids consumers needing to
// configure this separately, which is more or less trivial to do incorrectly.
#[cfg(feature = "ece")]
pub use ece;

pub use crate::error::{Error, ErrorKind, Result};

// So we link against the SQLite lib imported by parent crates
// such as places and logins.
#[allow(unused_extern_crates)]
extern crate libsqlite3_sys;

/// Only required to be called if you intend to use this library in conjunction
/// with the `hawk` or the `ece` crate.
pub fn ensure_initialized() {
    nss::ensure_initialized();
    #[cfg(any(feature = "hawk", feature = "ece"))]
    {
        static INIT_ONCE: std::sync::Once = std::sync::Once::new();
        INIT_ONCE.call_once(|| {
            #[cfg(feature = "hawk")]
            crate::hawk_crypto::init();
            #[cfg(feature = "ece")]
            crate::ece_crypto::init();
        });
    }
}
