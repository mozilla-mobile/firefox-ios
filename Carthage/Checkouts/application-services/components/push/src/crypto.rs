/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error;
use rc_crypto::ece::{
    Aes128GcmEceWebPush, AesGcmEceWebPush, AesGcmEncryptedBlock, EcKeyComponents, LocalKeyPair,
};
use rc_crypto::ece_crypto::RcCryptoLocalKeyPair;
use rc_crypto::rand;
use serde_derive::*;

pub const SER_AUTH_LENGTH: usize = 16;
pub type Decrypted = Vec<u8>;

#[derive(Serialize, Deserialize, Clone)]
pub(crate) enum VersionnedKey {
    V1(KeyV1),
}

#[derive(Clone, PartialEq, Serialize, Deserialize)]
pub struct KeyV1 {
    p256key: EcKeyComponents,
    pub auth: Vec<u8>,
}
pub type Key = KeyV1;

impl std::fmt::Debug for KeyV1 {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("KeyV1").finish()
    }
}

impl Key {
    // We define this method so the type-checker prevents us from
    // trying to serialize `Key` directly since `bincode::serialize`
    // would compile because both types derive `Serialize`.
    pub(crate) fn serialize(&self) -> error::Result<Vec<u8>> {
        bincode::serialize(&VersionnedKey::V1(self.clone())).map_err(|e| {
            error::ErrorKind::GeneralError(format!("Could not serialize key: {:?}", e)).into()
        })
    }

    pub(crate) fn deserialize(bytes: &[u8]) -> error::Result<Self> {
        let versionned: VersionnedKey = bincode::deserialize(bytes).map_err(|e| {
            error::ErrorKind::GeneralError(format!("Could not de-serialize key: {:?}", e))
        })?;
        match versionned {
            VersionnedKey::V1(prv_key) => Ok(prv_key),
        }
    }

    pub fn key_pair(&self) -> error::Result<RcCryptoLocalKeyPair> {
        RcCryptoLocalKeyPair::from_raw_components(&self.p256key).map_err(|e| {
            error::ErrorKind::CryptoError(format!(
                "Could not re-create key from components: {:?}",
                e
            ))
            .into()
        })
    }

    pub fn private_key(&self) -> &[u8] {
        self.p256key.private_key()
    }

    pub fn public_key(&self) -> &[u8] {
        self.p256key.public_key()
    }
}

pub trait Cryptography {
    /// generate a new local EC p256 key
    fn generate_key() -> error::Result<Key>;

    /// create a test key for testing
    fn test_key(priv_key: &str, pub_key: &str, auth: &str) -> Key;

    /// General decrypt function. Calls to decrypt_aesgcm or decrypt_aes128gcm as needed.
    // (sigh, can't use notifier::Notification because of circular dependencies.)
    fn decrypt(
        key: &Key,
        body: &str,
        encoding: &str,
        salt: Option<&str>,
        dh: Option<&str>,
    ) -> error::Result<Decrypted>;
    // IIUC: objects created on one side of FFI can't be freed on the other side, so we have to use references (or clone)

    /// Decrypt the obsolete "aesgcm" format (which is still used by a number of providers)
    fn decrypt_aesgcm(
        key: &Key,
        content: &[u8],
        salt: Option<Vec<u8>>,
        crypto_key: Option<Vec<u8>>,
    ) -> error::Result<Decrypted>;

    /// Decrypt the RFC 8188 format.
    fn decrypt_aes128gcm(key: &Key, content: &[u8]) -> error::Result<Decrypted>;
}

pub struct Crypto;

pub fn get_bytes(size: usize) -> error::Result<Vec<u8>> {
    let mut bytes = vec![0u8; size];
    rand::fill(&mut bytes).map_err(|e| {
        error::ErrorKind::CryptoError(format!("Could not generate random bytes: {:?}", e))
    })?;
    Ok(bytes)
}

