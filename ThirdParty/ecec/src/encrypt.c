#include "ece.h"
#include "ece/keys.h"
#include "ece/trailer.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/ec.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

typedef size_t (*min_block_pad_length_t)(size_t padLen, size_t maxBlockLen);

typedef int (*encrypt_block_t)(EVP_CIPHER_CTX* ctx,
                               const uint8_t* blockPlaintext,
                               size_t blockPlaintextLen, size_t blockPadLen,
                               bool lastRecord, uint8_t* record);

static const uint8_t pad = 0;

// Writes an unsigned 32-bit integer in network byte order.
static inline void
ece_write_uint32_be(uint8_t* bytes, uint32_t value) {
  bytes[0] = (value >> 24) & 0xff;
  bytes[1] = (value >> 16) & 0xff;
  bytes[2] = (value >> 8) & 0xff;
  bytes[3] = value & 0xff;
}

// Writes an unsigned 16-bit integer in network byte order.
static inline void
ece_write_uint16_be(uint8_t* bytes, uint16_t value) {
  bytes[0] = (value >> 8) & 0xff;
  bytes[1] = value & 0xff;
}

// Calculates the padding so that the block contains at least one plaintext
// byte.
static inline size_t
ece_min_block_pad_length(size_t padLen, size_t maxBlockLen) {
  assert(maxBlockLen >= 1);
  size_t blockPadLen = maxBlockLen - 1;
  if (padLen && !blockPadLen) {
    // If `maxBlockLen` is 1, we can only include 1 byte of data, so write
    // the padding first.
    blockPadLen++;
  }
  return blockPadLen > padLen ? padLen : blockPadLen;
}

// Calculates the padding for an "aesgcm" block. We still want one plaintext
// byte per block, but the padding length must fit into a `uint16_t`.
static size_t
ece_aesgcm_min_block_pad_length(size_t padLen, size_t maxBlockLen) {
  size_t blockPadLen = ece_min_block_pad_length(padLen, maxBlockLen);
  return blockPadLen > UINT16_MAX ? UINT16_MAX : blockPadLen;
}

// Calculates the maximum length of an encrypted ciphertext. This does not
// account for the "aes128gcm" header length.
static inline size_t
ece_ciphertext_max_length(uint32_t rs, size_t padSize, size_t padLen,
                          size_t plaintextLen, needs_trailer_t needsTrailer) {
  // The per-record overhead for the padding delimiter and authentication tag.
  // 17 for "aes128gcm", 18 for "aesgcm".
  assert(padSize <= 2);
  size_t overhead = padSize + ECE_TAG_LENGTH;
  if (rs <= overhead) {
    return 0;
  }
  if (padLen > SIZE_MAX - plaintextLen) {
    return 0;
  }

  // The total length of the data to encrypt, including the plaintext and
  // padding.
  size_t dataLen = plaintextLen + padLen;

  // The maximum length of data to include in each record, excluding the
  // padding delimiter and authentication tag.
  size_t maxBlockLen = rs - overhead;

  // The total number of encrypted records.
  assert(maxBlockLen >= 1);
  size_t numRecords = dataLen / maxBlockLen;
  if (plaintextLen % rs || needsTrailer(rs, plaintextLen)) {
    // If the plaintext length doesn't fall on a record boundary, or if
    // we need to write an empty trailing record, allocate space to hold
    // an extra padding delimiter and authentication tag.
    numRecords++;
  }
  if (numRecords > (SIZE_MAX - dataLen) / overhead) {
    return 0;
  }

  return dataLen + (overhead * numRecords);
}

// Encrypts an "aes128gcm" block into `record`.
static int
ece_aes128gcm_encrypt_block(EVP_CIPHER_CTX* ctx, const uint8_t* blockPlaintext,
                            size_t blockPlaintextLen, size_t blockPadLen,
                            bool lastRecord, uint8_t* record) {
  int chunkLen = -1;

  // The plaintext block precedes the padding.
  if (blockPlaintextLen > INT_MAX ||
      EVP_EncryptUpdate(ctx, record, &chunkLen, blockPlaintext,
                        (int) blockPlaintextLen) != 1) {
    return ECE_ERROR_ENCRYPT;
  }

  // The padding block comprises the delimiter, followed by zeros up to the end
  // of the block.
  uint8_t padDelim = lastRecord ? 2 : 1;
  if (EVP_EncryptUpdate(ctx, &record[blockPlaintextLen], &chunkLen, &padDelim,
                        ECE_AES128GCM_PAD_SIZE) != 1) {
    return ECE_ERROR_ENCRYPT;
  }

  for (size_t i = 0; i < blockPadLen; i++) {
    if (EVP_EncryptUpdate(
          ctx, &record[blockPlaintextLen + ECE_AES128GCM_PAD_SIZE + i],
          &chunkLen, &pad, 1) != 1) {
      return ECE_ERROR_ENCRYPT;
    }
  }

  return ECE_OK;
}

