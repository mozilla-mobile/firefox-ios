#ifndef ECE_H
#define ECE_H
#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define ECE_SALT_LENGTH 16
#define ECE_TAG_LENGTH 16
#define ECE_WEBPUSH_PRIVATE_KEY_LENGTH 32
#define ECE_WEBPUSH_PUBLIC_KEY_LENGTH 65
#define ECE_WEBPUSH_AUTH_SECRET_LENGTH 16

#define ECE_AES128GCM_MIN_RS 18
#define ECE_AES128GCM_HEADER_LENGTH 21
#define ECE_AES128GCM_MAX_KEY_ID_LENGTH 255
#define ECE_AES128GCM_PAD_SIZE 1

#define ECE_AESGCM_MIN_RS 3
#define ECE_AESGCM_PAD_SIZE 2

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
#define ECE_ERROR_DECRYPT_TRUNCATED -22

// Annotates a variable or parameter as unused to avoid compiler warnings.
#define ECE_UNUSED(x) (void) (x)

/*!
 * The policy for appending trailing "=" characters to Base64url-encoded output.
 */
typedef enum ece_base64url_encode_policy_e {
  /*! Omits padding, even if the input is not a multiple of 4. */
  ECE_BASE64URL_OMIT_PADDING,

  /*! Includes padding if the input is not a multiple of 4. */
  ECE_BASE64URL_INCLUDE_PADDING,
} ece_base64url_encode_policy_t;

/*!
 * The policy for handling trailing "=" characters in Base64url-encoded input.
 */
typedef enum ece_base64url_decode_policy_e {
  /*!
   * Fails decoding if the input is unpadded. RFC 4648, section 3.2 requires
   * padding, unless the referring specification prohibits it.
   */
  ECE_BASE64URL_REQUIRE_PADDING,

  /*! Tolerates padded and unpadded input. */
  ECE_BASE64URL_IGNORE_PADDING,

  /*!
   * Fails decoding if the input is padded. This follows the strict Base64url
   * variant used in JWS (RFC 7515, Appendix C) and
   * draft-ietf-httpbis-encryption-encoding-03. */
  ECE_BASE64URL_REJECT_PADDING,
} ece_base64url_decode_policy_t;

/*!
 * Generates a public-private ECDH key pair and authentication secret for a Web
 * Push subscription.
 *
 * \sa                          ece_webpush_aes128gcm_decrypt(),
 *                              ece_webpush_aesgcm_decrypt()
 *
 * \param rawRecvPrivKey[in]    The subscription private key. This key should
 *                              be stored locally, and used to decrypt incoming
 *                              messages.
 * \param rawRecvPrivKeyLen[in] The length of the subscription private key. Must
 *                              be `ECE_WEBPUSH_PRIVATE_KEY_LENGTH`.
 * \param rawRecvPubKey[in]     The subscription public key, in uncompressed
 *                              form. This key should be shared with the app
 *                              server, and used to encrypt outgoing messages.
 * \param rawRecvPubKeyLen[in]  The length of the subscription public key. Must
 *                              be `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param authSecret[in]        The authentication secret. This secret should
 *                              be stored locally and shared with the app
 *                              server. It's used to derive the content
 *                              encryption key and nonce.
 * \param authSecretLen[in]     The length of the authentication secret. Must
 *                              be `ECE_WEBPUSH_AUTH_SECRET_LENGTH`.
 *
 * \return                      `ECE_OK` on success, or an error code if key
 *                              generation fails.
 */
int
ece_webpush_generate_keys(uint8_t* rawRecvPrivKey, size_t rawRecvPrivKeyLen,
                          uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
                          uint8_t* authSecret, size_t authSecretLen);

/*!
 * Calculates the maximum "aes128gcm" plaintext length. The caller should
 * allocate and pass an array of this length to the "aes128gcm" decryption
 * functions.
 *
 * \sa                   ece_aes128gcm_decrypt(),
 *                       ece_webpush_aes128gcm_decrypt()
 *
 * \param payload[in]    The encrypted payload.
 * \param payloadLen[in] The length of the encrypted payload.
 *
 * \return               The maximum plaintext length, or 0 if the payload
 *                       header is truncated or invalid.
 */
