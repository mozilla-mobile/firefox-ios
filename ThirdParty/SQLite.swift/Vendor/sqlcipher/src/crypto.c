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

#include <assert.h>
#include "sqliteInt.h"
#include "btreeInt.h"
#include "crypto.h"

static const char* codec_get_cipher_version() {
  return CIPHER_VERSION;
}

/* Generate code to return a string value */
static void codec_vdbe_return_static_string(Parse *pParse, const char *zLabel, const char *value){
  Vdbe *v = sqlite3GetVdbe(pParse);
  sqlite3VdbeSetNumCols(v, 1);
  sqlite3VdbeSetColName(v, 0, COLNAME_NAME, zLabel, SQLITE_STATIC);
  sqlite3VdbeAddOp4(v, OP_String8, 0, 1, 0, value, 0);
  sqlite3VdbeAddOp2(v, OP_ResultRow, 1, 1);
}

static int codec_set_btree_to_codec_pagesize(sqlite3 *db, Db *pDb, codec_ctx *ctx) {
  int rc, page_sz, reserve_sz; 

  page_sz = sqlcipher_codec_ctx_get_pagesize(ctx);
  reserve_sz = sqlcipher_codec_ctx_get_reservesize(ctx);

  sqlite3_mutex_enter(db->mutex);
  db->nextPagesize = page_sz; 

  /* before forcing the page size we need to unset the BTS_PAGESIZE_FIXED flag, else  
     sqliteBtreeSetPageSize will block the change  */
  pDb->pBt->pBt->btsFlags &= ~BTS_PAGESIZE_FIXED;
  CODEC_TRACE(("codec_set_btree_to_codec_pagesize: sqlite3BtreeSetPageSize() size=%d reserve=%d\n", page_sz, reserve_sz));
  rc = sqlite3BtreeSetPageSize(pDb->pBt, page_sz, reserve_sz, 0);
  sqlite3_mutex_leave(db->mutex);
  return rc;
}

static int codec_set_pass_key(sqlite3* db, int nDb, const void *zKey, int nKey, int for_ctx) {
  struct Db *pDb = &db->aDb[nDb];
  CODEC_TRACE(("codec_set_pass_key: entered db=%p nDb=%d zKey=%s nKey=%d for_ctx=%d\n", db, nDb, (char *)zKey, nKey, for_ctx));
  if(pDb->pBt) {
    codec_ctx *ctx;
    sqlite3pager_get_codec(pDb->pBt->pBt->pPager, (void **) &ctx);
    if(ctx) return sqlcipher_codec_ctx_set_pass(ctx, zKey, nKey, for_ctx);
  }
  return SQLITE_ERROR;
} 

