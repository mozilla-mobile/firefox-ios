#include "test.h"

#include <inttypes.h>
#include <string.h>

void
test_webpush_aes128gcm_e2e(void) {
  uint8_t rawRecvPrivKey[ECE_WEBPUSH_PRIVATE_KEY_LENGTH];
  uint8_t rawRecvPubKey[ECE_WEBPUSH_PUBLIC_KEY_LENGTH];
  uint8_t authSecret[ECE_WEBPUSH_AUTH_SECRET_LENGTH];
  int err = ece_webpush_generate_keys(
    rawRecvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH, rawRecvPubKey,
    ECE_WEBPUSH_PUBLIC_KEY_LENGTH, authSecret, ECE_WEBPUSH_AUTH_SECRET_LENGTH);
  ece_assert(!err, "Got %d generating keys", err);

  const void* input = "When I grow up, I want to be a watermelon";
  size_t inputLen = strlen(input);

  size_t payloadLen = ece_aes128gcm_payload_max_length(4096, 0, inputLen);
  ece_assert(payloadLen == 334, "Got %zu for payload max length; want 334",
             payloadLen);
  uint8_t* payload = calloc(payloadLen, sizeof(uint8_t));

  err = ece_webpush_aes128gcm_encrypt(rawRecvPubKey,
                                      ECE_WEBPUSH_PUBLIC_KEY_LENGTH, authSecret,
                                      ECE_WEBPUSH_AUTH_SECRET_LENGTH, 4096, 0,
                                      input, inputLen, payload, &payloadLen);
  ece_assert(!err, "Got %d encrypting plaintext", err);
  ece_assert(payloadLen == 144, "Got %zu for payload length; want 144",
             payloadLen);

  size_t plaintextLen = ece_aes128gcm_plaintext_max_length(payload, payloadLen);
  ece_assert(plaintextLen == 42, "Got %zu for plaintext max length; want 42",
             plaintextLen);
  uint8_t* plaintext = calloc(plaintextLen, sizeof(uint8_t));

  err = ece_webpush_aes128gcm_decrypt(
    rawRecvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH, authSecret,
    ECE_WEBPUSH_AUTH_SECRET_LENGTH, payload, payloadLen, plaintext,
    &plaintextLen);
  ece_assert(!err, "Got %d decrypting payload", err);
  ece_assert(plaintextLen == inputLen, "Got %zu for plaintext length; want %zu",
             plaintextLen, inputLen);
  ece_assert(!memcmp(plaintext, input, inputLen),
             "Got `%s` for plaintext; want `%s`", plaintext, input);

  free(payload);
  free(plaintext);
}