// Encrypts an "aesgcm" block into `record`.
static int
ece_aesgcm_encrypt_block(EVP_CIPHER_CTX* ctx, const uint8_t* blockPlaintext,
                         size_t plaintextLen, size_t blockPadLen,
                         bool lastRecord, uint8_t* record) {
  ECE_UNUSED(lastRecord);

  int chunkLen = -1;

  // The padding block comprises the padding length as a 16-bit integer,
  // followed by that many zeros. We checked that the length fits into a
  // `uint16_t` in `ece_aesgcm_min_block_pad_length`, so this cast is safe.
  uint8_t padDelim[ECE_AESGCM_PAD_SIZE];
  ece_write_uint16_be(padDelim, (uint16_t) blockPadLen);
  if (EVP_EncryptUpdate(ctx, record, &chunkLen, padDelim,
                        ECE_AESGCM_PAD_SIZE) != 1) {
    return ECE_ERROR_ENCRYPT;
  }

  for (size_t i = 0; i < blockPadLen; i++) {
    if (EVP_EncryptUpdate(ctx, &record[ECE_AESGCM_PAD_SIZE + i], &chunkLen,
                          &pad, 1) != 1) {
      return ECE_ERROR_ENCRYPT;
    }
  }

  // The plaintext block follows the padding.
  if (plaintextLen > INT_MAX ||
      EVP_EncryptUpdate(ctx, &record[ECE_AESGCM_PAD_SIZE + blockPadLen],
                        &chunkLen, blockPlaintext, (int) plaintextLen) != 1) {
    return ECE_ERROR_ENCRYPT;
  }

  return ECE_OK;
}