int sqlcipher_codec_pragma(sqlite3* db, int iDb, Parse *pParse, const char *zLeft, const char *zRight) {
  struct Db *pDb = &db->aDb[iDb];
  codec_ctx *ctx = NULL;
  int rc;

  if(pDb->pBt) {
    sqlite3pager_get_codec(pDb->pBt->pBt->pPager, (void **) &ctx);
  }

  CODEC_TRACE(("sqlcipher_codec_pragma: entered db=%p iDb=%d pParse=%p zLeft=%s zRight=%s ctx=%p\n", db, iDb, pParse, zLeft, zRight, ctx));
  
  if( sqlite3StrICmp(zLeft, "cipher_fips_status")== 0 && !zRight ){
    if(ctx) {
      char *fips_mode_status = sqlite3_mprintf("%d", sqlcipher_codec_fips_status(ctx));
      codec_vdbe_return_static_string(pParse, "cipher_fips_status", fips_mode_status);
      sqlite3_free(fips_mode_status);
    }
  } else
  if( sqlite3StrICmp(zLeft, "cipher_store_pass")==0 && zRight ) {
    if(ctx) {
      sqlcipher_codec_set_store_pass(ctx, sqlite3GetBoolean(zRight, 1));
    }
  } else
  if( sqlite3StrICmp(zLeft, "cipher_store_pass")==0 && !zRight ) {
    if(ctx){
      char *store_pass_value = sqlite3_mprintf("%d", sqlcipher_codec_get_store_pass(ctx));
      codec_vdbe_return_static_string(pParse, "cipher_store_pass", store_pass_value);
      sqlite3_free(store_pass_value);
    }
  }
  if( sqlite3StrICmp(zLeft, "cipher_profile")== 0 && zRight ){
      char *profile_status = sqlite3_mprintf("%d", sqlcipher_cipher_profile(db, zRight));
      codec_vdbe_return_static_string(pParse, "cipher_profile", profile_status);
      sqlite3_free(profile_status);
  } else
  if( sqlite3StrICmp(zLeft, "cipher_add_random")==0 && zRight ){
    if(ctx) {
      char *add_random_status = sqlite3_mprintf("%d", sqlcipher_codec_add_random(ctx, zRight, sqlite3Strlen30(zRight)));
      codec_vdbe_return_static_string(pParse, "cipher_add_random", add_random_status);
      sqlite3_free(add_random_status);
    }
  } else
  if( sqlite3StrICmp(zLeft, "cipher_migrate")==0 && !zRight ){
    if(ctx){
      char *migrate_status = sqlite3_mprintf("%d", sqlcipher_codec_ctx_migrate(ctx));
      codec_vdbe_return_static_string(pParse, "cipher_migrate", migrate_status);
      sqlite3_free(migrate_status);
    }
  } else
  if( sqlite3StrICmp(zLeft, "cipher_provider")==0 && !zRight ){
    if(ctx) { codec_vdbe_return_static_string(pParse, "cipher_provider",
                                              sqlcipher_codec_get_cipher_provider(ctx));
    }
  } else
  if( sqlite3StrICmp(zLeft, "cipher_version")==0 && !zRight ){
    codec_vdbe_return_static_string(pParse, "cipher_version", codec_get_cipher_version());
  }else
  if( sqlite3StrICmp(zLeft, "cipher")==0 ){
    if(ctx) {
      if( zRight ) {
        sqlcipher_codec_ctx_set_cipher(ctx, zRight, 2); // change cipher for both
      }else {
        codec_vdbe_return_static_string(pParse, "cipher",
          sqlcipher_codec_ctx_get_cipher(ctx, 2));
      }
    }
  }else
  if( sqlite3StrICmp(zLeft, "rekey_cipher")==0 && zRight ){
    if(ctx) sqlcipher_codec_ctx_set_cipher(ctx, zRight, 1); // change write cipher only 
  }else
  if( sqlite3StrICmp(zLeft,"cipher_default_kdf_iter")==0 ){
    if( zRight ) {
      sqlcipher_set_default_kdf_iter(atoi(zRight)); // change default KDF iterations
    } else {
      char *kdf_iter = sqlite3_mprintf("%d", sqlcipher_get_default_kdf_iter());
      codec_vdbe_return_static_string(pParse, "cipher_default_kdf_iter", kdf_iter);
      sqlite3_free(kdf_iter);
    }
  }else
  if( sqlite3StrICmp(zLeft, "kdf_iter")==0 ){
    if(ctx) {
      if( zRight ) {
        sqlcipher_codec_ctx_set_kdf_iter(ctx, atoi(zRight), 2); // change of RW PBKDF2 iteration 
      } else {
        char *kdf_iter = sqlite3_mprintf("%d", sqlcipher_codec_ctx_get_kdf_iter(ctx, 2));
        codec_vdbe_return_static_string(pParse, "kdf_iter", kdf_iter);
        sqlite3_free(kdf_iter);
      }
    }
  }else
  if( sqlite3StrICmp(zLeft, "fast_kdf_iter")==0){
    if(ctx) {
      if( zRight ) {
        sqlcipher_codec_ctx_set_fast_kdf_iter(ctx, atoi(zRight), 2); // change of RW PBKDF2 iteration 
      } else {
        char *fast_kdf_iter = sqlite3_mprintf("%d", sqlcipher_codec_ctx_get_fast_kdf_iter(ctx, 2));
        codec_vdbe_return_static_string(pParse, "fast_kdf_iter", fast_kdf_iter);
        sqlite3_free(fast_kdf_iter);
      }
    }
  }else
  if( sqlite3StrICmp(zLeft, "rekey_kdf_iter")==0 && zRight ){
    if(ctx) sqlcipher_codec_ctx_set_kdf_iter(ctx, atoi(zRight), 1); // write iterations only
  }else
  if( sqlite3StrICmp(zLeft,"cipher_page_size")==0 ){
    if(ctx) {
      if( zRight ) {
        int size = atoi(zRight);
        rc = sqlcipher_codec_ctx_set_pagesize(ctx, size);
        if(rc != SQLITE_OK) sqlcipher_codec_ctx_set_error(ctx, rc);
        rc = codec_set_btree_to_codec_pagesize(db, pDb, ctx);
        if(rc != SQLITE_OK) sqlcipher_codec_ctx_set_error(ctx, rc);
      } else {
        char * page_size = sqlite3_mprintf("%d", sqlcipher_codec_ctx_get_pagesize(ctx));
        codec_vdbe_return_static_string(pParse, "cipher_page_size", page_size);
        sqlite3_free(page_size);
      }
    }
  }else
  if( sqlite3StrICmp(zLeft,"cipher_default_page_size")==0 ){
    if( zRight ) {
      sqlcipher_set_default_pagesize(atoi(zRight));
    } else {
      char *default_page_size = sqlite3_mprintf("%d", sqlcipher_get_default_pagesize());
      codec_vdbe_return_static_string(pParse, "cipher_default_page_size", default_page_size);
      sqlite3_free(default_page_size);
    }
  }else
  if( sqlite3StrICmp(zLeft,"cipher_default_use_hmac")==0 ){
    if( zRight ) {
      sqlcipher_set_default_use_hmac(sqlite3GetBoolean(zRight,1));
    } else {
      char *default_use_hmac = sqlite3_mprintf("%d", sqlcipher_get_default_use_hmac());
      codec_vdbe_return_static_string(pParse, "cipher_default_use_hmac", default_use_hmac);
      sqlite3_free(default_use_hmac);
    }
  }else
  if( sqlite3StrICmp(zLeft,"cipher_use_hmac")==0 ){
    if(ctx) {
      if( zRight ) {
        rc = sqlcipher_codec_ctx_set_use_hmac(ctx, sqlite3GetBoolean(zRight,1));
        if(rc != SQLITE_OK) sqlcipher_codec_ctx_set_error(ctx, rc);
        /* since the use of hmac has changed, the page size may also change */
        rc = codec_set_btree_to_codec_pagesize(db, pDb, ctx);
        if(rc != SQLITE_OK) sqlcipher_codec_ctx_set_error(ctx, rc);
      } else {
        char *hmac_flag = sqlite3_mprintf("%d", sqlcipher_codec_ctx_get_use_hmac(ctx, 2));
        codec_vdbe_return_static_string(pParse, "cipher_use_hmac", hmac_flag);
        sqlite3_free(hmac_flag);
      }
    }
  }else
  if( sqlite3StrICmp(zLeft,"cipher_hmac_pgno")==0 ){
    if(ctx) {
      if(zRight) {
        // clear both pgno endian flags
        if(sqlite3StrICmp(zRight, "le") == 0) {
          sqlcipher_codec_ctx_unset_flag(ctx, CIPHER_FLAG_BE_PGNO);
          sqlcipher_codec_ctx_set_flag(ctx, CIPHER_FLAG_LE_PGNO);
        } else if(sqlite3StrICmp(zRight, "be") == 0) {
          sqlcipher_codec_ctx_unset_flag(ctx, CIPHER_FLAG_LE_PGNO);
          sqlcipher_codec_ctx_set_flag(ctx, CIPHER_FLAG_BE_PGNO);
        } else if(sqlite3StrICmp(zRight, "native") == 0) {
          sqlcipher_codec_ctx_unset_flag(ctx, CIPHER_FLAG_LE_PGNO);
          sqlcipher_codec_ctx_unset_flag(ctx, CIPHER_FLAG_BE_PGNO);
        }
      } else {
        if(sqlcipher_codec_ctx_get_flag(ctx, CIPHER_FLAG_LE_PGNO, 2)) {
          codec_vdbe_return_static_string(pParse, "cipher_hmac_pgno", "le");
        } else if(sqlcipher_codec_ctx_get_flag(ctx, CIPHER_FLAG_BE_PGNO, 2)) {
          codec_vdbe_return_static_string(pParse, "cipher_hmac_pgno", "be");
        } else {
          codec_vdbe_return_static_string(pParse, "cipher_hmac_pgno", "native");
        }
      }
    }
  }else
  if( sqlite3StrICmp(zLeft,"cipher_hmac_salt_mask")==0 ){
    if(ctx) {
      if(zRight) {
        if (sqlite3StrNICmp(zRight ,"x'", 2) == 0 && sqlite3Strlen30(zRight) == 5) {
          unsigned char mask = 0;
          const unsigned char *hex = (const unsigned char *)zRight+2;
          cipher_hex2bin(hex,2,&mask);
          sqlcipher_set_hmac_salt_mask(mask);
        }
      } else {
          char *hmac_salt_mask = sqlite3_mprintf("%02x", sqlcipher_get_hmac_salt_mask());
          codec_vdbe_return_static_string(pParse, "cipher_hmac_salt_mask", hmac_salt_mask);
          sqlite3_free(hmac_salt_mask);
      }
    }
  }else {
    return 0;
  }
  return 1;
}


