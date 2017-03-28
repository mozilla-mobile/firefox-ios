#include "ece/keys.h"

#include <stdlib.h>
#include <string.h>

#include <openssl/ec.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

// Writes an unsigned 32-bit integer in network byte order.
static inline void
ece_write_uint32_be(uint8_t* bytes, uint32_t value) {
  bytes[0] = (value >> 24) & 0xff;
  bytes[1] = (value >> 16) & 0xff;
  bytes[2] = (value >> 8) & 0xff;
  bytes[3] = value & 0xff;
}

// Encrypts a plaintext block with optional padding.
static int
ece_aes128gcm_encrypt_block(EVP_CIPHER_CTX* ctx, const uint8_t* key,
                            const uint8_t* iv, const uint8_t* block,
                            size_t blockLen, const uint8_t* pad, size_t padLen,
                            uint8_t* record) {
  int err = ECE_OK;

  // Encrypt the plaintext and padding.
  if (EVP_EncryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, key, iv) <= 0) {
    err = ECE_ERROR_ENCRYPT;
    goto end;
  }
  int chunkLen = -1;
  if (EVP_EncryptUpdate(ctx, record, &chunkLen, block, (int) blockLen) <= 0) {
    err = ECE_ERROR_ENCRYPT;
    goto end;
  }
  if (EVP_EncryptUpdate(ctx, &record[blockLen], &chunkLen, pad, (int) padLen) <=
      0) {
    err = ECE_ERROR_ENCRYPT;
    goto end;
  }
  if (EVP_EncryptFinal_ex(ctx, NULL, &chunkLen) <= 0) {
    err = ECE_ERROR_ENCRYPT;
    goto end;
  }

  // Append the authentication tag.
  if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, ECE_TAG_LENGTH,
                          &record[blockLen + padLen]) <= 0) {
    err = ECE_ERROR_ENCRYPT;
    goto end;
  }

end:
  EVP_CIPHER_CTX_reset(ctx);
  return err;
}

// Encrypts a complete message with the given parameters.
static int
ece_aes128gcm_encrypt_blocks(EC_KEY* senderPrivKey, EC_KEY* recvPubKey,
                             const uint8_t* authSecret, size_t authSecretLen,
                             const uint8_t* salt, size_t saltLen, uint32_t rs,
                             size_t padLen, const uint8_t* plaintext,
                             size_t plaintextLen, uint8_t* payload,
                             size_t* payloadLen) {
  int err = ECE_OK;

  EVP_CIPHER_CTX* ctx = NULL;
  uint8_t* pad = NULL;

  if (authSecretLen != ECE_WEBPUSH_AUTH_SECRET_LENGTH) {
    err = ECE_ERROR_INVALID_AUTH_SECRET;
    goto end;
  }
  if (saltLen != ECE_SALT_LENGTH) {
    err = ECE_ERROR_INVALID_SALT;
    goto end;
  }
  if (!plaintextLen) {
    err = ECE_ERROR_ZERO_PLAINTEXT;
    goto end;
  }

  // Make sure the payload buffer is large enough to hold the header and
  // ciphertext.
  size_t maxRecordEnd =
    ece_aes128gcm_payload_max_length(rs, padLen, plaintextLen);
  if (!maxRecordEnd) {
    err = ECE_ERROR_INVALID_RS;
    goto end;
  }
  if (*payloadLen < maxRecordEnd) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  // Allocate enough memory to hold the padding and one-byte padding delimiter.
  pad = calloc(padLen + 1, sizeof(uint8_t));
  if (!pad) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  uint8_t key[ECE_AES_KEY_LENGTH];
  uint8_t nonce[ECE_NONCE_LENGTH];
  err = ece_webpush_aes128gcm_derive_key_and_nonce(
    ECE_MODE_ENCRYPT, senderPrivKey, recvPubKey, authSecret,
    ECE_WEBPUSH_AUTH_SECRET_LENGTH, salt, ECE_SALT_LENGTH, key, nonce);
  if (err) {
    goto end;
  }

  // Write the header.
  memcpy(payload, salt, ECE_SALT_LENGTH);
  ece_write_uint32_be(&payload[ECE_SALT_LENGTH], rs);
  payload[ECE_SALT_LENGTH + 4] = ECE_WEBPUSH_PUBLIC_KEY_LENGTH;
  if (!EC_POINT_point2oct(
        EC_KEY_get0_group(senderPrivKey), EC_KEY_get0_public_key(senderPrivKey),
        POINT_CONVERSION_UNCOMPRESSED, &payload[ECE_AES128GCM_HEADER_LENGTH],
        ECE_WEBPUSH_PUBLIC_KEY_LENGTH, NULL)) {
    err = ECE_ERROR_ENCODE_PUBLIC_KEY;
    goto end;
  }

  bool isLastRecord = false;
  size_t overhead = ECE_AES128GCM_MIN_RS - 1;
  size_t plaintextPerBlock = rs - overhead;
  size_t blockStart = 0;
  size_t recordStart =
    ECE_AES128GCM_HEADER_LENGTH + ECE_WEBPUSH_PUBLIC_KEY_LENGTH;
  size_t counter = 0;
  while (!isLastRecord) {
    // Pad so that at least one plaintext byte is in a block.
    size_t blockPadLen = plaintextPerBlock - 1;
    if (blockPadLen > padLen) {
      blockPadLen = padLen;
    }
    if (padLen && !blockPadLen) {
      // If our record size is `ECE_AES128GCM_MIN_RS + 1`, we can only include
      // one byte of data, so write the padding first.
      blockPadLen++;
    }
    padLen -= blockPadLen;

    size_t blockEnd = blockStart + plaintextPerBlock - blockPadLen;
    if (blockEnd >= plaintextLen) {
      blockEnd = plaintextLen;
      if (!padLen) {
        // We've reached the last record when the plaintext and padding are
        // exhausted.
        isLastRecord = true;
      }
    }
    size_t blockLen = blockEnd - blockStart;

    pad[0] = isLastRecord ? 2 : 1;

    size_t recordEnd = recordStart + blockLen + blockPadLen + overhead;
    if (recordEnd >= maxRecordEnd) {
      recordEnd = maxRecordEnd;
    }

    // Generate the IV for this record using the nonce.
    uint8_t iv[ECE_NONCE_LENGTH];
    ece_generate_iv(nonce, counter, iv);

    // Encrypt and pad the block. `blockPadLen + 1` ensures we always write the
    // delimiter.
    err = ece_aes128gcm_encrypt_block(ctx, key, iv, &plaintext[blockStart],
                                      blockEnd - blockStart, pad,
                                      blockPadLen + 1, &payload[recordStart]);
    if (err) {
      goto end;
    }
    blockStart = blockEnd;
    recordStart = recordEnd;
    counter++;
  }
  *payloadLen = recordStart;

end:
  EVP_CIPHER_CTX_free(ctx);
  free(pad);
  return err;
}

