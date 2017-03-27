#include "ece/keys.h"

#include <string.h>

#include <openssl/evp.h>
#include <openssl/rand.h>

typedef size_t (*max_decrypted_length_t)(uint32_t rs, size_t ciphertextLen);

typedef int (*unpad_t)(uint8_t* block, bool isLastRecord, size_t* blockLen);

// Returns the maximum decrypted length of an "aes128gcm" ciphertext.
static inline size_t
ece_aes128gcm_max_decrypted_length(uint32_t rs, size_t ciphertextLen) {
  size_t numRecords = (ciphertextLen / rs) + 1;
  return ciphertextLen - (ECE_TAG_LENGTH * numRecords);
}

// Returns the maximum decrypted length of an "aesgcm" ciphertext.
static size_t
ece_aesgcm_max_decrypted_length(uint32_t rs, size_t ciphertextLen) {
  ECE_UNUSED(rs);
  return ciphertextLen;
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
  int err = ECE_OK;

  if (EVP_DecryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, key, iv) <= 0) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  // The authentication tag is included at the end of the encrypted record.
  uint8_t tag[ECE_TAG_LENGTH];
  memcpy(tag, &record[recordLen - ECE_TAG_LENGTH], ECE_TAG_LENGTH);
  if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, ECE_TAG_LENGTH, tag) <=
      0) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  int updateLen = 0;
  if (EVP_DecryptUpdate(ctx, block, &updateLen, record,
                        (int) recordLen - ECE_TAG_LENGTH) <= 0) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  int finalLen = -1;
  if (EVP_DecryptFinal_ex(ctx, NULL, &finalLen) <= 0) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }

end:
  EVP_CIPHER_CTX_reset(ctx);
  return err;
}

static int
ece_decrypt_records(const uint8_t* key, const uint8_t* nonce, uint32_t rs,
                    const uint8_t* ciphertext, size_t ciphertextLen,
                    max_decrypted_length_t maxDecryptedLen, unpad_t unpad,
                    uint8_t* plaintext, size_t* plaintextLen) {
  int err = ECE_OK;

  EVP_CIPHER_CTX* ctx = NULL;

  size_t maxBlockEnd = maxDecryptedLen(rs, ciphertextLen);
  if (*plaintextLen < maxBlockEnd) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  size_t recordStart = 0;
  size_t blockStart = 0;
  for (size_t counter = 0; recordStart < ciphertextLen; counter++) {
    size_t recordEnd = recordStart + rs;
    if (recordEnd > ciphertextLen) {
      recordEnd = ciphertextLen;
    }
    size_t recordLen = recordEnd - recordStart;
    if (recordLen <= ECE_TAG_LENGTH) {
      err = ECE_ERROR_SHORT_BLOCK;
      goto end;
    }

    size_t blockEnd = blockStart + recordLen - ECE_TAG_LENGTH;
    if (blockEnd > maxBlockEnd) {
      blockEnd = maxBlockEnd;
    }

    // Generate the IV for this record using the nonce.
    uint8_t iv[ECE_NONCE_LENGTH];
    ece_generate_iv(nonce, counter, iv);

    err = ece_decrypt_record(ctx, key, iv, &ciphertext[recordStart], recordLen,
                             &plaintext[blockStart]);
    if (err) {
      goto end;
    }
    size_t blockLen = blockEnd - blockStart;
    err = unpad(&plaintext[blockStart], recordEnd >= ciphertextLen, &blockLen);
    if (err) {
      goto end;
    }
    recordStart = recordEnd;
    blockStart += blockLen;
  }
  *plaintextLen = blockStart;

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
                    uint32_t rs, const uint8_t* ciphertext,
                    size_t ciphertextLen,
                    derive_key_and_nonce_t deriveKeyAndNonce,
                    max_decrypted_length_t maxDecryptedLen, unpad_t unpad,
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

  err = ece_decrypt_records(key, nonce, rs, ciphertext, ciphertextLen,
                            maxDecryptedLen, unpad, plaintext, plaintextLen);

end:
  EC_KEY_free(recvPrivKey);
  EC_KEY_free(senderPubKey);
  return err;
}

