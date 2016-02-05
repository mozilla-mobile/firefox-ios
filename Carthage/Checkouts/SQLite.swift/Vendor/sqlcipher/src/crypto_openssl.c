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
#ifdef SQLCIPHER_CRYPTO_OPENSSL
#include "sqliteInt.h"
#include "crypto.h"
#include "sqlcipher.h"
#include <openssl/rand.h>
#include <openssl/evp.h>
#include <openssl/hmac.h>

typedef struct {
  EVP_CIPHER *evp_cipher;
} openssl_ctx;

static unsigned int openssl_external_init = 0;
static unsigned int openssl_init_count = 0;
static sqlite3_mutex* openssl_rand_mutex = NULL;

static int sqlcipher_openssl_add_random(void *ctx, void *buffer, int length) {
#ifndef SQLCIPHER_OPENSSL_NO_MUTEX_RAND
  sqlite3_mutex_enter(openssl_rand_mutex);
#endif
  RAND_add(buffer, length, 0);
#ifndef SQLCIPHER_OPENSSL_NO_MUTEX_RAND
  sqlite3_mutex_leave(openssl_rand_mutex);
#endif
  return SQLITE_OK;
}

/* activate and initialize sqlcipher. Most importantly, this will automatically
   intialize OpenSSL's EVP system if it hasn't already be externally. Note that 
   this function may be called multiple times as new codecs are intiialized. 
   Thus it performs some basic counting to ensure that only the last and final
   sqlcipher_openssl_deactivate() will free the EVP structures. 
*/
static int sqlcipher_openssl_activate(void *ctx) {
  /* initialize openssl and increment the internal init counter
     but only if it hasn't been initalized outside of SQLCipher by this program 
     e.g. on startup */
  sqlite3_mutex_enter(sqlite3_mutex_alloc(SQLITE_MUTEX_STATIC_MASTER));

  if(openssl_init_count == 0 && EVP_get_cipherbyname(CIPHER) != NULL) {
    /* if openssl has not yet been initialized by this library, but 
       a call to get_cipherbyname works, then the openssl library
       has been initialized externally already. */
    openssl_external_init = 1;
  }

#ifdef SQLCIPHER_FIPS
  if(!FIPS_mode()){
    if(!FIPS_mode_set(1)){
      ERR_load_crypto_strings();
      ERR_print_errors_fp(stderr);
    }
  }
#endif

  if(openssl_init_count == 0 && openssl_external_init == 0)  {
    /* if the library was not externally initialized, then should be now */
    OpenSSL_add_all_algorithms();
  } 

#ifndef SQLCIPHER_OPENSSL_NO_MUTEX_RAND
  if(openssl_rand_mutex == NULL) {
    /* allocate a mutex to guard against concurrent calls to RAND_bytes() */
    openssl_rand_mutex = sqlite3_mutex_alloc(SQLITE_MUTEX_FAST);
  }
#endif

  openssl_init_count++; 
  sqlite3_mutex_leave(sqlite3_mutex_alloc(SQLITE_MUTEX_STATIC_MASTER));
  return SQLITE_OK;
}

/* deactivate SQLCipher, most imporantly decremeting the activation count and
   freeing the EVP structures on the final deactivation to ensure that 
   OpenSSL memory is cleaned up */
static int sqlcipher_openssl_deactivate(void *ctx) {
  sqlite3_mutex_enter(sqlite3_mutex_alloc(SQLITE_MUTEX_STATIC_MASTER));
  openssl_init_count--;

  if(openssl_init_count == 0) {
    if(openssl_external_init == 0) {
    /* if OpenSSL hasn't be initialized externally, and the counter reaches zero 
       after it's decremented, release EVP memory
       Note: this code will only be reached if OpensSSL_add_all_algorithms()
       is called by SQLCipher internally. This should prevent SQLCipher from 
       "cleaning up" openssl when it was initialized externally by the program */
      EVP_cleanup();
    }
#ifndef SQLCIPHER_OPENSSL_NO_MUTEX_RAND
    sqlite3_mutex_free(openssl_rand_mutex);
    openssl_rand_mutex = NULL;
#endif
  }
  sqlite3_mutex_leave(sqlite3_mutex_alloc(SQLITE_MUTEX_STATIC_MASTER));
  return SQLITE_OK;
}

static const char* sqlcipher_openssl_get_provider_name(void *ctx) {
  return "openssl";
}

/* generate a defined number of random bytes */
static int sqlcipher_openssl_random (void *ctx, void *buffer, int length) {
  int rc = 0;
  /* concurrent calls to RAND_bytes can cause a crash under some openssl versions when a 
     naive application doesn't use CRYPTO_set_locking_callback and
     CRYPTO_THREADID_set_callback to ensure openssl thread safety. 
     This is simple workaround to prevent this common crash
     but a more proper solution is that applications setup platform-appropriate
     thread saftey in openssl externally */
#ifndef SQLCIPHER_OPENSSL_NO_MUTEX_RAND
  sqlite3_mutex_enter(openssl_rand_mutex);
#endif
  rc = RAND_bytes((unsigned char *)buffer, length);
#ifndef SQLCIPHER_OPENSSL_NO_MUTEX_RAND
  sqlite3_mutex_leave(openssl_rand_mutex);
#endif
  return (rc == 1) ? SQLITE_OK : SQLITE_ERROR;
}

