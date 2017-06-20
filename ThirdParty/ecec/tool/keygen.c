#include <stdio.h>
#include <stdlib.h>

#include <ece.h>

static const char ece_keygen_hex_alphabet[] = "0123456789abcdef";

char*
ece_keygen_hex_encode(const uint8_t* binary, size_t binaryLen) {
  if (binaryLen > SIZE_MAX / 2 - 1) {
    return NULL;
  }
  char* encoded = malloc(binaryLen * 2 + 1);
  if (!encoded) {
    return NULL;
  }
  char* hex = encoded;
  for (size_t i = 0; i < binaryLen; i++) {
    *hex++ = ece_keygen_hex_alphabet[(binary[i] >> 4) & 0xf];
    *hex++ = ece_keygen_hex_alphabet[binary[i] & 0xf];
  }
  *hex = '\0';
  return encoded;
}

int
main(int argc, char** argv) {
  uint8_t rawRecvPrivKey[ECE_WEBPUSH_PRIVATE_KEY_LENGTH];
  uint8_t rawRecvPubKey[ECE_WEBPUSH_PUBLIC_KEY_LENGTH];
  uint8_t authSecret[ECE_WEBPUSH_AUTH_SECRET_LENGTH];

  int err = ece_webpush_generate_keys(
    rawRecvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH, rawRecvPubKey,
    ECE_WEBPUSH_PUBLIC_KEY_LENGTH, authSecret, ECE_WEBPUSH_AUTH_SECRET_LENGTH);
  if (err) {
    fprintf(stderr, "Error: Failed to generate subscription keys: %d\n", err);
    return 1;
  }

  char* hexRecvPrivKey =
    ece_keygen_hex_encode(rawRecvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH);
  if (hexRecvPrivKey) {
    printf("Private key: %s\n", hexRecvPrivKey);
  }

  char* hexRecvPubKey =
    ece_keygen_hex_encode(rawRecvPubKey, ECE_WEBPUSH_PUBLIC_KEY_LENGTH);
  if (hexRecvPubKey) {
    printf("Public key: %s\n", hexRecvPubKey);
  }

  char* hexAuthSecret =
    ece_keygen_hex_encode(authSecret, ECE_WEBPUSH_AUTH_SECRET_LENGTH);
  if (hexAuthSecret) {
    printf("Authentication secret: %s\n", hexAuthSecret);
  }

  free(hexRecvPrivKey);
  free(hexRecvPubKey);
  free(hexAuthSecret);

  return 0;
}
