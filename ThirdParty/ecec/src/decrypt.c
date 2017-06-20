#include "ece.h"
#include "ece/keys.h"
#include "ece/trailer.h"

#include <assert.h>
#include <string.h>

#include <openssl/evp.h>
#include <openssl/rand.h>

typedef int (*unpad_t)(uint8_t* block, bool lastRecord, size_t* blockLen);

// Calculates the maximum plaintext length, including room for the padding
// delimiter and padding.
static inline size_t
ece_plaintext_max_length(uint32_t rs, size_t padSize, size_t ciphertextLen) {
  assert(padSize <= 2);
  size_t overhead = padSize + ECE_TAG_LENGTH;
  if (rs <= overhead) {
    return 0;
  }
  size_t numRecords = ciphertextLen / rs;
  if (ciphertextLen % rs) {
    // If the ciphertext length doesn't fall on a record boundary, we have
    // a smaller final record.
    numRecords++;
  }
  if (numRecords > ciphertextLen / ECE_TAG_LENGTH) {
    // Each record includes a trailing auth tag. If the number of records
    // exceeds the number of tags, the ciphertext is truncated.
    return 0;
  }
  return ciphertextLen - (ECE_TAG_LENGTH * numRecords);
}

// Extracts an unsigned 16-bit integer in network byte order.
static inline uint16_t
ece_read_uint16_be(const uint8_t* bytes) {
  uint16_t value = (uint16_t) bytes[1];
  value |= bytes[0] << 8;
  return value;
}

// Converts an encrypted record to a decrypted block.
static int
ece_decrypt_record(EVP_CIPHER_CTX* ctx, const uint8_t* key, const uint8_t* iv,
                   const uint8_t* record, size_t recordLen, uint8_t* block) {
  int chunkLen = -1;

  if (EVP_DecryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, key, iv) != 1) {
    return ECE_ERROR_DECRYPT;
  }

  assert(recordLen > ECE_TAG_LENGTH);
  size_t blockLen = recordLen - ECE_TAG_LENGTH;

  // The authentication tag is included at the end of the encrypted record.
  uint8_t tag[ECE_TAG_LENGTH];
  memcpy(tag, &record[blockLen], ECE_TAG_LENGTH);
  if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, ECE_TAG_LENGTH, tag) !=
      1) {
    return ECE_ERROR_DECRYPT;
  }

  if (blockLen > INT_MAX ||
      EVP_DecryptUpdate(ctx, block, &chunkLen, record, (int) blockLen) != 1) {
    return ECE_ERROR_DECRYPT;
  }

  // Since we're using a stream cipher, finalization shouldn't write out any
  // bytes.
  assert(EVP_CIPHER_CTX_block_size(ctx) == 1);
  if (EVP_DecryptFinal_ex(ctx, NULL, &chunkLen) != 1) {
    return ECE_ERROR_DECRYPT;
  }

  if (EVP_CIPHER_CTX_reset(ctx) != 1) {
    return ECE_ERROR_DECRYPT;
  }

  return ECE_OK;
}

