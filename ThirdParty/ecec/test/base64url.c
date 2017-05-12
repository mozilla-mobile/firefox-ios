#include "test.h"

#include <string.h>

typedef struct base64url_encode_test_s {
  const char* binary;
  size_t binaryLen;
  ece_base64url_encode_policy_t paddingPolicy;
  const char* base64;
  size_t base64Len;
} base64url_encode_test_t;

static base64url_encode_test_t base64url_encode_tests[] = {
  {"f", 1, ECE_BASE64URL_OMIT_PADDING, "Zg", 2},
  {"f", 1, ECE_BASE64URL_INCLUDE_PADDING, "Zg==", 4},

  {"fo", 2, ECE_BASE64URL_OMIT_PADDING, "Zm8", 3},
  {"fo", 2, ECE_BASE64URL_INCLUDE_PADDING, "Zm8=", 4},

  {"foo", 3, ECE_BASE64URL_OMIT_PADDING, "Zm9v", 4},
  {"foo", 3, ECE_BASE64URL_INCLUDE_PADDING, "Zm9v", 4},

  {"foob", 4, ECE_BASE64URL_OMIT_PADDING, "Zm9vYg", 6},
  {"foob", 4, ECE_BASE64URL_INCLUDE_PADDING, "Zm9vYg==", 8},

  {"fooba", 5, ECE_BASE64URL_OMIT_PADDING, "Zm9vYmE", 7},
  {"fooba", 5, ECE_BASE64URL_INCLUDE_PADDING, "Zm9vYmE=", 8},

  {"foobar", 6, ECE_BASE64URL_OMIT_PADDING, "Zm9vYmFy", 8},
  {"foobar", 6, ECE_BASE64URL_INCLUDE_PADDING, "Zm9vYmFy", 8},

  {"\x14\xfb\x9c\x03\xd9\x7e", 6, ECE_BASE64URL_OMIT_PADDING, "FPucA9l-", 8},
  {"\x14\xfb\x9c\x03\xd9\x7e", 6, ECE_BASE64URL_INCLUDE_PADDING, "FPucA9l-", 8},

  {"\x14\xfb\x9c\x03\xd9", 5, ECE_BASE64URL_OMIT_PADDING, "FPucA9k", 7},
  {"\x14\xfb\x9c\x03\xd9", 5, ECE_BASE64URL_INCLUDE_PADDING, "FPucA9k=", 8},

  {"\x14\xfb\x9c\x03", 4, ECE_BASE64URL_OMIT_PADDING, "FPucAw", 6},
  {"\x14\xfb\x9c\x03", 4, ECE_BASE64URL_INCLUDE_PADDING, "FPucAw==", 8},
};

typedef struct base64url_decode_test_s {
  const char* base64;
  size_t base64Len;
  ece_base64url_decode_policy_t paddingPolicy;
  size_t requiredBinaryLen;
  const char* binary;
  size_t binaryLen;
} base64url_decode_test_t;