size_t
ece_aes128gcm_plaintext_max_length(const uint8_t* payload, size_t payloadLen);

/*!
 * Decrypts a message encrypted using the "aes128gcm" scheme, with a symmetric
 * key. The key is shared out of band, and identified by the `keyId` parameter
 * in the payload header.
 *
 * \sa                          ece_aes128gcm_plaintext_max_length(),
 *                              ece_aes128gcm_payload_extract_params()
 *
 * \param ikm[in]               The input keying material (IKM) for the content
 *                              encryption key and nonce.
 * \param ikmLen[in]            The length of the IKM.
 * \param payload[in]           The encrypted payload.
 * \param payloadLen[in]        The length of the encrypted payload.
 * \param plaintext[in]         An empty array. Must be large enough to hold the
 *                              full plaintext.
 * \param plaintextLen[in,out]  The input is the length of the empty `plaintext`
 *                              array. On success, the output is set to the
 *                              actual plaintext length, and
 *                              `[0..plaintextLen]` contains the plaintext.
 *
 * \return                      `ECE_OK` on success, or an error code if
 *                              the payload is empty or malformed.
 */
int
ece_aes128gcm_decrypt(const uint8_t* ikm, size_t ikmLen, const uint8_t* payload,
                      size_t payloadLen, uint8_t* plaintext,
                      size_t* plaintextLen);

/*!
 * Decrypts a Web Push message encrypted using the "aes128gcm" scheme.
 *
 * \sa                          ece_aes128gcm_plaintext_max_length()
 *
 * \param rawRecvPrivKey[in]    The subscription private key.
 * \param rawRecvPrivKeyLen[in] The length of the subscription private key. Must
 *                              be `ECE_WEBPUSH_PRIVATE_KEY_LENGTH`.
 * \param authSecret[in]        The authentication secret.
 * \param authSecretLen[in]     The length of the authentication secret. Must be
 *                              `ECE_WEBPUSH_AUTH_SECRET_LENGTH`.
 * \param payload[in]           The encrypted payload.
 * \param payloadLen[in]        The length of the encrypted payload.
 * \param plaintext[in]         An empty array. Must be large enough to hold the
 *                              full plaintext.
 * \param plaintextLen[in,out]  The input is the length of the empty `plaintext`
 *                              array. On success, the output is set to the
 *                              the actual plaintext length, and
 *                              `[0..plaintextLen]` contains the plaintext.
 *
 * \return                      `ECE_OK` on success, or an error code if
 *                              the payload is empty or malformed.
 */
int
ece_webpush_aes128gcm_decrypt(const uint8_t* rawRecvPrivKey,
                              size_t rawRecvPrivKeyLen,
                              const uint8_t* authSecret, size_t authSecretLen,
                              const uint8_t* payload, size_t payloadLen,
                              uint8_t* plaintext, size_t* plaintextLen);

/*!
 * Calculates the maximum "aes128gcm" encrypted payload length. The caller
 * should allocate and pass an array of this length to the "aes128gcm"
 * encryption functions.
 *
 * \param rs[in]           The record size. This is the length of each encrypted
 *                         plaintext chunk, including room for the padding
 *                         delimiter and GCM authentication tag. Must be at
 *                         least `ECE_AES128GCM_MIN_RS`.
 * \param padLen[in]       The length of additional padding, used to hide the
 *                         plaintext length. Padding is added to the plaintext
 *                         during encryption, and discarded during decryption.
 * \param plaintextLen[in] The length of the plaintext.
 *
 * \return                 The maximum payload length, or 0 if `rs` is too
 *                         small.
 */
size_t
ece_aes128gcm_payload_max_length(uint32_t rs, size_t padLen,
                                 size_t plaintextLen);

