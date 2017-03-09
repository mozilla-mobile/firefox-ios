#include "keys.h"

#include <string.h>

#include <openssl/evp.h>
#include <openssl/kdf.h>

// Writes an unsigned 16-bit integer in network byte order.
static inline void
ece_write_uint16_be(uint8_t* bytes, uint16_t value) {
  bytes[0] = (value >> 8) & 0xff;
  bytes[1] = value & 0xff;
}

// Extracts an unsigned 48-bit integer in network byte order.
static inline uint64_t
ece_read_uint48_be(uint8_t* bytes) {
  return bytes[5] | (bytes[4] << 8) | (bytes[3] << 16) |
         ((uint64_t) bytes[2] << 24) | ((uint64_t) bytes[1] << 32) |
         ((uint64_t) bytes[0] << 40);
}

// Writes an unsigned 48-bit integer in network byte order.
static inline void
ece_write_uint48_be(uint8_t* bytes, uint64_t value) {
  bytes[0] = (value >> 40) & 0xff;
  bytes[1] = (value >> 32) & 0xff;
  bytes[2] = (value >> 24) & 0xff;
  bytes[3] = (value >> 16) & 0xff;
  bytes[4] = (value >> 8) & 0xff;
  bytes[5] = value & 0xff;
}

void
ece_generate_iv(uint8_t* nonce, uint64_t counter, uint8_t* iv) {
  // Copy the first 6 bytes as-is, since `(x ^ 0) == x`.
  size_t offset = ECE_NONCE_LENGTH - 6;
  memcpy(iv, nonce, offset);
  // Combine the remaining 6 bytes (an unsigned 48-bit integer) with the
  // record sequence number using XOR. See the "nonce derivation" section
  // of the draft.
  uint64_t mask = ece_read_uint48_be(&nonce[offset]);
  ece_write_uint48_be(&iv[offset], mask ^ counter);
}

