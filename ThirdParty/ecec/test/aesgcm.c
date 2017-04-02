#include "test.h"

#include <inttypes.h>
#include <string.h>

#include <ece.h>

typedef struct valid_param_test_s {
  const char* desc;
  const char* cryptoKey;
  const char* encryption;
  const char* salt;
  const char* rawSenderPubKey;
  uint32_t rs;
} valid_param_test_t;

typedef struct invalid_param_test_s {
  const char* desc;
  const char* cryptoKey;
  const char* encryption;
  int err;
} invalid_param_test_t;

typedef struct valid_ciphertext_test_s {
  const char* desc;
  const char* plaintext;
  const char* recvPrivKey;
  const char* authSecret;
  const char* ciphertext;
  const char* cryptoKey;
  const char* encryption;
} valid_ciphertext_test_t;

static valid_param_test_t valid_param_tests[] = {
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
    .desc = "Quoted key param",
    .cryptoKey = "dh=\"byfHbUffc-k\"",
    .encryption = "salt=C11AvAsp6Gc",
    .salt = "\x0b\x5d\x40\xbc\x0b\x29\xe8\x67",
    .rawSenderPubKey = "\x6f\x27\xc7\x6d\x47\xdf\x73\xe9",
    .rs = 4096,
  },
  {
    .desc = "Quoted salt param and rs = 24",
    .cryptoKey = "dh=ybuT4VDz-Bg",
    .encryption = "salt=\"H7U7wcIoIKs\"; rs=24",
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
};

static invalid_param_test_t invalid_param_tests[] = {
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
    .desc = "Crypto-Key missing param value",
    .cryptoKey = "dh=",
    .encryption = "salt=Esao8aTBfIk",
    .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
  },
  {
    .desc = "Encryption missing param value with trailing whitespace",
    .cryptoKey = "dh=pbmv1QkcEDY",
    .encryption = "salt= ",
    .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
  },
  {
    .desc = "Crypto-Key param without value",
    .cryptoKey = "dh=pbmv1QkcEDY; keyid, dh=rqowftPcCVo",
    .encryption = "salt=Esao8aTBfIk",
    .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
  },
  {
    .desc = "Encryption param without value",
    .cryptoKey = "dh=pbmv1QkcEDY",
    .encryption = "rs; salt=Esao8aTBfIk",
    .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
  },
  {
    .desc = "Crypto-Key missing param name",
    .cryptoKey = "dh=pbmv1QkcEDY; =rqowftPcCVo",
    .encryption = "salt=Esao8aTBfIk",
    .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
  },
  {
    .desc = "Encryption missing param name",
    .cryptoKey = "dh=pbmv1QkcEDY",
    .encryption = "=Esao8aTBfIk",
    .err = ECE_ERROR_INVALID_ENCRYPTION_HEADER,
  },
  {
    .desc = "Whitespace in quoted value in Crypto-Key header",
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
    .desc = "Invalid character in Crypto-Key param value",
    .cryptoKey = "dh==byfHbUffc-k",
    .encryption = "salt=C11AvAsp6Gc",
    .err = ECE_ERROR_INVALID_CRYPTO_KEY_HEADER,
  },
  {
    .desc = "Invalid character in Encryption param name",
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
    .desc = "Key ID with wrong param name",
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
    .desc = "Invalid Base64url-encoded dh param",
    .cryptoKey = "dh=zzzzz",
    .encryption = "salt=Esao8aTBfIk",
    .err = ECE_ERROR_INVALID_DH,
  },
};