/*!
 * Encrypts a Web Push message using the "aes128gcm" scheme. This function
 * automatically generates an ephemeral ECDH key pair and a random salt.
 *
 * \sa                         ece_aes128gcm_payload_max_length()
 *
 * \param rawRecvPubKey[in]    The subscription public key, in uncompressed
 *                             form.
 * \param rawRecvPubKeyLen[in] The length of the subscription public key. Must
 *                             be `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param authSecret[in]       The authentication secret.
 * \param authSecretLen[in]    The length of the authentication secret. Must be
 *                             `ECE_WEBPUSH_AUTH_SECRET_LENGTH`.
 * \param rs[in]               The record size. Must be at least
 *                             `ECE_AES128GCM_MIN_RS`.
 * \param padLen[in]           The length of additional padding to include in
 *                             the ciphertext, if any.
 * \param plaintext[in]        The plaintext to encrypt.
 * \param plaintextLen[in]     The length of the plaintext.
 * \param payload[in]          An empty array. Must be large enough to hold the
 *                             full payload.
 * \param payloadLen[in,out]   The input is the length of the empty `payload`
 *                             array. On success, the output is set to the
 *                             actual payload length, and
 *                             `payload[0..payloadLen]` contains the payload.
 *
 * \return                     `ECE_OK` on success, or an error code if
 *                             encryption fails.
 */
int
ece_webpush_aes128gcm_encrypt(const uint8_t* rawRecvPubKey,
                              size_t rawRecvPubKeyLen,
                              const uint8_t* authSecret, size_t authSecretLen,
                              uint32_t rs, size_t padLen,
                              const uint8_t* plaintext, size_t plaintextLen,
                              uint8_t* payload, size_t* payloadLen);

/*!
 * Encrypts a Web Push message using the "aes128gcm" scheme, with an explicit
 * sender key and salt. The sender key can be reused, but the salt *must* be
 * unique to avoid deriving the same content encryption key for multiple
 * messages.
 *
 * \warning                       In general, you should only use this function
 *                                for testing. `ece_webpush_aes128gcm_encrypt`
 *                                is safer because it doesn't risk accidental
 *                                salt reuse.
 *
 * \sa                            ece_aes128gcm_payload_max_length(),
 *                                ece_webpush_aes128gcm_encrypt()
 *
 * \param rawSenderPrivKey[in]    The sender private key.
 * \param rawSenderPrivKeyLen[in] The length of the sender private key. Must be
 *                                `ECE_WEBPUSH_PRIVATE_KEY_LENGTH`.
 * \param authSecret[in]          The authentication secret.
 * \param authSecretLen[in]       The length of the authentication secret. Must
 *                                be `ECE_WEBPUSH_AUTH_SECRET_LENGTH`.
 * \param salt[in]                The encryption salt.
 * \param saltLen[in]             The length of the salt. Must be
 *                                `ECE_SALT_LENGTH`.
 * \param rawRecvPubKey[in]       The subscription public key, in uncompressed
 *                                form. Must be `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param rawRecvPubKeyLen[in]    The length of the subscription public key.
 * \param rs[in]                  The record size. Must be at least
 *                                `ECE_AES128GCM_MIN_RS`.
 * \param padLen[in]              The length of additional padding to include in
 *                                the ciphertext, if any.
 * \param plaintext[in]           The plaintext to encrypt.
 * \param plaintextLen[in]        The length of the plaintext.
 * \param payload[in]             An empty array. Must be large enough to hold
 *                                the full payload.
 * \param payloadLen[in,out]      The input is the length of the empty `payload`
 *                                array. On success, the output is set to the
 *                                actual payload length, and
 *                                `payload[0..payloadLen]` contains the payload.
 *
 * \return                        `ECE_OK` on success, or an error code if
 *                                encryption fails.
 */
int
ece_webpush_aes128gcm_encrypt_with_keys(
  const uint8_t* rawSenderPrivKey, size_t rawSenderPrivKeyLen,
  const uint8_t* authSecret, size_t authSecretLen, const uint8_t* salt,
  size_t saltLen, const uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
  uint32_t rs, size_t padLen, const uint8_t* plaintext, size_t plaintextLen,
  uint8_t* payload, size_t* payloadLen);