/*
 * sqlite3Codec can be called in multiple modes.
 * encrypt mode - expected to return a pointer to the 
 *   encrypted data without altering pData.
 * decrypt mode - expected to return a pointer to pData, with
 *   the data decrypted in the input buffer
 */
void* sqlite3Codec(void *iCtx, void *data, Pgno pgno, int mode) {
  codec_ctx *ctx = (codec_ctx *) iCtx;
  int offset = 0, rc = 0;
  int page_sz = sqlcipher_codec_ctx_get_pagesize(ctx); 
  unsigned char *pData = (unsigned char *) data;
  void *buffer = sqlcipher_codec_ctx_get_data(ctx);
  void *kdf_salt = sqlcipher_codec_ctx_get_kdf_salt(ctx);
  CODEC_TRACE(("sqlite3Codec: entered pgno=%d, mode=%d, page_sz=%d\n", pgno, mode, page_sz));

  /* call to derive keys if not present yet */
  if((rc = sqlcipher_codec_key_derive(ctx)) != SQLITE_OK) {
   sqlcipher_codec_ctx_set_error(ctx, rc); 
   return NULL;
  }

  if(pgno == 1) offset = FILE_HEADER_SZ; /* adjust starting pointers in data page for header offset on first page*/

  CODEC_TRACE(("sqlite3Codec: switch mode=%d offset=%d\n",  mode, offset));
  switch(mode) {
    case 0: /* decrypt */
    case 2:
    case 3:
      if(pgno == 1) memcpy(buffer, SQLITE_FILE_HEADER, FILE_HEADER_SZ); /* copy file header to the first 16 bytes of the page */ 
      rc = sqlcipher_page_cipher(ctx, CIPHER_READ_CTX, pgno, CIPHER_DECRYPT, page_sz - offset, pData + offset, (unsigned char*)buffer + offset);
      if(rc != SQLITE_OK) sqlcipher_codec_ctx_set_error(ctx, rc);
      memcpy(pData, buffer, page_sz); /* copy buffer data back to pData and return */
      return pData;
      break;
    case 6: /* encrypt */
      if(pgno == 1) memcpy(buffer, kdf_salt, FILE_HEADER_SZ); /* copy salt to output buffer */ 
      rc = sqlcipher_page_cipher(ctx, CIPHER_WRITE_CTX, pgno, CIPHER_ENCRYPT, page_sz - offset, pData + offset, (unsigned char*)buffer + offset);
      if(rc != SQLITE_OK) sqlcipher_codec_ctx_set_error(ctx, rc);
      return buffer; /* return persistent buffer data, pData remains intact */
      break;
    case 7:
      if(pgno == 1) memcpy(buffer, kdf_salt, FILE_HEADER_SZ); /* copy salt to output buffer */ 
      rc = sqlcipher_page_cipher(ctx, CIPHER_READ_CTX, pgno, CIPHER_ENCRYPT, page_sz - offset, pData + offset, (unsigned char*)buffer + offset);
      if(rc != SQLITE_OK) sqlcipher_codec_ctx_set_error(ctx, rc);
      return buffer; /* return persistent buffer data, pData remains intact */
      break;
    default:
      return pData;
      break;
  }
}

