/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::util::ensure_nss_initialized;
use std::{convert::TryInto, os::raw::c_void};

pub fn secure_memcmp(a: &[u8], b: &[u8]) -> bool {
    ensure_nss_initialized();
    // NSS_SecureMemcmp will compare N elements fron our slices,
    // so make sure they are the same length first.
    if a.len() != b.len() {
        return false;
    }
    let result = unsafe {
        nss_sys::NSS_SecureMemcmp(
            a.as_ptr() as *const c_void,
            b.as_ptr() as *const c_void,
            a.len().try_into().unwrap(),
        )
    };
    result == 0
}
