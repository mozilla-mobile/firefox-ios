#include "keys.h"

#include <string.h>

#include <openssl/evp.h>

typedef int (*derive_key_and_nonce_t)(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                                      const ece_buf_t* authSecret,
                                      const ece_buf_t* salt, ece_buf_t* key,
                                      ece_buf_t* nonce);

typedef int (*unpad_t)(ece_buf_t* block, bool isLastRecord);

// Extracts an unsigned 16-bit integer in network byte order.
static inline uint16_t
ece_read_uint16_be(uint8_t* bytes) {
  return bytes[1] | (bytes[0] << 8);
}

// Extracts an unsigned 32-bit integer in network byte order.
static inline uint32_t
ece_read_uint32_be(uint8_t* bytes) {
  return bytes[3] | (bytes[2] << 8) | (bytes[1] << 16) | (bytes[0] << 24);
}

// Converts an encrypted record to a decrypted block.
static int
ece_decrypt_record(const ece_buf_t* key, const ece_buf_t* nonce, size_t counter,
                   const ece_buf_t* record, ece_buf_t* block) {
  int err = ECE_OK;

  EVP_CIPHER_CTX* ctx = NULL;
  if (record->length > INT_MAX) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }
  // Generate the IV for this record using the nonce.
  uint8_t iv[ECE_NONCE_LENGTH];
  ece_generate_iv(nonce->bytes, counter, iv);
  if (EVP_DecryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, key->bytes, iv) <= 0) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  // The authentication tag is included at the end of the encrypted record.
  if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, ECE_TAG_LENGTH,
                          &record->bytes[record->length - ECE_TAG_LENGTH]) <=
      0) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  int blockLen = 0;
  if (EVP_DecryptUpdate(ctx, block->bytes, &blockLen, record->bytes,
                        (int) record->length - ECE_TAG_LENGTH) <= 0 ||
      blockLen < 0) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  int finalLen = 0;
  if (EVP_DecryptFinal_ex(ctx, &block->bytes[blockLen], &finalLen) <= 0 ||
      finalLen < 0) {
    err = ECE_ERROR_DECRYPT;
    goto end;
  }
  block->length = blockLen + finalLen;

end:
  EVP_CIPHER_CTX_free(ctx);
  return err;
}

// A generic decryption function shared by "aesgcm" and "aes128gcm".
// `deriveKeyAndNonce` and `unpad` are function pointers that change based on
// the scheme.
static int
ece_decrypt(const ece_buf_t* rawRecvPrivKey, const ece_buf_t* rawSenderPubKey,
            const ece_buf_t* authSecret, const ece_buf_t* salt, uint32_t rs,
            const ece_buf_t* ciphertext,
            derive_key_and_nonce_t deriveKeyAndNonce, unpad_t unpad,
            ece_buf_t* plaintext) {
  int err = ECE_OK;

  ece_buf_reset(plaintext);

  EC_KEY* recvPrivKey = NULL;
  EC_KEY* senderPubKey = NULL;

  ece_buf_t key;
  ece_buf_reset(&key);
  ece_buf_t nonce;
  ece_buf_reset(&nonce);

  recvPrivKey = ece_import_private_key(rawRecvPrivKey);
  if (!recvPrivKey) {
    err = ECE_INVALID_RECEIVER_PRIVATE_KEY;
    goto end;
  }
  senderPubKey = ece_import_public_key(rawSenderPubKey);
  if (!senderPubKey) {
    err = ECE_INVALID_SENDER_PUBLIC_KEY;
    goto end;
  }

  err = deriveKeyAndNonce(recvPrivKey, senderPubKey, authSecret, salt, &key,
                          &nonce);
  if (err) {
    goto error;
  }

  // For simplicity, we allocate a buffer equal to the encrypted record size,
  // even though the decrypted block will be smaller. `ece_decrypt_record`
  // will set the actual length.
  if (!ece_buf_alloc(plaintext, ciphertext->length)) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto error;
  }
  size_t start = 0;
  size_t offset = 0;
  for (size_t counter = 0; start < ciphertext->length; counter++) {
    size_t end = start + rs;
    if (end > ciphertext->length) {
      end = ciphertext->length;
    }
    if (end - start <= ECE_TAG_LENGTH) {
      err = ECE_ERROR_SHORT_BLOCK;
      goto error;
    }
    ece_buf_t record;
    ece_buf_slice(ciphertext, start, end, &record);
    ece_buf_t block;
    ece_buf_slice(plaintext, offset, end - start, &block);
    err = ece_decrypt_record(&key, &nonce, counter, &record, &block);
    if (err) {
      goto error;
    }
    err = unpad(&block, end >= ciphertext->length);
    if (err) {
      goto error;
    }
    start = end;
    offset += block.length;
  }
  plaintext->length = offset;
  goto end;

