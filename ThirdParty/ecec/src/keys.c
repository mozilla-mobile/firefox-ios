#include "ece/keys.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/evp.h>
#include <openssl/kdf.h>

// Writes an unsigned 16-bit integer in network byte order.
static inline void
ece_write_uint16_be(uint8_t* bytes, uint16_t value) {
  bytes[0] = (value >> 8) & 0xff;
  bytes[1] = value & 0xff;
}

// Extracts an unsigned 64-bit integer in network byte order.
static inline uint64_t
ece_read_uint64_be(const uint8_t* bytes) {
  uint64_t value = bytes[7];
  value |= (uint64_t) bytes[6] << 8;
  value |= (uint64_t) bytes[5] << 16;
  value |= (uint64_t) bytes[4] << 24;
  value |= (uint64_t) bytes[3] << 32;
  value |= (uint64_t) bytes[2] << 40;
  value |= (uint64_t) bytes[1] << 48;
  value |= (uint64_t) bytes[0] << 56;
  return value;
}

// Writes an unsigned 64-bit integer in network byte order.
static inline void
ece_write_uint64_be(uint8_t* bytes, uint64_t value) {
  bytes[0] = (value >> 56) & 0xff;
  bytes[1] = (value >> 48) & 0xff;
  bytes[2] = (value >> 40) & 0xff;
  bytes[3] = (value >> 32) & 0xff;
  bytes[4] = (value >> 24) & 0xff;
  bytes[5] = (value >> 16) & 0xff;
  bytes[6] = (value >> 8) & 0xff;
  bytes[7] = value & 0xff;
}

void
ece_generate_iv(const uint8_t* nonce, uint64_t counter, uint8_t* iv) {
  // Copy the first 4 bytes as-is, since `(x ^ 0) == x`.
  size_t offset = ECE_NONCE_LENGTH - 8;
  memcpy(iv, nonce, offset);
  // Combine the remaining unsigned 64-bit integer with the record sequence
  // number using XOR. See the "nonce derivation" section of the draft.
  uint64_t mask = ece_read_uint64_be(&nonce[offset]);
  ece_write_uint64_be(&iv[offset], mask ^ counter);
}

EC_KEY*
ece_import_private_key(const uint8_t* rawKey, size_t rawKeyLen) {
  EC_KEY* key = NULL;
  EC_POINT* pubKeyPt = NULL;

  key = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
  if (!key) {
    goto error;
  }
  if (EC_KEY_oct2priv(key, rawKey, rawKeyLen) <= 0) {
    goto error;
  }
  const EC_GROUP* group = EC_KEY_get0_group(key);
  pubKeyPt = EC_POINT_new(group);
  if (!pubKeyPt) {
    goto error;
  }
  const BIGNUM* privKey = EC_KEY_get0_private_key(key);
  if (EC_POINT_mul(group, pubKeyPt, privKey, NULL, NULL, NULL) <= 0) {
    goto error;
  }
  if (EC_KEY_set_public_key(key, pubKeyPt) <= 0) {
    goto error;
  }
  goto end;

error:
  EC_KEY_free(key);
  key = NULL;

end:
  EC_POINT_free(pubKeyPt);
  return key;
}

EC_KEY*
ece_import_public_key(const uint8_t* rawKey, size_t rawKeyLen) {
  EC_KEY* key = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
  if (!key) {
    return NULL;
  }
  if (!EC_KEY_oct2key(key, rawKey, rawKeyLen, NULL)) {
    EC_KEY_free(key);
    return NULL;
  }
  return key;
}