void sqlite3FreeCodecArg(void *pCodecArg) {
  codec_ctx *ctx = (codec_ctx *) pCodecArg;
  if(pCodecArg == NULL) return;
  sqlcipher_codec_ctx_free(&ctx); // wipe and free allocated memory for the context 
  sqlcipher_deactivate(); /* cleanup related structures, OpenSSL etc, when codec is detatched */
}

int sqlite3CodecAttach(sqlite3* db, int nDb, const void *zKey, int nKey) {
  struct Db *pDb = &db->aDb[nDb];

  CODEC_TRACE(("sqlite3CodecAttach: entered nDb=%d zKey=%s, nKey=%d\n", nDb, (char *)zKey, nKey));


  if(nKey && zKey && pDb->pBt) {
    int rc;
    Pager *pPager = pDb->pBt->pBt->pPager;
    sqlite3_file *fd = sqlite3Pager_get_fd(pPager);
    codec_ctx *ctx;

    sqlcipher_activate(); /* perform internal initialization for sqlcipher */

    sqlite3_mutex_enter(db->mutex);

    /* point the internal codec argument against the contet to be prepared */
    rc = sqlcipher_codec_ctx_init(&ctx, pDb, pDb->pBt->pBt->pPager, fd, zKey, nKey); 

    if(rc != SQLITE_OK) return rc; /* initialization failed, do not attach potentially corrupted context */

    sqlite3pager_sqlite3PagerSetCodec(sqlite3BtreePager(pDb->pBt), sqlite3Codec, NULL, sqlite3FreeCodecArg, (void *) ctx);

    codec_set_btree_to_codec_pagesize(db, pDb, ctx);

    /* force secure delete. This has the benefit of wiping internal data when deleted
       and also ensures that all pages are written to disk (i.e. not skipped by
       sqlite3PagerDontWrite optimizations) */ 
    sqlite3BtreeSecureDelete(pDb->pBt, 1); 

    /* if fd is null, then this is an in-memory database and
       we dont' want to overwrite the AutoVacuum settings
       if not null, then set to the default */
    if(fd != NULL) { 
      sqlite3BtreeSetAutoVacuum(pDb->pBt, SQLITE_DEFAULT_AUTOVACUUM);
    }
    sqlite3_mutex_leave(db->mutex);
  }
  return SQLITE_OK;
}