// Removes padding from a decrypted "aesgcm" block.
static int
ece_aesgcm_unpad(uint8_t* block, bool isLastRecord, size_t* blockLen) {
  ECE_UNUSED(isLastRecord);
  if (*blockLen < 2) {
    return ECE_ERROR_DECRYPT_PADDING;
  }
  uint16_t padLen = ece_read_uint16_be(block);
  if (padLen >= *blockLen) {
    return ECE_ERROR_DECRYPT_PADDING;
  }
  // In "aesgcm", the content is offset by the pad size and padding.
  size_t offset = padLen + 2;
  const uint8_t* pad = &block[2];
  while (pad < &block[offset]) {
    if (*pad) {
      // All padding bytes must be zero.
      return ECE_ERROR_DECRYPT_PADDING;
    }
    pad++;
  }
  // Move the unpadded contents to the start of the block.
  *blockLen -= offset;
  memmove(block, pad, *blockLen);
  return ECE_OK;
}

// Removes padding from a decrypted "aes128gcm" block.
static int
ece_aes128gcm_unpad(uint8_t* block, bool isLastRecord, size_t* blockLen) {
  // Remove trailing padding.
  while (*blockLen > 0) {
    (*blockLen)--;
    if (!block[*blockLen]) {
      continue;
    }
    uint8_t padDelim = isLastRecord ? 2 : 1;
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
  if (EC_KEY_generate_key(subKey) <= 0) {
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

  if (RAND_bytes(authSecret, (int) authSecretLen) <= 0) {
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
  return ece_aes128gcm_max_decrypted_length(rs, ciphertextLen);
}

size_t
ece_aesgcm_plaintext_max_length(size_t ciphertextLen) {
  return ciphertextLen;
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
  return ece_decrypt_records(key, nonce, rs, ciphertext, ciphertextLen,
                             &ece_aes128gcm_max_decrypted_length,
                             &ece_aes128gcm_unpad, plaintext, plaintextLen);
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
  return ece_webpush_decrypt(rawRecvPrivKey, rawRecvPrivKeyLen, authSecret,
                             authSecretLen, salt, saltLen, rawSenderPubKey,
                             rawSenderPubKeyLen, rs, ciphertext, ciphertextLen,
                             &ece_webpush_aes128gcm_derive_key_and_nonce,
                             &ece_aes128gcm_max_decrypted_length,
                             &ece_aes128gcm_unpad, plaintext, plaintextLen);
}

int
ece_webpush_aesgcm_decrypt(const uint8_t* rawRecvPrivKey,
                           size_t rawRecvPrivKeyLen, const uint8_t* authSecret,
                           size_t authSecretLen, const char* cryptoKeyHeader,
                           const char* encryptionHeader,
                           const uint8_t* ciphertext, size_t ciphertextLen,
                           uint8_t* plaintext, size_t* plaintextLen) {
  uint8_t salt[ECE_SALT_LENGTH];
  uint8_t rawSenderPubKey[ECE_WEBPUSH_PUBLIC_KEY_LENGTH];
  uint32_t rs;
  int err = ece_webpush_aesgcm_headers_extract_params(
    cryptoKeyHeader, encryptionHeader, salt, ECE_SALT_LENGTH, rawSenderPubKey,
    ECE_WEBPUSH_PUBLIC_KEY_LENGTH, &rs);
  if (err) {
    return err;
  }
  rs += ECE_TAG_LENGTH;
  return ece_webpush_decrypt(
    rawRecvPrivKey, rawRecvPrivKeyLen, authSecret, authSecretLen, salt,
    ECE_SALT_LENGTH, rawSenderPubKey, ECE_WEBPUSH_PUBLIC_KEY_LENGTH, rs,
    ciphertext, ciphertextLen, &ece_webpush_aesgcm_derive_key_and_nonce,
    &ece_aesgcm_max_decrypted_length, &ece_aesgcm_unpad, plaintext,
    plaintextLen);
}
