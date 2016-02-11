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
#ifdef SQLCIPHER_CRYPTO_LIBTOMCRYPT
#include "sqliteInt.h"
#include "sqlcipher.h"
#include <tomcrypt.h>

#define FORTUNA_MAX_SZ 32
static prng_state prng;
static unsigned int ltc_init = 0;
static unsigned int ltc_ref_count = 0;
static sqlite3_mutex* ltc_rand_mutex = NULL;

static int sqlcipher_ltc_add_random(void *ctx, void *buffer, int length) {
  int rc = 0;
  int data_to_read = length;
  int block_sz = data_to_read < FORTUNA_MAX_SZ ? data_to_read : FORTUNA_MAX_SZ;
  const unsigned char * data = (const unsigned char *)buffer;
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
  sqlite3_mutex_enter(ltc_rand_mutex);
#endif
    while(data_to_read > 0){
      rc = fortuna_add_entropy(data, block_sz, &prng);
      rc = rc != CRYPT_OK ? SQLITE_ERROR : SQLITE_OK;
      if(rc != SQLITE_OK){
        break;
      }
      data_to_read -= block_sz;
      data += block_sz;
      block_sz = data_to_read < FORTUNA_MAX_SZ ? data_to_read : FORTUNA_MAX_SZ;
    }
    fortuna_ready(&prng);
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
  sqlite3_mutex_leave(ltc_rand_mutex);
#endif
  return rc;
}

static int sqlcipher_ltc_activate(void *ctx) {
  unsigned char random_buffer[FORTUNA_MAX_SZ];
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
  if(ltc_rand_mutex == NULL){
    ltc_rand_mutex = sqlite3_mutex_alloc(SQLITE_MUTEX_FAST);
  }
  sqlite3_mutex_enter(ltc_rand_mutex);
#endif
  sqlcipher_memset(random_buffer, 0, FORTUNA_MAX_SZ);
  if(ltc_init == 0) {
    if(register_prng(&fortuna_desc) != CRYPT_OK) return SQLITE_ERROR;
    if(register_cipher(&rijndael_desc) != CRYPT_OK) return SQLITE_ERROR;
    if(register_hash(&sha1_desc) != CRYPT_OK) return SQLITE_ERROR;
    if(fortuna_start(&prng) != CRYPT_OK) {
      return SQLITE_ERROR;
    }
    ltc_init = 1;
  }
  ltc_ref_count++;
#ifndef SQLCIPHER_TEST
  sqlite3_randomness(FORTUNA_MAX_SZ, random_buffer);
#endif
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
  sqlite3_mutex_leave(ltc_rand_mutex);
#endif
  if(sqlcipher_ltc_add_random(ctx, random_buffer, FORTUNA_MAX_SZ) != SQLITE_OK) {
    return SQLITE_ERROR;
  }
  sqlcipher_memset(random_buffer, 0, FORTUNA_MAX_SZ);
  return SQLITE_OK;
}

static int sqlcipher_ltc_deactivate(void *ctx) {
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
  sqlite3_mutex_enter(ltc_rand_mutex);
#endif
  ltc_ref_count--;
  if(ltc_ref_count == 0){
    fortuna_done(&prng);
    sqlcipher_memset((void *)&prng, 0, sizeof(prng));
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
    sqlite3_mutex_leave(ltc_rand_mutex);
    sqlite3_mutex_free(ltc_rand_mutex);
    ltc_rand_mutex = NULL;
#endif
  }
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
  else {
    sqlite3_mutex_leave(ltc_rand_mutex);
  }
#endif    
  return SQLITE_OK;
}

static const char* sqlcipher_ltc_get_provider_name(void *ctx) {
  return "libtomcrypt";
}

static int sqlcipher_ltc_random(void *ctx, void *buffer, int length) {
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
  sqlite3_mutex_enter(ltc_rand_mutex);
#endif
  fortuna_read(buffer, length, &prng);
#ifndef SQLCIPHER_LTC_NO_MUTEX_RAND
  sqlite3_mutex_leave(ltc_rand_mutex);
#endif
  return SQLITE_OK;
}

static int sqlcipher_ltc_hmac(void *ctx, unsigned char *hmac_key, int key_sz, unsigned char *in, int in_sz, unsigned char *in2, int in2_sz, unsigned char *out) {
  int rc, hash_idx;
  hmac_state hmac;
  unsigned long outlen = key_sz;

  hash_idx = find_hash("sha1");
  if((rc = hmac_init(&hmac, hash_idx, hmac_key, key_sz)) != CRYPT_OK) return SQLITE_ERROR;
  if((rc = hmac_process(&hmac, in, in_sz)) != CRYPT_OK) return SQLITE_ERROR;
  if((rc = hmac_process(&hmac, in2, in2_sz)) != CRYPT_OK) return SQLITE_ERROR;
  if((rc = hmac_done(&hmac, out, &outlen)) != CRYPT_OK) return SQLITE_ERROR;
  return SQLITE_OK;
}

