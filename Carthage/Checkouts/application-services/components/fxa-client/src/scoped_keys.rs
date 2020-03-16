/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{error::*, FirefoxAccount};
use byteorder::{BigEndian, ByteOrder};
use rc_crypto::{
    aead, agreement,
    agreement::{Ephemeral, KeyPair},
    digest,
};
use serde_derive::*;
use serde_json::{self, json};

impl FirefoxAccount {
    pub(crate) fn get_scoped_key(&self, scope: &str) -> Result<&ScopedKey> {
        self.state
            .scoped_keys
            .get(scope)
            .ok_or_else(|| ErrorKind::NoScopedKey(scope.to_string()).into())
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct ScopedKey {
    pub kty: String,
    pub scope: String,
    /// URL Safe Base 64 encoded key.
    pub k: String,
    pub kid: String,
}

impl ScopedKey {
    pub fn key_bytes(&self) -> Result<Vec<u8>> {
        Ok(base64::decode_config(&self.k, base64::URL_SAFE_NO_PAD)?)
    }
}

impl std::fmt::Debug for ScopedKey {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ScopedKey")
            .field("kty", &self.kty)
            .field("scope", &self.scope)
            .field("kid", &self.kid)
            .finish()
    }
}

pub struct ScopedKeysFlow {
    key_pair: KeyPair<Ephemeral>,
}

/// Theorically, everything done in this file could and should be done in a JWT library.
/// However, none of the existing rust JWT libraries can handle ECDH-ES encryption, and API choices
/// made by their authors make it difficult to add this feature.
/// In the past, we chose cjose to do that job, but it added three C dependencies to build and link
/// against: jansson, openssl and cjose itself.
impl ScopedKeysFlow {
    pub fn with_random_key() -> Result<Self> {
        let key_pair = KeyPair::<Ephemeral>::generate(&agreement::ECDH_P256)
            .map_err(|_| ErrorKind::KeyGenerationFailed)?;
        Ok(Self { key_pair })
    }

    #[cfg(test)]
    pub fn from_static_key_pair(key_pair: KeyPair<agreement::Static>) -> Result<Self> {
        let (private_key, _) = key_pair.split();
        let ephemeral_prv_key = private_key._tests_only_dangerously_convert_to_ephemeral();
        let key_pair = KeyPair::from_private_key(ephemeral_prv_key)?;
        Ok(Self { key_pair })
    }

    pub fn generate_keys_jwk(&self) -> Result<String> {
        let pub_key_bytes = self.key_pair.public_key().to_bytes()?;
        // Uncompressed form (see SECG SEC1 section 2.3.3).
        // First byte is 4, then 32 bytes for x, and 32 bytes for y.
        assert_eq!(pub_key_bytes.len(), 1 + 32 + 32);
        assert_eq!(pub_key_bytes[0], 0x04);
        let x = Vec::from(&pub_key_bytes[1..33]);
        let x = base64::encode_config(&x, base64::URL_SAFE_NO_PAD);
        let y = Vec::from(&pub_key_bytes[33..]);
        let y = base64::encode_config(&y, base64::URL_SAFE_NO_PAD);
        Ok(json!({
            "crv": "P-256",
            "kty": "EC",
            "x": x,
            "y": y,
        })
        .to_string())
    }

