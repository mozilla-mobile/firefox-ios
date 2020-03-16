/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{
    error::*,
    pk11::slot::{generate_random, get_internal_slot},
    util::{map_nss_secstatus, ScopedPtr},
};
use std::{
    convert::TryFrom,
    ops::Deref,
    os::raw::{c_int, c_uchar, c_uint, c_void},
    ptr,
};

scoped_ptr!(SymKey, nss_sys::PK11SymKey, nss_sys::PK11_FreeSymKey);
scoped_ptr!(
    PrivateKey,
    nss_sys::SECKEYPrivateKey,
    nss_sys::SECKEY_DestroyPrivateKey
);
scoped_ptr!(
    PublicKey,
    nss_sys::SECKEYPublicKey,
    nss_sys::SECKEY_DestroyPublicKey
);
scoped_ptr!(
    GenericObject,
    nss_sys::PK11GenericObject,
    nss_sys::PK11_DestroyGenericObject
);
scoped_ptr!(Context, nss_sys::PK11Context, pk11_destroy_context_true);
scoped_ptr!(Slot, nss_sys::PK11SlotInfo, nss_sys::PK11_FreeSlot);

#[inline]
unsafe fn pk11_destroy_context_true(context: *mut nss_sys::PK11Context) {
    nss_sys::PK11_DestroyContext(context, nss_sys::PR_TRUE);
}

// Trait for types that have PCKS#11 attributes that are readable. See
// https://searchfox.org/mozilla-central/rev/8ed8474757695cdae047150a0eaf94a5f1c96dbe/security/nss/lib/pk11wrap/pk11pub.h#842-864
pub(crate) unsafe trait Pkcs11Object: ScopedPtr {
    const PK11_OBJECT_TYPE: nss_sys::PK11ObjectType::Type;
    fn read_raw_attribute(
        &self,
        attribute_type: nss_sys::CK_ATTRIBUTE_TYPE,
    ) -> Result<ScopedSECItem> {
        let mut out_sec = ScopedSECItem::empty(nss_sys::SECItemType::siBuffer);
        map_nss_secstatus(|| unsafe {
            nss_sys::PK11_ReadRawAttribute(
                Self::PK11_OBJECT_TYPE,
                self.as_mut_ptr() as *mut c_void,
                attribute_type,
                out_sec.as_mut_ref(),
            )
        })?;
        Ok(out_sec)
    }
}

unsafe impl Pkcs11Object for GenericObject {
    const PK11_OBJECT_TYPE: nss_sys::PK11ObjectType::Type =
        nss_sys::PK11ObjectType::PK11_TypeGeneric;
}
unsafe impl Pkcs11Object for PrivateKey {
    const PK11_OBJECT_TYPE: nss_sys::PK11ObjectType::Type =
        nss_sys::PK11ObjectType::PK11_TypePrivKey;
}
unsafe impl Pkcs11Object for PublicKey {
    const PK11_OBJECT_TYPE: nss_sys::PK11ObjectType::Type =
        nss_sys::PK11ObjectType::PK11_TypePubKey;
}
unsafe impl Pkcs11Object for SymKey {
    const PK11_OBJECT_TYPE: nss_sys::PK11ObjectType::Type =
        nss_sys::PK11ObjectType::PK11_TypeSymKey;
}

// From https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/NSS_API_Guidelines#Thread_Safety:
// "Data structures that are read only, like SECKEYPublicKeys or PK11SymKeys, need not be protected."
unsafe impl Send for PrivateKey {}
unsafe impl Send for PublicKey {}

impl PrivateKey {
    pub fn convert_to_public_key(&self) -> Result<PublicKey> {
        Ok(unsafe { PublicKey::from_ptr(nss_sys::SECKEY_ConvertToPublicKey(self.as_mut_ptr()))? })
    }

