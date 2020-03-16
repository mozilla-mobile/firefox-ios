/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{
    error::*,
    pk11::{
        slot,
        types::{Pkcs11Object, PrivateKey as PK11PrivateKey, PublicKey as PK11PublicKey},
    },
    util::{ensure_nss_initialized, sec_item_as_slice, ScopedPtr},
};
use serde_derive::{Deserialize, Serialize};
use std::{
    convert::TryFrom,
    mem,
    ops::Deref,
    os::raw::{c_uchar, c_uint, c_void},
    ptr,
};

#[derive(Serialize, Deserialize, Clone, Copy, Debug, PartialEq)]
#[repr(u8)]
pub enum Curve {
    P256,
}
const CRV_P256: &str = "P-256";

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct EcKey {
    curve: String,
    // The `d` value of the EC Key.
    private_key: Vec<u8>,
    // The uncompressed x,y-representation of the public component of the EC Key.
    public_key: Vec<u8>,
}

impl EcKey {
    pub fn new(curve: Curve, private_key: &[u8], public_key: &[u8]) -> Self {
        let curve = match curve {
            Curve::P256 => CRV_P256,
        };
        Self {
            curve: curve.to_owned(),
            private_key: private_key.to_vec(),
            public_key: public_key.to_vec(),
        }
    }

    pub fn from_coordinates(curve: Curve, d: &[u8], x: &[u8], y: &[u8]) -> Result<Self> {
        let ec_point = create_ec_point_for_coordinates(x, y)?;
        Ok(EcKey::new(curve, d, &ec_point))
    }

    pub fn curve(&self) -> Curve {
        if self.curve == CRV_P256 {
            return Curve::P256;
        }
        unimplemented!("It is impossible to create a curve object with a different CRV.")
    }

    pub fn public_key(&self) -> &[u8] {
        &self.public_key
    }

    pub fn private_key(&self) -> &[u8] {
        &self.private_key
    }
}

fn create_ec_point_for_coordinates(x: &[u8], y: &[u8]) -> Result<Vec<u8>> {
    if x.len() != y.len() {
        return Err(ErrorKind::InternalError.into());
    }
    let mut buf = vec![0u8; x.len() + y.len() + 1];
    buf[0] = u8::try_from(nss_sys::EC_POINT_FORM_UNCOMPRESSED)?;
    let mut offset = 1;
    buf[offset..offset + x.len()].copy_from_slice(x);
    offset += x.len();
    buf[offset..offset + y.len()].copy_from_slice(y);
    Ok(buf)
}

pub fn generate_keypair(curve: Curve) -> Result<(PrivateKey, PublicKey)> {
    ensure_nss_initialized();
    // 1. Create EC params
    let params_buf = create_ec_params_for_curve(curve)?;
    let mut params = nss_sys::SECItem {
        type_: nss_sys::SECItemType::siBuffer,
        data: params_buf.as_ptr() as *mut c_uchar,
        len: c_uint::try_from(params_buf.len())?,
    };

    // 2. Generate the key pair
    // The following code is adapted from:
    // https://searchfox.org/mozilla-central/rev/f46e2bf881d522a440b30cbf5cf8d76fc212eaf4/dom/crypto/WebCryptoTask.cpp#2389
    let mech = match curve {
        Curve::P256 => nss_sys::CKM_EC_KEY_PAIR_GEN,
    };
    let slot = slot::get_internal_slot()?;
    let mut pub_key: *mut nss_sys::SECKEYPublicKey = ptr::null_mut();
    let prv_key = PrivateKey::from(curve, unsafe {
        PK11PrivateKey::from_ptr(nss_sys::PK11_GenerateKeyPair(
            slot.as_mut_ptr(),
            mech.into(),
            &mut params as *mut _ as *mut c_void,
            &mut pub_key,
            nss_sys::PR_FALSE,
            nss_sys::PR_FALSE,
            ptr::null_mut(),
        ))?
    });
    let pub_key = PublicKey::from(curve, unsafe { PK11PublicKey::from_ptr(pub_key)? });
    Ok((prv_key, pub_key))
}

pub struct PrivateKey {
    curve: Curve,
    wrapped: PK11PrivateKey,
}

impl Deref for PrivateKey {
    type Target = PK11PrivateKey;
    #[inline]
    fn deref(&self) -> &PK11PrivateKey {
        &self.wrapped
    }
}