    pub fn decrypt_keys_jwe(self, jwe: &str) -> Result<String> {
        let segments: Vec<&str> = jwe.split('.').collect();
        let header = base64::decode_config(&segments[0], base64::URL_SAFE_NO_PAD)?;
        let protected_header: serde_json::Value = serde_json::from_slice(&header)?;
        if protected_header["epk"]["kty"] != "EC" {
            return Err(ErrorKind::UnrecoverableServerError("Only EC keys are supported.").into());
        }
        if protected_header["epk"]["crv"] != "P-256" {
            return Err(
                ErrorKind::UnrecoverableServerError("Only P-256 curves are supported.").into(),
            );
        }
        let alg = protected_header["enc"]
            .as_str()
            .ok_or_else(|| ErrorKind::UnrecoverableServerError("enc is not a string."))?;
        let apu = protected_header["apu"].as_str().unwrap_or("");
        let apv = protected_header["apv"].as_str().unwrap_or("");

        // Part 1: Grab the x/y from the other party and construct the secret.
        let x = base64::decode_config(
            &protected_header["epk"]["x"]
                .as_str()
                .ok_or_else(|| ErrorKind::UnrecoverableServerError("x is not a string."))?,
            base64::URL_SAFE_NO_PAD,
        )?;
        let y = base64::decode_config(
            &protected_header["epk"]["y"]
                .as_str()
                .ok_or_else(|| ErrorKind::UnrecoverableServerError("y is not a string."))?,
            base64::URL_SAFE_NO_PAD,
        )?;
        if x.len() != (256 / 8) {
            return Err(ErrorKind::UnrecoverableServerError("X must be 32 bytes long.").into());
        }
        if y.len() != (256 / 8) {
            return Err(ErrorKind::UnrecoverableServerError("Y must be 32 bytes long.").into());
        }
        let mut peer_pub_key: Vec<u8> = vec![0x04];
        peer_pub_key.extend_from_slice(&x);
        peer_pub_key.extend_from_slice(&y);
        let (private_key, _) = self.key_pair.split();
        let ikm = private_key.agree(&agreement::ECDH_P256, &peer_pub_key)?;
        let secret = ikm.derive(|z| {
            // ConcatKDF (1 iteration since keyLen <= hashLen).
            // See rfc7518 section 4.6 for reference.
            let counter = 1;
            let mut buf: Vec<u8> = vec![];
            buf.extend_from_slice(&to_32b_buf(counter));
            buf.extend_from_slice(&z);
            // otherinfo
            buf.extend_from_slice(&to_32b_buf(alg.len() as u32));
            buf.extend_from_slice(alg.as_bytes());
            buf.extend_from_slice(&to_32b_buf(apu.len() as u32));
            buf.extend_from_slice(apu.as_bytes());
            buf.extend_from_slice(&to_32b_buf(apv.len() as u32));
            buf.extend_from_slice(apv.as_bytes());
            buf.extend_from_slice(&to_32b_buf(256));
            digest::digest(&digest::SHA256, &buf)
        })?;

        // Part 2: decrypt the payload with the obtained secret
        if !segments[1].is_empty() {
            return Err(
                ErrorKind::UnrecoverableServerError("The Encrypted Key must be empty.").into(),
            );
        }
        let iv = base64::decode_config(&segments[2], base64::URL_SAFE_NO_PAD)?;
        let ciphertext = base64::decode_config(&segments[3], base64::URL_SAFE_NO_PAD)?;
        let auth_tag = base64::decode_config(&segments[4], base64::URL_SAFE_NO_PAD)?;
        if auth_tag.len() != (128 / 8) {
            return Err(
                ErrorKind::UnrecoverableServerError("The auth tag must be 16 bytes long.").into(),
            );
        }
        let opening_key = aead::OpeningKey::new(&aead::AES_256_GCM, &secret.as_ref())
            .map_err(|_| ErrorKind::KeyImportFailed)?;
        let mut ciphertext_and_tag = ciphertext.to_vec();
        ciphertext_and_tag.extend(&auth_tag.to_vec());
        let nonce = aead::Nonce::try_assume_unique_for_key(&aead::AES_256_GCM, &iv)?;
        let aad = aead::Aad::from(segments[0].as_bytes());
        let plaintext = aead::open(&opening_key, nonce, aad, &ciphertext_and_tag)
            .map_err(|_| ErrorKind::AEADOpenFailure)?;
        String::from_utf8(plaintext.to_vec()).map_err(Into::into)
    }
}

fn to_32b_buf(n: u32) -> Vec<u8> {
    let mut buf = [0; 4];
    BigEndian::write_u32(&mut buf, n);
    buf.to_vec()
}

#[cfg(test)]
mod tests {
    use super::*;
    use rc_crypto::agreement::PrivateKey;

