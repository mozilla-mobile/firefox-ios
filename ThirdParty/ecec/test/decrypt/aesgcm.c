#include "test.h"

#include <string.h>

typedef struct webpush_aesgcm_decrypt_ok_test_s {
  const char* desc;
  const char* plaintext;
  const char* recvPrivKey;
  const char* authSecret;
  const char* ciphertext;
  const char* cryptoKey;
  const char* encryption;
  size_t ciphertextLen;
  size_t maxPlaintextLen;
  size_t plaintextLen;
} webpush_aesgcm_decrypt_ok_test_t;

typedef struct webpush_aesgcm_decrypt_err_test_s {
  const char* desc;
  const char* recvPrivKey;
  const char* authSecret;
  const char* ciphertext;
  const char* cryptoKey;
  const char* encryption;
  size_t maxPlaintextLen;
  size_t ciphertextLen;
  int err;
} webpush_aesgcm_decrypt_err_test_t;

static webpush_aesgcm_decrypt_ok_test_t webpush_aesgcm_decrypt_ok_tests[] = {
  {
    .desc = "rs = 24, pad = 0",
    .plaintext = "Some message",
    .recvPrivKey = "\xe2\x1d\xb7\x1b\xf2\xa4\x5c\x2f\x53\xbc\x14\x8a\xda\xfd"
                   "\x10\xec\x89\xa9\x4b\x66\x00\xb9\x17\x7c\x85\x0c\x8d\xd2"
                   "\xb1\x40\xc0\x18",
    .authSecret =
      "\x69\x30\xdc\xe8\x97\x9b\xcd\x1e\x9e\x49\xcc\xb6\xa0\xba\x38\x45",
    .ciphertext = "\x3a\x8d\xf8\xc3\x61\x7d\x55\x59\xd3\x30\x57\xca\xb5\xdc"
                  "\x78\xf0\x06\x56\x43\xd2\xe2\xf4\xce\x83\x6a\xe5\x89\x56"
                  "\x05\xd4",
    .cryptoKey = "dh="
                 "BCHFVrflyxibGLlgztLwKelsRZp4gqX3tNfAKFaxAcBhpvYeN1yIUMrxa"
                 "DKiLh4LNKPtj0BOXGdr-IQ-QP82Wjo",
    .encryption = "salt=zCU18Rw3A5aB_Xi-vfixmA; rs=24",
    .ciphertextLen = 30,
    .maxPlaintextLen = 14,
    .plaintextLen = 12,
  },
  {
    .desc = "rs = 8, pad = 16",
    .plaintext = "Yet another message",
    .recvPrivKey = "\xe2\x1d\xb7\x1b\xf2\xa4\x5c\x2f\x53\xbc\x14\x8a\xda\xfd"
                   "\x10\xec\x89\xa9\x4b\x66\x00\xb9\x17\x7c\x85\x0c\x8d\xd2"
                   "\xb1\x40\xc0\x18",
    .authSecret =
      "\xea\x99\x70\x66\x74\xa9\x55\x46\xc5\xec\x03\xc3\x5e\xeb\x37\x51",
    .ciphertext =
      "\xb8\x40\xb9\x07\xfb\x51\xf9\xfb\x90\xdd\xd7\xa5\x41\xca\xf3\xac\x30"
      "\xa9\xe3\x45\xba\x8a\x93\x19\x8c\x66\x7b\xf1\x44\x83\x27\x9b\x0c\x8f"
      "\xee\x9b\x00\xe5\x46\xdc\x02\xba\x26\xa1\x65\xf4\x4e\x80\xa1\x68\x81"
      "\x61\x8b\xcc\x65\xfc\x13\x85\x5c\x66\x0e\x7c\x3a\x44\x7b\x55\x78\xb2"
      "\x85\x33\x90\xd6\x82\x5d\x44\xc2\x43\xa8\x87\x01\xf6\x12\x18\x83\x0f"
      "\x48\x0c\xde\x2a\x3e\x77\xbf\x56\x2b\x33\x8f\x64\x4f\x6b\x0d\x65\x12"
      "\xbf\xae\x09\xb2\xd2\x26\x49\xf5\xff\x00\x34\x1f\x00\x1a\xef\x6d\x99"
      "\x1e\x69\x6c\x61\xe7\x71\x06\xe7\xd4\x0c\x38\x49\x45\x26\xa1\xee\x7b"
      "\x87\x4c\x51\x1a\x6c\x31\x78",
    .cryptoKey = "dh=BEaA4gzA3i0JDuirGhiLgymS4hfFX7TNTdEhSk_"
                 "HBlLpkjgCpjPL5c-GL9uBGIfa_fhGNKKFhXz1k9Kyens2ZpQ",
    .encryption = "salt=ZFhzj0S-n29g9P2p4-I7tA; rs=8",
    .ciphertextLen = 143,
    .maxPlaintextLen = 47,
    .plaintextLen = 19,
  },
  {
    .desc = "rs = 3, pad = 0",
    .plaintext = "Small record size",
    .recvPrivKey = "\xe2\x1d\xb7\x1b\xf2\xa4\x5c\x2f\x53\xbc\x14\x8a\xda\xfd"
                   "\x10\xec\x89\xa9\x4b\x66\x00\xb9\x17\x7c\x85\x0c\x8d\xd2"
                   "\xb1\x40\xc0\x18",
    .authSecret =
      "\x83\x6a\xd6\x54\x75\x02\xa5\x4c\x60\x70\xbf\x53\xcf\xbb\xf2\x79",
    .ciphertext =
      "\xa1\x8e\x1e\xe5\xe0\xda\xb4\x35\x6d\xd9\xfa\x50\xca\x5c\x5b\x3c\x93"
      "\x3e\xde\xfa\xdf\x84\x36\xac\x7c\xf7\x3c\x43\x53\xd6\xb7\x8b\x4f\x7c"
      "\xc5\x5b\xcf\xfb\x03\x34\xbf\xdc\xbe\xbd\x03\x5d\x79\x1d\x17\x34\xb5"
      "\x97\x1b\x09\xb2\x3e\x79\xd1\x44\xb1\xe0\xc3\x25\xd3\x58\xa1\x8c\x89"
      "\x97\x0a\x3a\xf0\xf5\x1e\x71\x16\x01\x6b\x08\x0a\x89\x0f\x71\xb0\x5c"
      "\x0d\x6f\xcd\x2e\x13\xe7\x2b\xc6\x55\xb5\x29\xdd\x29\xdd\x30\x37\x53"
      "\xd4\xe0\x9c\x12\x87\xd3\x9f\xb5\x42\xeb\x16\x7e\xcc\xff\x2b\xcd\x24"
      "\x1f\x0c\x20\x41\xc6\x63\xd4\xec\xe2\x12\xce\xbf\x19\xe0\x7c\xb3\x14"
      "\x21\x89\x78\x17\xea\x89\x9e\xf2\x51\xf3\x65\x28\x5d\x71\xe5\x46\x99"
      "\xe1\x7e\xa2\x53\xf4\xd7\xc7\x92\xa5\x43\x2f\xed\xa1\x5d\x5d\x5d\x9d"
      "\x9e\x10\x03\x07\x25\x47\x12\x74\x0a\xef\x07\xac\xd1\xa4\x57\x44\x23"
      "\x17\x5c\x1d\xc2\x72\xa3\x50\x48\x62\x00\x18\x4c\x37\x40\x23\x2f\xff"
      "\x20\x95\x42\x3d\x8f\xdb\xd8\x21\x39\x5b\xfe\xa8\x86\x56\x0a\x07\xbc"
      "\x43\xc8\x7f\x20\x88\xdb\x96\x59\x70\x20\x06\x8c\xd4\x7d\x27\x0b\x51"
      "\x58\xcf\x0b\x7f\x32\x25\x3a\x40\x52\x2e\xb0\xea\x95\xe0\x5d\x45\x9f"
      "\x7d\xe9\xdd\x7b\x91\x6b\x79\x0a\x67\x30\x52\xf5\x2f\x81\xbe\xdf\xcc"
      "\x2c\x23\xff\x88\x48\x83\xb3\x74\xef\x10\x22\xb5\xc7\xc6\x6b\x5c\xd5"
      "\x2e\x71\xcd\x8b\xbc\x6c\xca\x92\x80\x28\xa7\xbc\x21\x30\x75\xe1\x85"
      "\x0a\x68\xa0\x85\x18\xe3\xf2\xdd\x73\x45\x6a\x34\x0f\x5e\x2b\x1d\xb4"
      "\x0b\x3d\x1f\xdb\xd4\xfe\x52\xbc\x47\x89\x4e\xd4\xbd\x36\x6d\xe2\x89"
      "\xb3",
    .cryptoKey = "dh=BCg6ZIGuE2ZNm2ti6Arf4CDVD_8--"
                 "aLXAGLYhpghwjl1xxVjTLLpb7zihuEOGGbyt8Qj0_"
                 "fYHBP4ObxwJNl56bk",
    .encryption = "salt=5LIDBXbvkBvvb7ZdD-T4PQ; rs=3",
    .ciphertextLen = 341,
    .maxPlaintextLen = 53,
    .plaintextLen = 17,
  },
  {
    .desc = "Example from draft-ietf-httpbis-encryption-encoding-02",
    .plaintext = "I am the walrus",
    .recvPrivKey = "\xf4\x55\xa5\xd7\x9f\xd0\x51\x00\x16\x0d\xa0\xf7\x93\x79"
                   "\x79\xd1\x90\x59\x40\x9e\x1a\xbb\x6e\xc5\xd5\x5e\x05\xd2"
                   "\xe2\xd2\x0f\xf3",
    .authSecret =
      "\x47\x6f\x6f\x20\x67\x6f\x6f\x20\x67\x27\x20\x6a\x6f\x6f\x62\x21",
    .ciphertext = "\xea\x7a\x80\x41\x43\x04\xf2\x13\x6a\xc3\x92\x77\x92\x5f"
                  "\x1c\xa5\x55\x49\xca\x55\xca\x62\xa6\x4e\x7a\xc7\x99\x1b"
                  "\xc5\x2e\x78\xaa\x40",
    .cryptoKey = "keyid=\"dhkey\"; "
                 "dh="
                 "\"BNoRDbb84JGm8g5Z5CFxurSqsXWJ11ItfXEWYVLE85Y7CYkDjXsIEc4"
                 "aqxYaQ1G8BqkXCJ6DPpDrWtdWj_mugHU\"",
    .encryption = "keyid=\"dhkey\"; salt=\"lngarbyKfMoi9Z75xYXmkg\"",
    .ciphertextLen = 33,
    .maxPlaintextLen = 17,
    .plaintextLen = 15,
  },
};

