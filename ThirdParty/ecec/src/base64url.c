#include "ece.h"

// This file implements a Base64url decoder per RFC 4648. Originally implemented
// in https://bugzilla.mozilla.org/show_bug.cgi?id=1256488; ported from Firefox
// with minimal changes.

#include <assert.h>
#include <stdbool.h>

// Maps an encoded character to a value in the Base64 URL alphabet, per
// RFC 4648, Table 2. Invalid input characters map to UINT8_MAX.
static const uint8_t ece_base64url_decode_table[] = {
  255, 255, 255, 255, 255,        255, 255, 255, 255, 255,        255, 255,
  255, 255, 255, 255, 255,        255, 255, 255, 255, 255,        255, 255,
  255, 255, 255, 255, 255,        255, 255, 255, 255, 255,        255, 255,
  255, 255, 255, 255, 255,        255, 255, 255, 255, 62 /* - */, 255, 255,
  52,  53,  54,  55,  56,         57,  58,  59,  60,  61, /* 0 - 9 */
  255, 255, 255, 255, 255,        255, 255, 0,   1,   2,          3,   4,
  5,   6,   7,   8,   9,          10,  11,  12,  13,  14,         15,  16,
  17,  18,  19,  20,  21,         22,  23,  24,  25, /* A - Z */
  255, 255, 255, 255, 63 /* _ */, 255, 26,  27,  28,  29,         30,  31,
  32,  33,  34,  35,  36,         37,  38,  39,  40,  41,         42,  43,
  44,  45,  46,  47,  48,         49,  50,  51, /* a - z */
  255, 255, 255, 255,
};

static inline bool
ece_base64url_decode_lookup(char c, uint8_t* b) {
  *b = ece_base64url_decode_table[c & 0x7f];
  return (*b != 255) && !(*b & ~0x7f);
}

size_t
ece_base64url_decode(const char* base64, size_t base64Len,
                     ece_base64url_decode_policy_t paddingPolicy,
                     uint8_t* decoded, size_t decodedLen) {
  // Don't decode empty strings.
  if (!base64Len) {
    return 0;
  }

  // Check for overflow.
  if (base64Len > SIZE_MAX / 3) {
    return 0;
  }

  // Determine whether to check for and ignore trailing padding.
  bool maybePadded = false;
  switch (paddingPolicy) {
  case ECE_BASE64URL_REQUIRE_PADDING:
    if (base64Len % 4) {
      // Padded input length must be a multiple of 4.
      return 0;
    }
    maybePadded = true;
    break;

  case ECE_BASE64URL_IGNORE_PADDING:
    // Check for padding only if the length is a multiple of 4.
    maybePadded = !(base64Len % 4);
    break;

  // If we're expecting unpadded input, no need for additional checks.
  // `=` isn't in the decode table, so padded strings will fail to decode.
  default:
    // Invalid decode padding policy.
    assert(false);
  case ECE_BASE64URL_REJECT_PADDING:
    break;
  }
  if (maybePadded && base64[base64Len - 1] == '=') {
    if (base64[base64Len - 2] == '=') {
      base64Len -= 2;
    } else {
      base64Len--;
    }
  }

  size_t maxDecodedLen = (base64Len * 3) / 4;
  if (!decodedLen) {
    return maxDecodedLen;
  }

  uint8_t* binary = decoded;
  if (!binary || decodedLen < maxDecodedLen) {
    return 0;
  }

  for (; base64Len >= 4; base64Len -= 4) {
    uint8_t w, x, y, z;
    if (!ece_base64url_decode_lookup(*base64++, &w) ||
        !ece_base64url_decode_lookup(*base64++, &x) ||
        !ece_base64url_decode_lookup(*base64++, &y) ||
        !ece_base64url_decode_lookup(*base64++, &z)) {
      return 0;
    }
    *binary++ = (w << 2 | x >> 4) & 0xff;
    *binary++ = (x << 4 | y >> 2) & 0xff;
    *binary++ = (y << 6 | z) & 0xff;
  }

  if (base64Len == 3) {
    uint8_t w, x, y;
    if (!ece_base64url_decode_lookup(*base64++, &w) ||
        !ece_base64url_decode_lookup(*base64++, &x) ||
        !ece_base64url_decode_lookup(*base64++, &y)) {
      return 0;
    }
    *binary++ = (w << 2 | x >> 4) & 0xff;
    *binary++ = (x << 4 | y >> 2) & 0xff;
  } else if (base64Len == 2) {
    uint8_t w, x;
    if (!ece_base64url_decode_lookup(*base64++, &w) ||
        !ece_base64url_decode_lookup(*base64++, &x)) {
      return 0;
    }
    *binary++ = (w << 2 | x >> 4) & 0xff;
  } else if (base64Len) {
    return 0;
  }

  return (size_t)(binary - decoded);
}