static int
ece_decrypt_records(const uint8_t* key, const uint8_t* nonce, uint32_t rs,
                    size_t padSize, const uint8_t* ciphertext,
                    size_t ciphertextLen, unpad_t unpad, uint8_t* plaintext,
                    size_t* plaintextLen) {
  int err = ECE_OK;

  EVP_CIPHER_CTX* ctx = NULL;

  // Make sure the plaintext array is large enough to hold the full plaintext.
  size_t maxPlaintextLen = ece_plaintext_max_length(rs, padSize, ciphertextLen);
  if (!maxPlaintextLen) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  if (*plaintextLen < maxPlaintextLen) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  // The offset at which to start reading the ciphertext.
  size_t ciphertextStart = 0;

  // The offset at which to start writing the plaintext.
  size_t plaintextStart = 0;

  for (size_t counter = 0; ciphertextStart < ciphertextLen; counter++) {
    size_t ciphertextEnd;
    if (rs > ciphertextLen - ciphertextStart) {
      // This check is equivalent to `ciphertextStart + rs > ciphertextLen`;
      // it's written this way to avoid an integer overflow.
      ciphertextEnd = ciphertextLen;
    } else {
      ciphertextEnd = ciphertextStart + rs;
    }

    assert(ciphertextEnd > ciphertextStart);

    // The full length of the encrypted record.
    size_t recordLen = ciphertextEnd - ciphertextStart;
    if (recordLen <= ECE_TAG_LENGTH) {
      err = ECE_ERROR_SHORT_BLOCK;
      goto end;
    }

    // Generate the IV for this record using the nonce.
    uint8_t iv[ECE_NONCE_LENGTH];
    ece_generate_iv(nonce, counter, iv);

    // Decrypt the record.
    err = ece_decrypt_record(ctx, key, iv, &ciphertext[ciphertextStart],
                             recordLen, &plaintext[plaintextStart]);
    if (err) {
      goto end;
    }

    // `unpad` sets `blockLen` to the actual plaintext block length, without
    // the padding delimiter and padding.
    bool lastRecord = ciphertextEnd >= ciphertextLen;
    size_t blockLen = recordLen - ECE_TAG_LENGTH;
    if (blockLen < padSize) {
      err = ECE_ERROR_DECRYPT_PADDING;
      goto end;
    }
    err = unpad(&plaintext[plaintextStart], lastRecord, &blockLen);
    if (err) {
      goto end;
    }

    ciphertextStart = ciphertextEnd;
    plaintextStart += blockLen;
  }

  // Finally, set the actual plaintext length.
  *plaintextLen = plaintextStart;

end:
  EVP_CIPHER_CTX_free(ctx);
  return err;
}

// A generic decryption function shared by "aesgcm" and "aes128gcm".
// `deriveKeyAndNonce` and `unpad` are function pointers that change based on
// the scheme.
static int
ece_webpush_decrypt(const uint8_t* rawRecvPrivKey, size_t rawRecvPrivKeyLen,
                    const uint8_t* authSecret, size_t authSecretLen,
                    const uint8_t* salt, size_t saltLen,
                    const uint8_t* rawSenderPubKey, size_t rawSenderPubKeyLen,
                    uint32_t rs, size_t padSize, const uint8_t* ciphertext,
                    size_t ciphertextLen, needs_trailer_t needsTrailer,
                    derive_key_and_nonce_t deriveKeyAndNonce, unpad_t unpad,
                    uint8_t* plaintext, size_t* plaintextLen) {
  int err = ECE_OK;

  EC_KEY* recvPrivKey = NULL;
  EC_KEY* senderPubKey = NULL;

  if (authSecretLen != ECE_WEBPUSH_AUTH_SECRET_LENGTH) {
    err = ECE_ERROR_INVALID_AUTH_SECRET;
    goto end;
  }
  if (saltLen != ECE_SALT_LENGTH) {
    err = ECE_ERROR_INVALID_SALT;
    goto end;
  }
  if (!ciphertextLen) {
    err = ECE_ERROR_ZERO_CIPHERTEXT;
    goto end;
  }
  if (needsTrailer(rs, ciphertextLen)) {
    // If we're missing a trailing block, the ciphertext is truncated. This only
    // applies to "aesgcm".
    err = ECE_ERROR_DECRYPT_TRUNCATED;
    goto end;
  }

  recvPrivKey = ece_import_private_key(rawRecvPrivKey, rawRecvPrivKeyLen);
  if (!recvPrivKey) {
    err = ECE_ERROR_INVALID_PRIVATE_KEY;
    goto end;
  }
  senderPubKey = ece_import_public_key(rawSenderPubKey, rawSenderPubKeyLen);
  if (!senderPubKey) {
    err = ECE_ERROR_INVALID_PUBLIC_KEY;
    goto end;
  }

  uint8_t key[ECE_AES_KEY_LENGTH];
  uint8_t nonce[ECE_NONCE_LENGTH];
  err = deriveKeyAndNonce(ECE_MODE_DECRYPT, recvPrivKey, senderPubKey,
                          authSecret, authSecretLen, salt, saltLen, key, nonce);
  if (err) {
    goto end;
  }

  err = ece_decrypt_records(key, nonce, rs, padSize, ciphertext, ciphertextLen,
                            unpad, plaintext, plaintextLen);

end:
  EC_KEY_free(recvPrivKey);
  EC_KEY_free(senderPubKey);
  return err;
}