static int sqlcipher_ltc_kdf(void *ctx, const unsigned char *pass, int pass_sz, unsigned char* salt, int salt_sz, int workfactor, int key_sz, unsigned char *key) {
  int rc, hash_idx;
  unsigned long outlen = key_sz;
  unsigned long random_buffer_sz = sizeof(char) * 256;
  unsigned char *random_buffer = sqlcipher_malloc(random_buffer_sz);
  sqlcipher_memset(random_buffer, 0, random_buffer_sz);

  hash_idx = find_hash("sha1");
  if((rc = pkcs_5_alg2(pass, pass_sz, salt, salt_sz,
                       workfactor, hash_idx, key, &outlen)) != CRYPT_OK) {
    return SQLITE_ERROR;
  }
  if((rc = pkcs_5_alg2(key, key_sz, salt, salt_sz,
                       1, hash_idx, random_buffer, &random_buffer_sz)) != CRYPT_OK) {
    return SQLITE_ERROR;
  }
  sqlcipher_ltc_add_random(ctx, random_buffer, random_buffer_sz);
  sqlcipher_free(random_buffer, random_buffer_sz);
  return SQLITE_OK;
}

static const char* sqlcipher_ltc_get_cipher(void *ctx) {
  return "rijndael";
}

static int sqlcipher_ltc_cipher(void *ctx, int mode, unsigned char *key, int key_sz, unsigned char *iv, unsigned char *in, int in_sz, unsigned char *out) {
  int rc, cipher_idx;
  symmetric_CBC cbc;

  if((cipher_idx = find_cipher(sqlcipher_ltc_get_cipher(ctx))) == -1) return SQLITE_ERROR;
  if((rc = cbc_start(cipher_idx, iv, key, key_sz, 0, &cbc)) != CRYPT_OK) return SQLITE_ERROR;
  rc = mode == 1 ? cbc_encrypt(in, out, in_sz, &cbc) : cbc_decrypt(in, out, in_sz, &cbc);
  if(rc != CRYPT_OK) return SQLITE_ERROR;
  cbc_done(&cbc);
  return SQLITE_OK;
}

static int sqlcipher_ltc_set_cipher(void *ctx, const char *cipher_name) {
  return SQLITE_OK;
}

static int sqlcipher_ltc_get_key_sz(void *ctx) {
  int cipher_idx = find_cipher(sqlcipher_ltc_get_cipher(ctx));
  return cipher_descriptor[cipher_idx].max_key_length;
}

static int sqlcipher_ltc_get_iv_sz(void *ctx) {
  int cipher_idx = find_cipher(sqlcipher_ltc_get_cipher(ctx));
  return cipher_descriptor[cipher_idx].block_length;
}

static int sqlcipher_ltc_get_block_sz(void *ctx) {
  int cipher_idx = find_cipher(sqlcipher_ltc_get_cipher(ctx));
  return cipher_descriptor[cipher_idx].block_length;
}

static int sqlcipher_ltc_get_hmac_sz(void *ctx) {
  int hash_idx = find_hash("sha1");
  return hash_descriptor[hash_idx].hashsize;
}

static int sqlcipher_ltc_ctx_copy(void *target_ctx, void *source_ctx) {
  return SQLITE_OK;
}

static int sqlcipher_ltc_ctx_cmp(void *c1, void *c2) {
  return 1;
}

static int sqlcipher_ltc_ctx_init(void **ctx) {
  sqlcipher_ltc_activate(NULL);
  return SQLITE_OK;
}

static int sqlcipher_ltc_ctx_free(void **ctx) {
  sqlcipher_ltc_deactivate(&ctx);
  return SQLITE_OK;
}

static int sqlcipher_ltc_fips_status(void *ctx) {
  return 0;
}

int sqlcipher_ltc_setup(sqlcipher_provider *p) {
  p->activate = sqlcipher_ltc_activate;
  p->deactivate = sqlcipher_ltc_deactivate;
  p->get_provider_name = sqlcipher_ltc_get_provider_name;
  p->random = sqlcipher_ltc_random;
  p->hmac = sqlcipher_ltc_hmac;
  p->kdf = sqlcipher_ltc_kdf;
  p->cipher = sqlcipher_ltc_cipher;
  p->set_cipher = sqlcipher_ltc_set_cipher;
  p->get_cipher = sqlcipher_ltc_get_cipher;
  p->get_key_sz = sqlcipher_ltc_get_key_sz;
  p->get_iv_sz = sqlcipher_ltc_get_iv_sz;
  p->get_block_sz = sqlcipher_ltc_get_block_sz;
  p->get_hmac_sz = sqlcipher_ltc_get_hmac_sz;
  p->ctx_copy = sqlcipher_ltc_ctx_copy;
  p->ctx_cmp = sqlcipher_ltc_ctx_cmp;
  p->ctx_init = sqlcipher_ltc_ctx_init;
  p->ctx_free = sqlcipher_ltc_ctx_free;
  p->add_random = sqlcipher_ltc_add_random;
  p->fips_status = sqlcipher_ltc_fips_status;
  return SQLITE_OK;
}

#endif
#endif
/* END SQLCIPHER */