static webpush_aesgcm_decrypt_err_test_t webpush_aesgcm_decrypt_err_tests[] = {
  {
    .desc = "rs = 7, no trailer",
    .recvPrivKey = "\xd9\xbb\xb8\xa5\xa3\x80\x65\xb2\xf6\x79\xfd\x6e\xfb\x04"
                   "\xf3\x38\xdb\x93\x21\xc0\xcf\x73\x4d\x28\xd3\x35\x09\x82"
                   "\x0e\x3a\x5d\x37",
    .authSecret =
      "\x42\x80\xe2\xd2\xee\xaf\x72\xc9\x48\x54\x92\xa2\xa2\xe5\xcc\x5f",
    // "O hai". The ciphertext is exactly `rs + 16`, without a trailer.
    .ciphertext = "\x60\x6e\x05\xf9\xbd\x3a\xcb\x9f\x74\x85\x19\x67\x4a\xcc\x3f"
                  "\xbe\xe3\xb0\xeb\x65\x7d\x23\x3f",
    .cryptoKey = "dh=BD_"
                 "bsTUpxBMvSv8eksith3vijMLj44D4jhJjO51y7wK1ytbUlsyYBBYYyB5AAe5b"
                 "nREA_WipTgemDVz00LiWcfM",
    .encryption = "salt=xKWvs_jWWeg4KOsot_uBhA; rs=7",
    .ciphertextLen = 23,
    .maxPlaintextLen = 7,
    .err = ECE_ERROR_DECRYPT_TRUNCATED,
  },
  {
    // Last block is only 1 byte; pad length prefix is 2 bytes.
    .desc = "Pad size > last block length",
    .recvPrivKey = "\x0a\x8b\x04\x44\x05\x57\x82\xf4\xef\xa2\x1e\xd4\x92\xb4"
                   "\x42\xd9\x5f\xa2\x5e\x83\x6c\xd1\xb5\xe5\x7b\xd2\x3a\xf2"
                   "\xac\xe4\x95\xeb",
    .authSecret =
      "\x42\xd1\x99\x79\x8f\x0c\x41\xf0\x9a\xab\xe5\xf0\x28\xe5\x46\x05",
    .ciphertext = "\x26\xf5\xfd\x1e\xc2\x78\x94\xbe\x60\xcc\xff\x3f\xb8\x22\x9c"
                  "\xea\xcd\x79\x89\x12\x1a\x36\x10\xf8\xa4\x50\xa0\xab\x9f\x9d"
                  "\x7f\x06\xd4\xa8\x47\x0d\x52\x4a\xaf",
    .cryptoKey = "dh=BBNZNEi5Ew_ID5S4Y9jWBi1NeVDje6Mjs7SDLViUn6A8VAZj-"
                 "6X3QAuYQ3j20BblqjwTgYst7PRnY6UGrKyLbmU",
    .encryption = "salt=ot8hzbwOo6CYe6ZhdlwKtg; rs=6",
    .ciphertextLen = 39,
    .maxPlaintextLen = 7,
    .err = ECE_ERROR_DECRYPT_PADDING,
  },
  {
    // Last block is 1 byte, but claims its pad length is 2.
    .desc = "Padding length > last block length",
    .recvPrivKey = "\xf6\x5f\x9a\x85\xc0\x4c\xf8\x8d\x32\x93\x06\xd6\x88\x34"
                   "\xbd\x29\x1a\xcf\x76\x1c\xaf\x4d\x9d\x12\xc4\xa8\x8f\xa6"
                   "\x3d\x9a\x79\xa2",
    .authSecret =
      "\x80\xa1\xbf\x3f\xaf\x9d\x7b\x9a\x72\xcd\x2f\x21\xc8\x7f\xcd\xc9",
    .ciphertext = "\xa1\x64\x8e\x14\x0f\x94\x3b\x9a\x16\xab\xe9\x08\xef\xd4\x47"
                  "\x68\x57\xf0\x01\xe8\xcb\x89\x02\x78\x0b\xb7\x93\x9a\xb4\x93"
                  "\x06\x5e\x20\x02\xb2\xd7\x7f\x1e\xe5\x67\xe6",
    .cryptoKey = "dh=BKe2IBO_cwmEzQyTVscSbQcj0Y3uBSzGZ_mHlANMciS8uGpb7U8_"
                 "Bw7TNdlYfpwWDLd0cxM8YYWNDbNJ_p2Rp4o",
    .encryption = "salt=z7QJ6UR89SiFRkd4RsC4Vg; rs=6",
    .ciphertextLen = 41,
    .maxPlaintextLen = 9,
    .err = ECE_ERROR_DECRYPT_PADDING,
  },
  {
    // First block has no padding, but claims its pad length is 1.
    .desc = "Non-zero padding",
    .recvPrivKey = "\x23\x3b\x9a\xc4\xba\x85\x26\x68\xd2\xbb\xc1\xa3\x2c\x2a"
                   "\x36\xa0\x46\x83\x66\x30\xc1\xba\xd5\xb8\x9b\x84\xf4\xab"
                   "\x1d\x36\x5e\xc3",
    .authSecret =
      "\x70\xca\x56\x41\x6e\x7c\x06\xba\x43\x6c\x9f\x0a\xa9\xb4\xbd\x8a",
    .ciphertext = "\x41\xdb\xe3\x87\x42\xe4\x65\x72\xae\xff\x51\xef\xbf\x9e\x83"
                  "\xd2\xb3\x92\x17\xa3\x30\xc3\x7c\xb4\x17\xcc\x64\xc5\x43\x65"
                  "\xc1\x5b\xb6\x53\x58\x9a\x90\xe5\x14\x19\x1b",
    .cryptoKey = "dh=BBicj01QI0ryiFzAaty9VpW_crgq9XbU1bOCtEZI9UNE6tuOgp4lyN_"
                 "UN0N905ECnLWK5v_sCPUIxnQgOuCseSo",
    .encryption = "salt=SbkGHONbQBBsBcj9dLyIUw; rs=6",
    .ciphertextLen = 41,
    .maxPlaintextLen = 9,
    .err = ECE_ERROR_DECRYPT_PADDING,
  },
  {
    .desc = "rs = 6, auth tag for last record",
    .recvPrivKey = "\x9e\x13\x93\xf7\x5e\xf5\xc6\xea\x10\x04\x91\xa4\x89\x9d"
                   "\xda\xa9\x3e\x6a\xc3\xf2\x0b\x27\xde\x3f\x3c\xf8\x95\x36"
                   "\xed\x4b\x15\x26",
    .authSecret =
      "\xde\xb5\xa1\xb1\x10\x94\xfc\xa7\x5a\xa9\xf2\x8f\x6d\xdd\xf3\x05",
    .ciphertext = "\x0b\xbb\xb7\x8f\x90\x0b\xe1\x8c\xe1\xdb\x26\x01\xfe\xe9\x8d"
                  "\xea\xdc\xeb\x54\x7c\x6b\xb7\xb0\xf9\x6d\xa4\xc4\x5b\xd0\xc4"
                  "\xd4\x19\x37\xba\x9f\x5f\x63\x8c",
    .cryptoKey = "dh=BI38Qs_OhDmQIxbszc6Nako-MrX3FzAE_8HzxM1wgoEIG4ocxyF-"
                 "YAAVhfkpJUvDpRyKW2LDHIaoylaZuxQfRhE",
    .encryption = "salt=QClh48OlvGpSjZ0Mg0e8rg; rs=6",
    .ciphertextLen = 38,
    .maxPlaintextLen = 6,
    .err = ECE_ERROR_SHORT_BLOCK,
  },
};

