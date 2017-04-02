#include <stdio.h>
#include <stdlib.h>

#include <ece.h>

// This macro is similar to the standard `assert`, but accepts a format string
// with an informative failure message.
#define ece_assert(cond, format, ...)                                          \
  do {                                                                         \
    if (!(cond)) {                                                             \
      ece_log(__func__, __LINE__, #cond, format, __VA_ARGS__);                 \
      abort();                                                                 \
    }                                                                          \
  } while (0)

// Logs an assertion failure to standard error.
void
ece_log(const char* funcName, int line, const char* expr, const char* format,
        ...);

void
test_aesgcm_valid_crypto_params();

void
test_aesgcm_invalid_crypto_params();

void
test_aesgcm_valid_ciphertexts();

void
test_webpush_aes128gcm_encrypt();

void
test_webpush_aes128gcm_decrypt_valid_payloads();

void
test_aes128gcm_decrypt_invalid_payloads();

void
test_base64url_decode();
