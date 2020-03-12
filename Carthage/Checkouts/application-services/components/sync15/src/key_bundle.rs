/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::{ErrorKind, Result};
use rc_crypto::{
    aead::{self, OpeningKey, SealingKey},
    rand,
};

#[derive(Clone, PartialEq, Eq, Hash)]
pub struct KeyBundle {
    enc_key: Vec<u8>,
    mac_key: Vec<u8>,
}

impl std::fmt::Debug for KeyBundle {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("KeyBundle").finish()
    }
}

impl KeyBundle {
    /// Construct a key bundle from the already-decoded encrypt and hmac keys.
    /// Panics (asserts) if they aren't both 32 bytes.
    pub fn new(enc: Vec<u8>, mac: Vec<u8>) -> Result<KeyBundle> {
        if enc.len() != 32 {
            log::error!("Bad key length (enc_key): {} != 32", enc.len());
            return Err(ErrorKind::BadKeyLength("enc_key", enc.len(), 32).into());
        }
        if mac.len() != 32 {
            log::error!("Bad key length (mac_key): {} != 32", mac.len());
            return Err(ErrorKind::BadKeyLength("mac_key", mac.len(), 32).into());
        }
        Ok(KeyBundle {
            enc_key: enc,
            mac_key: mac,
        })
    }

    pub fn new_random() -> Result<KeyBundle> {
        let mut buffer = [0u8; 64];
        rand::fill(&mut buffer)?;
        KeyBundle::from_ksync_bytes(&buffer)
    }

    pub fn from_ksync_bytes(ksync: &[u8]) -> Result<KeyBundle> {
        if ksync.len() != 64 {
            log::error!("Bad key length (kSync): {} != 64", ksync.len());
            return Err(ErrorKind::BadKeyLength("kSync", ksync.len(), 64).into());
        }
        Ok(KeyBundle {
            enc_key: ksync[0..32].into(),
            mac_key: ksync[32..64].into(),
        })
    }

    pub fn from_ksync_base64(ksync: &str) -> Result<KeyBundle> {
        let bytes = base64::decode_config(&ksync, base64::URL_SAFE_NO_PAD)?;
        KeyBundle::from_ksync_bytes(&bytes)
    }

    pub fn from_base64(enc: &str, mac: &str) -> Result<KeyBundle> {
        let enc_bytes = base64::decode(&enc)?;
        let mac_bytes = base64::decode(&mac)?;
        KeyBundle::new(enc_bytes, mac_bytes)
    }

    #[inline]
    pub fn encryption_key(&self) -> &[u8] {
        &self.enc_key
    }

    #[inline]
    pub fn hmac_key(&self) -> &[u8] {
        &self.mac_key
    }

    #[inline]
    pub fn to_b64_array(&self) -> [String; 2] {
        [base64::encode(&self.enc_key), base64::encode(&self.mac_key)]
    }

    /// Decrypt the provided ciphertext with the given iv, and decodes the
    /// result as a utf8 string.
    pub fn decrypt(&self, enc_base64: &str, iv_base64: &str, hmac_base16: &str) -> Result<String> {
        // Decode the expected_hmac into bytes to avoid issues if a client happens to encode
        // this as uppercase. This shouldn't happen in practice, but doing it this way is more
        // robust and avoids an allocation.
        let mut decoded_hmac = vec![0u8; 32];
        if base16::decode_slice(hmac_base16, &mut decoded_hmac).is_err() {
            log::warn!("Garbage HMAC verification string: contained non base16 characters");
            return Err(ErrorKind::HmacMismatch.into());
        }
        let iv = base64::decode(iv_base64)?;
        let ciphertext_bytes = base64::decode(enc_base64)?;
        let key_bytes = [self.encryption_key(), self.hmac_key()].concat();
        let key = OpeningKey::new(&aead::LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes)?;
        let nonce = aead::Nonce::try_assume_unique_for_key(
            &aead::LEGACY_SYNC_AES_256_CBC_HMAC_SHA256,
            &iv,
        )?;
        let ciphertext_and_hmac = [ciphertext_bytes, decoded_hmac].concat();
        let cleartext_bytes = aead::open(&key, nonce, aead::Aad::empty(), &ciphertext_and_hmac)?;
        let cleartext = String::from_utf8(cleartext_bytes)?;
        Ok(cleartext)
    }

    /// Encrypt using the provided IV.
    pub fn encrypt_bytes_with_iv(
        &self,
        cleartext_bytes: &[u8],
        iv: &[u8],
    ) -> Result<(String, String)> {
        let key_bytes = [self.encryption_key(), self.hmac_key()].concat();
        let key = SealingKey::new(&aead::LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, &key_bytes)?;
        let nonce =
            aead::Nonce::try_assume_unique_for_key(&aead::LEGACY_SYNC_AES_256_CBC_HMAC_SHA256, iv)?;
        let ciphertext_and_hmac = aead::seal(&key, nonce, aead::Aad::empty(), cleartext_bytes)?;
        let ciphertext_len = ciphertext_and_hmac.len() - key.algorithm().tag_len();
        // Do the string conversions here so we don't have to split and copy to 2 vectors.
        let (ciphertext, hmac_signature) = ciphertext_and_hmac.split_at(ciphertext_len);
        let enc_base64 = base64::encode(&ciphertext);
        let hmac_base16 = base16::encode_lower(&hmac_signature);
        Ok((enc_base64, hmac_base16))
    }

