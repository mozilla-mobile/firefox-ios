/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{
    error::*,
    pk11::{
        sym_key::import_sym_key,
        types::{Context, SymKey},
    },
    util::{ensure_nss_initialized, map_nss_secstatus, ScopedPtr},
};
use std::{convert::TryFrom, ptr};

#[derive(Clone, Debug)]
#[repr(u8)]
pub enum HashAlgorithm {
    SHA256,
}

impl HashAlgorithm {
    fn result_len(&self) -> u32 {
        match self {
            HashAlgorithm::SHA256 => nss_sys::SHA256_LENGTH,
        }
    }

    fn as_hmac_mechanism(&self) -> u32 {
        match self {
            HashAlgorithm::SHA256 => nss_sys::CKM_SHA256_HMAC,
        }
    }

    pub(crate) fn as_hkdf_mechanism(&self) -> u32 {
        match self {
            HashAlgorithm::SHA256 => nss_sys::CKM_NSS_HKDF_SHA256,
        }
    }
}

impl From<&HashAlgorithm> for nss_sys::SECOidTag::Type {
    fn from(alg: &HashAlgorithm) -> Self {
        match alg {
            HashAlgorithm::SHA256 => nss_sys::SECOidTag::SEC_OID_SHA256,
        }
    }
}

pub fn hash_buf(algorithm: &HashAlgorithm, data: &[u8]) -> Result<Vec<u8>> {
    ensure_nss_initialized();
    let result_len = usize::try_from(algorithm.result_len())?;
    let mut out = vec![0u8; result_len];
    let data_len = i32::try_from(data.len())?;
    map_nss_secstatus(|| unsafe {
        nss_sys::PK11_HashBuf(algorithm.into(), out.as_mut_ptr(), data.as_ptr(), data_len)
    })?;
    Ok(out)
}

pub fn hmac_sign(digest_alg: &HashAlgorithm, sym_key_bytes: &[u8], data: &[u8]) -> Result<Vec<u8>> {
    let mech = digest_alg.as_hmac_mechanism();
    let sym_key = import_sym_key(mech.into(), nss_sys::CKA_SIGN.into(), sym_key_bytes)?;
    let context = create_context_by_sym_key(mech.into(), nss_sys::CKA_SIGN.into(), &sym_key)?;
    Ok(hash_buf_with_context(&context, data)?)
}

/// Similar to hash_buf except the consumer has to provide the digest context.
fn hash_buf_with_context(context: &Context, data: &[u8]) -> Result<Vec<u8>> {
    ensure_nss_initialized();
    map_nss_secstatus(|| unsafe { nss_sys::PK11_DigestBegin(context.as_mut_ptr()) })?;
    let data_len = u32::try_from(data.len())?;
    map_nss_secstatus(|| unsafe {
        nss_sys::PK11_DigestOp(context.as_mut_ptr(), data.as_ptr(), data_len)
    })?;
    // We allocate the maximum possible length for the out buffer then we'll
    // slice it after nss fills `out_len`.
    let mut out_len: u32 = 0;
    let mut out = vec![0u8; nss_sys::HASH_LENGTH_MAX as usize];
    map_nss_secstatus(|| unsafe {
        nss_sys::PK11_DigestFinal(
            context.as_mut_ptr(),
            out.as_mut_ptr(),
            &mut out_len,
            nss_sys::HASH_LENGTH_MAX,
        )
    })?;
    out.truncate(usize::try_from(out_len)?);
    Ok(out)
}

/// Safe wrapper around PK11_CreateContextBySymKey that
/// de-allocates memory when the context goes out of
/// scope.
pub fn create_context_by_sym_key(
    mechanism: nss_sys::CK_MECHANISM_TYPE,
    operation: nss_sys::CK_ATTRIBUTE_TYPE,
    sym_key: &SymKey,
) -> Result<Context> {
    ensure_nss_initialized();
    let mut param = nss_sys::SECItem {
        type_: nss_sys::SECItemType::siBuffer,
        data: ptr::null_mut(),
        len: 0,
    };
    unsafe {
        Context::from_ptr(nss_sys::PK11_CreateContextBySymKey(
            mechanism,
            operation,
            sym_key.as_mut_ptr(),
            &mut param,
        ))
    }
}