// A generic encryption function shared by "aesgcm" and "aes128gcm".
// `deriveKeyAndNonce`, `minBlockPadLen`, `encryptBlock`, and `needsTrailer`
// change depending on the scheme.
static int
ece_webpush_encrypt_plaintext(
  EC_KEY* senderPrivKey, EC_KEY* recvPubKey, const uint8_t* authSecret,
  size_t authSecretLen, const uint8_t* salt, size_t saltLen, uint32_t rs,
  size_t padSize, size_t padLen, const uint8_t* plaintext, size_t plaintextLen,
  derive_key_and_nonce_t deriveKeyAndNonce,
  min_block_pad_length_t minBlockPadLen, encrypt_block_t encryptBlock,
  needs_trailer_t needsTrailer, uint8_t* ciphertext, size_t* ciphertextLen) {

  int err = ECE_OK;

  EVP_CIPHER_CTX* ctx = NULL;

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

  // Make sure the ciphertext buffer is large enough to hold the ciphertext.
  size_t maxCiphertextLen =
    ece_ciphertext_max_length(rs, padSize, padLen, plaintextLen, needsTrailer);
  if (!maxCiphertextLen) {
    err = ECE_ERROR_INVALID_RS;
    goto end;
  }
  if (*ciphertextLen < maxCiphertextLen) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }

  uint8_t key[ECE_AES_KEY_LENGTH];
  uint8_t nonce[ECE_NONCE_LENGTH];
  err = deriveKeyAndNonce(ECE_MODE_ENCRYPT, senderPrivKey, recvPubKey,
                          authSecret, ECE_WEBPUSH_AUTH_SECRET_LENGTH, salt,
                          ECE_SALT_LENGTH, key, nonce);
  if (err) {
    goto end;
  }

  assert(padSize <= 2);
  size_t overhead = padSize + ECE_TAG_LENGTH;

  // The maximum amount of plaintext and padding that will fit into a full
  // block. The last block can be smaller.
  assert(rs > overhead);
  size_t maxBlockLen = rs - overhead;

  // The offset at which to start reading the plaintext.
  size_t plaintextStart = 0;

  // The offset at which to start writing the ciphertext.
  size_t ciphertextStart = 0;

  // The record sequence number, used to generate the IV.
  size_t counter = 0;

  bool lastRecord = false;
  while (!lastRecord) {
    size_t blockPadLen = minBlockPadLen(padLen, maxBlockLen);
    assert(blockPadLen <= padLen);
    padLen -= blockPadLen;

    // Fill the rest of the block with plaintext.
    assert(blockPadLen <= maxBlockLen);
    size_t maxBlockPlaintextLen = maxBlockLen - blockPadLen;
    size_t plaintextEnd;
    if (maxBlockPlaintextLen >= plaintextLen - plaintextStart) {
      // Equivalent to `plaintextStart + maxBlockPlaintextLen >= plaintextLen`
      // without overflow.
      plaintextEnd = plaintextLen;
    } else {
      plaintextEnd = plaintextStart + maxBlockPlaintextLen;
    }

    // The length of the plaintext.
    assert(plaintextEnd >= plaintextStart);
    size_t blockPlaintextLen = plaintextEnd - plaintextStart;

    // The length of the plaintext and padding. This should never overflow
    // because `maxBlockPlaintextLen` accounts for `blockPadLen`.
    assert(blockPlaintextLen <= maxBlockPlaintextLen);
    size_t blockLen = blockPlaintextLen + blockPadLen;

    // The length of the full encrypted record, including the plaintext,
    // padding, padding delimiter, and auth tag. This should never overflow
    // because `maxBlockLen` accounts for `overhead`.
    assert(blockLen <= maxBlockLen);
    size_t recordLen = blockLen + overhead;

    size_t ciphertextEnd;
    if (recordLen >= maxCiphertextLen - ciphertextStart) {
      // Equivalent to `ciphertextStart + recordLen >= maxCiphertextLen`
      // without overflow.
      ciphertextEnd = maxCiphertextLen;
    } else {
      ciphertextEnd = ciphertextStart + recordLen;
    }

    assert(ciphertextEnd > ciphertextStart);

    bool plaintextExhausted = plaintextEnd >= plaintextLen;
    if (!padLen && plaintextExhausted && !needsTrailer(rs, ciphertextEnd)) {
      // We've reached the last record when the padding and plaintext are
      // exhausted, and we don't need to write an empty trailing record.
      lastRecord = true;
    }

    if (!lastRecord && blockLen < maxBlockLen) {
      // We have padding left, but not enough plaintext to form a full record.
      // Writing trailing padding-only records will still leak size information,
      // so we force the caller to pick a smaller padding length.
      err = ECE_ERROR_ENCRYPT_PADDING;
      goto end;
    }

    // Generate the IV for this record using the nonce.
    uint8_t iv[ECE_NONCE_LENGTH];
    ece_generate_iv(nonce, counter, iv);

    if (EVP_EncryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, key, iv) != 1) {
      err = ECE_ERROR_ENCRYPT;
      goto end;
    }

    // Encrypt and pad the block.
    err = encryptBlock(ctx, &plaintext[plaintextStart], blockPlaintextLen,
                       blockPadLen, lastRecord, &ciphertext[ciphertextStart]);
    if (err) {
      err = ECE_ERROR_ENCRYPT;
      goto end;
    }

    // OpenSSL requires us to finalize the encryption, but, since we're using a
    // stream cipher, finalization shouldn't write out any bytes.
    int chunkLen = -1;
    assert(EVP_CIPHER_CTX_block_size(ctx) == 1);
    if (EVP_EncryptFinal_ex(ctx, NULL, &chunkLen) != 1) {
      err = ECE_ERROR_ENCRYPT;
      goto end;
    }

    // Append the authentication tag.
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, ECE_TAG_LENGTH,
                            &ciphertext[ciphertextEnd - ECE_TAG_LENGTH]) != 1) {
      err = ECE_ERROR_ENCRYPT;
      goto end;
    }

    if (EVP_CIPHER_CTX_reset(ctx) != 1) {
      err = ECE_ERROR_ENCRYPT;
      goto end;
    }

    plaintextStart = plaintextEnd;
    ciphertextStart = ciphertextEnd;
    counter++;
  }

  // Finally, set the actual ciphertext length.
  *ciphertextLen = ciphertextStart;

end:
  EVP_CIPHER_CTX_free(ctx);
  return err;
}