static base64url_decode_test_t base64url_decode_tests[] = {
  // Test vectors from RFC 4648, section 10.
  {"", 0, ECE_BASE64URL_REQUIRE_PADDING, 0, NULL, 0},

  {"Zg", 2, ECE_BASE64URL_REQUIRE_PADDING, 0, NULL, 0},
  {"Zg", 2, ECE_BASE64URL_IGNORE_PADDING, 1, "f", 1},
  {"Zg", 2, ECE_BASE64URL_REJECT_PADDING, 1, "f", 1},

  {"Zg==", 4, ECE_BASE64URL_REQUIRE_PADDING, 1, "f", 1},
  {"Zg==", 4, ECE_BASE64URL_IGNORE_PADDING, 1, "f", 1},
  {"Zg==", 4, ECE_BASE64URL_REJECT_PADDING, 3, NULL, 0},

  {"Zm8", 3, ECE_BASE64URL_REQUIRE_PADDING, 0, NULL, 0},
  {"Zm8", 3, ECE_BASE64URL_IGNORE_PADDING, 2, "fo", 2},
  {"Zm8", 3, ECE_BASE64URL_REJECT_PADDING, 2, "fo", 2},

  {"Zm8=", 4, ECE_BASE64URL_REQUIRE_PADDING, 2, "fo", 2},
  {"Zm8=", 4, ECE_BASE64URL_IGNORE_PADDING, 2, "fo", 2},
  {"Zm8=", 4, ECE_BASE64URL_REJECT_PADDING, 3, NULL, 0},

  {"Zm9v", 4, ECE_BASE64URL_REQUIRE_PADDING, 3, "foo", 3},
  {"Zm9v", 4, ECE_BASE64URL_IGNORE_PADDING, 3, "foo", 3},
  {"Zm9v", 4, ECE_BASE64URL_REJECT_PADDING, 3, "foo", 3},

  {"Zm9vYg", 6, ECE_BASE64URL_REQUIRE_PADDING, 0, NULL, 0},
  {"Zm9vYg", 6, ECE_BASE64URL_IGNORE_PADDING, 4, "foob", 4},
  {"Zm9vYg", 6, ECE_BASE64URL_REJECT_PADDING, 4, "foob", 4},

  {"Zm9vYg==", 8, ECE_BASE64URL_REQUIRE_PADDING, 4, "foob", 4},
  {"Zm9vYg==", 8, ECE_BASE64URL_IGNORE_PADDING, 4, "foob", 4},
  {"Zm9vYg==", 8, ECE_BASE64URL_REJECT_PADDING, 6, NULL, 0},

  {"Zm9vYmE", 7, ECE_BASE64URL_REQUIRE_PADDING, 0, NULL, 0},
  {"Zm9vYmE", 7, ECE_BASE64URL_IGNORE_PADDING, 5, "fooba", 5},
  {"Zm9vYmE", 7, ECE_BASE64URL_REJECT_PADDING, 5, "fooba", 5},

  {"Zm9vYmE=", 8, ECE_BASE64URL_REQUIRE_PADDING, 5, "fooba", 5},
  {"Zm9vYmE=", 8, ECE_BASE64URL_IGNORE_PADDING, 5, "fooba", 5},
  {"Zm9vYmE=", 8, ECE_BASE64URL_REJECT_PADDING, 6, NULL, 0},

  {"Zm9vYmFy", 8, ECE_BASE64URL_REQUIRE_PADDING, 6, "foobar", 6},
  {"Zm9vYmFy", 8, ECE_BASE64URL_IGNORE_PADDING, 6, "foobar", 6},
  {"Zm9vYmFy", 8, ECE_BASE64URL_REJECT_PADDING, 6, "foobar", 6},

  // Examples from RFC 4648, section 9.
  {"FPucA9l-", 8, ECE_BASE64URL_REQUIRE_PADDING, 6, "\x14\xfb\x9c\x03\xd9\x7e",
   6},
  {"FPucA9l-", 8, ECE_BASE64URL_IGNORE_PADDING, 6, "\x14\xfb\x9c\x03\xd9\x7e",
   6},
  {"FPucA9l-", 8, ECE_BASE64URL_REJECT_PADDING, 6, "\x14\xfb\x9c\x03\xd9\x7e",
   6},

  {"FPucA9k", 7, ECE_BASE64URL_REQUIRE_PADDING, 0, NULL, 0},
  {"FPucA9k", 7, ECE_BASE64URL_IGNORE_PADDING, 5, "\x14\xfb\x9c\x03\xd9", 5},
  {"FPucA9k", 7, ECE_BASE64URL_REJECT_PADDING, 5, "\x14\xfb\x9c\x03\xd9", 5},

  {"FPucA9k=", 8, ECE_BASE64URL_REQUIRE_PADDING, 5, "\x14\xfb\x9c\x03\xd9", 5},
  {"FPucA9k=", 8, ECE_BASE64URL_IGNORE_PADDING, 5, "\x14\xfb\x9c\x03\xd9", 5},
  {"FPucA9k=", 8, ECE_BASE64URL_REJECT_PADDING, 6, NULL, 0},

  {"FPucAw", 6, ECE_BASE64URL_REQUIRE_PADDING, 0, NULL, 0},
  {"FPucAw", 6, ECE_BASE64URL_IGNORE_PADDING, 4, "\x14\xfb\x9c\x03", 4},
  {"FPucAw", 6, ECE_BASE64URL_REJECT_PADDING, 4, "\x14\xfb\x9c\x03", 4},

  {"FPucAw==", 8, ECE_BASE64URL_REQUIRE_PADDING, 4, "\x14\xfb\x9c\x03", 4},
  {"FPucAw==", 8, ECE_BASE64URL_IGNORE_PADDING, 4, "\x14\xfb\x9c\x03", 4},
  {"FPucAw==", 8, ECE_BASE64URL_REJECT_PADDING, 6, NULL, 0},
};

void
test_base64url_encode(void) {
  size_t tests =
    sizeof(base64url_encode_tests) / sizeof(base64url_encode_test_t);
  for (size_t i = 0; i < tests; i++) {
    base64url_encode_test_t t = base64url_encode_tests[i];

    size_t requiredBase64Len =
      ece_base64url_encode(t.binary, t.binaryLen, t.paddingPolicy, NULL, 0);
    ece_assert(
      requiredBase64Len == t.base64Len,
      "Got required length %zu for `%s` with padding policy %d; want %zu",
      requiredBase64Len, t.base64, t.paddingPolicy, t.base64Len);

    char* base64 = malloc(requiredBase64Len + 1);
    ece_assert(base64,
               "Failed to allocate string for `%s` with padding policy %d",
               t.base64, t.paddingPolicy);

    size_t actualBase64Len = ece_base64url_encode(
      t.binary, t.binaryLen, t.paddingPolicy, base64, requiredBase64Len + 1);
    ece_assert(actualBase64Len == t.base64Len,
               "Got length %zu for `%s` with padding policy %d; want %zu",
               actualBase64Len, t.base64, t.paddingPolicy, t.base64Len);

    free(base64);
  }
}

void
test_base64url_decode(void) {
  size_t tests =
    sizeof(base64url_decode_tests) / sizeof(base64url_decode_test_t);
  for (size_t i = 0; i < tests; i++) {
    base64url_decode_test_t t = base64url_decode_tests[i];

    size_t requiredBinaryLen =
      ece_base64url_decode(t.base64, t.base64Len, t.paddingPolicy, NULL, 0);
    ece_assert(requiredBinaryLen == t.requiredBinaryLen,
               "Got required length %zu for `%s` with padding %d; want %zu",
               requiredBinaryLen, t.base64, t.paddingPolicy,
               t.requiredBinaryLen);

    uint8_t* binary = calloc(requiredBinaryLen, sizeof(uint8_t));
    ece_assert(binary, "Failed to allocate buffer for `%s` with padding %d",
               t.base64, t.paddingPolicy);

    size_t binaryLen = ece_base64url_decode(
      t.base64, t.base64Len, t.paddingPolicy, binary, requiredBinaryLen);
    ece_assert(binaryLen == t.binaryLen,
               "Got length %zu for `%s` with padding %d; want %zu", binaryLen,
               t.base64, t.paddingPolicy, t.binaryLen);
    ece_assert(!memcmp(binary, t.binary, binaryLen),
               "Wrong output for `%s` with padding %d", t.base64,
               t.paddingPolicy);

    free(binary);
  }
}