    /// Generate a random iv and encrypt with it. Return both the encrypted bytes
    /// and the generated iv.
    pub fn encrypt_bytes_rand_iv(
        &self,
        cleartext_bytes: &[u8],
    ) -> Result<(String, String, String)> {
        let mut iv = [0u8; 16];
        rand::fill(&mut iv)?;
        let (enc_base64, hmac_base16) = self.encrypt_bytes_with_iv(cleartext_bytes, &iv)?;
        let iv_base64 = base64::encode(&iv);
        Ok((enc_base64, iv_base64, hmac_base16))
    }

    pub fn encrypt_with_iv(&self, cleartext: &str, iv: &[u8]) -> Result<(String, String)> {
        self.encrypt_bytes_with_iv(cleartext.as_bytes(), iv)
    }

    pub fn encrypt_rand_iv(&self, cleartext: &str) -> Result<(String, String, String)> {
        self.encrypt_bytes_rand_iv(cleartext.as_bytes())
    }
}

#[cfg(test)]
mod test {
    use super::*;

    const HMAC_B16: &str = "b1e6c18ac30deb70236bc0d65a46f7a4dce3b8b0e02cf92182b914e3afa5eebc";
    const IV_B64: &str = "GX8L37AAb2FZJMzIoXlX8w==";
    const HMAC_KEY_B64: &str = "MMntEfutgLTc8FlTLQFms8/xMPmCldqPlq/QQXEjx70=";
    const ENC_KEY_B64: &str = "9K/wLdXdw+nrTtXo4ZpECyHFNr4d7aYHqeg3KW9+m6Q=";

    const CIPHERTEXT_B64_PIECES: &[&str] = &[
        "NMsdnRulLwQsVcwxKW9XwaUe7ouJk5Wn80QhbD80l0HEcZGCynh45qIbeYBik0lgcHbK",
        "mlIxTJNwU+OeqipN+/j7MqhjKOGIlvbpiPQQLC6/ffF2vbzL0nzMUuSyvaQzyGGkSYM2",
        "xUFt06aNivoQTvU2GgGmUK6MvadoY38hhW2LCMkoZcNfgCqJ26lO1O0sEO6zHsk3IVz6",
        "vsKiJ2Hq6VCo7hu123wNegmujHWQSGyf8JeudZjKzfi0OFRRvvm4QAKyBWf0MgrW1F8S",
        "FDnVfkq8amCB7NhdwhgLWbN+21NitNwWYknoEWe1m6hmGZDgDT32uxzWxCV8QqqrpH/Z",
        "ggViEr9uMgoy4lYaWqP7G5WKvvechc62aqnsNEYhH26A5QgzmlNyvB+KPFvPsYzxDnSC",
        "jOoRSLx7GG86wT59QZw=",
    ];

    const CLEARTEXT_B64_PIECES: &[&str] = &[
        "eyJpZCI6IjVxUnNnWFdSSlpYciIsImhpc3RVcmkiOiJmaWxlOi8vL1VzZXJzL2phc29u",
        "L0xpYnJhcnkvQXBwbGljYXRpb24lMjBTdXBwb3J0L0ZpcmVmb3gvUHJvZmlsZXMva3Nn",
        "ZDd3cGsuTG9jYWxTeW5jU2VydmVyL3dlYXZlL2xvZ3MvIiwidGl0bGUiOiJJbmRleCBv",
        "ZiBmaWxlOi8vL1VzZXJzL2phc29uL0xpYnJhcnkvQXBwbGljYXRpb24gU3VwcG9ydC9G",
        "aXJlZm94L1Byb2ZpbGVzL2tzZ2Q3d3BrLkxvY2FsU3luY1NlcnZlci93ZWF2ZS9sb2dz",
        "LyIsInZpc2l0cyI6W3siZGF0ZSI6MTMxOTE0OTAxMjM3MjQyNSwidHlwZSI6MX1dfQ==",
    ];

    #[test]
    fn test_decrypt() {
        let key_bundle = KeyBundle::from_base64(ENC_KEY_B64, HMAC_KEY_B64).unwrap();
        let ciphertext = CIPHERTEXT_B64_PIECES.join("");
        let s = key_bundle.decrypt(&ciphertext, IV_B64, HMAC_B16).unwrap();

        let cleartext =
            String::from_utf8(base64::decode(&CLEARTEXT_B64_PIECES.join("")).unwrap()).unwrap();
        assert_eq!(&cleartext, &s);
    }

    #[test]
    fn test_encrypt() {
        let key_bundle = KeyBundle::from_base64(ENC_KEY_B64, HMAC_KEY_B64).unwrap();
        let iv = base64::decode(IV_B64).unwrap();

        let cleartext_bytes = base64::decode(&CLEARTEXT_B64_PIECES.join("")).unwrap();
        let (enc_base64, _hmac_base16) = key_bundle
            .encrypt_bytes_with_iv(&cleartext_bytes, &iv)
            .unwrap();

        let expect_ciphertext = CIPHERTEXT_B64_PIECES.join("");

        assert_eq!(&enc_base64, &expect_ciphertext);

        let (enc_base64_2, iv_base64_2, hmac_base16_2) =
            key_bundle.encrypt_bytes_rand_iv(&cleartext_bytes).unwrap();
        assert_ne!(&enc_base64_2, &expect_ciphertext);

        let s = key_bundle
            .decrypt(&enc_base64_2, &iv_base64_2, &hmac_base16_2)
            .unwrap();
        assert_eq!(&cleartext_bytes, &s.as_bytes());
    }
}