// Encrypts a Web Push message using the "aes128gcm" scheme.
static int
ece_webpush_aes128gcm_encrypt_plaintext(
  EC_KEY* senderPrivKey, EC_KEY* recvPubKey, const uint8_t* authSecret,
  size_t authSecretLen, const uint8_t* salt, size_t saltLen, uint32_t rs,
  size_t padLen, const uint8_t* plaintext, size_t plaintextLen,
  uint8_t* payload, size_t* payloadLen) {

  size_t headerLen =
    ECE_AES128GCM_HEADER_LENGTH + ECE_WEBPUSH_PUBLIC_KEY_LENGTH;
  if (*payloadLen < headerLen) {
    return ECE_ERROR_OUT_OF_MEMORY;
  }

  // Write the header.
  memcpy(payload, salt, ECE_SALT_LENGTH);
  ece_write_uint32_be(&payload[ECE_SALT_LENGTH], rs);
  payload[ECE_SALT_LENGTH + 4] = ECE_WEBPUSH_PUBLIC_KEY_LENGTH;
  if (!EC_POINT_point2oct(
        EC_KEY_get0_group(senderPrivKey), EC_KEY_get0_public_key(senderPrivKey),
        POINT_CONVERSION_UNCOMPRESSED, &payload[ECE_AES128GCM_HEADER_LENGTH],
        ECE_WEBPUSH_PUBLIC_KEY_LENGTH, NULL)) {
    return ECE_ERROR_ENCODE_PUBLIC_KEY;
  }

  // Write the ciphertext.
  size_t ciphertextLen = *payloadLen - headerLen;
  int err = ece_webpush_encrypt_plaintext(
    senderPrivKey, recvPubKey, authSecret, authSecretLen, salt, saltLen, rs,
    ECE_AES128GCM_PAD_SIZE, padLen, plaintext, plaintextLen,
    &ece_webpush_aes128gcm_derive_key_and_nonce, &ece_min_block_pad_length,
    &ece_aes128gcm_encrypt_block, &ece_aes128gcm_needs_trailer,
    &payload[headerLen], &ciphertextLen);
  if (err) {
    return err;
  }

  *payloadLen = headerLen + ciphertextLen;
  return ECE_OK;
}

size_t
ece_aes128gcm_payload_max_length(uint32_t rs, size_t padLen,
                                 size_t plaintextLen) {
  size_t ciphertextLen =
    ece_ciphertext_max_length(rs, ECE_AES128GCM_PAD_SIZE, padLen, plaintextLen,
                              &ece_aes128gcm_needs_trailer);
  if (!ciphertextLen) {
    return 0;
  }
  size_t maxHeaderLen =
    ECE_AES128GCM_HEADER_LENGTH + ECE_AES128GCM_MAX_KEY_ID_LENGTH;
  if (ciphertextLen > SIZE_MAX - maxHeaderLen) {
    return 0;
  }
  return maxHeaderLen + ciphertextLen;
}

