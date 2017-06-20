#include "ece/trailer.h"
#include "ece.h"

uint32_t
ece_aesgcm_rs(uint32_t rs) {
  return rs > UINT32_MAX - ECE_TAG_LENGTH ? 0 : rs + ECE_TAG_LENGTH;
}

bool
ece_aesgcm_needs_trailer(uint32_t rs, size_t ciphertextLen) {
  return !(ciphertextLen % rs);
}

bool
ece_aes128gcm_needs_trailer(uint32_t rs, size_t ciphertextLen) {
  ECE_UNUSED(rs);
  ECE_UNUSED(ciphertextLen);
  return false;
}
