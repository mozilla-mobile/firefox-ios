#include "test.h"

#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>

int
main() {
  test_aesgcm_valid_crypto_params();
  test_aesgcm_invalid_crypto_params();
  test_aesgcm_valid_ciphertexts();

  test_webpush_aes128gcm_encrypt();
  test_webpush_aes128gcm_decrypt_valid_payloads();
  test_aes128gcm_decrypt_invalid_payloads();

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