void sqlite3_activate_see(const char* in) {
  /* do nothing, security enhancements are always active */
}

static int sqlcipher_find_db_index(sqlite3 *db, const char *zDb) {
  int db_index;
  if(zDb == NULL){
    return 0;
  }
  for(db_index = 0; db_index < db->nDb; db_index++) {
    struct Db *pDb = &db->aDb[db_index];
    if(strcmp(pDb->zName, zDb) == 0) {
      return db_index;
    }
  }
  return 0;
}

int sqlite3_key(sqlite3 *db, const void *pKey, int nKey) {
  CODEC_TRACE(("sqlite3_key entered: db=%p pKey=%s nKey=%d\n", db, (char *)pKey, nKey));
  return sqlite3_key_v2(db, "main", pKey, nKey);
}

int sqlite3_key_v2(sqlite3 *db, const char *zDb, const void *pKey, int nKey) {
  CODEC_TRACE(("sqlite3_key_v2: entered db=%p zDb=%s pKey=%s nKey=%d\n", db, zDb, (char *)pKey, nKey));
  /* attach key if db and pKey are not null and nKey is > 0 */
  if(db && pKey && nKey) {
    int db_index = sqlcipher_find_db_index(db, zDb);
    return sqlite3CodecAttach(db, db_index, pKey, nKey); 
  }
  return SQLITE_ERROR;
}

int sqlite3_rekey(sqlite3 *db, const void *pKey, int nKey) {
  CODEC_TRACE(("sqlite3_rekey entered: db=%p pKey=%s nKey=%d\n", db, (char *)pKey, nKey));
  return sqlite3_rekey_v2(db, "main", pKey, nKey);
}

