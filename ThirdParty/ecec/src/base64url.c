#include "ece.h"

// This file implements Base64url encoding and decoding per RFC 4648. Originally
// implemented in https://bugzilla.mozilla.org/show_bug.cgi?id=1256488 and
// https://bugzilla.mozilla.org/show_bug.cgi?id=1205137.

#include <assert.h>
#include <stdbool.h>

#define ECE_BASE64URL_INVALID_CHAR 64
#define ECE_BASE64URL_INVALID_PADDING 3

// Maps an index to a character in the Base64url alphabet.
static const char ece_base64url_encode_table[] =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

// Maps a character in the Base64url alphabet to its index, per RFC 4648,
// Table 2. Invalid characters map to 64.
static const uint8_t ece_base64url_decode_table[] = {
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 52, 53, 54, 55, 56, 57, 58, 59, 60,
  61, 64, 64, 64, 64, 64, 64, 64, 0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10,
  11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64,
  63, 64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
  43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64,
};

// Returns the size of the buffer required to hold the Base64url output,
// or 0 if `binaryLen` is too large.
static inline size_t
ece_base64url_base64_length(size_t binaryLen) {
  if (binaryLen / 3 > SIZE_MAX / 4) {
    return 0;
  }
  // Base64 expands each 3-byte quantum to 4 bytes. The final quantum can be
  // 2 or 3 bytes.
  size_t baseLen = (binaryLen / 3) * 4;
  size_t finalLen = 0;
  switch (binaryLen % 3) {
  case 1:
    finalLen = 2;
    break;

  case 2:
    finalLen = 3;
    break;
  }
  if (finalLen > SIZE_MAX - baseLen) {
    return 0;
  }
  return baseLen + finalLen;
}

// Encodes a `binary` quantum into `base64`, and returns the number of bytes
// written. A 3-byte quantum encodes to 4 bytes, a 2-byte quantum encodes to
// 3 bytes, and a 1-byte quantum encodes to 2 bytes.
static inline int
ece_base64url_encode_quantum(const uint8_t* binary, size_t binaryLen,
                             char* base64) {
  assert(binaryLen <= 3);

  uint32_t quantum = 0;
  for (size_t i = 0; i < binaryLen; i++) {
    quantum <<= 8;
    quantum |= (uint32_t) binary[i];
  }

  switch (binaryLen) {
  case 1:
    base64[0] = ece_base64url_encode_table[(quantum >> 2) & 0x3f];
    base64[1] = ece_base64url_encode_table[(quantum << 4) & 0x3f];
    return 2;

  case 2:
    base64[0] = ece_base64url_encode_table[(quantum >> 10) & 0x3f];
    base64[1] = ece_base64url_encode_table[(quantum >> 4) & 0x3f];
    base64[2] = ece_base64url_encode_table[(quantum << 2) & 0x3f];
    return 3;

  case 3:
    base64[0] = ece_base64url_encode_table[(quantum >> 18) & 0x3f];
    base64[1] = ece_base64url_encode_table[(quantum >> 12) & 0x3f];
    base64[2] = ece_base64url_encode_table[(quantum >> 6) & 0x3f];
    base64[3] = ece_base64url_encode_table[quantum & 0x3f];
    return 4;
  }

  return 0;
}

