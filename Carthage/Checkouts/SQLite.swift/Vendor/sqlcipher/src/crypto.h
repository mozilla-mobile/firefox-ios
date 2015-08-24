/* 
** SQLCipher
** crypto.h developed by Stephen Lombardo (Zetetic LLC) 
** sjlombardo at zetetic dot net
** http://zetetic.net
** 
** Copyright (c) 2008, ZETETIC LLC
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
#ifndef CRYPTO_H
#define CRYPTO_H

#if !defined (SQLCIPHER_CRYPTO_CC) \
   && !defined (SQLCIPHER_CRYPTO_LIBTOMCRYPT) \
   && !defined (SQLCIPHER_CRYPTO_OPENSSL)
#define SQLCIPHER_CRYPTO_OPENSSL
#endif

#define FILE_HEADER_SZ 16

#ifndef CIPHER_VERSION
#ifdef SQLCIPHER_FIPS
#define CIPHER_VERSION "3.3.0 FIPS"
#else
#define CIPHER_VERSION "3.3.0"
#endif
#endif

#ifndef CIPHER
#define CIPHER "aes-256-cbc"
#endif

#define CIPHER_DECRYPT 0
#define CIPHER_ENCRYPT 1

#define CIPHER_READ_CTX 0
#define CIPHER_WRITE_CTX 1
#define CIPHER_READWRITE_CTX 2

#ifndef PBKDF2_ITER
#define PBKDF2_ITER 64000
#endif

/* possible flags for cipher_ctx->flags */
#define CIPHER_FLAG_HMAC          0x01
#define CIPHER_FLAG_LE_PGNO       0x02
#define CIPHER_FLAG_BE_PGNO       0x04

#ifndef DEFAULT_CIPHER_FLAGS
#define DEFAULT_CIPHER_FLAGS CIPHER_FLAG_HMAC | CIPHER_FLAG_LE_PGNO
#endif


/* by default, sqlcipher will use a reduced number of iterations to generate
   the HMAC key / or transform a raw cipher key 
   */
#ifndef FAST_PBKDF2_ITER
#define FAST_PBKDF2_ITER 2
#endif

/* this if a fixed random array that will be xor'd with the database salt to ensure that the
   salt passed to the HMAC key derivation function is not the same as that used to derive
   the encryption key. This can be overridden at compile time but it will make the resulting
   binary incompatible with the default builds when using HMAC. A future version of SQLcipher
   will likely allow this to be defined at runtime via pragma */ 
#ifndef HMAC_SALT_MASK
#define HMAC_SALT_MASK 0x3a
#endif

#ifndef CIPHER_MAX_IV_SZ
#define CIPHER_MAX_IV_SZ 16
#endif

#ifndef CIPHER_MAX_KEY_SZ
#define CIPHER_MAX_KEY_SZ 64
#endif


#ifdef CODEC_DEBUG
#define CODEC_TRACE(X)  {printf X;fflush(stdout);}
#else
#define CODEC_TRACE(X)
#endif

#ifdef CODEC_DEBUG_PAGEDATA
#define CODEC_HEXDUMP(DESC,BUFFER,LEN)  \
  { \
    int __pctr; \
    printf(DESC); \
    for(__pctr=0; __pctr < LEN; __pctr++) { \
      if(__pctr % 16 == 0) printf("\n%05x: ",__pctr); \
      printf("%02x ",((unsigned char*) BUFFER)[__pctr]); \
    } \
    printf("\n"); \
    fflush(stdout); \
  }
#else
#define CODEC_HEXDUMP(DESC,BUFFER,LEN)
#endif

/* extensions defined in pager.c */ 
void sqlite3pager_get_codec(Pager *pPager, void **ctx);
int sqlite3pager_is_mj_pgno(Pager *pPager, Pgno pgno);
sqlite3_file *sqlite3Pager_get_fd(Pager *pPager);
void sqlite3pager_sqlite3PagerSetCodec(
  Pager *pPager,
  void *(*xCodec)(void*,void*,Pgno,int),
  void (*xCodecSizeChng)(void*,int,int),
  void (*xCodecFree)(void*),
  void *pCodec
);
void sqlite3pager_sqlite3PagerSetError(Pager *pPager, int error);
/* end extensions defined in pager.c */
 
/*
**  Simple shared routines for converting hex char strings to binary data
 */
static int cipher_hex2int(char c) {
  return (c>='0' && c<='9') ? (c)-'0' :
         (c>='A' && c<='F') ? (c)-'A'+10 :
         (c>='a' && c<='f') ? (c)-'a'+10 : 0;
}

