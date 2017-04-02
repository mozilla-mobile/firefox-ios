#include "test.h"

#include <string.h>

typedef struct base64url_test_s {
  const char* encoded;
  const char* decoded;
  size_t decodedLen;
} base64url_test_t;

static base64url_test_t base64url_tests[] = {
  // Test vectors from RFC 4648, section 10.
  {"", "", 0},
  {"Zg", "f", 1},
  {"Zg==", "f", 1},
  {"Zm8", "fo", 2},
  {"Zm8=", "fo", 2},
  {"Zm9v", "foo", 3},
  {"Zm9vYg", "foob", 4},
  {"Zm9vYg==", "foob", 4},
  {"Zm9vYmE", "fooba", 5},
  {"Zm9vYmE=", "fooba", 5},
  {"Zm9vYmFy", "foobar", 6},

  // Examples from RFC 4648, section 9.g
  {"FPucA9l-", "\x14\xfb\x9c\x03\xd9\x7e", 6},
  {"FPucA9k", "\x14\xfb\x9c\x03\xd9", 5},
  {"FPucA9k=", "\x14\xfb\x9c\x03\xd9", 5},
  {"FPucAw", "\x14\xfb\x9c\x03", 4},
  {"FPucAw==", "\x14\xfb\x9c\x03", 4},
};

void
test_base64url_decode() {
  size_t tests = sizeof(base64url_tests) / sizeof(base64url_test_t);
  for (size_t i = 0; i < tests; i++) {
    base64url_test_t t = base64url_tests[i];

    size_t encodedLen = strlen(t.encoded);
    size_t minDecodedLen = ece_base64url_decode(
      t.encoded, encodedLen, ECE_BASE64URL_IGNORE_PADDING, NULL, 0);

    if (!t.decodedLen) {
      ece_assert(!minDecodedLen, "Got minimum decoded length %zu",
                 minDecodedLen);
      continue;
    }

    ece_assert(minDecodedLen == t.decodedLen,
               "Got minimum decoded length %zu for `%s`; want %zu",
               minDecodedLen, t.encoded, t.decodedLen);

    uint8_t* decoded = calloc(t.decodedLen, sizeof(uint8_t));
    ece_assert(decoded, "Failed to allocate buffer for `%s`", t.encoded);

    size_t decodedLen =
      ece_base64url_decode(t.encoded, encodedLen, ECE_BASE64URL_IGNORE_PADDING,
                           decoded, t.decodedLen);
    ece_assert(decodedLen == t.decodedLen,
               "Got length %zu for `%s` with padding ignored; want %zu",
               decodedLen, t.encoded, t.decodedLen);
    ece_assert(!memcmp(decoded, t.decoded, decodedLen),
               "Wrong output for `%s` with padding ignored", t.encoded);

    const char* padStart = strchr(t.encoded, '=');
    if (padStart) {
      decodedLen = ece_base64url_decode(t.encoded, encodedLen,
                                        ECE_BASE64URL_REJECT_PADDING, decoded,
                                        t.decodedLen);
      ece_assert(!decodedLen,
                 "Got length %zu decoding `%s` with padding rejected",
                 decodedLen, t.encoded);

      size_t unpaddedLen = (size_t)(padStart - t.encoded);
      decodedLen = ece_base64url_decode(t.encoded, unpaddedLen,
                                        ECE_BASE64URL_REQUIRE_PADDING, decoded,
                                        t.decodedLen);
      ece_assert(!decodedLen,
                 "Got length %zu decoding `%s` with required padding trimmed",
                 decodedLen, t.encoded);
    }

    if (padStart || !(encodedLen % 4)) {
      decodedLen = ece_base64url_decode(t.encoded, encodedLen,
                                        ECE_BASE64URL_REQUIRE_PADDING, decoded,
                                        t.decodedLen);
      ece_assert(decodedLen == t.decodedLen,
                 "Got length %zu for `%s` with padding required; want %zu",
                 decodedLen, t.encoded, t.decodedLen);
      ece_assert(!memcmp(decoded, t.decoded, decodedLen),
                 "Wrong output for `%s` with padding required", t.encoded);
    }

    free(decoded);
  }
}
