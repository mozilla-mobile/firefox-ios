#include "test.h"

#include <inttypes.h>
#include <string.h>

typedef struct webpush_aesgcm_from_params_test_s {
  const char* cryptoKey;
  const char* encryption;
  const char* salt;
  const char* rawSenderPubKey;
  size_t cryptoKeyLen;
  size_t encryptionLen;
  size_t saltLen;
  size_t rawSenderPubKeyLen;
  uint32_t rs;
} webpush_aesgcm_from_params_test_t;

static webpush_aesgcm_from_params_test_t webpush_aesgcm_from_params_tests[] = {
  {
    .cryptoKey = "dh=Iy1Je2Kv11A",
    .cryptoKeyLen = 14,
    .encryption = "rs=7;salt=upk1yFkp1xI",
    .encryptionLen = 21,
    .salt = "\xba\x99\x35\xc8\x59\x29\xd7\x12",
    .saltLen = 8,
    .rawSenderPubKey = "\x23\x2d\x49\x7b\x62\xaf\xd7\x50",
    .rawSenderPubKeyLen = 8,
    .rs = 7,
  },
  {
    .cryptoKey = "dh=mwyOULZ4upjVbCpQLRLOeg",
    .cryptoKeyLen = 25,
    .encryption = "rs=4096;salt=qzqku7FRdW9Vs97w8O8DoA",
    .encryptionLen = 35,
    .salt = "\xab\x3a\xa4\xbb\xb1\x51\x75\x6f\x55\xb3\xde\xf0\xf0\xef\x03\xa0",
    .saltLen = 16,
    .rawSenderPubKey =
      "\x9b\x0c\x8e\x50\xb6\x78\xba\x98\xd5\x6c\x2a\x50\x2d\x12\xce\x7a",
    .rawSenderPubKeyLen = 16,
    .rs = 4096,
  },
};

typedef struct webpush_aesgcm_extract_params_ok_test_s {
  const char* desc;
  const char* cryptoKey;
  const char* encryption;
  const char* salt;
  const char* rawSenderPubKey;
  uint32_t rs;
} webpush_aesgcm_extract_params_ok_test_t;

static webpush_aesgcm_extract_params_ok_test_t
  webpush_aesgcm_extract_params_ok_tests[] = {
    {
      .desc = "Multiple keys in Crypto-Key header",
      .cryptoKey = "keyid=p256dh;dh=Iy1Je2Kv11A,p256ecdsa=o2M8QfiEKuI",
      .encryption = "keyid=p256dh;salt=upk1yFkp1xI",
      .salt = "\xba\x99\x35\xc8\x59\x29\xd7\x12",
      .rawSenderPubKey = "\x23\x2d\x49\x7b\x62\xaf\xd7\x50",
      .rs = 4096,
    },
    {
      .desc = "Multiple keys in both headers",
      .cryptoKey = "keyid=a;dh=bX0VbuZy8HQ,dh=Iy1Je2Kv11A;keyid=p256dh",
      .encryption =
        "salt=upk1yFkp1xI;rs=48;keyid=p256dh,salt=U0DM1JsdIbU;keyid=a",
      .salt = "\xba\x99\x35\xc8\x59\x29\xd7\x12",
      .rawSenderPubKey = "\x23\x2d\x49\x7b\x62\xaf\xd7\x50",
      .rs = 48,
    },
    {
      .desc = "Quoted key ID pair value",
      .cryptoKey = "dh=\"byfHbUffc-k\"",
      .encryption = "salt=C11AvAsp6Gc",
      .salt = "\x0b\x5d\x40\xbc\x0b\x29\xe8\x67",
      .rawSenderPubKey = "\x6f\x27\xc7\x6d\x47\xdf\x73\xe9",
      .rs = 4096,
    },
    {
      .desc = "Quoted salt pair value and rs = 24",
      .cryptoKey = "dh=ybuT4VDz-Bg",
      .encryption = "rs=24; salt=\"H7U7wcIoIKs\"",
      .salt = "\x1f\xb5\x3b\xc1\xc2\x28\x20\xab",
      .rawSenderPubKey = "\xc9\xbb\x93\xe1\x50\xf3\xf8\x18",
      .rs = 24,
    },
    {
      .desc = "Multiple keys, extra whitespace, strange key ID",
      .cryptoKey = " dh= \"ujIToeKunCY\" ,keyid = hello ; dh = I7p5M0yyP8A ",
      .encryption = "salt=ie_oYLhw7SI; keyid=\"hello\"; rs =6 , salt = "
                    "6NAh50bfJZc ;keyid=ujIToeKunCY ",
      .salt = "\x89\xef\xe8\x60\xb8\x70\xed\x22",
      .rawSenderPubKey = "\x23\xba\x79\x33\x4c\xb2\x3f\xc0",
      .rs = 6,
    },
    {
      // Invalid, but we don't check the entire `Crypto-Key` param once we see a
      // match.
      .desc = "Duplicate key ID in Crypto-Key",
      .cryptoKey = "keyid=a;keyid=b;dh=pbmv1QkcEDY",
      .encryption = "salt=Esao8aTBfIk;keyid=b",
      .salt = "\x12\xc6\xa8\xf1\xa4\xc1\x7c\x89",
      .rawSenderPubKey = "\xa5\xb9\xaf\xd5\x09\x1c\x10\x36",
      .rs = 4096,
    },
};

