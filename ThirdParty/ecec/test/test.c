#include "test.h"

#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

int
main() {
  test_webpush_aesgcm_headers_from_params();
  test_webpush_aesgcm_headers_extract_params_ok();
  test_webpush_aesgcm_headers_extract_params_err();

  test_webpush_aesgcm_encrypt_ok();
  test_webpush_aesgcm_encrypt_pad();
  test_webpush_aesgcm_decrypt_ok();
  test_webpush_aesgcm_decrypt_err();

  test_webpush_aes128gcm_encrypt_ok();
  test_webpush_aes128gcm_encrypt_pad();
  test_webpush_aes128gcm_decrypt_ok();
  test_webpush_aes128gcm_decrypt_err();
  test_aes128gcm_decrypt_ok();
  test_aes128gcm_decrypt_err();

  test_webpush_aes128gcm_e2e();
  test_webpush_aesgcm_e2e();

  test_base64url_encode();
  test_base64url_decode();

  return 0;
}

void
ece_log(const char* funcName, int line, const char* expr, const char* format,
        ...) {
  char* message = NULL;
  va_list args;
  va_start(args, format);

  // Determine the size of the formatted message, then allocate and write to a
  // buffer large enough to hold the message. `vsnprintf` mutates its argument
  // list, so we make a copy for calculating the size.
  va_list sizeArgs;
  va_copy(sizeArgs, args);
  int size = vsnprintf(NULL, 0, format, sizeArgs);
  va_end(sizeArgs);
  if (size < 0) {
    goto error;
  }
  message = malloc((size_t) size + 1);
  if (!message || vsprintf(message, format, args) != size) {
    goto error;
  }
  message[size] = '\0';
  fprintf(stderr, "[%s:%d] (%s): %s\n", funcName, line, expr, message);
  goto end;

error:
  fprintf(stderr, "[%s:%d]: %s\n", funcName, line, expr);

end:
  va_end(args);
  free(message);
}