// Removes padding from a decrypted "aesgcm" block.
static int
ece_aesgcm_unpad(uint8_t* block, bool lastRecord, size_t* blockLen) {
  ECE_UNUSED(lastRecord);

  assert(*blockLen >= ECE_AESGCM_PAD_SIZE);

  uint16_t padLen = ece_read_uint16_be(block);
  if (padLen > *blockLen - ECE_AESGCM_PAD_SIZE) {
    return ECE_ERROR_DECRYPT_PADDING;
  }
  size_t plaintextStart = ECE_AESGCM_PAD_SIZE + padLen;

  for (size_t i = ECE_AESGCM_PAD_SIZE; i < plaintextStart; i++) {
    if (block[i]) {
      // All padding bytes must be zero.
      return ECE_ERROR_DECRYPT_PADDING;
    }
  }

  // Move the unpadded plaintext to the start of the block.
  *blockLen -= plaintextStart;
  memmove(block, &block[plaintextStart], *blockLen);
  return ECE_OK;
}

// Removes padding from a decrypted "aes128gcm" block.
static int
ece_aes128gcm_unpad(uint8_t* block, bool lastRecord, size_t* blockLen) {
  // Remove trailing padding.
  while (*blockLen > 0) {
    (*blockLen)--;
    if (!block[*blockLen]) {
      continue;
    }
    uint8_t padDelim = lastRecord ? 2 : 1;
    if (block[*blockLen] != padDelim) {
      // Last record needs to start padding with a 2; preceding records need
      // to start padding with a 1.
      return ECE_ERROR_DECRYPT_PADDING;
    }
    return ECE_OK;
  }

  // All zero plaintext.
  return ECE_ERROR_ZERO_PLAINTEXT;
}

int
ece_webpush_generate_keys(uint8_t* rawRecvPrivKey, size_t rawRecvPrivKeyLen,
                          uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
                          uint8_t* authSecret, size_t authSecretLen) {
  int err = ECE_OK;
  EC_KEY* subKey = NULL;

  // Generate a public-private ECDH key pair for the push subscription.
  subKey = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
  if (!subKey) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }
  if (EC_KEY_generate_key(subKey) != 1) {
    err = ECE_ERROR_GENERATE_KEYS;
    goto end;
  }

  if (!EC_KEY_priv2oct(subKey, rawRecvPrivKey, rawRecvPrivKeyLen)) {
    err = ECE_ERROR_INVALID_PRIVATE_KEY;
    goto end;
  }
  const EC_GROUP* subGrp = EC_KEY_get0_group(subKey);
  const EC_POINT* rawSubPubKeyPt = EC_KEY_get0_public_key(subKey);
  if (!EC_POINT_point2oct(subGrp, rawSubPubKeyPt, POINT_CONVERSION_UNCOMPRESSED,
                          rawRecvPubKey, rawRecvPubKeyLen, NULL)) {
    err = ECE_ERROR_INVALID_PUBLIC_KEY;
    goto end;
  }

  if (authSecretLen > INT_MAX ||
      RAND_bytes(authSecret, (int) authSecretLen) != 1) {
    err = ECE_ERROR_INVALID_AUTH_SECRET;
    goto end;
  }

end:
  EC_KEY_free(subKey);
  return err;
}

size_t
ece_aes128gcm_plaintext_max_length(const uint8_t* payload, size_t payloadLen) {
  const uint8_t* salt;
  size_t saltLen;
  const uint8_t* keyId;
  size_t keyIdLen;
  uint32_t rs;
  const uint8_t* ciphertext;
  size_t ciphertextLen;
  int err = ece_aes128gcm_payload_extract_params(
    payload, payloadLen, &salt, &saltLen, &keyId, &keyIdLen, &rs, &ciphertext,
    &ciphertextLen);
  if (err) {
    return 0;
  }
  return ece_plaintext_max_length(rs, ECE_AES128GCM_PAD_SIZE, ciphertextLen);
}

