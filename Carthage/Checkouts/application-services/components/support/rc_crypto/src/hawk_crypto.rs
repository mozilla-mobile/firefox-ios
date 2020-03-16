/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::{digest, hmac, rand};
use hawk::crypto as hc;

impl From<crate::Error> for hc::CryptoError {
    // Our errors impl `Fail`, so we can do this.
    fn from(e: crate::Error) -> Self {
        hc::CryptoError::Other(e.into())
    }
}

pub(crate) struct RcCryptoCryptographer;

impl hc::HmacKey for crate::hmac::SigningKey {
    fn sign(&self, data: &[u8]) -> Result<Vec<u8>, hc::CryptoError> {
        let digest = hmac::sign(&self, data)?;
        Ok(digest.as_ref().into())
    }
}

// I don't really see a reason to bother doing incremental hashing here. A
// one-shot is going to be faster in many cases anyway, and the higher memory
// usage probably doesn't matter given our usage.
struct NssHasher {
    buffer: Vec<u8>,
    algorithm: &'static digest::Algorithm,
}

impl hc::Hasher for NssHasher {
    fn update(&mut self, data: &[u8]) -> Result<(), hc::CryptoError> {
        self.buffer.extend_from_slice(data);
        Ok(())
    }

    fn finish(&mut self) -> Result<Vec<u8>, hc::CryptoError> {
        let digest = digest::digest(self.algorithm, &self.buffer)?;
        let bytes: &[u8] = digest.as_ref();
        Ok(bytes.to_owned())
    }
}

impl hc::Cryptographer for RcCryptoCryptographer {
    fn rand_bytes(&self, output: &mut [u8]) -> Result<(), hc::CryptoError> {
        rand::fill(output)?;
        Ok(())
    }

    fn new_key(
        &self,
        algorithm: hawk::DigestAlgorithm,
        key: &[u8],
    ) -> Result<Box<dyn hc::HmacKey>, hc::CryptoError> {
        let k = hmac::SigningKey::new(to_rc_crypto_algorithm(algorithm)?, key);
        Ok(Box::new(k))
    }

    fn constant_time_compare(&self, a: &[u8], b: &[u8]) -> bool {
        crate::constant_time::verify_slices_are_equal(a, b).is_ok()
    }

    fn new_hasher(
        &self,
        algorithm: hawk::DigestAlgorithm,
    ) -> Result<Box<dyn hc::Hasher>, hc::CryptoError> {
        Ok(Box::new(NssHasher {
            algorithm: to_rc_crypto_algorithm(algorithm)?,
            buffer: vec![],
        }))
    }
}

fn to_rc_crypto_algorithm(
    algorithm: hawk::DigestAlgorithm,
) -> Result<&'static digest::Algorithm, hc::CryptoError> {
    match algorithm {
        hawk::DigestAlgorithm::Sha256 => Ok(&digest::SHA256),
        algo => Err(hc::CryptoError::UnsupportedDigest(algo)),
    }
}

// Note: this doesn't initialize NSS!
pub(crate) fn init() {
    hawk::crypto::set_cryptographer(&crate::hawk_crypto::RcCryptoCryptographer)
        .expect("Failed to initialize `hawk` cryptographer!")
}

#[cfg(test)]
mod test {

    // Based on rust-hawk's hash_consistency. This fails if we've messed up the hashing.
    #[test]
    fn test_hawk_hashing() {
        crate::ensure_initialized();
        let mut hasher1 = hawk::PayloadHasher::new("text/plain", hawk::SHA256).unwrap();
        hasher1.update("pày").unwrap();
        hasher1.update("load").unwrap();
        let hash1 = hasher1.finish().unwrap();

        let mut hasher2 = hawk::PayloadHasher::new("text/plain", hawk::SHA256).unwrap();
        hasher2.update("pàyload").unwrap();
        let hash2 = hasher2.finish().unwrap();

        let hash3 = hawk::PayloadHasher::hash("text/plain", hawk::SHA256, "pàyload").unwrap();

        let hash4 = // "pàyload" as utf-8 bytes
            hawk::PayloadHasher::hash("text/plain", hawk::SHA256, &[112, 195, 160, 121, 108, 111, 97, 100]).unwrap();

        assert_eq!(
            hash1,
            &[
                228, 238, 241, 224, 235, 114, 158, 112, 211, 254, 118, 89, 25, 236, 87, 176, 181,
                54, 61, 135, 42, 223, 188, 103, 194, 59, 83, 36, 136, 31, 198, 50
            ]
        );
        assert_eq!(hash2, hash1);
        assert_eq!(hash3, hash1);
        assert_eq!(hash4, hash1);
    }

    // Based on rust-hawk's test_make_mac. This fails if we've messed up the signing.
    #[test]
    fn test_hawk_signing() {
        crate::ensure_initialized();
        let key = hawk::Key::new(
            &[
                11u8, 19, 228, 209, 79, 189, 200, 59, 166, 47, 86, 254, 235, 184, 120, 197, 75,
                152, 201, 79, 115, 61, 111, 242, 219, 187, 173, 14, 227, 108, 60, 232,
            ],
            hawk::SHA256,
        )
        .unwrap();

        let mac = hawk::mac::Mac::new(
            hawk::mac::MacType::Header,
            &key,
            std::time::UNIX_EPOCH + std::time::Duration::new(1000, 100),
            "nonny",
            "POST",
            "mysite.com",
            443,
            "/v1/api",
            None,
            None,
        )
        .unwrap();
        assert_eq!(
            mac.as_ref(),
            &[
                192, 227, 235, 121, 157, 185, 197, 79, 189, 214, 235, 139, 9, 232, 99, 55, 67, 30,
                68, 0, 150, 187, 192, 238, 21, 200, 209, 107, 245, 159, 243, 178
            ]
        );
    }
}
