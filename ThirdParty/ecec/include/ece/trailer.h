#ifndef ECE_TRAILER_H
#define ECE_TRAILER_H
#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef bool (*needs_trailer_t)(uint32_t rs, size_t ciphertextLen);

// Adjusts the aesgcm record size to account for the authentication tag.
// aesgcm includes the size of the padding delimiter, but not the tag.
uint32_t
ece_aesgcm_rs(uint32_t rs);

// Indicates if an "aesgcm" ciphertext is a multiple of the record size, and
// needs a padding-only trailing block to prevent truncation attacks.
bool
ece_aesgcm_needs_trailer(uint32_t rs, size_t ciphertextLen);

// Provided for completeness, but always returns false because "aes128gcm" uses
// a padding scheme that doesn't need a trailer.
bool
ece_aes128gcm_needs_trailer(uint32_t rs, size_t ciphertextLen);

#ifdef __cplusplus
}
#endif
#endif /* ECE_TRAILER_H */