size_t
ece_aesgcm_plaintext_max_length(uint32_t rs, size_t ciphertextLen) {
  rs = ece_aesgcm_rs(rs);
  if (!rs) {
    return 0;
  }
  return ece_plaintext_max_length(rs, ECE_AESGCM_PAD_SIZE, ciphertextLen);
}

int
ece_aes128gcm_decrypt(const uint8_t* ikm, size_t ikmLen, const uint8_t* payload,
                      size_t payloadLen, uint8_t* plaintext,
                      size_t* plaintextLen) {
  const uint8_t* salt;
  size_t saltLen;
  const uint8_t* keyId;
  size_t keyIdLen;
  uint32_t rs;
  const uint8_t* ciphertext;
  size_t ciphertextLen;
  int err = ece_aes128gcm_payload_extract_params(
    payload, payloadLen, &salt, &saltLen, &keyId, &keyIdLen, &rs, &ciphertext,
    &ciphertextLen);
  if (err) {
    return err;
  }
  uint8_t key[ECE_AES_KEY_LENGTH];
  uint8_t nonce[ECE_NONCE_LENGTH];
  err =
    ece_aes128gcm_derive_key_and_nonce(salt, saltLen, ikm, ikmLen, key, nonce);
  if (err) {
    return err;
  }
  return ece_decrypt_records(key, nonce, rs, ECE_AES128GCM_PAD_SIZE, ciphertext,
                             ciphertextLen, &ece_aes128gcm_unpad, plaintext,
                             plaintextLen);
}

int
ece_webpush_aes128gcm_decrypt(const uint8_t* rawRecvPrivKey,
                              size_t rawRecvPrivKeyLen,
                              const uint8_t* authSecret, size_t authSecretLen,
                              const uint8_t* payload, size_t payloadLen,
                              uint8_t* plaintext, size_t* plaintextLen) {
  const uint8_t* salt;
  size_t saltLen;
  const uint8_t* rawSenderPubKey;
  size_t rawSenderPubKeyLen;
  uint32_t rs;
  const uint8_t* ciphertext;
  size_t ciphertextLen;
  int err = ece_aes128gcm_payload_extract_params(
    payload, payloadLen, &salt, &saltLen, &rawSenderPubKey, &rawSenderPubKeyLen,
    &rs, &ciphertext, &ciphertextLen);
  if (err) {
    return err;
  }
  return ece_webpush_decrypt(
    rawRecvPrivKey, rawRecvPrivKeyLen, authSecret, authSecretLen, salt, saltLen,
    rawSenderPubKey, rawSenderPubKeyLen, rs, ECE_AES128GCM_PAD_SIZE, ciphertext,
    ciphertextLen, &ece_aes128gcm_needs_trailer,
    &ece_webpush_aes128gcm_derive_key_and_nonce, &ece_aes128gcm_unpad,
    plaintext, plaintextLen);
}

int
ece_webpush_aesgcm_decrypt(const uint8_t* rawRecvPrivKey,
                           size_t rawRecvPrivKeyLen, const uint8_t* authSecret,
                           size_t authSecretLen, const uint8_t* salt,
                           size_t saltLen, const uint8_t* rawSenderPubKey,
                           size_t rawSenderPubKeyLen, uint32_t rs,
                           const uint8_t* ciphertext, size_t ciphertextLen,
                           uint8_t* plaintext, size_t* plaintextLen) {
  rs = ece_aesgcm_rs(rs);
  if (!rs) {
    return 0;
  }
  return ece_webpush_decrypt(
    rawRecvPrivKey, rawRecvPrivKeyLen, authSecret, authSecretLen, salt, saltLen,
    rawSenderPubKey, rawSenderPubKeyLen, rs, ECE_AESGCM_PAD_SIZE, ciphertext,
    ciphertextLen, &ece_aesgcm_needs_trailer,
    &ece_webpush_aesgcm_derive_key_and_nonce, &ece_aesgcm_unpad, plaintext,
    plaintextLen);
}
