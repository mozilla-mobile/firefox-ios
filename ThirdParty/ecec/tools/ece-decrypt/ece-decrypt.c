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
  int err = ECE_OK;

  ece_buf_t authSecret;
  ece_buf_reset(&authSecret);
  ece_buf_t rawRecvPrivKey;
  ece_buf_reset(&rawRecvPrivKey);
  ece_buf_t payload;
  ece_buf_reset(&payload);
  ece_buf_t plaintext;
  ece_buf_reset(&plaintext);

  err = ece_base64url_decode(argv[1], strlen(argv[1]),
                             ECE_BASE64URL_REJECT_PADDING, &authSecret);
  if (err) {
    fprintf(stderr, "Error: Failed to Base64url-decode auth secret: %d\n", err);
    goto end;
  }
  err = ece_base64url_decode(argv[2], strlen(argv[2]),
                             ECE_BASE64URL_REJECT_PADDING, &rawRecvPrivKey);
  if (err) {
    fprintf(stderr, "Error: Failed to Base64url-decode private key: %d\n", err);
    goto end;
  }
  err = ece_base64url_decode(argv[3], strlen(argv[3]),
                             ECE_BASE64URL_REJECT_PADDING, &payload);
  if (err) {
    fprintf(stderr, "Error: Failed to Base64url-decode message: %d\n", err);
    goto end;
  }
  err =
    ece_aes128gcm_decrypt(&rawRecvPrivKey, &authSecret, &payload, &plaintext);
  if (err) {
    fprintf(stderr, "Error: Failed to decrypt message: %d\n", err);
    goto end;
  }
  char* text = (char*) malloc(plaintext.length + 1);
  if (!text) {
    err = ECE_ERROR_OUT_OF_MEMORY;
    goto end;
  }
  memcpy(text, plaintext.bytes, plaintext.length);
  text[plaintext.length] = '\0';
  printf("Decrypted message: %s\n", text);
  free(text);

end:
  ece_buf_free(&authSecret);
  ece_buf_free(&rawRecvPrivKey);
  ece_buf_free(&payload);
  ece_buf_free(&plaintext);
  return err;
}