/*!
 * Calculates the maximum "aesgcm" ciphertext length. The caller should allocate
 * and pass an array of this length to `ece_webpush_aesgcm_encrypt_with_keys`.
 *
 * \param rs[in]           The record size. Must be least `ECE_AESGCM_MIN_RS`.
 * \param padLen[in]       The length of additional padding.
 * \param plaintextLen[in] The length of the plaintext.
 *
 * \return                 The maximum ciphertext length, or 0 if `rs` is too
 *                         small.
 */
size_t
ece_aesgcm_ciphertext_max_length(uint32_t rs, size_t padLen,
                                 size_t plaintextLen);

/*!
 * Encrypts a Web Push message using the "aesgcm" scheme. Like
 * `ece_webpush_aes128gcm_encrypt`, this function generates a sender key pair
 * and salt.
 *
 * \sa                           ece_aesgcm_ciphertext_max_length()
 *
 * \param rawRecvPubKey[in]      The subscription public key, in uncompressed
 *                               form.
 * \param rawRecvPubKeyLen[in]   The length of the subscription public key. Must
 *                               be `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param authSecret[in]         The authentication secret.
 * \param authSecretLen[in]      The length of the authentication secret. Must
 *                               be `ECE_WEBPUSH_AUTH_SECRET_LENGTH`.
 * \param rs[in]                 The record size. Must be at least
 *                               `ECE_AES128GCM_MIN_RS`.
 * \param padLen[in]             The length of additional padding to include in
 *                               the ciphertext, if any.
 * \param plaintext[in]          The plaintext to encrypt.
 * \param plaintextLen[in]       The length of the plaintext.
 * \param salt[in]               An empty array to hold the salt.
 * \param saltLen[in]            The length of the empty `salt` array. Must be
 *                               `ECE_SALT_LENGTH`.
 * \param rawSenderPubKey[in]    An empty array to hold the sender public key.
 * \param rawSenderPubKeyLen[in] The length of the empty `rawSenderPubKey`
 *                               array. Must be `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param ciphertext[in]         An empty array to hold the ciphertext.
 * \param ciphertextLen[in, out] The input is the length of the empty
 *                               `ciphertext` array. On success, the output is
 *                               set to the actual ciphertext length, and
 *                               `ciphertext[0..ciphertextLen]` contains the
 *                               ciphertext.
 *
 * \return                       `ECE_OK` on success, or an error code if
 *                               encryption fails.
 */
int
ece_webpush_aesgcm_encrypt(const uint8_t* rawRecvPubKey,
                           size_t rawRecvPubKeyLen, const uint8_t* authSecret,
                           size_t authSecretLen, uint32_t rs, size_t padLen,
                           const uint8_t* plaintext, size_t plaintextLen,
                           uint8_t* salt, size_t saltLen,
                           uint8_t* rawSenderPubKey, size_t rawSenderPubKeyLen,
                           uint8_t* ciphertext, size_t* ciphertextLen);