EC_KEY*
ece_import_private_key(const ece_buf_t* rawKey) {
  EC_KEY* key = NULL;
  EC_POINT* pubKeyPt = NULL;

  key = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
  if (!key) {
    goto error;
  }
  if (EC_KEY_oct2priv(key, rawKey->bytes, rawKey->length) <= 0) {
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
ece_import_public_key(const ece_buf_t* rawKey) {
  EC_KEY* key = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
  if (!key) {
    return NULL;
  }
  if (!EC_KEY_oct2key(key, rawKey->bytes, rawKey->length, NULL)) {
    EC_KEY_free(key);
    return NULL;
  }
  return key;
}

// HKDF from RFC 5869: `HKDF-Expand(HKDF-Extract(salt, ikm), info, length)`.
// This function does not reset or free `result` on error; its callers already
// handle that.
static int
ece_hkdf_sha256(const ece_buf_t* salt, const ece_buf_t* ikm,
                const ece_buf_t* info, size_t outputLen, ece_buf_t* result) {
  int err = ECE_OK;

  EVP_PKEY_CTX* ctx = NULL;
  if (salt->length > INT_MAX || ikm->length > INT_MAX ||
      info->length > INT_MAX) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  ctx = EVP_PKEY_CTX_new_id(EVP_PKEY_HKDF, NULL);
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
  if (EVP_PKEY_CTX_set1_hkdf_salt(ctx, salt->bytes, (int) salt->length) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (EVP_PKEY_CTX_set1_hkdf_key(ctx, ikm->bytes, (int) ikm->length) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (EVP_PKEY_CTX_add1_hkdf_info(ctx, info->bytes, (int) info->length) <= 0) {
    err = ECE_ERROR_HKDF;
    goto end;
  }
  if (!ece_buf_alloc(result, outputLen)) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }
  if (EVP_PKEY_derive(ctx, result->bytes, &result->length) <= 0 ||
      result->length != outputLen) {
    err = ECE_ERROR_HKDF;
    goto end;
  }

end:
  EVP_PKEY_CTX_free(ctx);
  return err;
}

// Computes the ECDH shared secret, used as the input key material (IKM) for
// HKDF.
static int
ece_compute_secret(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                   ece_buf_t* sharedSecret) {
  int err = ECE_OK;

  const EC_GROUP* recvGrp = EC_KEY_get0_group(recvPrivKey);
  const EC_POINT* senderPubKeyPt = EC_KEY_get0_public_key(senderPubKey);
  int fieldSize = EC_GROUP_get_degree(recvGrp);
  if (fieldSize <= 0) {
    err = ECE_ERROR_COMPUTE_SECRET;
    goto error;
  }
  if (!ece_buf_alloc(sharedSecret, (fieldSize + 7) / 8)) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto error;
  }
  if (ECDH_compute_key(sharedSecret->bytes, sharedSecret->length,
                       senderPubKeyPt, recvPrivKey, NULL) <= 0) {
    err = ECE_ERROR_COMPUTE_SECRET;
    goto error;
  }
  goto end;

error:
  ece_buf_free(sharedSecret);

end:
  return err;
}

// The "aes128gcm" info string is "WebPush: info\0", followed by the receiver
// and sender public keys.
static int
ece_aes128gcm_generate_info(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                            const char* prefix, size_t prefixLen,
                            ece_buf_t* info) {
  int err = ECE_OK;

  // Build up the HKDF info string: "WebPush: info\0", followed by the receiver
  // and sender public keys. First, we determine the lengths of the two keys.
  // Then, we allocate a buffer large enough to hold the prefix and keys, and
  // write them to the buffer.
  const EC_GROUP* recvGrp = EC_KEY_get0_group(recvPrivKey);
  const EC_POINT* recvPubKeyPt = EC_KEY_get0_public_key(recvPrivKey);
  const EC_GROUP* senderGrp = EC_KEY_get0_group(senderPubKey);
  const EC_POINT* senderPubKeyPt = EC_KEY_get0_public_key(senderPubKey);

  // First, we determine the lengths of the two keys.
  size_t recvPubKeyLen = EC_POINT_point2oct(
    recvGrp, recvPubKeyPt, POINT_CONVERSION_UNCOMPRESSED, NULL, 0, NULL);
  if (!recvPubKeyLen) {
    err = ECE_ERROR_ENCODE_RECEIVER_PUBLIC_KEY;
    goto error;
  }
  size_t senderPubKeyLen = EC_POINT_point2oct(
    senderGrp, senderPubKeyPt, POINT_CONVERSION_UNCOMPRESSED, NULL, 0, NULL);
  if (!senderPubKeyLen) {
    err = ECE_ERROR_ENCODE_SENDER_PUBLIC_KEY;
    goto error;
  }

  // Next, we allocate a buffer large enough to hold the prefix and keys.
  size_t infoLen = prefixLen + recvPubKeyLen + senderPubKeyLen;
  if (!ece_buf_alloc(info, infoLen)) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto error;
  }

  // Copy the prefix.
  memcpy(info->bytes, prefix, prefixLen);

  // Copy the receiver public key.
  if (EC_POINT_point2oct(recvGrp, recvPubKeyPt, POINT_CONVERSION_UNCOMPRESSED,
                         &info->bytes[prefixLen], recvPubKeyLen,
                         NULL) != recvPubKeyLen) {
    err = ECE_ERROR_ENCODE_RECEIVER_PUBLIC_KEY;
    goto error;
  }

  // Copy the sender public key.
  if (EC_POINT_point2oct(senderGrp, senderPubKeyPt,
                         POINT_CONVERSION_UNCOMPRESSED,
                         &info->bytes[prefixLen + recvPubKeyLen],
                         senderPubKeyLen, NULL) != senderPubKeyLen) {
    err = ECE_ERROR_ENCODE_SENDER_PUBLIC_KEY;
    goto error;
  }
  goto end;

error:
  ece_buf_free(info);

end:
  return err;
}

int
ece_aes128gcm_derive_key_and_nonce(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                                   const ece_buf_t* authSecret,
                                   const ece_buf_t* salt, ece_buf_t* key,
                                   ece_buf_t* nonce) {
  int err = ECE_OK;

  ece_buf_t sharedSecret;
  ece_buf_reset(&sharedSecret);
  ece_buf_t prkInfo;
  ece_buf_reset(&prkInfo);
  ece_buf_t prk;
  ece_buf_reset(&prk);

  err = ece_compute_secret(recvPrivKey, senderPubKey, &sharedSecret);
  if (err) {
    goto end;
  }

  // The new "aes128gcm" scheme includes the sender and receiver public keys in
  // the info string when deriving the Web Push PRK.
  err = ece_aes128gcm_generate_info(
    recvPrivKey, senderPubKey, ECE_AES128GCM_WEB_PUSH_PRK_INFO_PREFIX,
    ECE_AES128GCM_WEB_PUSH_PRK_INFO_PREFIX_LENGTH, &prkInfo);
  if (err) {
    goto end;
  }
  err = ece_hkdf_sha256(authSecret, &sharedSecret, &prkInfo, ECE_SHA_256_LENGTH,
                        &prk);
  if (err) {
    goto end;
  }

  // Next, derive the AES decryption key and nonce. We use static info strings.
  // These buffers are stack-allocated, so they shouldn't be freed.
  uint8_t keyInfoBytes[ECE_AES128GCM_KEY_INFO_LENGTH];
  memcpy(keyInfoBytes, ECE_AES128GCM_KEY_INFO, ECE_AES128GCM_KEY_INFO_LENGTH);
  ece_buf_t keyInfo;
  keyInfo.bytes = keyInfoBytes;
  keyInfo.length = ECE_AES128GCM_KEY_INFO_LENGTH;
  err = ece_hkdf_sha256(salt, &prk, &keyInfo, ECE_KEY_LENGTH, key);
  if (err) {
    goto end;
  }
  uint8_t nonceInfoBytes[ECE_AES128GCM_NONCE_INFO_LENGTH];
  memcpy(nonceInfoBytes, ECE_AES128GCM_NONCE_INFO,
         ECE_AES128GCM_NONCE_INFO_LENGTH);
  ece_buf_t nonceInfo;
  nonceInfo.bytes = nonceInfoBytes;
  nonceInfo.length = ECE_AES128GCM_NONCE_INFO_LENGTH;
  err = ece_hkdf_sha256(salt, &prk, &nonceInfo, ECE_NONCE_LENGTH, nonce);

end:
  ece_buf_free(&sharedSecret);
  ece_buf_free(&prkInfo);
  ece_buf_free(&prk);
  return err;
}

// The "aesgcm" info string is "Content-Encoding: <aesgcm | nonce>\0P-256\0",
// followed by the length-prefixed (unsigned 16-bit integers) receiver and
// sender public keys.
static int
ece_aesgcm_generate_info(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                         const char* prefix, size_t prefixLen,
                         ece_buf_t* info) {
  int err = ECE_OK;

  const EC_GROUP* recvGrp = EC_KEY_get0_group(recvPrivKey);
  const EC_POINT* recvPubKeyPt = EC_KEY_get0_public_key(recvPrivKey);
  const EC_GROUP* senderGrp = EC_KEY_get0_group(senderPubKey);
  const EC_POINT* senderPubKeyPt = EC_KEY_get0_public_key(senderPubKey);

  // First, we determine the lengths of the two keys.
  size_t recvPubKeyLen = EC_POINT_point2oct(
    recvGrp, recvPubKeyPt, POINT_CONVERSION_UNCOMPRESSED, NULL, 0, NULL);
  if (!recvPubKeyLen || recvPubKeyLen > UINT16_MAX) {
    err = ECE_ERROR_ENCODE_RECEIVER_PUBLIC_KEY;
    goto error;
  }
  size_t senderPubKeyLen = EC_POINT_point2oct(
    senderGrp, senderPubKeyPt, POINT_CONVERSION_UNCOMPRESSED, NULL, 0, NULL);
  if (!senderPubKeyLen || senderPubKeyLen > UINT16_MAX) {
    err = ECE_ERROR_ENCODE_SENDER_PUBLIC_KEY;
    goto error;
  }

  // Next, we allocate a buffer large enough to hold the prefix, lengths,
  // and keys.
  size_t infoLen = prefixLen + recvPubKeyLen + senderPubKeyLen +
                   ECE_AESGCM_KEY_LENGTH_SIZE * 2;
  if (!ece_buf_alloc(info, infoLen)) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto error;
  }

  // Copy the prefix to the buffer.
  memcpy(info->bytes, prefix, prefixLen);

  // Copy the length-prefixed receiver public key.
  ece_write_uint16_be(&info->bytes[prefixLen], (uint16_t) recvPubKeyLen);
  if (EC_POINT_point2oct(recvGrp, recvPubKeyPt, POINT_CONVERSION_UNCOMPRESSED,
                         &info->bytes[prefixLen + ECE_AESGCM_KEY_LENGTH_SIZE],
                         recvPubKeyLen, NULL) != recvPubKeyLen) {
    err = ECE_ERROR_ENCODE_RECEIVER_PUBLIC_KEY;
    goto error;
  }

  // Copy the length-prefixed sender public key.
  ece_write_uint16_be(
    &info->bytes[prefixLen + recvPubKeyLen + ECE_AESGCM_KEY_LENGTH_SIZE],
    (uint16_t) senderPubKeyLen);
  if (EC_POINT_point2oct(
        senderGrp, senderPubKeyPt, POINT_CONVERSION_UNCOMPRESSED,
        &info
           ->bytes[prefixLen + recvPubKeyLen + ECE_AESGCM_KEY_LENGTH_SIZE * 2],
        senderPubKeyLen, NULL) != senderPubKeyLen) {
    err = ECE_ERROR_ENCODE_SENDER_PUBLIC_KEY;
    goto error;
  }
  goto end;

error:
  ece_buf_free(info);

end:
  return err;
}