void
test_webpush_aesgcm_decrypt_ok(void) {
  size_t length = sizeof(webpush_aesgcm_decrypt_ok_tests) /
                  sizeof(webpush_aesgcm_decrypt_ok_test_t);
  for (size_t i = 0; i < length; i++) {
    webpush_aesgcm_decrypt_ok_test_t t = webpush_aesgcm_decrypt_ok_tests[i];

    const void* recvPrivKey = t.recvPrivKey;
    const void* authSecret = t.authSecret;
    const void* ciphertext = t.ciphertext;

    uint8_t salt[ECE_SALT_LENGTH];
    uint8_t rawSenderPubKey[ECE_WEBPUSH_PUBLIC_KEY_LENGTH];
    uint32_t rs;
    int err = ece_webpush_aesgcm_headers_extract_params(
      t.cryptoKey, t.encryption, salt, ECE_SALT_LENGTH, rawSenderPubKey,
      ECE_WEBPUSH_PUBLIC_KEY_LENGTH, &rs);
    ece_assert(!err, "Got %d parsing crypto headers", err);

    size_t plaintextLen = ece_aesgcm_plaintext_max_length(rs, t.ciphertextLen);
    ece_assert(plaintextLen == t.maxPlaintextLen,
               "Got plaintext max length %zu for `%s`; want %zu", plaintextLen,
               t.desc, t.maxPlaintextLen);

    uint8_t* plaintext = calloc(plaintextLen, sizeof(uint8_t));

    err = ece_webpush_aesgcm_decrypt(
      recvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH, authSecret,
      ECE_WEBPUSH_AUTH_SECRET_LENGTH, salt, ECE_SALT_LENGTH, rawSenderPubKey,
      ECE_WEBPUSH_PUBLIC_KEY_LENGTH, rs, ciphertext, t.ciphertextLen, plaintext,
      &plaintextLen);
    ece_assert(!err, "Got %d decrypting ciphertext for `%s`", err, t.desc);

    ece_assert(plaintextLen == t.plaintextLen,
               "Got plaintext length %zu for `%s`; want %zu", plaintextLen,
               t.desc, t.plaintextLen);
    ece_assert(!memcmp(plaintext, t.plaintext, plaintextLen),
               "Wrong plaintext for `%s`", t.desc);

    free(plaintext);
  }
}