static valid_ciphertext_test_t valid_ciphertext_tests[] = {
  {
    .desc = "padSize = 2, rs = 24, pad = 0",
    .plaintext = "Some message",
    .recvPrivKey = "4h23G_KkXC9TvBSK2v0Q7ImpS2YAuRd8hQyN0rFAwBg",
    .authSecret = "aTDc6JebzR6eScy2oLo4RQ",
    .ciphertext = "Oo34w2F9VVnTMFfKtdx48AZWQ9Li9M6DauWJVgXU",
    .cryptoKey = "dh="
                 "BCHFVrflyxibGLlgztLwKelsRZp4gqX3tNfAKFaxAcBhpvYeN1yIUMrxa"
                 "DKiLh4LNKPtj0BOXGdr-IQ-QP82Wjo",
    .encryption = "salt=zCU18Rw3A5aB_Xi-vfixmA; rs=24",
  },
  {
    .desc = "padSize = 2, rs = 8, pad = 16",
    .plaintext = "Yet another message",
    .recvPrivKey = "4h23G_KkXC9TvBSK2v0Q7ImpS2YAuRd8hQyN0rFAwBg",
    .authSecret = "6plwZnSpVUbF7APDXus3UQ",
    .ciphertext = "uEC5B_tR-fuQ3delQcrzrDCp40W6ipMZjGZ78USDJ5sMj-"
                  "6bAOVG3AK6JqFl9E6AoWiBYYvMZfwThVxmDnw6RHtVeLKFM5DWgl1Ewk"
                  "OohwH2EhiDD0gM3io-d79WKzOPZE9rDWUSv64JstImSfX_"
                  "ADQfABrvbZkeaWxh53EG59QMOElFJqHue4dMURpsMXg",
    .cryptoKey = "dh=BEaA4gzA3i0JDuirGhiLgymS4hfFX7TNTdEhSk_"
                 "HBlLpkjgCpjPL5c-GL9uBGIfa_fhGNKKFhXz1k9Kyens2ZpQ",
    .encryption = "salt=ZFhzj0S-n29g9P2p4-I7tA; rs=8",
  },
  {
    .desc = "padSize = 2, rs = 3, pad = 0",
    .plaintext = "Small record size",
    .recvPrivKey = "4h23G_KkXC9TvBSK2v0Q7ImpS2YAuRd8hQyN0rFAwBg",
    .authSecret = "g2rWVHUCpUxgcL9Tz7vyeQ",
    .ciphertext = "oY4e5eDatDVt2fpQylxbPJM-3vrfhDasfPc8Q1PWt4tPfMVbz_sDNL_"
                  "cvr0DXXkdFzS1lxsJsj550USx4MMl01ihjImXCjrw9R5xFgFrCAqJD3G"
                  "wXA1vzS4T5yvGVbUp3SndMDdT1OCcEofTn7VC6xZ-"
                  "zP8rzSQfDCBBxmPU7OISzr8Z4HyzFCGJeBfqiZ7yUfNlKF1x5UaZ4X6i"
                  "U_TXx5KlQy_"
                  "toV1dXZ2eEAMHJUcSdArvB6zRpFdEIxdcHcJyo1BIYgAYTDdAIy__"
                  "IJVCPY_b2CE5W_"
                  "6ohlYKB7xDyH8giNuWWXAgBozUfScLUVjPC38yJTpAUi6w6pXgXUWffe"
                  "nde5FreQpnMFL1L4G-38wsI_-"
                  "ISIOzdO8QIrXHxmtc1S5xzYu8bMqSgCinvCEwdeGFCmighRjj8t1zRWo"
                  "0D14rHbQLPR_b1P5SvEeJTtS9Nm3iibM",
    .cryptoKey = "dh=BCg6ZIGuE2ZNm2ti6Arf4CDVD_8--"
                 "aLXAGLYhpghwjl1xxVjTLLpb7zihuEOGGbyt8Qj0_"
                 "fYHBP4ObxwJNl56bk",
    .encryption = "salt=5LIDBXbvkBvvb7ZdD-T4PQ; rs=3",
  },
  {
    .desc = "Example from draft-ietf-httpbis-encryption-encoding-02",
    .plaintext = "I am the walrus",
    .recvPrivKey = "9FWl15_QUQAWDaD3k3l50ZBZQJ4au27F1V4F0uLSD_M",
    .authSecret = "R29vIGdvbyBnJyBqb29iIQ",
    .ciphertext = "6nqAQUME8hNqw5J3kl8cpVVJylXKYqZOeseZG8UueKpA",
    .cryptoKey = "keyid=\"dhkey\"; "
                 "dh="
                 "\"BNoRDbb84JGm8g5Z5CFxurSqsXWJ11ItfXEWYVLE85Y7CYkDjXsIEc4"
                 "aqxYaQ1G8BqkXCJ6DPpDrWtdWj_mugHU\"",
    .encryption = "keyid=\"dhkey\"; salt=\"lngarbyKfMoi9Z75xYXmkg\"",
  },
};

