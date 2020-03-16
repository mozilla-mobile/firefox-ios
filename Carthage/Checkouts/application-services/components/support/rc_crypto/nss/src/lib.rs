/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]
#[macro_use]
mod util;
pub mod aes;
pub mod ec;
pub mod ecdh;
mod error;
pub mod pk11;
pub mod secport;
pub use crate::error::{Error, ErrorKind, Result};
pub use util::ensure_nss_initialized as ensure_initialized;
