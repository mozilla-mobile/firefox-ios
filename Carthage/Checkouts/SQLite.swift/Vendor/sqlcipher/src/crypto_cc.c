/*
** SQLCipher
** http://sqlcipher.net
**
** Copyright (c) 2008 - 2013, ZETETIC LLC
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**     * Redistributions of source code must retain the above copyright
**       notice, this list of conditions and the following disclaimer.
**     * Redistributions in binary form must reproduce the above copyright
**       notice, this list of conditions and the following disclaimer in the
**       documentation and/or other materials provided with the distribution.
**     * Neither the name of the ZETETIC LLC nor the
**       names of its contributors may be used to endorse or promote products
**       derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY ZETETIC LLC ''AS IS'' AND ANY
** EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
** WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL ZETETIC LLC BE LIABLE FOR ANY
** DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
** (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
** LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
** ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
** SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
*/
/* BEGIN SQLCIPHER */
#ifdef SQLITE_HAS_CODEC
#ifdef SQLCIPHER_CRYPTO_CC
#include "crypto.h"
#include "sqlcipher.h"
#include <CommonCrypto/CommonCrypto.h>
#include <Security/SecRandom.h>

static int sqlcipher_cc_add_random(void *ctx, void *buffer, int length) {
  return SQLITE_OK;
}

/* generate a defined number of random bytes */
static int sqlcipher_cc_random (void *ctx, void *buffer, int length) {
  return (SecRandomCopyBytes(kSecRandomDefault, length, (uint8_t *)buffer) == 0) ? SQLITE_OK : SQLITE_ERROR;
}

static const char* sqlcipher_cc_get_provider_name(void *ctx) {
  return "commoncrypto";
}

static int sqlcipher_cc_hmac(void *ctx, unsigned char *hmac_key, int key_sz, unsigned char *in, int in_sz, unsigned char *in2, int in2_sz, unsigned char *out) {
  CCHmacContext hmac_context;
  CCHmacInit(&hmac_context, kCCHmacAlgSHA1, hmac_key, key_sz);
  CCHmacUpdate(&hmac_context, in, in_sz);
  CCHmacUpdate(&hmac_context, in2, in2_sz);
  CCHmacFinal(&hmac_context, out);
  return SQLITE_OK; 
}

static int sqlcipher_cc_kdf(void *ctx, const unsigned char *pass, int pass_sz, unsigned char* salt, int salt_sz, int workfactor, int key_sz, unsigned char *key) {
  CCKeyDerivationPBKDF(kCCPBKDF2, (const char *)pass, pass_sz, salt, salt_sz, kCCPRFHmacAlgSHA1, workfactor, key, key_sz);
  return SQLITE_OK; 
}

static int sqlcipher_cc_cipher(void *ctx, int mode, unsigned char *key, int key_sz, unsigned char *iv, unsigned char *in, int in_sz, unsigned char *out) {
  CCCryptorRef cryptor;
  size_t tmp_csz, csz;
  CCOperation op = mode == CIPHER_ENCRYPT ? kCCEncrypt : kCCDecrypt;

  CCCryptorCreate(op, kCCAlgorithmAES128, 0, key, kCCKeySizeAES256, iv, &cryptor);
  CCCryptorUpdate(cryptor, in, in_sz, out, in_sz, &tmp_csz);
  csz = tmp_csz;
  out += tmp_csz;
  CCCryptorFinal(cryptor, out, in_sz - csz, &tmp_csz);
  csz += tmp_csz;
  CCCryptorRelease(cryptor);
  assert(size == csz);

  return SQLITE_OK; 
}

static int sqlcipher_cc_set_cipher(void *ctx, const char *cipher_name) {
  return SQLITE_OK;
}

static const char* sqlcipher_cc_get_cipher(void *ctx) {
  return "aes-256-cbc";
}

static int sqlcipher_cc_get_key_sz(void *ctx) {
  return kCCKeySizeAES256;
}

static int sqlcipher_cc_get_iv_sz(void *ctx) {
  return kCCBlockSizeAES128;
}

static int sqlcipher_cc_get_block_sz(void *ctx) {
  return kCCBlockSizeAES128;
}

static int sqlcipher_cc_get_hmac_sz(void *ctx) {
  return CC_SHA1_DIGEST_LENGTH;
}

static int sqlcipher_cc_ctx_copy(void *target_ctx, void *source_ctx) {
  return SQLITE_OK;
}

static int sqlcipher_cc_ctx_cmp(void *c1, void *c2) {
  return 1; /* always indicate contexts are the same */
}

static int sqlcipher_cc_ctx_init(void **ctx) {
  return SQLITE_OK;
}

static int sqlcipher_cc_ctx_free(void **ctx) {
  return SQLITE_OK;
}

static int sqlcipher_cc_fips_status(void *ctx) {
  return 0;
}

int sqlcipher_cc_setup(sqlcipher_provider *p) {
  p->random = sqlcipher_cc_random;
  p->get_provider_name = sqlcipher_cc_get_provider_name;
  p->hmac = sqlcipher_cc_hmac;
  p->kdf = sqlcipher_cc_kdf;
  p->cipher = sqlcipher_cc_cipher;
  p->set_cipher = sqlcipher_cc_set_cipher;
  p->get_cipher = sqlcipher_cc_get_cipher;
  p->get_key_sz = sqlcipher_cc_get_key_sz;
  p->get_iv_sz = sqlcipher_cc_get_iv_sz;
  p->get_block_sz = sqlcipher_cc_get_block_sz;
  p->get_hmac_sz = sqlcipher_cc_get_hmac_sz;
  p->ctx_copy = sqlcipher_cc_ctx_copy;
  p->ctx_cmp = sqlcipher_cc_ctx_cmp;
  p->ctx_init = sqlcipher_cc_ctx_init;
  p->ctx_free = sqlcipher_cc_ctx_free;
  p->add_random = sqlcipher_cc_add_random;
  p->fips_status = sqlcipher_cc_fips_status;
  return SQLITE_OK;
}

#endif
#endif
/* END SQLCIPHER */
