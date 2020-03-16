/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]
#![allow(non_camel_case_types, non_upper_case_globals, non_snake_case)]

#[cfg_attr(feature = "cargo-clippy", allow(clippy::all))]
mod bindings;

pub use bindings::*;

// Remap some constants.
pub const SECSuccess: SECStatus = _SECStatus_SECSuccess;
pub const SECFailure: SECStatus = _SECStatus_SECFailure;
pub const PR_FALSE: PRBool = 0;
pub const PR_TRUE: PRBool = 1;
pub const CK_FALSE: CK_BBOOL = 0;
pub const CK_TRUE: CK_BBOOL = 1;

// This is the NSS version that this crate is claiming to be compatible with.
// We check it at runtime using `NSS_VersionCheck`.
pub const COMPATIBLE_NSS_VERSION: &str = "3.26";