impl PrivateKey {
    pub fn convert_to_public_key(&self) -> Result<PublicKey> {
        let mut pub_key = self.wrapped.convert_to_public_key()?;

        // Workaround for https://bugzilla.mozilla.org/show_bug.cgi?id=1562046.
        let field_len = match self.curve {
            Curve::P256 => 32,
        };
        let expected_len = 2 * field_len + 1;
        let mut pub_value = unsafe { (*pub_key.as_ptr()).u.ec.publicValue };
        if pub_value.len == expected_len - 2 {
            let old_pub_value_raw = unsafe { sec_item_as_slice(&mut pub_value)?.to_vec() };
            let mut new_pub_value_raw = vec![0u8; usize::try_from(expected_len)?];
            new_pub_value_raw[0] = u8::try_from(nss_sys::EC_POINT_FORM_UNCOMPRESSED)?;
            new_pub_value_raw[1] = u8::try_from(old_pub_value_raw.len())?;
            new_pub_value_raw[2..].copy_from_slice(&old_pub_value_raw);
            pub_key = PublicKey::from_bytes(self.curve, &new_pub_value_raw)?.wrapped;
        }
        Ok(PublicKey {
            wrapped: pub_key,
            curve: self.curve,
        })
    }

    #[inline]
    pub(crate) fn from(curve: Curve, key: PK11PrivateKey) -> Self {
        Self {
            curve,
            wrapped: key,
        }
    }

    pub fn curve(&self) -> Curve {
        self.curve
    }

    pub fn private_value(&self) -> Result<Vec<u8>> {
        let mut private_value = self.read_raw_attribute(nss_sys::CKA_VALUE.into()).unwrap();
        let private_key = unsafe { sec_item_as_slice(private_value.as_mut_ref())?.to_vec() };
        Ok(private_key)
    }

    fn from_nss_params(
        curve: Curve,
        ec_params: &[u8],
        ec_point: &[u8],
        private_value: &[u8],
    ) -> Result<Self> {
        // The following code is adapted from:
        // https://searchfox.org/mozilla-central/rev/444ee13e14fe30451651c0f62b3979c76766ada4/dom/crypto/CryptoKey.cpp#322
        // These explicit variable type declarations are *VERY* important, as we pass to NSS a pointer to them
        // and we need these variables to be of the right size!
        let mut private_key_value: nss_sys::CK_OBJECT_CLASS = nss_sys::CKO_PRIVATE_KEY.into();
        let mut false_value: nss_sys::CK_BBOOL = nss_sys::CK_FALSE;
        let mut ec_value: nss_sys::CK_KEY_TYPE = nss_sys::CKK_EC.into();
        let bbool_size = mem::size_of::<nss_sys::CK_BBOOL>();
        let key_template = vec![
            ck_attribute(
                nss_sys::CKA_CLASS.into(),
                &mut private_key_value as *mut _ as *mut c_void,
                mem::size_of::<nss_sys::CK_OBJECT_CLASS>(),
            )?,
            ck_attribute(
                nss_sys::CKA_KEY_TYPE.into(),
                &mut ec_value as *mut _ as *mut c_void,
                mem::size_of::<nss_sys::CK_KEY_TYPE>(),
            )?,
            ck_attribute(
                nss_sys::CKA_TOKEN.into(),
                &mut false_value as *mut _ as *mut c_void,
                bbool_size,
            )?,
            ck_attribute(
                nss_sys::CKA_SENSITIVE.into(),
                &mut false_value as *mut _ as *mut c_void,
                bbool_size,
            )?,
            ck_attribute(
                nss_sys::CKA_PRIVATE.into(),
                &mut false_value as *mut _ as *mut c_void,
                bbool_size,
            )?,
            // PrivateKeyFromPrivateKeyTemplate sets the ID.
            ck_attribute(nss_sys::CKA_ID.into(), ptr::null_mut(), 0)?,
            ck_attribute(
                nss_sys::CKA_EC_PARAMS.into(),
                ec_params.as_ptr() as *mut c_void,
                ec_params.len(),
            )?,
            ck_attribute(
                nss_sys::CKA_EC_POINT.into(),
                ec_point.as_ptr() as *mut c_void,
                ec_point.len(),
            )?,
            ck_attribute(
                nss_sys::CKA_VALUE.into(),
                private_value.as_ptr() as *mut c_void,
                private_value.len(),
            )?,
        ];
        Ok(Self::from(
            curve,
            PK11PrivateKey::from_private_key_template(key_template)?,
        ))
    }

    pub fn import(ec_key: &EcKey) -> Result<Self> {
        // The following code is adapted from:
        // https://searchfox.org/mozilla-central/rev/66086345467c69685434dd1c5177b30a7511b1a5/dom/crypto/CryptoKey.cpp#652
        ensure_nss_initialized();
        let curve = ec_key.curve();
        let ec_params = create_ec_params_for_curve(curve)?;
        Self::from_nss_params(curve, &ec_params, &ec_key.public_key, &ec_key.private_key)
    }

    pub fn export(&self) -> Result<EcKey> {
        let public_key = self.convert_to_public_key()?;
        let public_key_bytes = public_key.to_bytes()?;
        let private_key_bytes = self.private_value()?;
        Ok(EcKey::new(
            self.curve,
            &private_key_bytes,
            &public_key_bytes,
        ))
    }
}

