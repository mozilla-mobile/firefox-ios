/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{
    error::*,
    pk11::sym_key::import_sym_key,
    util::{ensure_nss_initialized, map_nss_secstatus, ScopedPtr},
};
use std::{
    convert::TryFrom,
    mem,
    os::raw::{c_uchar, c_uint},
};

const AES_GCM_TAG_LENGTH: usize = 16;

#[derive(Debug, Copy, Clone, PartialEq)]
pub enum Operation {
    Encrypt,
    Decrypt,
}

pub fn aes_gcm_crypt(
    key: &[u8],
    nonce: &[u8],
    aad: &[u8],
    data: &[u8],
    operation: Operation,
) -> Result<Vec<u8>> {
    let mut gcm_params = nss_sys::CK_GCM_PARAMS {
        pIv: nonce.as_ptr() as nss_sys::CK_BYTE_PTR,
        ulIvLen: nss_sys::CK_ULONG::try_from(nonce.len())?,
        pAAD: aad.as_ptr() as nss_sys::CK_BYTE_PTR,
        ulAADLen: nss_sys::CK_ULONG::try_from(aad.len())?,
        ulTagBits: nss_sys::CK_ULONG::try_from(AES_GCM_TAG_LENGTH * 8)?,
    };
    let mut params = nss_sys::SECItem {
        type_: nss_sys::SECItemType::siBuffer,
        data: &mut gcm_params as *mut _ as *mut c_uchar,
        len: c_uint::try_from(mem::size_of::<nss_sys::CK_GCM_PARAMS>())?,
    };
    common_crypt(
        nss_sys::CKM_AES_GCM.into(),
        key,
        data,
        AES_GCM_TAG_LENGTH,
        &mut params,
        operation,
    )
}

pub fn aes_cbc_crypt(
    key: &[u8],
    nonce: &[u8],
    data: &[u8],
    operation: Operation,
) -> Result<Vec<u8>> {
    let mut params = nss_sys::SECItem {
        type_: nss_sys::SECItemType::siBuffer,
        data: nonce.as_ptr() as *mut c_uchar,
        len: c_uint::try_from(nonce.len())?,
    };
    common_crypt(
        nss_sys::CKM_AES_CBC_PAD.into(),
        key,
        data,
        usize::try_from(nss_sys::AES_BLOCK_SIZE)?, // CBC mode might pad the result.
        &mut params,
        operation,
    )
}

pub fn common_crypt(
    mech: nss_sys::CK_MECHANISM_TYPE,
    key: &[u8],
    data: &[u8],
    extra_data_len: usize,
    params: &mut nss_sys::SECItem,
    operation: Operation,
) -> Result<Vec<u8>> {
    ensure_nss_initialized();
    // Most of the following code is inspired by the Firefox WebCrypto implementation:
    // https://searchfox.org/mozilla-central/rev/f46e2bf881d522a440b30cbf5cf8d76fc212eaf4/dom/crypto/WebCryptoTask.cpp#566
    // CKA_ENCRYPT always is fine.
    let sym_key = import_sym_key(mech, nss_sys::CKA_ENCRYPT.into(), &key)?;
    // Initialize the output buffer (enough space for padding / a full tag).
    let result_max_len = data
        .len()
        .checked_add(extra_data_len)
        .ok_or_else(|| ErrorKind::InternalError)?;
    let mut out_len: c_uint = 0;
    let mut out = vec![0u8; result_max_len];
    let result_max_len_uint = c_uint::try_from(result_max_len)?;
    let data_len = c_uint::try_from(data.len())?;
    let f = match operation {
        Operation::Decrypt => nss_sys::PK11_Decrypt,
        Operation::Encrypt => nss_sys::PK11_Encrypt,
    };
    map_nss_secstatus(|| unsafe {
        f(
            sym_key.as_mut_ptr(),
            mech,
            params,
            out.as_mut_ptr(),
            &mut out_len,
            result_max_len_uint,
            data.as_ptr(),
            data_len,
        )
    })?;
    out.truncate(usize::try_from(out_len)?);
    Ok(out)
}