void
test_aesgcm_valid_crypto_params() {
  size_t length = sizeof(valid_param_tests) / sizeof(valid_param_test_t);
  for (size_t i = 0; i < length; i++) {
    valid_param_test_t t = valid_param_tests[i];

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
test_aesgcm_invalid_crypto_params() {
  size_t length = sizeof(invalid_param_tests) / sizeof(invalid_param_test_t);
  for (size_t i = 0; i < length; i++) {
    invalid_param_test_t t = invalid_param_tests[i];

    uint8_t salt[8];
    uint32_t rs;
    uint8_t rawSenderPubKey[8];
    int err = ece_webpush_aesgcm_headers_extract_params(
      t.cryptoKey, t.encryption, salt, 8, rawSenderPubKey, 8, &rs);

    ece_assert(err == t.err, "Got %d extracting params for `%s`; want %d", err,
               t.desc, t.err);
  }
}

void
test_aesgcm_valid_ciphertexts() {
  size_t length =
    sizeof(valid_ciphertext_tests) / sizeof(valid_ciphertext_test_t);
  for (size_t i = 0; i < length; i++) {
    valid_ciphertext_test_t t = valid_ciphertext_tests[i];

    uint8_t rawRecvPrivKey[32];
    size_t decodedLen =
      ece_base64url_decode(t.recvPrivKey, strlen(t.recvPrivKey),
                           ECE_BASE64URL_REJECT_PADDING, rawRecvPrivKey, 32);
    ece_assert(decodedLen, "Want decoded receiver private key for `%s`",
               t.desc);

    uint8_t authSecret[16];
    decodedLen =
      ece_base64url_decode(t.authSecret, strlen(t.authSecret),
                           ECE_BASE64URL_REJECT_PADDING, authSecret, 16);
    ece_assert(decodedLen, "Want decoded auth secret length for `%s`", t.desc);

    size_t ciphertextBase64Len = strlen(t.ciphertext);
    decodedLen = ece_base64url_decode(t.ciphertext, ciphertextBase64Len,
                                      ECE_BASE64URL_REJECT_PADDING, NULL, 0);
    ece_assert(decodedLen, "Want decoded ciphertext length for `%s`", t.desc);
    uint8_t* ciphertext = calloc(decodedLen, sizeof(uint8_t));
    ece_assert(ciphertext, "Want ciphertext buffer length %zu for `%s`",
               decodedLen, t.desc);
    decodedLen = ece_base64url_decode(t.ciphertext, ciphertextBase64Len,
                                      ECE_BASE64URL_REJECT_PADDING, ciphertext,
                                      decodedLen);
    ece_assert(decodedLen, "Want decoded ciphertext for `%s`", t.desc);

    size_t plaintextLen = ece_aesgcm_plaintext_max_length(decodedLen);
    ece_assert(plaintextLen, "Want maximum plaintext length for `%s`", t.desc);
    uint8_t* plaintext = calloc(plaintextLen, sizeof(uint8_t));
    ece_assert(plaintext, "Want plaintext buffer length %zu for `%s`",
               plaintextLen, t.desc);

    int err = ece_webpush_aesgcm_decrypt(rawRecvPrivKey, 32, authSecret, 16,
                                         t.cryptoKey, t.encryption, ciphertext,
                                         decodedLen, plaintext, &plaintextLen);
    ece_assert(!err, "Got %d decrypting ciphertext for `%s`", err, t.desc);

    size_t expectedPlaintextLen = strlen(t.plaintext);
    ece_assert(plaintextLen == expectedPlaintextLen,
               "Got plaintext length %zu for `%s`; want %zu", plaintextLen,
               t.desc, expectedPlaintextLen);
    ece_assert(!memcmp(plaintext, t.plaintext, plaintextLen),
               "Wrong plaintext for `%s`", t.desc);

    free(ciphertext);
    free(plaintext);
  }
}