/* sqlite3_rekey_v2
** Given a database, this will reencrypt the database using a new key.
** There is only one possible modes of operation - to encrypt a database
** that is already encrpyted. If the database is not already encrypted
** this should do nothing
** The proposed logic for this function follows:
** 1. Determine if the database is already encryptped
** 2. If there is NOT already a key present do nothing
** 3. If there is a key present, re-encrypt the database with the new key
*/
int sqlite3_rekey_v2(sqlite3 *db, const char *zDb, const void *pKey, int nKey) {
  CODEC_TRACE(("sqlite3_rekey_v2: entered db=%p zDb=%s pKey=%s, nKey=%d\n", db, zDb, (char *)pKey, nKey));
  if(db && pKey && nKey) {
    int db_index = sqlcipher_find_db_index(db, zDb);
    struct Db *pDb = &db->aDb[db_index];
    CODEC_TRACE(("sqlite3_rekey_v2: database pDb=%p db_index:%d\n", pDb, db_index));
    if(pDb->pBt) {
      codec_ctx *ctx;
      int rc, page_count;
      Pgno pgno;
      PgHdr *page;
      Pager *pPager = pDb->pBt->pBt->pPager;

      sqlite3pager_get_codec(pDb->pBt->pBt->pPager, (void **) &ctx);
     
      if(ctx == NULL) { 
        /* there was no codec attached to this database, so this should do nothing! */ 
        CODEC_TRACE(("sqlite3_rekey_v2: no codec attached to db, exiting\n"));
        return SQLITE_OK;
      }

      sqlite3_mutex_enter(db->mutex);

      codec_set_pass_key(db, db_index, pKey, nKey, CIPHER_WRITE_CTX);
    
      /* do stuff here to rewrite the database 
      ** 1. Create a transaction on the database
      ** 2. Iterate through each page, reading it and then writing it.
      ** 3. If that goes ok then commit and put ctx->rekey into ctx->key
      **    note: don't deallocate rekey since it may be used in a subsequent iteration 
      */
      rc = sqlite3BtreeBeginTrans(pDb->pBt, 1); /* begin write transaction */
      sqlite3PagerPagecount(pPager, &page_count);
      for(pgno = 1; rc == SQLITE_OK && pgno <= (unsigned int)page_count; pgno++) { /* pgno's start at 1 see pager.c:pagerAcquire */
        if(!sqlite3pager_is_mj_pgno(pPager, pgno)) { /* skip this page (see pager.c:pagerAcquire for reasoning) */
          rc = sqlite3PagerGet(pPager, pgno, &page);
          if(rc == SQLITE_OK) { /* write page see pager_incr_changecounter for example */
            rc = sqlite3PagerWrite(page);
            if(rc == SQLITE_OK) {
              sqlite3PagerUnref(page);
            } else {
             CODEC_TRACE(("sqlite3_rekey_v2: error %d occurred writing page %d\n", rc, pgno));  
            }
          } else {
             CODEC_TRACE(("sqlite3_rekey_v2: error %d occurred getting page %d\n", rc, pgno));  
          }
        } 
      }

      /* if commit was successful commit and copy the rekey data to current key, else rollback to release locks */
      if(rc == SQLITE_OK) { 
        CODEC_TRACE(("sqlite3_rekey_v2: committing\n"));
        rc = sqlite3BtreeCommit(pDb->pBt); 
        sqlcipher_codec_key_copy(ctx, CIPHER_WRITE_CTX);
      } else {
        CODEC_TRACE(("sqlite3_rekey_v2: rollback\n"));
        sqlite3BtreeRollback(pDb->pBt, SQLITE_ABORT_ROLLBACK, 0);
      }

      sqlite3_mutex_leave(db->mutex);
    }
    return SQLITE_OK;
  }
  return SQLITE_ERROR;
}

void sqlite3CodecGetKey(sqlite3* db, int nDb, void **zKey, int *nKey) {
  struct Db *pDb = &db->aDb[nDb];
  CODEC_TRACE(("sqlite3CodecGetKey: entered db=%p, nDb=%d\n", db, nDb));
  if( pDb->pBt ) {
    codec_ctx *ctx;
    sqlite3pager_get_codec(pDb->pBt->pBt->pPager, (void **) &ctx);
    if(ctx) {
      if(sqlcipher_codec_get_store_pass(ctx) == 1) {
        sqlcipher_codec_get_pass(ctx, zKey, nKey);
      } else {
        sqlcipher_codec_get_keyspec(ctx, zKey, nKey);
      }
    } else {
      *zKey = NULL;
      *nKey = 0;
    }
  }
}

#ifndef OMIT_EXPORT