/*!
 * Encrypts a Web Push message using the "aesgcm" scheme and explicit keys.
 *
 * \warning                       `ece_webpush_aesgcm_encrypt` is safer because
 *                                it doesn't risk accidental salt reuse.
 *
 * \sa                            ece_aesgcm_ciphertext_max_length(),
 *                                ece_webpush_aesgcm_encrypt()
 *
 * \param rawSenderPrivKey[in]    The sender private key.
 * \param rawSenderPrivKeyLen[in] The length of the sender private key. Must be
 *                                `ECE_WEBPUSH_PRIVATE_KEY_LENGTH`.
 * \param authSecret[in]          The authentication secret.
 * \param authSecretLen[in]       The length of the authentication secret. Must
 *                                be `ECE_WEBPUSH_AUTH_SECRET_LENGTH`.
 * \param salt[in]                The encryption salt.
 * \param saltLen[in]             The length of the salt. Must be
 *                                `ECE_SALT_LENGTH`.
 * \param rawRecvPubKey[in]       The subscription public key, in uncompressed
 *                                form. Must be `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param rawRecvPubKeyLen[in]    The length of the subscription public key.
 * \param rs[in]                  The record size. Must be at least
 *                                `ECE_AES128GCM_MIN_RS`.
 * \param padLen[in]              The length of additional padding to include in
 *                                the ciphertext, if any.
 * \param plaintext[in]           The plaintext to encrypt.
 * \param plaintextLen[in]        The length of the plaintext.
 * \param ciphertext[in]          An empty array. Must be large enough to hold
 *                                the full ciphertext.
 * \param ciphertextLen[in,out]   The input is the length of the empty
 *                                `ciphertext` array. On success, the output is
 *                                set to the actual ciphertext length, and
 *                                `ciphertext[0..ciphertextLen]` contains the
 *                                ciphertext.
 *
 * \return                        `ECE_OK` on success, or an error code if
 *                                encryption fails.
 */
int
ece_webpush_aesgcm_encrypt_with_keys(
  const uint8_t* rawSenderPrivKey, size_t rawSenderPrivKeyLen,
  const uint8_t* authSecret, size_t authSecretLen, const uint8_t* salt,
  size_t saltLen, const uint8_t* rawRecvPubKey, size_t rawRecvPubKeyLen,
  uint32_t rs, size_t padLen, const uint8_t* plaintext, size_t plaintextLen,
  uint8_t* ciphertext, size_t* ciphertextLen);

/*!
 * Calculates the maximum "aesgcm" plaintext length. The caller should allocate
 * and pass an array of this length to `ece_webpush_aesgcm_decrypt`.
 *
 * \sa                      ece_webpush_aesgcm_decrypt()
 *
 * \param rs[in]            The record size. Must be at least
 *                          `ECE_AESGCM_MIN_RS`.
 * \param ciphertextLen[in] The ciphertext length.
 *
 * \return                  The maximum plaintext length.
 */
size_t
ece_aesgcm_plaintext_max_length(uint32_t rs, size_t ciphertextLen);

/*!
 * Decrypts a Web Push message encrypted using the "aesgcm" scheme.
 *
 * \sa                           ece_aesgcm_plaintext_max_length()
 *
 * \param rawRecvPrivKey[in]     The subscription private key.
 * \param rawRecvPrivKeyLen[in]  The length of the subscription private key.
 *                               Must be `ECE_WEBPUSH_PRIVATE_KEY_LENGTH`.
 * \param authSecret[in]         The authentication secret.
 * \param authSecretLen[in]      The length of the authentication secret. Must
 *                               be `ECE_WEBPUSH_AUTH_SECRET_LENGTH`.
 * \param salt[in]
 * \param salt[in]               The salt, from the `Encryption` header.
 * \param saltLen[in]            The length of the salt. Must be
 *                               `ECE_SALT_LENGTH`.
 * \param rawSenderPubKey[in]    The sender public key, in uncompressed form,
 *                               from the `Crypto-Key` header.
 * \param rawSenderPubKeyLen[in] The length of the sender public key. Must be
 *                               `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param rs[in]                 The record size. Must be at least
 *                               `ECE_AESGCM_MIN_RS`.
 * \param ciphertext[in]         The ciphertext.
 * \param ciphertextLen[in]      The length of the ciphertext.
 * \param plaintext[in]          An empty array. Must be large enough to hold
 *                               the full plaintext.
 * \param plaintextLen[in,out]   The input is the length of the empty
 *                               `plaintext` array. On success, the output is
 *                               set to the actual plaintext length, and
 *                               `[0..plaintextLen]` contains the plaintext.
 *
 * \return                       `ECE_OK` on success, or an error code if the
 *                               headers or ciphertext are malformed.
 */