/// Extract the sub-value from the header.
/// Sub values have the form of `label=value`. Due to a bug in some push providers, treat ',' and ';' as
/// equivalent.
/// @param string: the string to search,
fn extract_value(string: Option<&str>, target: &str) -> Option<Vec<u8>> {
    if let Some(val) = string {
        if !val.contains(&format!("{}=", target)) {
            log::debug!("No sub-value found for {}", target);
            return None;
        }
        let items: Vec<&str> = val.split(|c| c == ',' || c == ';').collect();
        for item in items {
            let kv: Vec<&str> = item.split('=').collect();
            if kv[0] == target {
                return match base64::decode_config(kv[1], base64::URL_SAFE_NO_PAD) {
                    Ok(v) => Some(v),
                    Err(e) => {
                        log::error!("base64 failed for target:{}; {:?}", target, e);
                        None
                    }
                };
            }
        }
    }
    None
}

impl Cryptography for Crypto {
    /// Generate a new cryptographic Key
    fn generate_key() -> error::Result<Key> {
        let key = RcCryptoLocalKeyPair::generate_random().map_err(|e| {
            error::ErrorKind::CryptoError(format!("Could not generate key: {:?}", e))
        })?;
        let components = key.raw_components().map_err(|e| {
            error::ErrorKind::CryptoError(format!("Could not extract key components: {:?}", e))
        })?;
        let auth = get_bytes(SER_AUTH_LENGTH)?;
        Ok(Key {
            p256key: components,
            auth,
        })
    }

    // generate unit test key
    fn test_key(priv_key: &str, pub_key: &str, auth: &str) -> Key {
        let components = EcKeyComponents::new(
            base64::decode_config(priv_key, base64::URL_SAFE_NO_PAD).unwrap(),
            base64::decode_config(pub_key, base64::URL_SAFE_NO_PAD).unwrap(),
        );
        let auth = base64::decode_config(auth, base64::URL_SAFE_NO_PAD).unwrap();
        Key {
            p256key: components,
            auth,
        }
    }

    /// Decrypt the incoming webpush message based on the content-encoding
    fn decrypt(
        key: &Key,
        body: &str,
        encoding: &str,
        salt: Option<&str>,
        dh: Option<&str>,
    ) -> error::Result<Decrypted> {
        rc_crypto::ensure_initialized();
        // convert the private key into something useful.
        let d_salt = extract_value(salt, "salt");
        let d_dh = extract_value(dh, "dh");
        let d_body = base64::decode_config(body, base64::URL_SAFE_NO_PAD).map_err(|e| {
            error::ErrorKind::TranscodingError(format!("Could not parse incoming body: {:?}", e))
        })?;

        match encoding.to_lowercase().as_str() {
            "aesgcm" => Self::decrypt_aesgcm(&key, &d_body, d_salt, d_dh),
            "aes128gcm" => Self::decrypt_aes128gcm(&key, &d_body),
            _ => Err(error::ErrorKind::CryptoError("Unknown Content Encoding".to_string()).into()),
        }
    }

    // IIUC: objects created on one side of FFI can't be freed on the other side, so we have to use references (or clone)
    fn decrypt_aesgcm(
        key: &Key,
        content: &[u8],
        salt: Option<Vec<u8>>,
        crypto_key: Option<Vec<u8>>,
    ) -> error::Result<Decrypted> {
        let dh = match crypto_key {
            Some(v) => v,
            None => {
                return Err(error::ErrorKind::CryptoError("Missing public key".to_string()).into());
            }
        };
        let salt = match salt {
            Some(v) => v,
            None => {
                return Err(error::ErrorKind::CryptoError("Missing salt".to_string()).into());
            }
        };
        let block = match AesGcmEncryptedBlock::new(&dh, &salt, 4096, content.to_vec()) {
            Ok(b) => b,
            Err(e) => {
                return Err(error::ErrorKind::CryptoError(format!(
                    "Could not create block: {}",
                    e
                ))
                .into());
            }
        };
        AesGcmEceWebPush::decrypt(&key.key_pair()?, &key.auth, &block)
            .map_err(|_| error::ErrorKind::CryptoError("Decryption error".to_owned()).into())
    }

    fn decrypt_aes128gcm(key: &Key, content: &[u8]) -> error::Result<Vec<u8>> {
        Aes128GcmEceWebPush::decrypt(&key.key_pair()?, &key.auth, &content)
            .map_err(|_| error::ErrorKind::CryptoError("Decryption error".to_owned()).into())
    }
}