    // To protect against key ID collisions, PrivateKeyFromPrivateKeyTemplate
    // generates a random ID for each key. The given template must contain an
    // attribute slot for a key ID, but it must consist of a null pointer and have a
    // length of 0.
    pub(crate) fn from_private_key_template(
        mut template: Vec<nss_sys::CK_ATTRIBUTE>,
    ) -> Result<Self> {
        // Generate a random 160-bit object ID. This ID must be unique.
        let mut obj_id_buf = vec![0u8; 160 / 8];
        generate_random(&mut obj_id_buf)?;
        let mut obj_id = nss_sys::SECItem {
            type_: nss_sys::SECItemType::siBuffer,
            data: obj_id_buf.as_ptr() as *mut c_uchar,
            len: c_uint::try_from(obj_id_buf.len())?,
        };
        let slot = get_internal_slot()?;
        let mut pre_existing_key = unsafe {
            nss_sys::PK11_FindKeyByKeyID(slot.as_mut_ptr(), &mut obj_id, std::ptr::null_mut())
        };
        if !pre_existing_key.is_null() {
            // Note that we can't just call SECKEY_DestroyPrivateKey here because that
            // will destroy the PKCS#11 object that is backing a preexisting key (that
            // we still have a handle on somewhere else in memory). If that object were
            // destroyed, cryptographic operations performed by that other key would
            // fail.
            unsafe {
                destroy_private_key_without_destroying_pkcs11_object(pre_existing_key);
            }
            // Try again with a new ID (but only once - collisions are very unlikely).
            generate_random(&mut obj_id_buf)?;
            pre_existing_key = unsafe {
                nss_sys::PK11_FindKeyByKeyID(slot.as_mut_ptr(), &mut obj_id, std::ptr::null_mut())
            };
            if !pre_existing_key.is_null() {
                unsafe {
                    destroy_private_key_without_destroying_pkcs11_object(pre_existing_key);
                }
                return Err(ErrorKind::InternalError.into());
            }
        }
        let template_len = c_int::try_from(template.len())?;
        let mut id_attr: &mut nss_sys::CK_ATTRIBUTE = template
            .iter_mut()
            .find(|&&mut attr| {
                attr.type_ == nss_sys::CKA_ID.into()
                    && attr.pValue.is_null()
                    && attr.ulValueLen == 0
            })
            .ok_or_else(|| ErrorKind::InternalError)?;
        id_attr.pValue = obj_id_buf.as_mut_ptr() as *mut c_void;
        id_attr.ulValueLen = nss_sys::CK_ULONG::try_from(obj_id_buf.len())?;
        // We use `PK11_CreateGenericObject` instead of `PK11_CreateManagedGenericObject`
        // to leak the reference on purpose because `PK11_FindKeyByKeyID` will take
        // ownership of it.
        let _obj = unsafe {
            GenericObject::from_ptr(nss_sys::PK11_CreateGenericObject(
                slot.as_mut_ptr(),
                template.as_mut_ptr(),
                template_len,
                nss_sys::PR_FALSE,
            ))?
        };
        // Have NSS translate the object to a private key.
        Ok(unsafe {
            PrivateKey::from_ptr(nss_sys::PK11_FindKeyByKeyID(
                slot.as_mut_ptr(),
                &mut obj_id,
                std::ptr::null_mut(),
            ))?
        })
    }
}

// This is typically used by functions receiving a pointer to an `out SECItem`,
// where we allocate the struct, but NSS allocates the elements it points to.
pub(crate) struct ScopedSECItem {
    wrapped: nss_sys::SECItem,
}

impl ScopedSECItem {
    pub(crate) fn empty(r#type: nss_sys::SECItemType::Type) -> Self {
        ScopedSECItem {
            wrapped: nss_sys::SECItem {
                type_: r#type,
                data: ptr::null_mut(),
                len: 0,
            },
        }
    }

    pub(crate) fn as_mut_ref(&mut self) -> &mut nss_sys::SECItem {
        &mut self.wrapped
    }
}

impl Deref for ScopedSECItem {
    type Target = nss_sys::SECItem;
    #[inline]
    fn deref(&self) -> &nss_sys::SECItem {
        &self.wrapped
    }
}

impl Drop for ScopedSECItem {
    fn drop(&mut self) {
        unsafe {
            // PR_FALSE asks the NSS allocator not to free the SECItem
            // itself, and just the pointee of `self.wrapped.data`.
            nss_sys::SECITEM_FreeItem(&mut self.wrapped, nss_sys::PR_FALSE);
        }
    }
}

// This helper function will release the memory backing a SECKEYPrivateKey and
// any resources acquired in its creation. It will leave the backing PKCS#11
// object untouched, however. This should only be called from
// PrivateKeyFromPrivateKeyTemplate.
// From: https://searchfox.org/mozilla-central/rev/444ee13e14fe30451651c0f62b3979c76766ada4/dom/crypto/CryptoKey.cpp#80
unsafe fn destroy_private_key_without_destroying_pkcs11_object(
    key: *mut nss_sys::SECKEYPrivateKey,
) {
    assert!(!key.is_null());
    nss_sys::PK11_FreeSlot((*key).pkcs11Slot);
    nss_sys::PORT_FreeArena((*key).arena, nss_sys::PR_TRUE);
}
