/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

#include <openssl/ec.h>
#include <openssl/ecdh.h>
#include <openssl/evp.h>

#define ECE_HEADER_SIZE 21
#define ECE_TAG_LENGTH 16
#define ECE_KEY_LENGTH 16
#define ECE_NONCE_LENGTH 12
#define ECE_SHA_256_LENGTH 32

// HKDF info strings for the shared secret, encryption key, and nonce. Note
// that the length includes the NUL terminator.
#define ECE_WEB_PUSH_INFO_PREFIX "WebPush: info\0"
#define ECE_WEB_PUSH_INFO_PREFIX_LENGTH 14
#define ECE_KEY_INFO "Content-Encoding: aes128gcm\0"
#define ECE_KEY_INFO_LENGTH 28
#define ECE_NONCE_INFO "Content-Encoding: nonce\0"
#define ECE_NONCE_INFO_LENGTH 24

#define ECE_OK 0
#define ECE_ERROR_OUT_OF_MEMORY -1
#define ECE_INVALID_RECEIVER_PRIVATE_KEY -2
#define ECE_INVALID_SENDER_PUBLIC_KEY -3
#define ECE_ERROR_COMPUTE_SECRET -4
#define ECE_ERROR_ENCODE_RECEIVER_PUBLIC_KEY -5
#define ECE_ERROR_ENCODE_SENDER_PUBLIC_KEY -6
#define ECE_ERROR_DECRYPT -7
#define ECE_ERROR_DECRYPT_PADDING -8
#define ECE_ERROR_ZERO_PLAINTEXT -9
#define ECE_ERROR_SHORT_BLOCK -10
#define ECE_ERROR_SHORT_HEADER -11
#define ECE_ERROR_ZERO_CIPHERTEXT -12
#define ECE_ERROR_NULL_POINTER -13
#define ECE_ERROR_HKDF -14

// Extracts an unsigned 32-bit integer in network byte order.
static inline uint32_t
ece_read_uint32_be(uint8_t* bytes) {
    return bytes[3] | (bytes[2] << 8) | (bytes[1] << 16) | (bytes[0] << 24);
}

// Extracts an unsigned 48-bit integer in network byte order.
static inline uint64_t
ece_read_uint48_be(uint8_t* bytes) {
    return bytes[5] | (bytes[4] << 8) | (bytes[3] << 16) |
    ((uint64_t) bytes[2] << 24) | ((uint64_t) bytes[1] << 32) |
    ((uint64_t) bytes[0] << 40);
}

// Writes an unsigned 48-bit integer in network byte order.
static inline void
ece_write_uint48_be(uint8_t* bytes, uint64_t value) {
    bytes[0] = (value >> 40) & 0xff;
    bytes[1] = (value >> 32) & 0xff;
    bytes[2] = (value >> 24) & 0xff;
    bytes[3] = (value >> 16) & 0xff;
    bytes[4] = (value >> 8) & 0xff;
    bytes[5] = value & 0xff;
}


// Inflates a raw ECDH private key into an OpenSSL `EC_KEY` containing the
// receiver's private and public keys. Returns `NULL` on error.
static EC_KEY*
ece_import_receiver_private_key(const NSData* rawKey) {
    EC_KEY* key = NULL;
    EC_POINT* pubKeyPt = NULL;

    key = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
    if (!key) {
        goto error;
    }
    if (EC_KEY_oct2priv(key, rawKey.bytes, rawKey.length) <= 0) {
        goto error;
    }
    const EC_GROUP* group = EC_KEY_get0_group(key);
    if (!group) {
        goto error;
    }
    pubKeyPt = EC_POINT_new(group);
    if (!pubKeyPt) {
        goto error;
    }
    const BIGNUM* privKey = EC_KEY_get0_private_key(key);
    if (!privKey) {
        goto error;
    }
    if (EC_POINT_mul(group, pubKeyPt, privKey, NULL, NULL, NULL) <= 0) {
        goto error;
    }
    if (EC_KEY_set_public_key(key, pubKeyPt) <= 0) {
        goto error;
    }
    goto end;

error:
    EC_KEY_free(key);
    key = NULL;

end:
    EC_POINT_free(pubKeyPt);
    return key;
}

// Inflates a raw ECDH public key into an `EC_KEY` containing the sender's
// public key. Returns `NULL` on error.
static EC_KEY*
ece_import_sender_public_key(NSData* rawKey) {
    EC_KEY* key = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
    if (!key) {
        return NULL;
    }
    if (!EC_KEY_oct2key(key, rawKey.bytes, rawKey.length, NULL)) {
        EC_KEY_free(key);
        return NULL;
    }
    return key;
}


@implementation NSData (Push)