typedef struct webpush_aesgcm_extract_params_err_test_s {
  const char* desc;
  const char* cryptoKey;
  const char* encryption;
  int err;
} webpush_aesgcm_extract_params_err_test_t;

static webpush_aesgcm_extract_params_err_test_t
  webpush_aesgcm_extract_params_err_tests[] = {
    {
      .desc = "Invalid record size",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "salt=Esao8aTBfIk;rs=bad",
      .err = ECE_ERROR_INVALID_RS,
    },
    {
      .desc = "Blank Crypto-Key header",
      .cryptoKey = " \t ",
      .encryption = "salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Empty Encryption header",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Crypto-Key missing pair value",
      .cryptoKey = "dh=",
      .encryption = "salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Encryption missing pair value with trailing whitespace",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "salt= ",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Crypto-Key pair without value",
      .cryptoKey = "dh=pbmv1QkcEDY; keyid, dh=rqowftPcCVo",
      .encryption = "salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Encryption pair without value",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "rs; salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Crypto-Key missing pair name",
      .cryptoKey = "dh=pbmv1QkcEDY; =rqowftPcCVo",
      .encryption = "salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Encryption missing pair name",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Whitespace in quoted Crypto-Key pair value",
      .cryptoKey = "dh=byfHbUffc-k; param=\" \"",
      .encryption = "salt=C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Empty quoted value in Encryption header",
      .cryptoKey = "dh=byfHbUffc-k",
      .encryption = "salt=\"\"; rs=6",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Invalid character in Crypto-Key pair value",
      .cryptoKey = "dh==byfHbUffc-k",
      .encryption = "salt=C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Invalid character in Encryption pair name",
      .cryptoKey = "dh=byfHbUffc-k",
      .encryption = "sa!t=C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Leading , in Crypto-Key header",
      .cryptoKey = ",dh=byfHbUffc-k",
      .encryption = "salt=C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Trailing ; in Crypto-Key header",
      .cryptoKey = "dh=byfHbUffc-k;",
      .encryption = "salt=C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Leading ; in Encryption header",
      .cryptoKey = "dh=byfHbUffc-k",
      .encryption = "; salt=C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Trailing , in Encryption header",
      .cryptoKey = "dh=byfHbUffc-k",
      .encryption = "salt=C11AvAsp6Gc,",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Unterminated quoted value in Encryption header",
      .cryptoKey = "dh=byfHbUffc-k",
      .encryption = "rs=6; salt=\"C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Invalid quoted name in Crypto-Key header",
      .cryptoKey = "\"dh\"=\"byfHbUffc-k\"",
      .encryption = "salt=C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Invalid quoted name in Encryption header",
      .cryptoKey = "dh=byfHbUffc-k",
      .encryption = "\"salt\"=C11AvAsp6Gc",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Mismatched key IDs",
      .cryptoKey = "keyid=p256dh;dh=pbmv1QkcEDY",
      .encryption = "keyid=different;salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_DH,
    },
    {
      .desc = "Multiple mismatched key IDs",
      .cryptoKey = "keyid=a;dh=bX0VbuZy8HQ,dh=Iy1Je2Kv11A;keyid=b",
      .encryption = "salt=upk1yFkp1xI;rs=48;keyid=c,salt=U0DM1JsdIbU;keyid=d",
      .err = ECE_ERROR_INVALID_DH,
    },
    {
      .desc = "Key ID with matching pair value, wrong pair name",
      .cryptoKey = "p256dh=p256dh;dh=pbmv1QkcEDY",
      .encryption = "keyid=p256dh;salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_DH,
    },
    {
      .desc = "Invalid Base64url-encoded salt",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "salt=99999",
      .err = ECE_ERROR_INVALID_SALT,
    },
    {
      .desc = "Invalid Base64url-encoded dh pair value",
      .cryptoKey = "dh=zzzzz",
      .encryption = "salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_DH,
    },
    {
      .desc = "Invalid character at end of salt pair name",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "salt !=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Invalid character at end of salt",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "salt=Esao8aTBfIk!",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Invalid character after quoted dh pair value",
      .cryptoKey = "dh=\"pbmv1QkcEDY\"!",
      .encryption = "salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
    },
    {
      .desc = "Duplicate key ID in Encryption header",
      .cryptoKey = "keyid=b;dh=pbmv1QkcEDY",
      .encryption = "keyid=a;salt=Esao8aTBfIk;keyid=b",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Duplicate record size in Encryption header",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "rs=5;salt=Esao8aTBfIk;rs=10",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Duplicate salt in Encryption header",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "salt=Esao8aTBfIk; salt=Esao8aTBfIk",
      .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
    },
    {
      .desc = "Missing salt in Encryption header",
      .cryptoKey = "dh=pbmv1QkcEDY",
      .encryption = "rs=5",
      .err = ECE_ERROR_INVALID_SALT,
    },
};