    #[test]
    fn test_flow() {
        let x = base64::decode_config(
            "ARvGIPJ5eIFdp6YTM-INVDqwfun2R9FfCUvXbH7QCIU",
            base64::URL_SAFE_NO_PAD,
        )
        .unwrap();
        let y = base64::decode_config(
            "hk8gP0Po8nBh-WSiTsvsyesC5c1L6fGOEVuX8FHsvTs",
            base64::URL_SAFE_NO_PAD,
        )
        .unwrap();
        let d = base64::decode_config(
            "UayD4kn_4QHvLvLLSSaANfDUp9AcQndQu_TohQKoyn8",
            base64::URL_SAFE_NO_PAD,
        )
        .unwrap();
        let ec_key =
            agreement::EcKey::from_coordinates(agreement::Curve::P256, &d, &x, &y).unwrap();
        let private_key = PrivateKey::<rc_crypto::agreement::Static>::import(&ec_key).unwrap();
        let key_pair = KeyPair::from(private_key).unwrap();
        let flow = ScopedKeysFlow::from_static_key_pair(key_pair).unwrap();
        let json = flow.generate_keys_jwk().unwrap();
        assert_eq!(json, "{\"crv\":\"P-256\",\"kty\":\"EC\",\"x\":\"ARvGIPJ5eIFdp6YTM-INVDqwfun2R9FfCUvXbH7QCIU\",\"y\":\"hk8gP0Po8nBh-WSiTsvsyesC5c1L6fGOEVuX8FHsvTs\"}");

        let jwe = "eyJhbGciOiJFQ0RILUVTIiwia2lkIjoiNFBKTTl5dGVGeUtsb21ILWd2UUtyWGZ0a0N3ak9HNHRfTmpYVXhLM1VqSSIsImVwayI6eyJrdHkiOiJFQyIsImNydiI6IlAtMjU2IiwieCI6IlB3eG9Na1RjSVZ2TFlKWU4wM2R0Y3o2TEJrR0FHaU1hZWlNQ3lTZXEzb2MiLCJ5IjoiLUYtTllRRDZwNUdSQ2ZoYm1hN3NvNkhxdExhVlNub012S0pFcjFBeWlaSSJ9LCJlbmMiOiJBMjU2R0NNIn0..b9FPhjjpmAmo_rP8.ur9jTry21Y2trvtcanSFmAtiRfF6s6qqyg6ruRal7PCwa7PxDzAuMN6DZW5BiK8UREOH08-FyRcIgdDOm5Zq8KwVAn56PGfcH30aNDGQNkA_mpfjx5Tj2z8kI6ryLWew4PGZb-PsL1g-_eyXhktq7dAhetjNYttKwSREWQFokv7N3nJGpukBqnwL1ost-MjDXlINZLVJKAiMHDcu-q7Epitwid2c2JVGOSCJjbZ4-zbxVmZ4o9xhFb2lbvdiaMygH6bPlrjEK99uT6XKtaIZmyDwftbD6G3x4On-CqA2TNL6ILRaJMtmyX--ctL0IrngUIHg_F0Wz94v.zBD8NACkUcZTPLH0tceGnA";
        let keys = flow.decrypt_keys_jwe(jwe).unwrap();
        assert_eq!(keys, "{\"https://identity.mozilla.com/apps/oldsync\":{\"kty\":\"oct\",\"scope\":\"https://identity.mozilla.com/apps/oldsync\",\"k\":\"8ek1VNk4sjrNP0DhGC4crzQtwmpoR64zHuFMHb4Tw-exR70Z2SSIfMSrJDTLEZid9lD05-hbA3n2Q4Esjlu1tA\",\"kid\":\"1526414944666-zgTjf5oXmPmBjxwXWFsDWg\"}}");
    }
}
