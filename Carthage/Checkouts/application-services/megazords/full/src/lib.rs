/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

use std::ffi::CString;
use std::os::raw::c_char;

pub use fxaclient_ffi;
pub use logins_ffi;
pub use places_ffi;
pub use push_ffi;
pub use rc_log_ffi;
pub use sync_manager_ffi;
pub use viaduct;

/// In order to support the use case of consumers who don't know about megazords
/// and don't need our e.g. networking or logging, we consider initialization
/// optional for the default (full) megazord.
///
/// This function exists so that the `native_support` code can ensure that we
/// still check that the version of the functions in the megazord library and
/// the version of the code loading them is identical.
///
/// Critically, that means this function (unlike our other functions) must be
/// ABI stable! It needs to take no arguments, and return either null, or a
/// NUL-terminated C string. Failure to do this will result in memory unsafety
/// when an old version of the megazord loader loads a newer library!
///
/// If we ever need to change that (which seems unlikely, since we could encode
/// whatever we want in a string if it came to it), we must change the functions
/// name too.
#[no_mangle]
pub extern "C" fn full_megazord_get_version() -> *const c_char {
    VERSION_PTR.0
}

// This is set by gradle, but wouldn't be set otherwise. If it is unset,
// we'll return null from this function, which will cause the megazord
// version checker to throw. Separated as a constant to make it clear that
// this is a thing determined at compile time.
static VERSION: Option<&str> = option_env!("MEGAZORD_VERSION");

// For now it's tricky for this string to get freed, so just allocate one and save its pointer.
lazy_static::lazy_static! {
    static ref VERSION_PTR: StaticCStringPtr = StaticCStringPtr(
        VERSION.and_then(|s| CString::new(s).ok())
            .map_or(std::ptr::null(), |cs| cs.into_raw()));
}

// Wrapper that lets us keep a raw pointer in a lazy_static
#[repr(transparent)]
#[derive(Copy, Clone)]
struct StaticCStringPtr(*const c_char);
unsafe impl Send for StaticCStringPtr {}
unsafe impl Sync for StaticCStringPtr {}