/*
 * Implementation of an "export" function that allows a caller
 * to duplicate the main database to an attached database. This is intended
 * as a conveneince for users who need to:
 * 
 *   1. migrate from an non-encrypted database to an encrypted database
 *   2. move from an encrypted database to a non-encrypted database
 *   3. convert beween the various flavors of encrypted databases.  
 *
 * This implementation is based heavily on the procedure and code used
 * in vacuum.c, but is exposed as a function that allows export to any
 * named attached database.
 */

/*
** Finalize a prepared statement.  If there was an error, store the
** text of the error message in *pzErrMsg.  Return the result code.
** 
** Based on vacuumFinalize from vacuum.c
*/
static int sqlcipher_finalize(sqlite3 *db, sqlite3_stmt *pStmt, char **pzErrMsg){
  int rc;
  rc = sqlite3VdbeFinalize((Vdbe*)pStmt);
  if( rc ){
    sqlite3SetString(pzErrMsg, db, sqlite3_errmsg(db));
  }
  return rc;
}

/*
** Execute zSql on database db. Return an error code.
** 
** Based on execSql from vacuum.c
*/
static int sqlcipher_execSql(sqlite3 *db, char **pzErrMsg, const char *zSql){
  sqlite3_stmt *pStmt;
  VVA_ONLY( int rc; )
  if( !zSql ){
    return SQLITE_NOMEM;
  }
  if( SQLITE_OK!=sqlite3_prepare(db, zSql, -1, &pStmt, 0) ){
    sqlite3SetString(pzErrMsg, db, sqlite3_errmsg(db));
    return sqlite3_errcode(db);
  }
  VVA_ONLY( rc = ) sqlite3_step(pStmt);
  assert( rc!=SQLITE_ROW );
  return sqlcipher_finalize(db, pStmt, pzErrMsg);
}

/*
** Execute zSql on database db. The statement returns exactly
** one column. Execute this as SQL on the same database.
** 
** Based on execExecSql from vacuum.c
*/
static int sqlcipher_execExecSql(sqlite3 *db, char **pzErrMsg, const char *zSql){
  sqlite3_stmt *pStmt;
  int rc;

  rc = sqlite3_prepare(db, zSql, -1, &pStmt, 0);
  if( rc!=SQLITE_OK ) return rc;

  while( SQLITE_ROW==sqlite3_step(pStmt) ){
    rc = sqlcipher_execSql(db, pzErrMsg, (char*)sqlite3_column_text(pStmt, 0));
    if( rc!=SQLITE_OK ){
      sqlcipher_finalize(db, pStmt, pzErrMsg);
      return rc;
    }
  }

  return sqlcipher_finalize(db, pStmt, pzErrMsg);
}

