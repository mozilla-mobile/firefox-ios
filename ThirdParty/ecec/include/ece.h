#ifndef ECE_H
#define ECE_H
#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define ECE_SALT_LENGTH 16
#define ECE_WEBPUSH_PRIVATE_KEY_LENGTH 32
#define ECE_WEBPUSH_PUBLIC_KEY_LENGTH 65
#define ECE_WEBPUSH_AUTH_SECRET_LENGTH 16

#define ECE_AES128GCM_MIN_RS 18
#define ECE_AES128GCM_HEADER_LENGTH 21
#define ECE_AES128GCM_MAX_KEY_ID_LENGTH 255

#define ECE_OK 0
#define ECE_ERROR_OUT_OF_MEMORY -1
#define ECE_ERROR_INVALID_PRIVATE_KEY -2
#define ECE_ERROR_INVALID_PUBLIC_KEY -3
#define ECE_ERROR_COMPUTE_SECRET -4
#define ECE_ERROR_ENCODE_PUBLIC_KEY -5
#define ECE_ERROR_DECRYPT -6
#define ECE_ERROR_DECRYPT_PADDING -7
#define ECE_ERROR_ZERO_PLAINTEXT -8
#define ECE_ERROR_SHORT_BLOCK -9
#define ECE_ERROR_SHORT_HEADER -10
#define ECE_ERROR_ZERO_CIPHERTEXT -11
#define ECE_ERROR_HKDF -12
#define ECE_ERROR_INVALID_ENCRYPTION_HEADER -13
#define ECE_ERROR_INVALID_CRYPTO_KEY_HEADER -14
#define ECE_ERROR_INVALID_RS -15
#define ECE_ERROR_INVALID_SALT -16
#define ECE_ERROR_INVALID_DH -17
#define ECE_ERROR_ENCRYPT -18
#define ECE_ERROR_ENCRYPT_PADDING -19
#define ECE_ERROR_INVALID_AUTH_SECRET -20
#define ECE_ERROR_GENERATE_KEYS -21

// Annotates a variable or parameter as unused to avoid compiler warnings.
#define ECE_UNUSED(x) (void) (x)

// The policy for handling trailing "=" characters in Base64url-encoded input.
typedef enum ece_base64url_decode_policy_e {
  // Fails decoding if the input is unpadded. RFC 4648, section 3.2 requires
  // padding, unless the referring specification prohibits it.
  ECE_BASE64URL_REQUIRE_PADDING,

  // Tolerates padded and unpadded input.
  ECE_BASE64URL_IGNORE_PADDING,

  // Fails decoding if the input is padded. This follows the strict Base64url
  // variant used in JWS (RFC 7515, Appendix C) and Web Push Message Encryption.
  ECE_BASE64URL_REJECT_PADDING,
} ece_base64url_decode_policy_t;

// Generate a public-private ECDH key pair and auth secret for a Web Push
// subscription.
int
ece_webpush_generate_keys(uint8_t* rawRecvPrivKey, size_t rawRecvPrivKeyLen,
                          uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
                          uint8_t* authSecret, size_t authSecretLen);

// Returns the maximum "aes128gcm" decrypted plaintext size, including room for
// padding. The caller should allocate and pass a buffer of this size as the
// `payload` argument to the "aes128gcm" decryption functions.
size_t
ece_aes128gcm_plaintext_max_length(const uint8_t* payload, size_t payloadLen);

// Decrypts a message encrypted with the "aes128gcm" scheme. `ikm` is the input
// keying material for the content encryption key and nonce.
int
ece_aes128gcm_decrypt(const uint8_t* ikm, size_t ikmLen, const uint8_t* payload,
                      size_t payloadLen, uint8_t* plaintext,
                      size_t* plaintextLen);

// Decrypts a Web Push message encrypted with the "aes128gcm" scheme.
int
ece_webpush_aes128gcm_decrypt(const uint8_t* rawRecvPrivKey,
                              size_t rawRecvPrivKeyLen,
                              const uint8_t* authSecret, size_t authSecretLen,
                              const uint8_t* payload, size_t payloadLen,
                              uint8_t* plaintext, size_t* plaintextLen);