// Derives the "aesgcm" decryption key and nonce given the receiver private key,
// sender public key, authentication secret, and sender salt.
int
ece_aesgcm_derive_key_and_nonce(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                                const ece_buf_t* authSecret,
                                const ece_buf_t* salt, ece_buf_t* key,
                                ece_buf_t* nonce) {
  int err = ECE_OK;

  ece_buf_t sharedSecret;
  ece_buf_reset(&sharedSecret);
  ece_buf_t prk;
  ece_buf_reset(&prk);
  ece_buf_t keyInfo;
  ece_buf_reset(&keyInfo);
  ece_buf_t nonceInfo;
  ece_buf_reset(&nonceInfo);

  err = ece_compute_secret(recvPrivKey, senderPubKey, &sharedSecret);
  if (err) {
    goto end;
  }

  // The old "aesgcm" scheme uses a static info string to derive the Web Push
  // PRK. This buffer is stack-allocated, so it shouldn't be freed.
  uint8_t prkInfoBytes[ECE_AESGCM_WEB_PUSH_PRK_INFO_LENGTH];
  memcpy(prkInfoBytes, ECE_AESGCM_WEB_PUSH_PRK_INFO,
         ECE_AESGCM_WEB_PUSH_PRK_INFO_LENGTH);
  ece_buf_t prkInfo;
  prkInfo.bytes = prkInfoBytes;
  prkInfo.length = ECE_AESGCM_WEB_PUSH_PRK_INFO_LENGTH;
  err = ece_hkdf_sha256(authSecret, &sharedSecret, &prkInfo, ECE_SHA_256_LENGTH,
                        &prk);
  if (err) {
    goto end;
  }

  // Next, derive the AES decryption key and nonce. We include the sender and
  // receiver public keys in the info strings.
  err = ece_aesgcm_generate_info(
    recvPrivKey, senderPubKey, ECE_AESGCM_WEB_PUSH_KEY_INFO_PREFIX,
    ECE_AESGCM_WEB_PUSH_KEY_INFO_PREFIX_LENGTH, &keyInfo);
  if (err) {
    goto end;
  }
  err = ece_hkdf_sha256(salt, &prk, &keyInfo, ECE_KEY_LENGTH, key);
  if (err) {
    goto end;
  }
  err = ece_aesgcm_generate_info(
    recvPrivKey, senderPubKey, ECE_AESGCM_WEB_PUSH_NONCE_INFO_PREFIX,
    ECE_AESGCM_WEB_PUSH_NONCE_INFO_PREFIX_LENGTH, &nonceInfo);
  if (err) {
    goto end;
  }
  err = ece_hkdf_sha256(salt, &prk, &nonceInfo, ECE_NONCE_LENGTH, nonce);

end:
  ece_buf_free(&sharedSecret);
  ece_buf_free(&prk);
  ece_buf_free(&keyInfo);
  ece_buf_free(&nonceInfo);
  return err;
}