void
test_webpush_aesgcm_decrypt_err(void) {
  size_t tests = sizeof(webpush_aesgcm_decrypt_err_tests) /
                 sizeof(webpush_aesgcm_decrypt_err_test_t);
  for (size_t i = 0; i < tests; i++) {
    webpush_aesgcm_decrypt_err_test_t t = webpush_aesgcm_decrypt_err_tests[i];

    const void* recvPrivKey = t.recvPrivKey;
    const void* authSecret = t.authSecret;
    const void* ciphertext = t.ciphertext;

    uint8_t salt[ECE_SALT_LENGTH];
    uint8_t rawSenderPubKey[ECE_WEBPUSH_PUBLIC_KEY_LENGTH];
    uint32_t rs;
    int err = ece_webpush_aesgcm_headers_extract_params(
      t.cryptoKey, t.encryption, salt, ECE_SALT_LENGTH, rawSenderPubKey,
      ECE_WEBPUSH_PUBLIC_KEY_LENGTH, &rs);
    ece_assert(!err, "Got %d parsing crypto headers", err);

    size_t plaintextLen = ece_aesgcm_plaintext_max_length(rs, t.ciphertextLen);
    ece_assert(plaintextLen == t.maxPlaintextLen,
               "Got plaintext max length %zu for `%s`; want %zu", plaintextLen,
               t.desc, t.maxPlaintextLen);

    uint8_t* plaintext = calloc(plaintextLen, sizeof(uint8_t));

    err = ece_webpush_aesgcm_decrypt(
      recvPrivKey, ECE_WEBPUSH_PRIVATE_KEY_LENGTH, authSecret,
      ECE_WEBPUSH_AUTH_SECRET_LENGTH, salt, ECE_SALT_LENGTH, rawSenderPubKey,
      ECE_WEBPUSH_PUBLIC_KEY_LENGTH, rs, ciphertext, t.ciphertextLen, plaintext,
      &plaintextLen);
    ece_assert(err == t.err, "Got %d decrypting ciphertext for `%s`; want %d",
               err, t.desc, t.err);

    free(plaintext);
  }
}
