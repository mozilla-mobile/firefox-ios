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
test_webpush_aesgcm_headers_from_params(void);

void
test_webpush_aesgcm_headers_extract_params_ok(void);

void
test_webpush_aesgcm_headers_extract_params_err(void);

void
test_webpush_aesgcm_encrypt_ok(void);

void
test_webpush_aesgcm_encrypt_pad(void);

void
test_webpush_aesgcm_decrypt_ok(void);

void
test_webpush_aesgcm_decrypt_err(void);

void
test_webpush_aes128gcm_encrypt_ok(void);

void
test_webpush_aes128gcm_encrypt_pad(void);

void
test_aes128gcm_decrypt_ok(void);

void
test_webpush_aes128gcm_decrypt_ok(void);

void
test_aes128gcm_decrypt_err(void);

void
test_webpush_aes128gcm_decrypt_err(void);

void
test_webpush_aes128gcm_e2e(void);

void
test_webpush_aesgcm_e2e(void);

void
test_base64url_encode(void);

void
test_base64url_decode(void);