int
ece_webpush_aesgcm_decrypt(const uint8_t* rawRecvPrivKey,
                           size_t rawRecvPrivKeyLen, const uint8_t* authSecret,
                           size_t authSecretLen, const uint8_t* salt,
                           size_t saltLen, const uint8_t* rawSenderPubKey,
                           size_t rawSenderPubKeyLen, uint32_t rs,
                           const uint8_t* ciphertext, size_t ciphertextLen,
                           uint8_t* plaintext, size_t* plaintextLen);

/*!
 * Extracts "aes128gcm" decryption parameters from an encrypted payload.
 * `salt`, `keyId`, and `ciphertext` are pointers into `payload`, and must not
 * outlive it.
 *
 * \sa                       ece_aes128gcm_decrypt()
 *
 * \param payload[in]        The encrypted payload.
 * \param payloadLen[in]     The length of the encrypted payload.
 * \param salt[out]          The encryption salt.
 * \param saltLen[out]       The length of the salt.
 * \param keyId[out]         An identifier for the keying material.
 * \param keyIdLen[out]      The length of the key ID.
 * \param rs[out]            The record size.
 * \param ciphertext[out]    The ciphertext.
 * \param ciphertextLen[out] The length of the ciphertext.
 *
 * \return                   `ECE_OK` on success, or an error code if the
 *                           payload header is truncated or invalid.
 */
int
ece_aes128gcm_payload_extract_params(const uint8_t* payload, size_t payloadLen,
                                     const uint8_t** salt, size_t* saltLen,
                                     const uint8_t** keyId, size_t* keyIdLen,
                                     uint32_t* rs, const uint8_t** ciphertext,
                                     size_t* ciphertextLen);

/*!
 * Extracts "aesgcm" decryption parameters from the `Crypto-Key` and
 * `Encryption` headers.
 *
 * \sa                           ece_webpush_aesgcm_decrypt(),
 *                               ece_webpush_aesgcm_headers_from_params()
 *
 * \param cryptoKeyHeader[in]    The value of the `Crypto-Key` HTTP header.
 * \param encryptionHeader[in]   The value of the `Encryption` HTTP header.
 * \param salt[in]               An empty array to hold the encryption salt,
 *                               extracted from the `Encryption` header.
 * \param saltLen[in]            The length of the empty `salt` array. Must be
 *                               `ECE_SALT_LENGTH`.
 * \param rawSenderPubKey[in]    An empty array to hold the sender public key,
 *                               in uncompressed form, extracted from the
 *                               `Crypto-Key` header.
 * \param rawSenderPubKeyLen[in] The length of the empty `rawSenderPubKey`
 *                               array. Must be `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param rs[out]                The record size.
 *
 * \return                       `ECE_OK` on success, or an error code if the
 *                               headers are malformed.
 */
int
ece_webpush_aesgcm_headers_extract_params(const char* cryptoKeyHeader,
                                          const char* encryptionHeader,
                                          uint8_t* salt, size_t saltLen,
                                          uint8_t* rawSenderPubKey,
                                          size_t rawSenderPubKeyLen,
                                          uint32_t* rs);