#[cfg(test)]
mod crypto_tests {
    use super::*;

    use error;

    const PLAINTEXT:&str = "Amidst the mists and coldest frosts I thrust my fists against the\nposts and still demand to see the ghosts.\n\n";

    fn decrypter(
        ciphertext: &str,
        encoding: &str,
        salt: Option<&str>,
        dh: Option<&str>,
    ) -> error::Result<Vec<u8>> {
        let priv_key_d = "qJkxxWGVVxy7BKvraNY3hg8Gs-Y8qi0lRaXWJ3R3aJ8";
        // The auth token
        let auth_raw = "LsuUOBKVQRY6-l7_Ajo-Ag";
        // This would be the public key sent to the subscription service.
        let pub_key_raw = "BBcJdfs1GtMyymFTtty6lIGWRFXrEtJP40Df0gOvRDR4D8CKVgqE6vlYR7tCYksIRdKD1MxDPhQVmKLnzuife50";

        let key = Crypto::test_key(priv_key_d, pub_key_raw, auth_raw);
        Crypto::decrypt(&key, ciphertext, encoding, salt, dh)
    }

    #[test]
    fn test_decrypt_aesgcm() {
        // The following comes from the delivered message body
        let ciphertext = "BNKu5uTFhjyS-06eECU9-6O61int3Rr7ARbm-xPhFuyDO5sfxVs-HywGaVonvzkarvfvXE9IRT_YNA81Og2uSqDasdMuw\
                          qm1zd0O3f7049IkQep3RJ2pEZTy5DqvI7kwMLDLzea9nroq3EMH5hYhvQtQgtKXeWieEL_3yVDQVg";
        // and now from the header values
        let dh = "keyid=foo;dh=BMOebOMWSRisAhWpRK9ZPszJC8BL9MiWvLZBoBU6pG6Kh6vUFSW4BHFMh0b83xCg3_7IgfQZXwmVuyu27vwiv5c,otherval=abcde";
        let salt = "salt=tSf2qu43C9BD0zkvRW5eUg";

        // and this is what it should be.

        let decrypted = decrypter(ciphertext, "aesgcm", Some(salt), Some(dh)).unwrap();

        assert_eq!(String::from_utf8(decrypted).unwrap(), PLAINTEXT.to_string());
    }

    #[test]
    fn test_fail_decrypt_aesgcm() {
        let ciphertext = "BNKu5uTFhjyS-06eECU9-6O61int3Rr7ARbm-xPhFuyDO5sfxVs-HywGaVonvzkarvfvXE9IRT_\
                          YNA81Og2uSqDasdMuwqm1zd0O3f7049IkQep3RJ2pEZTy5DqvI7kwMLDLzea9nroq3EMH5hYhvQtQgtKXeWieEL_3yVDQVg";
        let dh = "dh=BMOebOMWSRisAhWpRK9ZPszJC8BL9MiWvLZBoBU6pG6Kh6vUFSW4BHFMh0b83xCg3_7IgfQZXwmVuyu27vwiv5c";
        let salt = "salt=SomeInvalidSaltValue";

        decrypter(ciphertext, "aesgcm", Some(salt), Some(dh))
            .expect_err("Failed to abort, bad salt");
    }

    #[test]
    fn test_decrypt_aes128gcm() {
        let ciphertext = "Ek7iQgliMqS9kjFoiVOqRgAAEABBBFirfBtF6XTeHVPABFDveb1iu7uO1XVA_MYJeAo-\
             4ih8WYUsXSTIYmkKMv5_UB3tZuQI7BQ2EVpYYQfvOCrWZVMRL8fJCuB5wVXcoRoTaFJw\
             TlJ5hnw6IMSiaMqGVlc8drX7Hzy-ugzzAKRhGPV2x-gdsp58DZh9Ww5vHpHyT1xwVkXz\
             x3KTyeBZu4gl_zR0Q00li17g0xGsE6Dg3xlkKEmaalgyUyObl6_a8RA6Ko1Rc6RhAy2jdyY1LQbBUnA";

        let decrypted = decrypter(ciphertext, "aes128gcm", None, None).unwrap();
        assert_eq!(String::from_utf8(decrypted).unwrap(), PLAINTEXT.to_string());
    }
}