static void cipher_hex2bin(const unsigned char *hex, int sz, unsigned char *out){
  int i;
  for(i = 0; i < sz; i += 2){
    out[i/2] = (cipher_hex2int(hex[i])<<4) | cipher_hex2int(hex[i+1]);
  }
}

static void cipher_bin2hex(const unsigned char* in, int sz, char *out) {
    int i;
    for(i=0; i < sz; i++) {
      sqlite3_snprintf(3, out + (i*2), "%02x ", in[i]);
    } 
}

/* extensions defined in crypto_impl.c */
typedef struct codec_ctx codec_ctx;

/* activation and initialization */
void sqlcipher_activate();
void sqlcipher_deactivate();
int sqlcipher_codec_ctx_init(codec_ctx **, Db *, Pager *, sqlite3_file *, const void *, int);
void sqlcipher_codec_ctx_free(codec_ctx **);
int sqlcipher_codec_key_derive(codec_ctx *);
int sqlcipher_codec_key_copy(codec_ctx *, int);

/* page cipher implementation */
int sqlcipher_page_cipher(codec_ctx *, int, Pgno, int, int, unsigned char *, unsigned char *);

/* context setters & getters */
void sqlcipher_codec_ctx_set_error(codec_ctx *, int);

int sqlcipher_codec_ctx_set_pass(codec_ctx *, const void *, int, int);
void sqlcipher_codec_get_keyspec(codec_ctx *, void **zKey, int *nKey);

int sqlcipher_codec_ctx_set_pagesize(codec_ctx *, int);
int sqlcipher_codec_ctx_get_pagesize(codec_ctx *);
int sqlcipher_codec_ctx_get_reservesize(codec_ctx *);

void sqlcipher_set_default_pagesize(int page_size);
int sqlcipher_get_default_pagesize();

void sqlcipher_set_default_kdf_iter(int iter);
int sqlcipher_get_default_kdf_iter();

int sqlcipher_codec_ctx_set_kdf_iter(codec_ctx *, int, int);
int sqlcipher_codec_ctx_get_kdf_iter(codec_ctx *ctx, int);

void* sqlcipher_codec_ctx_get_kdf_salt(codec_ctx *ctx);

int sqlcipher_codec_ctx_set_fast_kdf_iter(codec_ctx *, int, int);
int sqlcipher_codec_ctx_get_fast_kdf_iter(codec_ctx *, int);

int sqlcipher_codec_ctx_set_cipher(codec_ctx *, const char *, int);
const char* sqlcipher_codec_ctx_get_cipher(codec_ctx *ctx, int for_ctx);

void* sqlcipher_codec_ctx_get_data(codec_ctx *);

void sqlcipher_exportFunc(sqlite3_context *, int, sqlite3_value **);

void sqlcipher_set_default_use_hmac(int use);
int sqlcipher_get_default_use_hmac();

void sqlcipher_set_hmac_salt_mask(unsigned char mask);
unsigned char sqlcipher_get_hmac_salt_mask();

int sqlcipher_codec_ctx_set_use_hmac(codec_ctx *ctx, int use);
int sqlcipher_codec_ctx_get_use_hmac(codec_ctx *ctx, int for_ctx);

int sqlcipher_codec_ctx_set_flag(codec_ctx *ctx, unsigned int flag);
int sqlcipher_codec_ctx_unset_flag(codec_ctx *ctx, unsigned int flag);
int sqlcipher_codec_ctx_get_flag(codec_ctx *ctx, unsigned int flag, int for_ctx);

const char* sqlcipher_codec_get_cipher_provider(codec_ctx *ctx);
int sqlcipher_codec_ctx_migrate(codec_ctx *ctx);
int sqlcipher_codec_add_random(codec_ctx *ctx, const char *data, int random_sz);
int sqlcipher_cipher_profile(sqlite3 *db, const char *destination);
static void sqlcipher_profile_callback(void *file, const char *sql, sqlite3_uint64 run_time);
static int sqlcipher_codec_get_store_pass(codec_ctx *ctx);
static void sqlcipher_codec_get_pass(codec_ctx *ctx, void **zKey, int *nKey);
static void sqlcipher_codec_set_store_pass(codec_ctx *ctx, int value);
int sqlcipher_codec_fips_status(codec_ctx *ctx);

#endif
#endif
/* END SQLCIPHER */
