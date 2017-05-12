#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <ece.h>

int
main(int argc, char** argv) {
  if (argc < 4) {
    fprintf(stderr, "Usage: %s <auth-secret> <receiver-private> <message>",
            argv[0]);
    return 2;
  }

  int err = 0;
  uint8_t* payload = NULL;
  uint8_t* plaintext = NULL;

  uint8_t authSecret[ECE_WEBPUSH_AUTH_SECRET_LENGTH];
  if (!ece_base64url_decode(argv[1], strlen(argv[1]),
                            ECE_BASE64URL_REJECT_PADDING, authSecret,
                            ECE_WEBPUSH_AUTH_SECRET_LENGTH)) {
    fprintf(stderr, "Error: Failed to Base64url-decode auth secret\n");
    goto error;
  }
  uint8_t rawRecvPrivKey[ECE_WEBPUSH_PRIVATE_KEY_LENGTH];
  if (!ece_base64url_decode(argv[2], strlen(argv[2]),
                            ECE_BASE64URL_REJECT_PADDING, rawRecvPrivKey,
                            ECE_WEBPUSH_PRIVATE_KEY_LENGTH)) {
    fprintf(stderr, "Error: Failed to Base64url-decode private key\n");
    goto error;
  }
  size_t payloadBase64Len = strlen(argv[3]);
  size_t payloadLen = ece_base64url_decode(
    argv[3], payloadBase64Len, ECE_BASE64URL_REJECT_PADDING, NULL, 0);
  if (!payloadLen) {
    fprintf(stderr, "Error: Empty or invalid Base64url-encoded message\n");
    goto error;
  }
  payload = calloc(payloadLen, sizeof(uint8_t));
  if (!payload) {
    fprintf(
      stderr,
      "Error: Failed to allocate %zu bytes for Base64url-decoded message\n",
      payloadLen);
    goto error;
  }
  payloadLen =
    ece_base64url_decode(argv[3], payloadBase64Len,
                         ECE_BASE64URL_REJECT_PADDING, payload, payloadLen);
  if (!payloadLen) {
    fprintf(stderr, "Error: Failed to Base64url-decode message\n");
    goto error;
  }

  size_t plaintextLen = ece_aes128gcm_plaintext_max_length(payload, payloadLen);
  if (!plaintextLen) {
    fprintf(stderr, "Error: Encrypted message too short\n");
    goto error;
  }
  plaintextLen++;
  plaintext = calloc(plaintextLen, sizeof(uint8_t));
  if (!plaintext) {
    fprintf(stderr,
            "Error: Failed to allocate %zu bytes for decrypted message\n",
            plaintextLen);
    goto error;
  }
  err = ece_webpush_aes128gcm_decrypt(
    rawRecvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH, authSecret,
    ECE_WEBPUSH_AUTH_SECRET_LENGTH, payload, payloadLen, plaintext,
    &plaintextLen);
  if (err) {
    fprintf(stderr, "Error: Failed to decrypt message: %d\n", err);
    goto error;
  }
  plaintext[plaintextLen] = '\0';
  printf("Decrypted message: %s\n", plaintext);
  goto end;

error:
  err = 1;

end:
  free(payload);
  free(plaintext);
  return err;
}