size_t
ece_aes128gcm_payload_max_length(uint32_t rs, size_t padLen,
                                 size_t plaintextLen) {
  if (rs < ECE_AES128GCM_MIN_RS) {
    return 0;
  }
  // The per-record overhead for the padding delimiter and authentication tag.
  size_t overhead = ECE_AES128GCM_MIN_RS - 1;
  // The total length of the data to encrypt, including the plaintext and
  // padding.
  size_t dataLen = plaintextLen + padLen;
  // The maximum length of data to include in each record, excluding the
  // padding delimiter and authentication tag.
  size_t dataPerBlock = rs - overhead;
  // The total number of encrypted records.
  size_t numRecords = (dataLen / dataPerBlock) + 1;
  return ECE_AES128GCM_HEADER_LENGTH + ECE_AES128GCM_MAX_KEY_ID_LENGTH +
         dataLen + (overhead * numRecords);
}

int
ece_aes128gcm_encrypt(const uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
                      const uint8_t* authSecret, size_t authSecretLen,
                      uint32_t rs, size_t padLen, const uint8_t* plaintext,
                      size_t plaintextLen, uint8_t* payload,
                      size_t* payloadLen) {
  int err = ECE_OK;

  EC_KEY* recvPubKey = NULL;
  EC_KEY* senderPrivKey = NULL;

  // Generate a random salt.
  uint8_t salt[ECE_SALT_LENGTH];
  if (RAND_bytes(salt, ECE_SALT_LENGTH) <= 0) {
    err = ECE_ERROR_INVALID_SALT;
    goto end;
  }

  // Import the receiver public key.
  recvPubKey = ece_import_public_key(rawRecvPubKey, rawRecvPubKeyLen);
  if (!recvPubKey) {
    err = ECE_ERROR_INVALID_PUBLIC_KEY;
    goto end;
  }

  // Generate the sender ECDH key pair.
  senderPrivKey = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
  if (!senderPrivKey) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }
  if (EC_KEY_generate_key(senderPrivKey) <= 0) {
    err = ECE_ERROR_INVALID_PRIVATE_KEY;
    goto end;
  }

  // Encrypt the message.
  err = ece_aes128gcm_encrypt_blocks(
    senderPrivKey, recvPubKey, authSecret, authSecretLen, salt, ECE_SALT_LENGTH,
    rs, padLen, plaintext, plaintextLen, payload, payloadLen);

end:
  EC_KEY_free(recvPubKey);
  EC_KEY_free(senderPrivKey);
  return err;
}

int
ece_aes128gcm_encrypt_with_keys(
  const uint8_t* rawSenderPrivKey, size_t rawSenderPrivKeyLen,
  const uint8_t* authSecret, size_t authSecretLen, const uint8_t* salt,
  size_t saltLen, const uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
  uint32_t rs, size_t padLen, const uint8_t* plaintext, size_t plaintextLen,
  uint8_t* payload, size_t* payloadLen) {
  int err = ECE_OK;

  EC_KEY* senderPrivKey = NULL;
  EC_KEY* recvPubKey = NULL;

  senderPrivKey = ece_import_private_key(rawSenderPrivKey, rawSenderPrivKeyLen);
  if (!senderPrivKey) {
    err = ECE_ERROR_INVALID_PRIVATE_KEY;
    goto end;
  }
  recvPubKey = ece_import_public_key(rawRecvPubKey, rawRecvPubKeyLen);
  if (!recvPubKey) {
    err = ECE_ERROR_INVALID_PUBLIC_KEY;
    goto end;
  }

  err = ece_aes128gcm_encrypt_blocks(
    senderPrivKey, recvPubKey, authSecret, authSecretLen, salt, saltLen, rs,
    padLen, plaintext, plaintextLen, payload, payloadLen);

end:
  EC_KEY_free(senderPrivKey);
  EC_KEY_free(recvPubKey);
  return err;
}