static int sqlcipher_openssl_hmac(void *ctx, unsigned char *hmac_key, int key_sz, unsigned char *in, int in_sz, unsigned char *in2, int in2_sz, unsigned char *out) {
  HMAC_CTX hctx;
  unsigned int outlen;
  HMAC_CTX_init(&hctx);
  HMAC_Init_ex(&hctx, hmac_key, key_sz, EVP_sha1(), NULL);
  HMAC_Update(&hctx, in, in_sz);
  HMAC_Update(&hctx, in2, in2_sz);
  HMAC_Final(&hctx, out, &outlen);
  HMAC_CTX_cleanup(&hctx);
  return SQLITE_OK; 
}

static int sqlcipher_openssl_kdf(void *ctx, const unsigned char *pass, int pass_sz, unsigned char* salt, int salt_sz, int workfactor, int key_sz, unsigned char *key) {
  PKCS5_PBKDF2_HMAC_SHA1((const char *)pass, pass_sz, salt, salt_sz, workfactor, key_sz, key);
  return SQLITE_OK; 
}

static int sqlcipher_openssl_cipher(void *ctx, int mode, unsigned char *key, int key_sz, unsigned char *iv, unsigned char *in, int in_sz, unsigned char *out) {
  EVP_CIPHER_CTX ectx;
  int tmp_csz, csz;
 
  EVP_CipherInit(&ectx, ((openssl_ctx *)ctx)->evp_cipher, NULL, NULL, mode);
  EVP_CIPHER_CTX_set_padding(&ectx, 0); // no padding
  EVP_CipherInit(&ectx, NULL, key, iv, mode);
  EVP_CipherUpdate(&ectx, out, &tmp_csz, in, in_sz);
  csz = tmp_csz;  
  out += tmp_csz;
  EVP_CipherFinal(&ectx, out, &tmp_csz);
  csz += tmp_csz;
  EVP_CIPHER_CTX_cleanup(&ectx);
  assert(in_sz == csz);
  return SQLITE_OK; 
}

static int sqlcipher_openssl_set_cipher(void *ctx, const char *cipher_name) {
  openssl_ctx *o_ctx = (openssl_ctx *)ctx;
  EVP_CIPHER* cipher = (EVP_CIPHER *) EVP_get_cipherbyname(cipher_name);
  if(cipher != NULL) {
    o_ctx->evp_cipher = cipher;
  }
  return cipher != NULL ? SQLITE_OK : SQLITE_ERROR;
}

static const char* sqlcipher_openssl_get_cipher(void *ctx) {
  return EVP_CIPHER_name(((openssl_ctx *)ctx)->evp_cipher);
}

static int sqlcipher_openssl_get_key_sz(void *ctx) {
  return EVP_CIPHER_key_length(((openssl_ctx *)ctx)->evp_cipher);
}

static int sqlcipher_openssl_get_iv_sz(void *ctx) {
  return EVP_CIPHER_iv_length(((openssl_ctx *)ctx)->evp_cipher);
}

static int sqlcipher_openssl_get_block_sz(void *ctx) {
  return EVP_CIPHER_block_size(((openssl_ctx *)ctx)->evp_cipher);
}

static int sqlcipher_openssl_get_hmac_sz(void *ctx) {
  return EVP_MD_size(EVP_sha1());
}

static int sqlcipher_openssl_ctx_copy(void *target_ctx, void *source_ctx) {
  memcpy(target_ctx, source_ctx, sizeof(openssl_ctx));
  return SQLITE_OK;
}

static int sqlcipher_openssl_ctx_cmp(void *c1, void *c2) {
  return ((openssl_ctx *)c1)->evp_cipher == ((openssl_ctx *)c2)->evp_cipher;
}

static int sqlcipher_openssl_ctx_init(void **ctx) {
  *ctx = sqlcipher_malloc(sizeof(openssl_ctx));
  if(*ctx == NULL) return SQLITE_NOMEM;
  sqlcipher_openssl_activate(*ctx);
  return SQLITE_OK;
}

static int sqlcipher_openssl_ctx_free(void **ctx) {
  sqlcipher_openssl_deactivate(*ctx);
  sqlcipher_free(*ctx, sizeof(openssl_ctx));
  return SQLITE_OK;
}

static int sqlcipher_openssl_fips_status(void *ctx) {
#ifdef SQLCIPHER_FIPS  
  return FIPS_mode();
#else
  return 0;
#endif
}

int sqlcipher_openssl_setup(sqlcipher_provider *p) {
  p->activate = sqlcipher_openssl_activate;  
  p->deactivate = sqlcipher_openssl_deactivate;
  p->get_provider_name = sqlcipher_openssl_get_provider_name;
  p->random = sqlcipher_openssl_random;
  p->hmac = sqlcipher_openssl_hmac;
  p->kdf = sqlcipher_openssl_kdf;
  p->cipher = sqlcipher_openssl_cipher;
  p->set_cipher = sqlcipher_openssl_set_cipher;
  p->get_cipher = sqlcipher_openssl_get_cipher;
  p->get_key_sz = sqlcipher_openssl_get_key_sz;
  p->get_iv_sz = sqlcipher_openssl_get_iv_sz;
  p->get_block_sz = sqlcipher_openssl_get_block_sz;
  p->get_hmac_sz = sqlcipher_openssl_get_hmac_sz;
  p->ctx_copy = sqlcipher_openssl_ctx_copy;
  p->ctx_cmp = sqlcipher_openssl_ctx_cmp;
  p->ctx_init = sqlcipher_openssl_ctx_init;
  p->ctx_free = sqlcipher_openssl_ctx_free;
  p->add_random = sqlcipher_openssl_add_random;
  p->fips_status = sqlcipher_openssl_fips_status;
  return SQLITE_OK;
}

#endif
#endif
/* END SQLCIPHER */