// Returns the number of trailing `=` characters to remove from the end of
// `base64`, based on the `paddingPolicy`. Valid values are 0, 1, or 2;
// 3 means the input is invalid.
static inline size_t
ece_base64url_decode_pad_length(const char* base64, size_t base64Len,
                                ece_base64url_decode_policy_t paddingPolicy) {
  // Determine whether to check for and ignore trailing padding.
  bool maybePadded = false;
  switch (paddingPolicy) {
  case ECE_BASE64URL_REQUIRE_PADDING:
    if (base64Len % 4) {
      // Padded input length must be a multiple of 4.
      return ECE_BASE64URL_INVALID_PADDING;
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
    base64Len--;
    if (base64[base64Len - 1] == '=') {
      return 2;
    }
    return 1;
  }
  return 0;
}

// Returns the size of the buffer required to hold the binary output, or 0 if
// `base64Len` is truncated.
static inline size_t
ece_base64url_binary_length(size_t base64Len) {
  size_t requiredBinaryLen = (base64Len / 4) * 3;
  switch (base64Len % 4) {
  case 1:
    return 0;

  case 2:
    requiredBinaryLen++;
    break;

  case 3:
    requiredBinaryLen += 2;
    break;
  }
  return requiredBinaryLen;
}

// Converts a Base64url character `c` to its index.
static inline uint8_t
ece_base64url_decode_byte(char b) {
  return (b & ~0x7f) ? ECE_BASE64URL_INVALID_CHAR
                     : ece_base64url_decode_table[b & 0x7f];
}

// Decodes a `base64` encoded quantum into `binary`. A 4-byte quantum decodes to
// 3 bytes, a 3-byte quantum decodes to 2 bytes, and a 2-byte quantum decodes to
// 1 byte.
static inline bool
ece_base64url_decode_quantum(const char* base64, size_t base64Len,
                             uint8_t* binary) {
  assert(base64Len <= 4);

  uint32_t quantum = 0;
  for (size_t i = 0; i < base64Len; i++) {
    uint8_t b = ece_base64url_decode_byte(base64[i]);
    if (b == ECE_BASE64URL_INVALID_CHAR) {
      return false;
    }
    quantum <<= 6;
    quantum |= (uint32_t) b;
  }

  switch (base64Len) {
  case 0:
    return true;

  case 2:
    binary[0] = (quantum >> 4) & 0xff;
    return true;

  case 3:
    binary[0] = (quantum >> 10) & 0xff;
    binary[1] = (quantum >> 2) & 0xff;
    return true;

  case 4:
    binary[0] = (quantum >> 16) & 0xff;
    binary[1] = (quantum >> 8) & 0xff;
    binary[2] = quantum & 0xff;
    return true;
  }

  return false;
}

size_t
ece_base64url_encode(const void* binary, size_t binaryLen,
                     ece_base64url_encode_policy_t paddingPolicy, char* base64,
                     size_t base64Len) {
  // Don't encode empty strings.
  if (!binaryLen) {
    return 0;
  }

  // Ensure we have enough room to hold the output.
  size_t requiredBase64Len = ece_base64url_base64_length(binaryLen);
  if (!requiredBase64Len) {
    return 0;
  }
  size_t padLen = 0;
  if (paddingPolicy == ECE_BASE64URL_INCLUDE_PADDING) {
    switch (requiredBase64Len % 4) {
    case 2:
      padLen = 2;
      break;

    case 3:
      padLen = 1;
      break;
    }
    if (padLen > SIZE_MAX - requiredBase64Len) {
      return 0;
    }
    requiredBase64Len += padLen;
  }

  if (base64Len) {
    if (base64Len < requiredBase64Len) {
      return 0;
    }
    const uint8_t* input = binary;
    for (; binaryLen >= 3; binaryLen -= 3) {
      base64 += ece_base64url_encode_quantum(input, 3, base64);
      input += 3;
    }
    base64 += ece_base64url_encode_quantum(input, binaryLen, base64);
    if (paddingPolicy == ECE_BASE64URL_INCLUDE_PADDING) {
      while (padLen) {
        *base64++ = '=';
        padLen--;
      }
    } else {
      assert(paddingPolicy == ECE_BASE64URL_OMIT_PADDING);
    }
  }

  return requiredBase64Len;
}

size_t
ece_base64url_decode(const char* base64, size_t base64Len,
                     ece_base64url_decode_policy_t paddingPolicy,
                     uint8_t* binary, size_t binaryLen) {
  // Don't decode empty strings.
  if (!base64Len) {
    return 0;
  }

  // Ensure we have enough room to hold the output.
  size_t padLen =
    ece_base64url_decode_pad_length(base64, base64Len, paddingPolicy);
  if (padLen == ECE_BASE64URL_INVALID_PADDING) {
    return 0;
  }
  base64Len -= padLen;
  size_t requiredBinaryLen = ece_base64url_binary_length(base64Len);

  if (binaryLen) {
    if (binaryLen < requiredBinaryLen) {
      return 0;
    }
    for (; base64Len >= 4; base64Len -= 4) {
      if (!ece_base64url_decode_quantum(base64, 4, binary)) {
        return 0;
      }
      base64 += 4;
      binary += 3;
    }
    if (!ece_base64url_decode_quantum(base64, base64Len, binary)) {
      return 0;
    }
  }

  return requiredBinaryLen;
}