// HKDF from RFC 5869: `HKDF-Expand(HKDF-Extract(salt, ikm), info, length)`.
static int
ece_hkdf_sha256(const uint8_t* salt, size_t saltLen, const uint8_t* ikm,
                size_t ikmLen, const uint8_t* info, size_t infoLen,
                uint8_t* output, size_t outputLen) {
  int err = ECE_OK;

  EVP_PKEY_CTX* ctx = EVP_PKEY_CTX_new_id(EVP_PKEY_HKDF, NULL);
  if (!ctx) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (EVP_PKEY_derive_init(ctx) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (EVP_PKEY_CTX_set_hkdf_md(ctx, EVP_sha256()) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (EVP_PKEY_CTX_set1_hkdf_salt(ctx, salt, (int) saltLen) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (EVP_PKEY_CTX_set1_hkdf_key(ctx, ikm, (int) ikmLen) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (EVP_PKEY_CTX_add1_hkdf_info(ctx, info, (int) infoLen) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (EVP_PKEY_derive(ctx, output, &outputLen) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }

end:
  EVP_PKEY_CTX_free(ctx);
  return err;
}

// Computes the ECDH shared secret, used as the input key material (IKM) for
// HKDF.
static uint8_t*
ece_compute_secret(EC_KEY* privKey, EC_KEY* pubKey, size_t* sharedSecretLen) {
  uint8_t* sharedSecret = NULL;

  const EC_GROUP* group = EC_KEY_get0_group(privKey);
  const EC_POINT* pubKeyPt = EC_KEY_get0_public_key(pubKey);
  int fieldSize = EC_GROUP_get_degree(group);
  if (fieldSize <= 0) {
    goto error;
  }
  *sharedSecretLen = ((size_t) fieldSize + 7) / 8;
  sharedSecret = calloc(*sharedSecretLen, sizeof(uint8_t));
  if (!sharedSecret) {
    goto error;
  }
  if (ECDH_compute_key(sharedSecret, *sharedSecretLen, pubKeyPt, privKey,
                       NULL) <= 0) {
    goto error;
  }
  goto end;

error:
  free(sharedSecret);
  sharedSecret = NULL;
  *sharedSecretLen = 0;

end:
  return sharedSecret;
}

// The "aes128gcm" IKM info string is "WebPush: info\0", followed by the
// receiver and sender public keys.
static int
ece_webpush_aes128gcm_generate_info(EC_KEY* recvKey, EC_KEY* senderKey,
                                    const char* prefix, size_t prefixLen,
                                    uint8_t* info) {
  size_t offset = 0;

  // Copy the prefix.
  memcpy(info, prefix, prefixLen);
  offset += prefixLen;

  // Copy the receiver public key.
  const EC_GROUP* recvGrp = EC_KEY_get0_group(recvKey);
  const EC_POINT* recvKeyPt = EC_KEY_get0_public_key(recvKey);
  size_t recvKeyLen =
    EC_POINT_point2oct(recvGrp, recvKeyPt, POINT_CONVERSION_UNCOMPRESSED,
                       &info[offset], ECE_WEBPUSH_PUBLIC_KEY_LENGTH, NULL);
  if (!recvKeyLen) {
    return ECE_ERROR_ENCODE_PUBLIC_KEY;
  }
  offset += recvKeyLen;

  // Copy the sender public key.
  const EC_GROUP* senderGrp = EC_KEY_get0_group(senderKey);
  const EC_POINT* senderKeyPt = EC_KEY_get0_public_key(senderKey);
  size_t senderKeyLen =
    EC_POINT_point2oct(senderGrp, senderKeyPt, POINT_CONVERSION_UNCOMPRESSED,
                       &info[offset], ECE_WEBPUSH_PUBLIC_KEY_LENGTH, NULL);
  if (!senderKeyLen) {
    return ECE_ERROR_ENCODE_PUBLIC_KEY;
  }

  return ECE_OK;
}

int
ece_aes128gcm_derive_key_and_nonce(const uint8_t* salt, size_t saltLen,
                                   const uint8_t* ikm, size_t ikmLen,
                                   uint8_t* key, uint8_t* nonce) {
  uint8_t keyInfo[ECE_AES128GCM_KEY_INFO_LENGTH];
  memcpy(keyInfo, ECE_AES128GCM_KEY_INFO, ECE_AES128GCM_KEY_INFO_LENGTH);
  int err =
    ece_hkdf_sha256(salt, saltLen, ikm, ikmLen, keyInfo,
                    ECE_AES128GCM_KEY_INFO_LENGTH, key, ECE_AES_KEY_LENGTH);
  if (err) {
    return err;
  }

  uint8_t nonceInfo[ECE_AES128GCM_NONCE_INFO_LENGTH];
  memcpy(nonceInfo, ECE_AES128GCM_NONCE_INFO, ECE_AES128GCM_NONCE_INFO_LENGTH);
  return ece_hkdf_sha256(salt, saltLen, ikm, ikmLen, nonceInfo,
                         ECE_AES128GCM_NONCE_INFO_LENGTH, nonce,
                         ECE_NONCE_LENGTH);
}

int
ece_webpush_aes128gcm_derive_key_and_nonce(ece_mode_t mode, EC_KEY* localKey,
                                           EC_KEY* remoteKey,
                                           const uint8_t* authSecret,
                                           size_t authSecretLen,
                                           const uint8_t* salt, size_t saltLen,
                                           uint8_t* key, uint8_t* nonce) {
  int err = ECE_OK;

  uint8_t* sharedSecret = NULL;

  size_t sharedSecretLen = 0;
  sharedSecret = ece_compute_secret(localKey, remoteKey, &sharedSecretLen);
  if (!sharedSecret) {
    err = ECE_ERROR_COMPUTE_SECRET;
    goto end;
  }

  // The new "aes128gcm" scheme includes the sender and receiver public keys in
  // the info string when deriving the Web Push IKM.
  uint8_t ikmInfo[ECE_WEBPUSH_AES128GCM_IKM_INFO_LENGTH];
  switch (mode) {
  case ECE_MODE_ENCRYPT:
    // For encryption, the remote static public key is the receiver key, and the
    // local ephemeral private key is the sender key.
    err = ece_webpush_aes128gcm_generate_info(
      remoteKey, localKey, ECE_WEBPUSH_AES128GCM_IKM_INFO_PREFIX,
      ECE_WEBPUSH_AES128GCM_IKM_INFO_PREFIX_LENGTH, ikmInfo);
    break;

  case ECE_MODE_DECRYPT:
    // For decryption, the local static private key is the receiver key, and the
    // remote ephemeral public key is the sender key.
    err = ece_webpush_aes128gcm_generate_info(
      localKey, remoteKey, ECE_WEBPUSH_AES128GCM_IKM_INFO_PREFIX,
      ECE_WEBPUSH_AES128GCM_IKM_INFO_PREFIX_LENGTH, ikmInfo);
    break;

  default:
    assert(false);
    err = ECE_ERROR_DECRYPT;
  }
  if (err) {
    goto end;
  }
  uint8_t ikm[ECE_WEBPUSH_IKM_LENGTH];
  err = ece_hkdf_sha256(
    authSecret, authSecretLen, sharedSecret, sharedSecretLen, ikmInfo,
    ECE_WEBPUSH_AES128GCM_IKM_INFO_LENGTH, ikm, ECE_WEBPUSH_IKM_LENGTH);
  if (err) {
    goto end;
  }

  err = ece_aes128gcm_derive_key_and_nonce(salt, saltLen, ikm,
                                           ECE_WEBPUSH_IKM_LENGTH, key, nonce);

end:
  free(sharedSecret);
  return err;
}

// The "aesgcm" info string is "Content-Encoding: <aesgcm | nonce>\0P-256\0",
// followed by the length-prefixed (unsigned 16-bit integers) receiver and
// sender public keys.
static int
ece_webpush_aesgcm_generate_info(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                                 const char* prefix, size_t prefixLen,
                                 uint8_t* info) {
  size_t offset = 0;

  // Copy the prefix to the buffer.
  memcpy(info, prefix, prefixLen);
  offset += prefixLen;

  // Copy the length-prefixed receiver public key.
  ece_write_uint16_be(&info[offset], ECE_WEBPUSH_PUBLIC_KEY_LENGTH);
  offset += 2;
  const EC_GROUP* recvGrp = EC_KEY_get0_group(recvPrivKey);
  const EC_POINT* recvPubKeyPt = EC_KEY_get0_public_key(recvPrivKey);
  size_t recvPubKeyLen =
    EC_POINT_point2oct(recvGrp, recvPubKeyPt, POINT_CONVERSION_UNCOMPRESSED,
                       &info[offset], ECE_WEBPUSH_PUBLIC_KEY_LENGTH, NULL);
  if (!recvPubKeyLen) {
    return ECE_ERROR_ENCODE_PUBLIC_KEY;
  }
  offset += recvPubKeyLen;

  // Copy the length-prefixed sender public key.
  ece_write_uint16_be(&info[offset], ECE_WEBPUSH_PUBLIC_KEY_LENGTH);
  offset += 2;
  const EC_GROUP* senderGrp = EC_KEY_get0_group(senderPubKey);
  const EC_POINT* senderPubKeyPt = EC_KEY_get0_public_key(senderPubKey);
  size_t senderPubKeyLen =
    EC_POINT_point2oct(senderGrp, senderPubKeyPt, POINT_CONVERSION_UNCOMPRESSED,
                       &info[offset], ECE_WEBPUSH_PUBLIC_KEY_LENGTH, NULL);
  if (!senderPubKeyLen) {
    return ECE_ERROR_ENCODE_PUBLIC_KEY;
  }

  return ECE_OK;
}

int
ece_webpush_aesgcm_derive_key_and_nonce(ece_mode_t mode, EC_KEY* recvPrivKey,
                                        EC_KEY* senderPubKey,
                                        const uint8_t* authSecret,
                                        size_t authSecretLen,
                                        const uint8_t* salt, size_t saltLen,
                                        uint8_t* key, uint8_t* nonce) {
  ECE_UNUSED(mode);

  int err = ECE_OK;

  uint8_t* sharedSecret = NULL;

  size_t sharedSecretLen = 0;
  sharedSecret =
    ece_compute_secret(recvPrivKey, senderPubKey, &sharedSecretLen);
  if (!sharedSecret) {
    err = ECE_ERROR_COMPUTE_SECRET;
    goto end;
  }

  // The old "aesgcm" scheme uses a static info string to derive the Web Push
  // IKM.
  uint8_t ikm[ECE_WEBPUSH_IKM_LENGTH];
  uint8_t ikmInfo[ECE_WEBPUSH_AESGCM_IKM_INFO_LENGTH];
  memcpy(ikmInfo, ECE_WEBPUSH_AESGCM_IKM_INFO,
         ECE_WEBPUSH_AESGCM_IKM_INFO_LENGTH);
  err = ece_hkdf_sha256(
    authSecret, authSecretLen, sharedSecret, sharedSecretLen, ikmInfo,
    ECE_WEBPUSH_AESGCM_IKM_INFO_LENGTH, ikm, ECE_WEBPUSH_IKM_LENGTH);
  if (err) {
    goto end;
  }

  // Next, derive the AES decryption key and nonce. We include the sender and
  // receiver public keys in the info strings.
  uint8_t keyInfo[ECE_WEBPUSH_AESGCM_KEY_INFO_LENGTH];
  err = ece_webpush_aesgcm_generate_info(
    recvPrivKey, senderPubKey, ECE_WEBPUSH_AESGCM_KEY_INFO_PREFIX,
    ECE_WEBPUSH_AESGCM_KEY_INFO_PREFIX_LENGTH, keyInfo);
  if (err) {
    goto end;
  }
  err = ece_hkdf_sha256(salt, saltLen, ikm, ECE_WEBPUSH_IKM_LENGTH, keyInfo,
                        ECE_WEBPUSH_AESGCM_KEY_INFO_LENGTH, key,
                        ECE_AES_KEY_LENGTH);
  if (err) {
    goto end;
  }
  uint8_t nonceInfo[ECE_WEBPUSH_AESGCM_NONCE_INFO_LENGTH];
  err = ece_webpush_aesgcm_generate_info(
    recvPrivKey, senderPubKey, ECE_WEBPUSH_AESGCM_NONCE_INFO_PREFIX,
    ECE_WEBPUSH_AESGCM_NONCE_INFO_PREFIX_LENGTH, nonceInfo);
  if (err) {
    goto end;
  }
  err = ece_hkdf_sha256(salt, saltLen, ikm, ECE_WEBPUSH_IKM_LENGTH, nonceInfo,
                        ECE_WEBPUSH_AESGCM_NONCE_INFO_LENGTH, nonce,
                        ECE_NONCE_LENGTH);

end:
  free(sharedSecret);
  return err;
}