#[inline]
fn ck_attribute(
    r#type: nss_sys::CK_ATTRIBUTE_TYPE,
    p_value: nss_sys::CK_VOID_PTR,
    value_len: usize,
) -> Result<nss_sys::CK_ATTRIBUTE> {
    Ok(nss_sys::CK_ATTRIBUTE {
        type_: r#type,
        pValue: p_value,
        ulValueLen: nss_sys::CK_ULONG::try_from(value_len)?,
    })
}

pub struct PublicKey {
    curve: Curve,
    wrapped: PK11PublicKey,
}

impl Deref for PublicKey {
    type Target = PK11PublicKey;
    #[inline]
    fn deref(&self) -> &PK11PublicKey {
        &self.wrapped
    }
}

impl PublicKey {
    #[inline]
    pub(crate) fn from(curve: Curve, key: PK11PublicKey) -> Self {
        Self {
            curve,
            wrapped: key,
        }
    }

    pub fn curve(&self) -> Curve {
        self.curve
    }

    pub fn to_bytes(&self) -> Result<Vec<u8>> {
        // Some public keys we create do not have an associated PCKS#11 slot
        // therefore we cannot use `read_raw_attribute(CKA_EC_POINT)`
        // so we read the `publicValue` field directly instead.
        let mut ec_point = unsafe { (*self.as_ptr()).u.ec.publicValue };
        let public_key = unsafe { sec_item_as_slice(&mut ec_point)?.to_vec() };
        check_pub_key_bytes(&public_key, self.curve)?;
        Ok(public_key)
    }

    pub fn from_bytes(curve: Curve, bytes: &[u8]) -> Result<PublicKey> {
        // The following code is adapted from:
        // https://searchfox.org/mozilla-central/rev/ec489aa170b6486891cf3625717d6fa12bcd11c1/dom/crypto/CryptoKey.cpp#1078
        check_pub_key_bytes(bytes, curve)?;
        let key_data = nss_sys::SECItem {
            type_: nss_sys::SECItemType::siBuffer,
            data: bytes.as_ptr() as *mut c_uchar,
            len: c_uint::try_from(bytes.len())?,
        };
        let params_buf = create_ec_params_for_curve(curve)?;
        let params = nss_sys::SECItem {
            type_: nss_sys::SECItemType::siBuffer,
            data: params_buf.as_ptr() as *mut c_uchar,
            len: c_uint::try_from(params_buf.len())?,
        };

        let pub_key = nss_sys::SECKEYPublicKey {
            arena: ptr::null_mut(),
            keyType: nss_sys::KeyType::ecKey,
            pkcs11Slot: ptr::null_mut(),
            pkcs11ID: nss_sys::CK_INVALID_HANDLE.into(),
            u: nss_sys::SECKEYPublicKeyStr__bindgen_ty_1 {
                ec: nss_sys::SECKEYECPublicKey {
                    DEREncodedParams: params,
                    publicValue: key_data,
                    encoding: nss_sys::ECPointEncoding_ECPoint_Uncompressed,
                    size: 0,
                },
            },
        };
        Ok(Self::from(curve, unsafe {
            PK11PublicKey::from_ptr(nss_sys::SECKEY_CopyPublicKey(&pub_key))?
        }))
    }
}

fn check_pub_key_bytes(bytes: &[u8], curve: Curve) -> Result<()> {
    let field_len = match curve {
        Curve::P256 => 32,
    };
    // Check length of uncompressed point coordinates. There are 2 field elements
    // and a leading "point form" octet (which must be EC_POINT_FORM_UNCOMPRESSED).
    if bytes.len() != (2 * field_len + 1) {
        return Err(ErrorKind::InternalError.into());
    }
    // No support for compressed points.
    if bytes[0] != u8::try_from(nss_sys::EC_POINT_FORM_UNCOMPRESSED)? {
        return Err(ErrorKind::InternalError.into());
    }
    Ok(())
}

fn create_ec_params_for_curve(curve: Curve) -> Result<Vec<u8>> {
    // The following code is adapted from:
    // https://searchfox.org/mozilla-central/rev/ec489aa170b6486891cf3625717d6fa12bcd11c1/dom/crypto/WebCryptoCommon.h#299
    let curve_oid_tag = match curve {
        Curve::P256 => nss_sys::SECOidTag::SEC_OID_ANSIX962_EC_PRIME256V1,
    };
    // Retrieve curve data by OID tag.
    let oid_data = unsafe { nss_sys::SECOID_FindOIDByTag(curve_oid_tag) };
    if oid_data.is_null() {
        return Err(ErrorKind::InternalError.into());
    }
    // Set parameters
    let oid_data_len = unsafe { (*oid_data).oid.len };
    let mut buf = vec![0u8; usize::try_from(oid_data_len)? + 2];
    buf[0] = c_uchar::try_from(nss_sys::SEC_ASN1_OBJECT_ID)?;
    buf[1] = c_uchar::try_from(oid_data_len)?;
    let oid_data_data =
        unsafe { std::slice::from_raw_parts((*oid_data).oid.data, usize::try_from(oid_data_len)?) };
    buf[2..].copy_from_slice(oid_data_data);
    Ok(buf)
}