void
test_webpush_aesgcm_e2e(void) {
  uint8_t rawRecvPrivKey[ECE_WEBPUSH_PRIVATE_KEY_LENGTH];
  uint8_t rawRecvPubKey[ECE_WEBPUSH_PUBLIC_KEY_LENGTH];
  uint8_t authSecret[ECE_WEBPUSH_AUTH_SECRET_LENGTH];
  int err = ece_webpush_generate_keys(
    rawRecvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH, rawRecvPubKey,
    ECE_WEBPUSH_PUBLIC_KEY_LENGTH, authSecret, ECE_WEBPUSH_AUTH_SECRET_LENGTH);
  ece_assert(!err, "Got %d generating keys", err);

  const void* input = "If the wind in my sail on the sea stays behind me, one "
                      "day I'll know how far I'll go";
  size_t inputLen = strlen(input);

  size_t ciphertextLen = ece_aesgcm_ciphertext_max_length(26, 6, inputLen);
  ece_assert(ciphertextLen == 162,
             "Got %zu for ciphertext max length; want 162", ciphertextLen);

  uint8_t* ciphertext = calloc(ciphertextLen, sizeof(uint8_t));

  uint8_t encryptSalt[ECE_SALT_LENGTH];
  uint8_t encryptRawSenderPubKey[ECE_WEBPUSH_PUBLIC_KEY_LENGTH];
  err = ece_webpush_aesgcm_encrypt(
    rawRecvPubKey, ECE_WEBPUSH_PUBLIC_KEY_LENGTH, authSecret,
    ECE_WEBPUSH_AUTH_SECRET_LENGTH, 26, 6, input, inputLen, encryptSalt,
    ECE_SALT_LENGTH, encryptRawSenderPubKey, ECE_WEBPUSH_PUBLIC_KEY_LENGTH,
    ciphertext, &ciphertextLen);
  ece_assert(!err, "Got %d encrypting plaintext", err);
  ece_assert(ciphertextLen == 162, "Got %zu for ciphertext length; want 162",
             ciphertextLen);

  size_t cryptoKeyHeaderLen = 0;
  size_t encryptionHeaderLen = 0;
  err = ece_webpush_aesgcm_headers_from_params(
    encryptSalt, ECE_SALT_LENGTH, encryptRawSenderPubKey,
    ECE_WEBPUSH_PUBLIC_KEY_LENGTH, 14, NULL, &cryptoKeyHeaderLen, NULL,
    &encryptionHeaderLen);
  ece_assert(!err, "Got %d determining crypto header lengths", err);

  char* cryptoKeyHeader = malloc(cryptoKeyHeaderLen + 1);
  char* encryptionHeader = malloc(encryptionHeaderLen + 1);
  err = ece_webpush_aesgcm_headers_from_params(
    encryptSalt, ECE_SALT_LENGTH, encryptRawSenderPubKey,
    ECE_WEBPUSH_PUBLIC_KEY_LENGTH, 26, cryptoKeyHeader, &cryptoKeyHeaderLen,
    encryptionHeader, &encryptionHeaderLen);
  ece_assert(!err, "Got %d formatting crypto headers", err);
  cryptoKeyHeader[cryptoKeyHeaderLen] = '\0';
  encryptionHeader[encryptionHeaderLen] = '\0';

  uint8_t decryptSalt[ECE_SALT_LENGTH];
  uint8_t decryptRawSenderPubKey[ECE_WEBPUSH_PUBLIC_KEY_LENGTH];
  uint32_t rs;
  err = ece_webpush_aesgcm_headers_extract_params(
    cryptoKeyHeader, encryptionHeader, decryptSalt, ECE_SALT_LENGTH,
    decryptRawSenderPubKey, ECE_WEBPUSH_PUBLIC_KEY_LENGTH, &rs);
  ece_assert(!err, "Got %d extracting crypto params", err);
  ece_assert(!memcmp(encryptSalt, decryptSalt, ECE_SALT_LENGTH),
             "Wrong salt for `%s`", input);
  ece_assert(!memcmp(encryptRawSenderPubKey, decryptRawSenderPubKey,
                     ECE_WEBPUSH_PUBLIC_KEY_LENGTH),
             "Wrong sender public key for `%s`", input);
  ece_assert(rs == 26, "Got rs = %" PRIu32 "; want 26", rs);

  size_t plaintextLen = ece_aesgcm_plaintext_max_length(rs, ciphertextLen);
  ece_assert(plaintextLen == 98, "Got %zu for plaintext max length; want 98",
             plaintextLen);
  uint8_t* plaintext = calloc(plaintextLen, sizeof(uint8_t));

  err = ece_webpush_aesgcm_decrypt(
    rawRecvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH, authSecret,
    ECE_WEBPUSH_AUTH_SECRET_LENGTH, decryptSalt, ECE_SALT_LENGTH,
    decryptRawSenderPubKey, ECE_WEBPUSH_PUBLIC_KEY_LENGTH, rs, ciphertext,
    ciphertextLen, plaintext, &plaintextLen);
  ece_assert(!err, "Got %d decrypting ciphertext", err);
  ece_assert(plaintextLen == inputLen, "Got %zu for plaintext length; want %zu",
             plaintextLen, inputLen);
  ece_assert(!memcmp(plaintext, input, inputLen),
             "Got `%s` for plaintext; want `%s`", plaintext, input);

  free(ciphertext);
  free(cryptoKeyHeader);
  free(encryptionHeader);
  free(plaintext);
}