int
ece_webpush_aes128gcm_encrypt(const uint8_t* rawRecvPubKey,
                              size_t rawRecvPubKeyLen,
                              const uint8_t* authSecret, size_t authSecretLen,
                              uint32_t rs, size_t padLen,
                              const uint8_t* plaintext, size_t plaintextLen,
                              uint8_t* payload, size_t* payloadLen) {
  int err = ECE_OK;

  EC_KEY* recvPubKey = NULL;
  EC_KEY* senderPrivKey = NULL;

  // Generate a random salt.
  uint8_t salt[ECE_SALT_LENGTH];
  if (RAND_bytes(salt, ECE_SALT_LENGTH) != 1) {
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
  if (EC_KEY_generate_key(senderPrivKey) != 1) {
    err = ECE_ERROR_INVALID_PRIVATE_KEY;
    goto end;
  }

  // Encrypt the message.
  err = ece_webpush_aes128gcm_encrypt_plaintext(
    senderPrivKey, recvPubKey, authSecret, authSecretLen, salt, ECE_SALT_LENGTH,
    rs, padLen, plaintext, plaintextLen, payload, payloadLen);

end:
  EC_KEY_free(recvPubKey);
  EC_KEY_free(senderPrivKey);
  return err;
}

int
ece_webpush_aes128gcm_encrypt_with_keys(
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

  err = ece_webpush_aes128gcm_encrypt_plaintext(
    senderPrivKey, recvPubKey, authSecret, authSecretLen, salt, saltLen, rs,
    padLen, plaintext, plaintextLen, payload, payloadLen);

end:
  EC_KEY_free(senderPrivKey);
  EC_KEY_free(recvPubKey);
  return err;
}

size_t
ece_aesgcm_ciphertext_max_length(uint32_t rs, size_t padLen,
                                 size_t plaintextLen) {
  rs = ece_aesgcm_rs(rs);
  if (!rs) {
    return 0;
  }
  return ece_ciphertext_max_length(rs, ECE_AESGCM_PAD_SIZE, padLen,
                                   plaintextLen, &ece_aesgcm_needs_trailer);
}

int
ece_webpush_aesgcm_encrypt(const uint8_t* rawRecvPubKey,
                           size_t rawRecvPubKeyLen, const uint8_t* authSecret,
                           size_t authSecretLen, uint32_t rs, size_t padLen,
                           const uint8_t* plaintext, size_t plaintextLen,
                           uint8_t* salt, size_t saltLen,
                           uint8_t* rawSenderPubKey, size_t rawSenderPubKeyLen,
                           uint8_t* ciphertext, size_t* ciphertextLen) {
  int err = ECE_OK;

  EC_KEY* recvPubKey = NULL;
  EC_KEY* senderPrivKey = NULL;

  rs = ece_aesgcm_rs(rs);
  if (!rs) {
    err = ECE_ERROR_INVALID_RS;
    goto end;
  }

  if (saltLen != ECE_SALT_LENGTH) {
    err = ECE_ERROR_INVALID_SALT;
    goto end;
  }
  if (rawSenderPubKeyLen != ECE_WEBPUSH_PUBLIC_KEY_LENGTH) {
    err = ECE_ERROR_INVALID_DH;
    goto end;
  }

  // Generate a random salt.
  if (saltLen > INT_MAX || RAND_bytes(salt, (int) saltLen) != 1) {
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
  if (EC_KEY_generate_key(senderPrivKey) != 1) {
    err = ECE_ERROR_INVALID_PRIVATE_KEY;
    goto end;
  }

  if (!EC_POINT_point2oct(EC_KEY_get0_group(senderPrivKey),
                          EC_KEY_get0_public_key(senderPrivKey),
                          POINT_CONVERSION_UNCOMPRESSED, rawSenderPubKey,
                          rawSenderPubKeyLen, NULL)) {
    err = ECE_ERROR_ENCODE_PUBLIC_KEY;
    goto end;
  }

  err = ece_webpush_encrypt_plaintext(
    senderPrivKey, recvPubKey, authSecret, authSecretLen, salt, saltLen, rs,
    ECE_AESGCM_PAD_SIZE, padLen, plaintext, plaintextLen,
    &ece_webpush_aesgcm_derive_key_and_nonce, &ece_aesgcm_min_block_pad_length,
    &ece_aesgcm_encrypt_block, &ece_aesgcm_needs_trailer, ciphertext,
    ciphertextLen);

end:
  EC_KEY_free(recvPubKey);
  EC_KEY_free(senderPrivKey);
  return err;
}

int
ece_webpush_aesgcm_encrypt_with_keys(
  const uint8_t* rawSenderPrivKey, size_t rawSenderPrivKeyLen,
  const uint8_t* authSecret, size_t authSecretLen, const uint8_t* salt,
  size_t saltLen, const uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
  uint32_t rs, size_t padLen, const uint8_t* plaintext, size_t plaintextLen,
  uint8_t* ciphertext, size_t* ciphertextLen) {

  int err = ECE_OK;

  EC_KEY* senderPrivKey = NULL;
  EC_KEY* recvPubKey = NULL;

  rs = ece_aesgcm_rs(rs);
  if (!rs) {
    err = ECE_ERROR_INVALID_RS;
    goto end;
  }

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

  err = ece_webpush_encrypt_plaintext(
    senderPrivKey, recvPubKey, authSecret, authSecretLen, salt, saltLen, rs,
    ECE_AESGCM_PAD_SIZE, padLen, plaintext, plaintextLen,
    &ece_webpush_aesgcm_derive_key_and_nonce, &ece_aesgcm_min_block_pad_length,
    &ece_aesgcm_encrypt_block, &ece_aesgcm_needs_trailer, ciphertext,
    ciphertextLen);

end:
  EC_KEY_free(senderPrivKey);
  EC_KEY_free(recvPubKey);
  return err;
}