/*
 * copy database and schema from the main database to an attached database
 * 
 * Based on sqlite3RunVacuum from vacuum.c
*/
void sqlcipher_exportFunc(sqlite3_context *context, int argc, sqlite3_value **argv) {
  sqlite3 *db = sqlite3_context_db_handle(context);
  const char* attachedDb = (const char*) sqlite3_value_text(argv[0]);
  int saved_flags;        /* Saved value of the db->flags */
  int saved_nChange;      /* Saved value of db->nChange */
  int saved_nTotalChange; /* Saved value of db->nTotalChange */
  void (*saved_xTrace)(void*,const char*);  /* Saved db->xTrace */
  int rc = SQLITE_OK;     /* Return code from service routines */
  char *zSql = NULL;         /* SQL statements */
  char *pzErrMsg = NULL;
  
  saved_flags = db->flags;
  saved_nChange = db->nChange;
  saved_nTotalChange = db->nTotalChange;
  saved_xTrace = db->xTrace;
  db->flags |= SQLITE_WriteSchema | SQLITE_IgnoreChecks | SQLITE_PreferBuiltin;
  db->flags &= ~(SQLITE_ForeignKeys | SQLITE_ReverseOrder);
  db->xTrace = 0;

  /* Query the schema of the main database. Create a mirror schema
  ** in the temporary database.
  */
  zSql = sqlite3_mprintf(
    "SELECT 'CREATE TABLE %s.' || substr(sql,14) "
    "  FROM sqlite_master WHERE type='table' AND name!='sqlite_sequence'"
    "   AND rootpage>0"
  , attachedDb);
  rc = (zSql == NULL) ? SQLITE_NOMEM : sqlcipher_execExecSql(db, &pzErrMsg, zSql); 
  if( rc!=SQLITE_OK ) goto end_of_export;
  sqlite3_free(zSql);

  zSql = sqlite3_mprintf(
    "SELECT 'CREATE INDEX %s.' || substr(sql,14)"
    "  FROM sqlite_master WHERE sql LIKE 'CREATE INDEX %%' "
  , attachedDb);
  rc = (zSql == NULL) ? SQLITE_NOMEM : sqlcipher_execExecSql(db, &pzErrMsg, zSql); 
  if( rc!=SQLITE_OK ) goto end_of_export;
  sqlite3_free(zSql);

  zSql = sqlite3_mprintf(
    "SELECT 'CREATE UNIQUE INDEX %s.' || substr(sql,21) "
    "  FROM sqlite_master WHERE sql LIKE 'CREATE UNIQUE INDEX %%'"
  , attachedDb);
  rc = (zSql == NULL) ? SQLITE_NOMEM : sqlcipher_execExecSql(db, &pzErrMsg, zSql); 
  if( rc!=SQLITE_OK ) goto end_of_export;
  sqlite3_free(zSql);

  /* Loop through the tables in the main database. For each, do
  ** an "INSERT INTO rekey_db.xxx SELECT * FROM main.xxx;" to copy
  ** the contents to the temporary database.
  */
  zSql = sqlite3_mprintf(
    "SELECT 'INSERT INTO %s.' || quote(name) "
    "|| ' SELECT * FROM main.' || quote(name) || ';'"
    "FROM main.sqlite_master "
    "WHERE type = 'table' AND name!='sqlite_sequence' "
    "  AND rootpage>0"
  , attachedDb);
  rc = (zSql == NULL) ? SQLITE_NOMEM : sqlcipher_execExecSql(db, &pzErrMsg, zSql); 
  if( rc!=SQLITE_OK ) goto end_of_export;
  sqlite3_free(zSql);

  /* Copy over the sequence table
  */
  zSql = sqlite3_mprintf(
    "SELECT 'DELETE FROM %s.' || quote(name) || ';' "
    "FROM %s.sqlite_master WHERE name='sqlite_sequence' "
  , attachedDb, attachedDb);
  rc = (zSql == NULL) ? SQLITE_NOMEM : sqlcipher_execExecSql(db, &pzErrMsg, zSql); 
  if( rc!=SQLITE_OK ) goto end_of_export;
  sqlite3_free(zSql);

  zSql = sqlite3_mprintf(
    "SELECT 'INSERT INTO %s.' || quote(name) "
    "|| ' SELECT * FROM main.' || quote(name) || ';' "
    "FROM %s.sqlite_master WHERE name=='sqlite_sequence';"
  , attachedDb, attachedDb);
  rc = (zSql == NULL) ? SQLITE_NOMEM : sqlcipher_execExecSql(db, &pzErrMsg, zSql); 
  if( rc!=SQLITE_OK ) goto end_of_export;
  sqlite3_free(zSql);

  /* Copy the triggers, views, and virtual tables from the main database
  ** over to the temporary database.  None of these objects has any
  ** associated storage, so all we have to do is copy their entries
  ** from the SQLITE_MASTER table.
  */
  zSql = sqlite3_mprintf(
    "INSERT INTO %s.sqlite_master "
    "  SELECT type, name, tbl_name, rootpage, sql"
    "    FROM main.sqlite_master"
    "   WHERE type='view' OR type='trigger'"
    "      OR (type='table' AND rootpage=0)"
  , attachedDb);
  rc = (zSql == NULL) ? SQLITE_NOMEM : sqlcipher_execSql(db, &pzErrMsg, zSql); 
  if( rc!=SQLITE_OK ) goto end_of_export;
  sqlite3_free(zSql);

  zSql = NULL;
end_of_export:
  db->flags = saved_flags;
  db->nChange = saved_nChange;
  db->nTotalChange = saved_nTotalChange;
  db->xTrace = saved_xTrace;

  sqlite3_free(zSql);

  if(rc) {
    if(pzErrMsg != NULL) {
      sqlite3_result_error(context, pzErrMsg, -1);
      sqlite3DbFree(db, pzErrMsg);
    } else {
      sqlite3_result_error(context, sqlite3ErrStr(rc), -1);
    }
  }
}

#endif

/* END SQLCIPHER */
#endif
