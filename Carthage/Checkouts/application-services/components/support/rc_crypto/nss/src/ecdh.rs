/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{
    ec::{PrivateKey, PublicKey},
    error::*,
    pk11::types::SymKey,
    util::{ensure_nss_initialized, map_nss_secstatus, sec_item_as_slice, ScopedPtr},
};

pub fn ecdh_agreement(priv_key: &PrivateKey, pub_key: &PublicKey) -> Result<Vec<u8>> {
    ensure_nss_initialized();
    if priv_key.curve() != pub_key.curve() {
        return Err(ErrorKind::InternalError.into());
    }
    // The following code is adapted from:
    // https://searchfox.org/mozilla-central/rev/444ee13e14fe30451651c0f62b3979c76766ada4/dom/crypto/WebCryptoTask.cpp#2835

    // CKM_SHA512_HMAC and CKA_SIGN are key type and usage attributes of the
    // derived symmetric key and don't matter because we ignore them anyway.
    let sym_key = unsafe {
        SymKey::from_ptr(nss_sys::PK11_PubDeriveWithKDF(
            priv_key.as_mut_ptr(),
            pub_key.as_mut_ptr(),
            nss_sys::PR_FALSE,
            std::ptr::null_mut(),
            std::ptr::null_mut(),
            nss_sys::CKM_ECDH1_DERIVE.into(),
            nss_sys::CKM_SHA512_HMAC.into(),
            nss_sys::CKA_SIGN.into(),
            0,
            nss_sys::CKD_NULL.into(),
            std::ptr::null_mut(),
            std::ptr::null_mut(),
        ))?
    };

    map_nss_secstatus(|| unsafe { nss_sys::PK11_ExtractKeyValue(sym_key.as_mut_ptr()) })?;

    // This doesn't leak, because the SECItem* returned by PK11_GetKeyData
    // just refers to a buffer managed by `sym_key` which we copy into `buf`.
    let mut key_data = unsafe { *nss_sys::PK11_GetKeyData(sym_key.as_mut_ptr()) };
    let buf = unsafe { sec_item_as_slice(&mut key_data)? };
    Ok(buf.to_vec())
}
