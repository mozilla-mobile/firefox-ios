#ifndef ECE_KEYS_H
#define ECE_KEYS_H
#ifdef __cplusplus
extern "C" {
#endif

#include "ece.h"

#include <openssl/ec.h>

#define ECE_AES_KEY_LENGTH 16
#define ECE_NONCE_LENGTH 12
#define ECE_TAG_LENGTH 16

#define ECE_WEBPUSH_IKM_LENGTH 32

// HKDF info strings for the "aes128gcm" scheme. Note that the lengths include
// the NUL terminator.
#define ECE_WEBPUSH_AES128GCM_IKM_INFO_PREFIX "WebPush: info\0"
#define ECE_WEBPUSH_AES128GCM_IKM_INFO_PREFIX_LENGTH 14
#define ECE_WEBPUSH_AES128GCM_IKM_INFO_LENGTH 144

#define ECE_AES128GCM_KEY_INFO "Content-Encoding: aes128gcm\0"
#define ECE_AES128GCM_KEY_INFO_LENGTH 28
#define ECE_AES128GCM_NONCE_INFO "Content-Encoding: nonce\0"
#define ECE_AES128GCM_NONCE_INFO_LENGTH 24

// HKDF info strings for the "aesgcm" scheme.
#define ECE_WEBPUSH_AESGCM_IKM_INFO "Content-Encoding: auth\0"
#define ECE_WEBPUSH_AESGCM_IKM_INFO_LENGTH 23
#define ECE_WEBPUSH_AESGCM_KEY_INFO_PREFIX "Content-Encoding: aesgcm\0P-256\0"
#define ECE_WEBPUSH_AESGCM_KEY_INFO_PREFIX_LENGTH 31
#define ECE_WEBPUSH_AESGCM_KEY_INFO_LENGTH 165
#define ECE_WEBPUSH_AESGCM_NONCE_INFO_PREFIX "Content-Encoding: nonce\0P-256\0"
#define ECE_WEBPUSH_AESGCM_NONCE_INFO_PREFIX_LENGTH 30
#define ECE_WEBPUSH_AESGCM_NONCE_INFO_LENGTH 164

// Key derivation modes.
typedef enum ece_mode_e {
  ECE_MODE_ENCRYPT,
  ECE_MODE_DECRYPT,
} ece_mode_t;

typedef int (*derive_key_and_nonce_t)(ece_mode_t mode, EC_KEY* localKey,
                                      EC_KEY* remoteKey,
                                      const uint8_t* authSecret,
                                      size_t authSecretLen, const uint8_t* salt,
                                      size_t saltLen, uint8_t* key,
                                      uint8_t* nonce);

// Generates a 96-bit IV for decryption, 48 bits of which are populated.
void
ece_generate_iv(const uint8_t* nonce, uint64_t counter, uint8_t* iv);

// Inflates a raw ECDH private key into an OpenSSL `EC_KEY` containing a
// private and public key pair. Returns `NULL` on error.
EC_KEY*
ece_import_private_key(const uint8_t* rawKey, size_t rawKeyLen);

// Inflates a raw ECDH public key into an `EC_KEY` containing a public key.
// Returns `NULL` on error.
EC_KEY*
ece_import_public_key(const uint8_t* rawKey, size_t rawKeyLen);

// Derives the "aes128gcm" content encryption key and nonce.
int
ece_aes128gcm_derive_key_and_nonce(const uint8_t* salt, size_t saltLen,
                                   const uint8_t* ikm, size_t ikmLen,
                                   uint8_t* key, uint8_t* nonce);

// Derives the "aes128gcm" decryption key and nonce given the receiver private
// key, sender public key, authentication secret, and sender salt.
int
ece_webpush_aes128gcm_derive_key_and_nonce(ece_mode_t mode, EC_KEY* localKey,
                                           EC_KEY* remoteKey,
                                           const uint8_t* authSecret,
                                           size_t authSecretLen,
                                           const uint8_t* salt, size_t saltLen,
                                           uint8_t* key, uint8_t* nonce);

// Derives the "aesgcm" decryption key and nonce given the receiver private key,
// sender public key, authentication secret, and sender salt.
int
ece_webpush_aesgcm_derive_key_and_nonce(ece_mode_t mode, EC_KEY* recvPrivKey,
                                        EC_KEY* senderPubKey,
                                        const uint8_t* authSecret,
                                        size_t authSecretLen,
                                        const uint8_t* salt, size_t saltLen,
                                        uint8_t* key, uint8_t* nonce);

#ifdef __cplusplus
}
#endif
#endif /* ECE_KEYS_H */