// Returns the maximum encrypted "aes128gcm" payload size. The caller should
// allocate and pass a buffer of this size as the `payload` argument to
// `ece_aes128gcm_encrypt*`.
size_t
ece_aes128gcm_payload_max_length(uint32_t rs, size_t padLen,
                                 size_t plaintextLen);

// Encrypts `plaintext` with an ephemeral ECDH key pair and a random salt.
// Returns an error if encryption fails, or if `payload` is not large enough
// to hold the encrypted payload.
int
ece_aes128gcm_encrypt(const uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
                      const uint8_t* authSecret, size_t authSecretLen,
                      uint32_t rs, size_t padLen, const uint8_t* plaintext,
                      size_t plaintextLen, uint8_t* payload,
                      size_t* payloadLen);

// Encrypts `plaintext` with the given sender private key, receiver public key,
// salt, record size, and pad length. `ece_aes128gcm_encrypt` is sufficient for
// most uses.
int
ece_aes128gcm_encrypt_with_keys(
  const uint8_t* rawSenderPrivKey, size_t rawSenderPrivKeyLen,
  const uint8_t* authSecret, size_t authSecretLen, const uint8_t* salt,
  size_t saltLen, const uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
  uint32_t rs, size_t padLen, const uint8_t* plaintext, size_t plaintextLen,
  uint8_t* payload, size_t* payloadLen);

// Returns the maximum "aesgcm" decrypted plaintext size. The caller should
// allocate and pass a buffer of this size as the `payload` argument to the
// "aesgcm" decryption functions.
size_t
ece_aesgcm_plaintext_max_length(size_t ciphertextLen);

// Decrypts a payload encrypted with the "aesgcm" scheme.
int
ece_webpush_aesgcm_decrypt(const uint8_t* rawRecvPrivKey,
                           size_t rawRecvPrivKeyLen, const uint8_t* authSecret,
                           size_t authSecretLen, const char* cryptoKeyHeader,
                           const char* encryptionHeader,
                           const uint8_t* ciphertext, size_t ciphertextLen,
                           uint8_t* plaintext, size_t* plaintextLen);

// Extracts the salt, record size, ephemeral public key, and ciphertext from a
// payload encrypted with the "aes128gcm" scheme.
int
ece_aes128gcm_payload_extract_params(const uint8_t* payload, size_t payloadLen,
                                     const uint8_t** salt, size_t* saltLen,
                                     const uint8_t** keyId, size_t* keyIdLen,
                                     uint32_t* rs, const uint8_t** ciphertext,
                                     size_t* ciphertextLen);

// Extracts the ephemeral public key, salt, and record size from the sender's
// `Crypto-Key` and `Encryption` headers. Returns an error if the header values
// are missing or invalid, or if `saltLen` or `rawSenderPubKeyLen` are not
// large enough to hold the Base64url-decoded `salt` and `dh` pair values.
int
ece_webpush_aesgcm_headers_extract_params(const char* cryptoKeyHeader,
                                          const char* encryptionHeader,
                                          uint8_t* salt, size_t saltLen,
                                          uint8_t* rawSenderPubKey,
                                          size_t rawSenderPubKeyLen,
                                          uint32_t* rs);

// Decodes a Base64url-encoded (RFC 4648) string. If `decoded` is `NULL` and
// `decodedLen` is 0, returns the minimum size of the buffer required to hold
// the decoded output. If `base64Len` is 0, `base64` contains invalid
// characters, or `decodedLen` is not large enough to hold the output, returns
// 0. Otherwise, returns the actual decoded size.
size_t
ece_base64url_decode(const char* base64, size_t base64Len,
                     ece_base64url_decode_policy_t paddingPolicy,
                     uint8_t* decoded, size_t decodedLen);

#ifdef __cplusplus
}
#endif
#endif /* ECE_H */
