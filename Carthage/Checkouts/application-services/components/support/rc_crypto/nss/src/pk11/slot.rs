/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{
    error::*,
    pk11::types::Slot,
    util::{ensure_nss_initialized, map_nss_secstatus, ScopedPtr},
};
use std::convert::TryFrom;

pub fn generate_random(data: &mut [u8]) -> Result<()> {
    // `NSS_Init` will initialize the RNG with data from `/dev/urandom`.
    ensure_nss_initialized();
    let len = i32::try_from(data.len())?;
    map_nss_secstatus(|| unsafe { nss_sys::PK11_GenerateRandom(data.as_mut_ptr(), len) })?;
    Ok(())
}

/// Safe wrapper around `PK11_GetInternalSlot` that
/// de-allocates memory when the slot goes out of
/// scope.
pub(crate) fn get_internal_slot() -> Result<Slot> {
    unsafe { Slot::from_ptr(nss_sys::PK11_GetInternalSlot()) }
}