/*!
 * Builds the `Crypto-Key` and `Encryption` headers from the "aesgcm"
 * encryption parameters.
 *
 * \sa                               ece_webpush_aesgcm_encrypt_with_keys(),
 *                                   ece_webpush_aesgcm_headers_extract_params()
 *
 * \param salt[in]                     The encryption salt, to include in the
 *                                     `Encryption` header.
 * \param saltLen[in]                  The length of the salt. Must be
 *                                     `ECE_SALT_LENGTH`.
 * \param rawSenderPubKey[in]          The sender public key, in uncompressed
 *                                     form, to include in the `Crypto-Key`
 *                                     header.
 * \param rawSenderPubKeyLen[in]       The length of the sender public key. Must
 *                                     be `ECE_WEBPUSH_PUBLIC_KEY_LENGTH`.
 * \param rs[in]                       The record size, to include in the
 *                                     `Encryption` header.
 * \param cryptoKeyHeader[in]          An empty array to hold the `Crypto-Key`
 *                                     header. May be `NULL` if
 *                                     `cryptoKeyHeaderLen` is 0. The header is
 *                                     *not* null-terminated; you'll need to add
 *                                     a trailing `'\0'` if you want to treat
 *                                     `cryptoKeyHeader` as a C string.
 * \param cryptoKeyHeaderLen[in, out]  The input is the length of the empty
 *                                     `cryptoKeyHeader` array. If 0, the output
 *                                     is set to the length required to hold
 *                                     the result. On success,
 *                                     `[0..cryptoKeyHeaderLen]` contains the
 *                                     header.
 * \param encryptionHeader[in]         An empty array to hold the `Encryption`
 *                                     header. May be `NULL` if
 *                                     `encryptionHeaderLen` is 0. Like
 *                                     `cryptoKeyHeader`, this header is not
 *                                     null-terminated.
 * \param encryptionHeaderLen[in, out] The input is the length of the empty
 *                                     `encryptionHeader` array. If 0, the
 *                                     output is set to the length required to
 *                                     hold the result. On success,
 *                                     `[0..encryptionHeaderLen]` contains the
 *                                     header.
 *
 * \return                             `ECE_OK` on success, or an error code if
 *                                     `cryptoKeyHeaderLen` or
 *                                     `encryptionHeaderLen` is too small.
 */
int
ece_webpush_aesgcm_headers_from_params(const void* salt, size_t saltLen,
                                       const void* rawSenderPubKey,
                                       size_t rawSenderPubKeyLen, uint32_t rs,
                                       char* cryptoKeyHeader,
                                       size_t* cryptoKeyHeaderLen,
                                       char* encryptionHeader,
                                       size_t* encryptionHeaderLen);

/*!
 * Converts a byte array to a Base64url-encoded (RFC 4648) string.
 *
 * \param binary[in]        The byte array to encode.
 * \param binaryLen[in]     The length of the byte array.
 * \param paddingPolicy[in] The policy for padding the encoded output.
 * \param base64[in]        An empty array to hold the encoded result. May be
 *                          `NULL` if `base64Len` is 0. This function does
 *                          *not* null-terminate `base64`. This makes it easier
 *                          to include Base64url-encoded substrings in larger
 *                          strings, but means you'll need to add a trailing
 *                          `'\0'` if you want to treat `base64` as a C string.
 * \param base64Len[in]     The length of the empty `base64` array. On success,
 *                          `base64[0..base64Len]` contains the result.
 *
 * \return                  The encoded length. If `binaryLen` is 0, returns the
 *                          length of the array required to hold the result. If
 *                          `binaryLen` is not large enough to hold the full
 *                          result, returns 0.
 */
size_t
ece_base64url_encode(const void* binary, size_t binaryLen,
                     ece_base64url_encode_policy_t paddingPolicy, char* base64,
                     size_t base64Len);

/*!
 * Decodes a Base64url-encoded (RFC 4648) string.
 *
 * \param base64[in]        The encoded string.
 * \param base64Len[in]     The length of the encoded string.
 * \param paddingPolicy[in] The policy for handling "=" padding in the encoded
 *                          input.
 * \param binary[in]        An empty array to hold the decoded result. May be
 *                          `NULL` if `binaryLen` is 0.
 * \param binaryLen[in]     The length of the empty `binary` array. On success,
 *                          `binary[0..binaryLen]` contains the result.
 *
 * \return                  The actual decoded length. If `binaryLen` is 0,
 *                          returns the length of the array
 *                          required to hold the result. If `base64` contains
 *                          invalid characters, or `binaryLen` is not large
 *                          enough to hold the full result, returns 0.
 */
size_t
ece_base64url_decode(const char* base64, size_t base64Len,
                     ece_base64url_decode_policy_t paddingPolicy,
                     uint8_t* binary, size_t binaryLen);

#ifdef __cplusplus
}
#endif
#endif /* ECE_H */