error:
  ece_buf_free(plaintext);

end:
  EC_KEY_free(recvPrivKey);
  EC_KEY_free(senderPubKey);
  ece_buf_free(&key);
  ece_buf_free(&nonce);
  return err;
}

// Removes padding from a decrypted "aesgcm" block.
static int
ece_aesgcm_unpad(ece_buf_t* block, bool isLastRecord) {
  ECE_UNUSED(isLastRecord);
  if (block->length < ECE_AESGCM_PAD_SIZE) {
    return ECE_ERROR_DECRYPT_PADDING;
  }
  uint16_t pad = ece_read_uint16_be(block->bytes);
  if (pad > block->length) {
    return ECE_ERROR_DECRYPT_PADDING;
  }
  // In "aesgcm", the content is offset by the pad size and padding.
  size_t offset = ECE_AESGCM_PAD_SIZE + pad;
  uint8_t* content = &block->bytes[ECE_AESGCM_PAD_SIZE];
  while (content < &block->bytes[offset]) {
    if (*content) {
      // All padding bytes must be zero.
      return ECE_ERROR_DECRYPT_PADDING;
    }
    content++;
  }
  // Move the unpadded contents to the start of the block.
  block->length -= offset;
  memmove(block->bytes, content, block->length);
  return ECE_OK;
}

// Removes padding from a decrypted "aes128gcm" block.
static int
ece_aes128gcm_unpad(ece_buf_t* block, bool isLastRecord) {
  if (!block->length) {
    return ECE_ERROR_ZERO_PLAINTEXT;
  }
  // Remove trailing padding.
  while (block->length > 0) {
    block->length--;
    if (!block->bytes[block->length]) {
      continue;
    }
    uint8_t recordPad = isLastRecord ? 2 : 1;
    if (block->bytes[block->length] != recordPad) {
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
ece_aes128gcm_decrypt(const ece_buf_t* rawRecvPrivKey,
                      const ece_buf_t* authSecret, const ece_buf_t* payload,
                      ece_buf_t* plaintext) {
  if (payload->length < ECE_AES128GCM_HEADER_SIZE) {
    return ECE_ERROR_SHORT_HEADER;
  }
  ece_buf_t salt;
  ece_buf_slice(payload, 0, ECE_KEY_LENGTH, &salt);
  uint32_t rs = ece_read_uint32_be(&payload->bytes[ECE_KEY_LENGTH]);
  uint8_t keyIdLen = payload->bytes[ECE_KEY_LENGTH + 4];
  if (payload->length < ECE_AES128GCM_HEADER_SIZE + keyIdLen) {
    return ECE_ERROR_SHORT_HEADER;
  }
  ece_buf_t rawSenderPubKey;
  ece_buf_slice(payload, ECE_AES128GCM_HEADER_SIZE,
                ECE_AES128GCM_HEADER_SIZE + keyIdLen, &rawSenderPubKey);
  ece_buf_t ciphertext;
  ece_buf_slice(payload, ECE_AES128GCM_HEADER_SIZE + keyIdLen, payload->length,
                &ciphertext);
  if (!ciphertext.length) {
    return ECE_ERROR_ZERO_CIPHERTEXT;
  }
  return ece_decrypt(rawRecvPrivKey, &rawSenderPubKey, authSecret, &salt, rs,
                     &ciphertext, &ece_aes128gcm_derive_key_and_nonce,
                     &ece_aes128gcm_unpad, plaintext);
}

int
ece_aesgcm_decrypt(const ece_buf_t* rawRecvPrivKey, const ece_buf_t* authSecret,
                   const char* cryptoKeyHeader, const char* encryptionHeader,
                   const ece_buf_t* ciphertext, ece_buf_t* plaintext) {
  int err = ECE_OK;

  ece_buf_t rawSenderPubKey;
  ece_buf_reset(&rawSenderPubKey);
  ece_buf_t salt;
  ece_buf_reset(&salt);

  uint32_t rs;
  err = ece_header_extract_aesgcm_crypto_params(
    cryptoKeyHeader, encryptionHeader, &rs, &salt, &rawSenderPubKey);
  if (err) {
    goto end;
  }
  rs += ECE_TAG_LENGTH;
  err = ece_decrypt(rawRecvPrivKey, &rawSenderPubKey, authSecret, &salt, rs,
                    ciphertext, &ece_aesgcm_derive_key_and_nonce,
                    &ece_aesgcm_unpad, plaintext);

end:
  ece_buf_free(&rawSenderPubKey);
  ece_buf_free(&salt);
  return err;
}