- (NSData*) generateIVFromNonce: (NSData*) aNonce andCounter: (UInt64) counter {
    // Generates a 96-bit IV for decryption, 48 bits of which are populated.
    unsigned char* iv = malloc(ECE_NONCE_LENGTH);
    unsigned char* nonce = aNonce.bytes;

    // Copy the first 4 bytes as-is, since `(x ^ 0) == x`.
    size_t offset = ECE_NONCE_LENGTH - 6;
    memcpy(iv, self.bytes, offset);
    // Combine the remaining 6 bytes (an unsigned 48-bit integer) with the
    // record sequence number using XOR. See the "nonce derivation" section
    // of the draft.
    uint64_t mask = ece_read_uint48_be(&nonce[offset]);
    ece_write_uint48_be(&iv[offset], mask ^ counter);

    return [NSData dataWithBytesNoCopy: iv length: ECE_NONCE_LENGTH freeWhenDone: YES];
}

- (NSData*) gcmDecipher: (NSData*) cipherText withKey: (NSData*) key andIV: (NSData*) iv {
    int err = ECE_OK;

    NSData* record = cipherText;
    unsigned char *block = malloc(record.length);

    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        err = ECE_ERROR_OUT_OF_MEMORY;
        goto end;
    }

    if (EVP_DecryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, key.bytes, iv.bytes) <= 0) {
        err = ECE_ERROR_DECRYPT;
        goto end;
    }
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, ECE_TAG_LENGTH,
                            &record.bytes[record.length - ECE_TAG_LENGTH]) <= 0) {
        err = ECE_ERROR_DECRYPT;
        goto end;
    }
    int blockLength = 0;
    if (EVP_DecryptUpdate(ctx, block->bytes, &blockLength, record.bytes,
                          record.length - ECE_TAG_LENGTH) <= 0 ||
        blockLength < 0) {
        err = ECE_ERROR_DECRYPT;
        goto end;
    }
    int finalLength = 0;
    if (EVP_DecryptFinal_ex(ctx, &block->bytes[blockLength], &finalLength) <= 0 ||
        finalLength < 0) {
        err = ECE_ERROR_DECRYPT;
        goto end;
    }
    // For simplicity, we allocate a buffer equal to the encrypted record size,
    // even though the decrypted block size will be smaller.
    block->length = blockLength + finalLength;

    // Remove trailing padding.
    if (!block->length) {
        err = ECE_ERROR_ZERO_PLAINTEXT;
        goto end;
    }
    while (block->length > 0) {
        block->length--;
        if (!block->bytes[block->length]) {
            continue;
        }
        uint8_t recordPad = isLastRecord ? 2 : 1;
        if (block->bytes[block->length] != recordPad) {
            // Last record needs to start padding with a 2; preceding records need
            // to start padding with a 1.
            err = ECE_ERROR_DECRYPT_PADDING;
            goto end;
        }
        goto end;
    }

    // All zero plaintext.
    err = ECE_ERROR_ZERO_PLAINTEXT;

    return [NSData dataWithBytesNoCopy: bytes length: finalLength freeWhenDone: YES];

end:
    EVP_CIPHER_CTX_cleanup(ctx);
    return nil;
}

- (NSData*) ecdh_computeSharedSecret: (NSData *) publicKey {
    int err = ECE_OK;

    // Import the raw receiver private key and sender public key.
    EC_KEY* recvPrivKey = ece_import_receiver_private_key(publicKey);
    if (!recvPrivKey) {
        err = ECE_INVALID_RECEIVER_PRIVATE_KEY;
        goto end;
    }

    EC_KEY* senderPubKey = ece_import_sender_public_key(rawSenderPubKey);
    if (!senderPubKey) {
        err = ECE_INVALID_SENDER_PUBLIC_KEY;
        goto end;
    }

    const EC_POINT* senderPubKeyPt = EC_KEY_get0_public_key(senderPubKey);
    if (!senderPubKeyPt) {
        err = ECE_INVALID_SENDER_PUBLIC_KEY;
        goto end;
    }

    const EC_GROUP* recvGroup = EC_KEY_get0_group(recvPrivKey);
    if (!recvGroup) {
        err = ECE_INVALID_RECEIVER_PRIVATE_KEY;
        goto end;
    }


    // Compute the shared secret, used as the input key material (IKM) for
    // HKDF.
    int fieldSize = EC_GROUP_get_degree(recvGroup);
    if (fieldSize <= 0) {
        err = ECE_ERROR_COMPUTE_SECRET;
        goto end;
    }
    if (!ece_buf_alloc(&ikm, (fieldSize + 7) / 8)) {
        err = ECE_ERROR_OUT_OF_MEMORY;
        goto end;
    }

    NSMutableData* ikm = [NSMutableData alloc];

    if (ECDH_compute_key(ikm.bytes, ikm.length, senderPubKeyPt, recvPrivKey,
                         NULL) <= 0) {
        err = ECE_ERROR_COMPUTE_SECRET;
        goto end;
    }
    
end:
    return nil;
    
}

@end