void
test_webpush_aesgcm_headers_from_params(void) {
  size_t length = sizeof(webpush_aesgcm_from_params_tests) /
                  sizeof(webpush_aesgcm_from_params_test_t);
  for (size_t i = 0; i < length; i++) {
    webpush_aesgcm_from_params_test_t t = webpush_aesgcm_from_params_tests[i];

    size_t cryptoKeyLen = 0;
    size_t encryptionLen = 0;
    int err = ece_webpush_aesgcm_headers_from_params(
      t.salt, t.saltLen, t.rawSenderPubKey, t.rawSenderPubKeyLen, t.rs, NULL,
      &cryptoKeyLen, NULL, &encryptionLen);
    ece_assert(!err, "Got %d determining lengths for (%s, %s)", err,
               t.cryptoKey, t.encryption);
    ece_assert(cryptoKeyLen == t.cryptoKeyLen,
               "Got Crypto-Key length %zu for (%s, %s); want %zu", cryptoKeyLen,
               t.cryptoKey, t.encryption, t.cryptoKeyLen);
    ece_assert(encryptionLen == t.encryptionLen,
               "Got Encryption length %zu for (%s, %s); want %zu",
               encryptionLen, t.cryptoKey, t.encryption, t.encryptionLen);

    char* cryptoKey = malloc(cryptoKeyLen + 1);
    char* encryption = malloc(encryptionLen + 1);

    err = ece_webpush_aesgcm_headers_from_params(
      t.salt, t.saltLen, t.rawSenderPubKey, t.rawSenderPubKeyLen, t.rs,
      cryptoKey, &cryptoKeyLen, encryption, &encryptionLen);
    ece_assert(!err, "Got %d formatting headers for (%s, %s)", err, t.cryptoKey,
               t.encryption);
    ece_assert(!memcmp(cryptoKey, t.cryptoKey, t.cryptoKeyLen),
               "Wrong Crypto-Key for (%s, %s)", t.cryptoKey, t.encryption);
    ece_assert(!memcmp(encryption, t.encryption, t.encryptionLen),
               "Wrong Encryption for (%s, %s)", t.cryptoKey, t.encryption);

    free(cryptoKey);
    free(encryption);
  }
}

void
test_webpush_aesgcm_headers_extract_params_ok(void) {
  size_t length = sizeof(webpush_aesgcm_extract_params_ok_tests) /
                  sizeof(webpush_aesgcm_extract_params_ok_test_t);
  for (size_t i = 0; i < length; i++) {
    webpush_aesgcm_extract_params_ok_test_t t =
      webpush_aesgcm_extract_params_ok_tests[i];

    uint8_t salt[8];
    uint32_t rs;
    uint8_t rawSenderPubKey[8];
    int err = ece_webpush_aesgcm_headers_extract_params(
      t.cryptoKey, t.encryption, salt, 8, rawSenderPubKey, 8, &rs);

    ece_assert(!err, "Got %d extracting params for `%s`", err, t.desc);
    ece_assert(!memcmp(salt, t.salt, 8), "Wrong salt for `%s`", t.desc);
    ece_assert(rs == t.rs, "Got rs = %" PRIu32 " for `%s`; want %" PRIu32, rs,
               t.desc, t.rs);
    ece_assert(!memcmp(rawSenderPubKey, t.rawSenderPubKey, 8),
               "Wrong public key for `%s`", t.desc);
  }
}

void
test_webpush_aesgcm_headers_extract_params_err(void) {
  size_t length = sizeof(webpush_aesgcm_extract_params_err_tests) /
                  sizeof(webpush_aesgcm_extract_params_err_test_t);
  for (size_t i = 0; i < length; i++) {
    webpush_aesgcm_extract_params_err_test_t t =
      webpush_aesgcm_extract_params_err_tests[i];

    uint8_t salt[8];
    uint32_t rs;
    uint8_t rawSenderPubKey[8];
    int err = ece_webpush_aesgcm_headers_extract_params(
      t.cryptoKey, t.encryption, salt, 8, rawSenderPubKey, 8, &rs);

    ece_assert(err == t.err, "Got %d extracting params for `%s`; want %d", err,
               t.desc, t.err);
  }
}
