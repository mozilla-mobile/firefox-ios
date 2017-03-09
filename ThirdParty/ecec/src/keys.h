#ifndef ECE_KEYS_H
#define ECE_KEYS_H
#ifdef __cplusplus
extern "C" {
#endif

#include "ece.h"

#include <openssl/ec.h>

// Generates a 96-bit IV for decryption, 48 bits of which are populated.
void
ece_generate_iv(uint8_t* nonce, uint64_t counter, uint8_t* iv);

// Inflates a raw ECDH private key into an OpenSSL `EC_KEY` containing a
// private and public key pair. Returns `NULL` on error.
EC_KEY*
ece_import_private_key(const ece_buf_t* rawKey);

// Inflates a raw ECDH public key into an `EC_KEY` containing a public key.
// Returns `NULL` on error.
EC_KEY*
ece_import_public_key(const ece_buf_t* rawKey);

// Derives the "aes128gcm" decryption key and nonce given the receiver private
// key, sender public key, authentication secret, and sender salt.
int
ece_aes128gcm_derive_key_and_nonce(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                                   const ece_buf_t* authSecret,
                                   const ece_buf_t* salt, ece_buf_t* key,
                                   ece_buf_t* nonce);

// Derives the "aesgcm" decryption key and nonce given the receiver private key,
// sender public key, authentication secret, and sender salt.
int
ece_aesgcm_derive_key_and_nonce(EC_KEY* recvPrivKey, EC_KEY* senderPubKey,
                                const ece_buf_t* authSecret,
                                const ece_buf_t* salt, ece_buf_t* key,
                                ece_buf_t* nonce);

#ifdef __cplusplus
}
#endif
#endif /* ECE_KEYS_H */
