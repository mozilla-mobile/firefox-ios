#include "test.h"

#include <string.h>

typedef struct encrypt_test_s {
  const char* desc;
  const char* ikm;
  const char* salt;
  uint32_t rs;
} encrypt_test_t;

typedef struct webpush_encrypt_test_s {
  const char* desc;
  const char* payload;
  const char* senderPrivKey;
  const char* recvPubKey;
  const char* authSecret;
  const char* salt;
  const char* plaintext;
  uint32_t rs;
  uint8_t pad;
} webpush_encrypt_test_t;

typedef struct webpush_valid_decrypt_test_s {
  const char* desc;
  const char* plaintext;
  const char* recvPrivKey;
  const char* authSecret;
  const char* payload;
} webpush_valid_decrypt_test_t;

typedef struct invalid_decrypt_test_s {
  const char* desc;
  const char* ikm;
  const char* payload;
  int err;
} invalid_decrypt_test_t;

static webpush_encrypt_test_t webpush_encrypt_tests[] = {
  {
    .desc = "Example from draft-ietf-webpush-encryption-latest",
    .payload = "DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_"
               "c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru"
               "3jl7A_"
               "yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgS"
               "xsj_Qulcy4a-fN",
    .senderPrivKey = "yfWPiYE-n46HLnH0KqZOF1fJJU3MYrct3AELtAQ-oRw",
    .recvPubKey = "BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-"
                  "AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4",
    .authSecret = "BTBZMqHH6r4Tts7J_aSIgg",
    .salt = "DGv6ra1nlYgDCS1FRnbzlw",
    .plaintext = "When I grow up, I want to be a watermelon",
    .rs = 4096,
    .pad = 0,
  },
  {
    .desc = "rs = 24, pad = 6",
    .payload =
      "_4BQMKEI4RTmwX-tYYahpgAAABhBBDDvyx6wQ7gF5ORLqzX4JRPDP-"
      "2yhwD35Wisi2Ho2DVmWlHrZnmy2yKKEMDD_lB3BihI2bs9YCefk841SEcoqh_"
      "SwXE5Sa7JjwUJbHKY_T9RxPgY-"
      "vof5hXYRHs6BUBgMfZAGsJPKndcpSRWqSG4O54AQsOmPhr6GuASd02dd1vo0ZQZRR03_1n_"
      "WS6E8HRApj_Bf1yry5pQ7dr3U3DbZH-URH0_FmJp2HEd8PV-"
      "VgSVduETClpeH5S6il0LAAfGwP0pmEKefWPU75GXmPRuz18LKPuA9bJDneJrilIgC8fWr3pI"
      "QHIf6L6FJKaRtu8O2ukLtvWSeJSBm4MbRbU_hAH-Ai27ZO11ZTUJBKwLUXE11_"
      "irvJgSf7Fjhk1NSjB0JbLNQ9siryZ9ccNxRplKjEgFrcNBv7onrwn9gL1e_1HYdygqL7-_"
      "6xAZnnh55LnROkbVf7fXhoJIU-HMicr7rxTeHpJMlE_ri2Js4CB9b5-"
      "p2EnuysabQtbnojvVEk1JYitEs1xbFfsOaneBpQPxpOBi4BXVV9ldRNnYsHmbOq_Og9XU",
    .senderPrivKey = "Dyi-r34neTwDY43ClzoVsAFuGzZ8v_2ohhqxdfMbzgI",
    .recvPubKey = "BMDRqBKykSkd177uNYcTwSbFifNjPCbRogExHeA23BCTHk7hQvYZIaPqWGTo"
                  "cqk4QaUpROWz9qzOzOjIKPsEpM0",
    .authSecret = "nXc12N4ZYrmDlLB__ih-IA",
    .salt = "_4BQMKEI4RTmwX-tYYahpg",
    .plaintext = "I am the very model of a modern Major-General, I've "
                 "information vegetable, animal, and mineral",
    .rs = 24,
    .pad = 6,
  },
  {
    // This test is also interesting because the data length (54) is a multiple
    // of rs (18). We'll allocate memory to hold 4 records, but only write 3.
    .desc = "rs = 18, pad = 31",
    .payload = "5JiI0rKPJ3-Ee8XelvD4GwAAABJBBAC4M-SBqZqjMNyyd5ItX4SvLpzmEa0q0-"
               "0PW0MZEtNepy_Fv3a3adlSZ3j1q_oFhlCYjaXlMf-"
               "C0acEN5THFwY665WL8Ra8z1B0L9TWm9Dqfj9hHHCb8s31zUfGQmy4MjtTmMQ8DQ"
               "uSzJgtocJM5f7isgP3rXjKRPBJDzQH9f7ogyZu5HA1GV3g_"
               "m2KdeSH3yVttZenXkWuT7VbglnLCy0Z57BXFCZ-"
               "tWCuByt6ZllRkXoGhzLfMJviVvkPKt2jLwX-"
               "ql6bBpW8oszyKq78fanO68XUDBLTKttchMsyCvlEAWCVNi_ruk_"
               "6SpmDDklY6iu6UIy2g6WNICfUt0cmqFOyS0fMunUavp2astqewrqcfM8M8XMFuu"
               "MU04podhiwdy_LcdRBkCekv0NctyGq1078F5mBtxaWBL-"
               "X7KxB5ziERWkzc0gYEykjtWwVLWyeWa75laylneC_LIA6BxgIiWcKCOZKINK_"
               "qFPgEShylHuqr_"
               "tRDMnnXWMQ7WqsvS4Lo6Kb5CxlMupOM0bh8FcWRjcccWZeP6yddvruHxIuZNSQ3"
               "So-MYFuq1g_FyhBoHXSBfMYcUqMcM4PMn9NkrjJ3LgT5tJP6FYz8anHweSh-"
               "zFN1f4-KA45CPNsjL-4C32SQ6uv-mXCFs8aqLjWJqYw3-"
               "gYbOl3pbjzZJ03U7kXbDZ-TgfyIKF1gGE46IglovNJhCBYK5Yglli7-"
               "o8rppM6g8Je2yaRh3llQuKsSbgHhja93CaOEWJei_-"
               "fCjQ9OkwGCA7wgDuNzY6EHQ4nWeSD6hm5AzJNnsTVL0kazvPu_"
               "0QcN4gcdZPqwxYhM3pehln5PiAHmw4m6_"
               "5WwQRV0QlxEwvSosFZx09IsuUmUwp29kzKLvskbnk9Eft1pmgBjnDDEHEA-"
               "BujsWrkCoOPGNTEfx1xMvF0aI7FOCOU4BGZIXMaFoebhY_zj3KFHqPZ9SY_"
               "7FpgbRJxqJuEzKU-"
               "1zxSVOJFv48vJ8LByH857qeMcBfIxrWrAWYwMrWNoxBXKF5WwgP05I1nicZrJpW"
               "pAOAEgr2EZVns3dQCZLOOJ5ZH0ewPzNwYgYOLvgyDXiaQ7wWLj2oD4pzZ65WE6X"
               "-8MJdzw2iOXgP5044-"
               "RUhzil9WnFkUfT6CPMyscdXogl1RNM6YE80Lj5Yno9v6Rbg6Wcg9K0061Dd3ijy"
               "xvHe6FskjBvQmGiofDVx-2uz5JvktfJ38rodROmi4x-"
               "98YyZLhYdnwRqqQdJ8Y29S4oVR6TqWnNyW1Dhnt8vWj-"
               "A1e9M0FfryKq7ryVf0tXN6BKtyd7TtQAjwntr_"
               "Wm22n2ywbz0LdmiJBrL1OyfmPzcoui7aUF-xsy-B3dxtMF_"
               "VlJ7dBUkMsWGPDOFDDp9e31ABLcM",
    .senderPrivKey = "eDBXe6_PxFgo2gxAqrCfsie_6uBoqrjAZCIqy-bv_TQ",
    .recvPubKey = "BMPXFMtC4rCh1vmFmeLxhrjCum9vq14JoqvKhlwIBYkrLDcpMw74PcnfS0Q2"
                  "KwOaBgnTa-uTIaQx7BI1Bt3ZDyQ",
    .authSecret = "5Ne3neze3hLD6dkNPgVzDw",
    .salt = "5JiI0rKPJ3-Ee8XelvD4Gw",
    .plaintext = "Push the button, Frank!",
    .rs = 18,
    .pad = 31,
  },
};

static webpush_valid_decrypt_test_t webpush_valid_decrypt_tests[] = {
  {
    .desc = "rs = 24",
    .plaintext = "I am the walrus",
    .recvPrivKey = "yJnRHTLit-b-dJh4b1DyO5is5Tl60mHeObpkSezBLK0",
    .authSecret = "mW-ti1CqLQK4PyZBKy4q7g",
    .payload = "SVzmyN6TpFOehi6GNJk8uwAAABhBBDwzeKLAq5VOFJhxjoXwi7cj-"
               "30l4TWmY_44WITrgZIza_"
               "kKVO1yDxwEXAtAXpu8OiFCsWyJCGc0w3Trr3CZ5kJ-"
               "LTLIraUBhwPFSxC0geECfXIJ2Ma0NVP6Ezr6WX8t3EWluoFAlE5kkLuNbZm"
               "6HQLmDZX0jOZER3wXIx2VuXpPld0",
  },
  {
    .desc = "Example from draft-ietf-webpush-encryption-latest",
    .plaintext = "When I grow up, I want to be a watermelon",
    .recvPrivKey = "q1dXpw3UpT5VOmu_cf_v6ih07Aems3njxI-JWgLcM94",
    .authSecret = "BTBZMqHH6r4Tts7J_aSIgg",
    .payload = "DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_"
               "c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru"
               "3jl7A_"
               "yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgS"
               "xsj_Qulcy4a-fN",
  },
};

static invalid_decrypt_test_t invalid_decrypt_tests[] = {
  {
    .desc = "rs <= block overhead",
    .ikm = "L7F1wnG5L2tV5PKiUtFFQw",
    .payload = "dvkdSE6EkdpVxfe_5tM-iQAAAAIA",
    .err = ECE_ERROR_INVALID_RS,
  },
  {
    .desc = "Zero plaintext",
    .ikm = "ZMcOZKclVRRR8gjfuqC5cg",
    .payload = "qtIFfTNTt_83veQq4dUP2gAAACAAu8e5ZXYL8GYrk_Tl1pS3ZfDNFZsoAaU",
    .err = ECE_ERROR_ZERO_PLAINTEXT,
  },
  {
    .desc = "Bad early padding delimiter",
    .ikm = "ZMcOZKclVRRR8gjfuqC5cg",
    .payload = "qtIFfTNTt_"
               "83veQq4dUP2gAAACAAuce5ZXYL8J5CsQhDOHWjBsl4Bgr8fH3pUoWRi1gCYPNFO"
               "Hoo5SVmL0jBwzIEsZW1Tp5w1A488-8MZxvgFEl-3A",
    .err = ECE_ERROR_DECRYPT_PADDING,
  },
  {
    .desc = "Bad final padding delimiter",
    .ikm = "ZMcOZKclVRRR8gjfuqC5cg",
    .payload =
      "qtIFfTNTt_83veQq4dUP2gAAACAAuse5ZXYL8J5CsQhKaeRQG41J28Z5I01HwlcW",
    .err = ECE_ERROR_DECRYPT_PADDING,
  },
  {
    .desc = "Invalid auth tag",
    .ikm = "ZMcOZKclVRRR8gjfuqC5cg",
    .payload =
      "qtIFfTNTt_83veQq4dUP2gAAACAAu8axHUY6fg8HK76qRODWLkvl-V0l44Zx4H0",
    .err = ECE_ERROR_DECRYPT,
  },
};

void
test_webpush_aes128gcm_encrypt() {
  size_t tests = sizeof(webpush_encrypt_tests) / sizeof(webpush_encrypt_test_t);
  for (size_t i = 0; i < tests; i++) {
    webpush_encrypt_test_t t = webpush_encrypt_tests[i];

    uint8_t rawSenderPrivKey[32];
    size_t decodedLen =
      ece_base64url_decode(t.senderPrivKey, strlen(t.senderPrivKey),
                           ECE_BASE64URL_REJECT_PADDING, rawSenderPrivKey, 32);
    ece_assert(decodedLen, "Want decoded sender private key for `%s`", t.desc);

    uint8_t rawRecvPubKey[65];
    decodedLen =
      ece_base64url_decode(t.recvPubKey, strlen(t.recvPubKey),
                           ECE_BASE64URL_REJECT_PADDING, rawRecvPubKey, 65);
    ece_assert(decodedLen, "Want decoded receiver public key for `%s`", t.desc);

    uint8_t authSecret[16];
    decodedLen =
      ece_base64url_decode(t.authSecret, strlen(t.authSecret),
                           ECE_BASE64URL_REJECT_PADDING, authSecret, 16);
    ece_assert(decodedLen, "Want decoded auth secret for `%s`", t.desc);

    uint8_t salt[16];
    decodedLen = ece_base64url_decode(t.salt, strlen(t.salt),
                                      ECE_BASE64URL_REJECT_PADDING, salt, 16);
    ece_assert(decodedLen, "Want decoded salt for `%s`", t.desc);

    size_t expectedPayloadBase64Len = strlen(t.payload);
    decodedLen = ece_base64url_decode(t.payload, expectedPayloadBase64Len,
                                      ECE_BASE64URL_REJECT_PADDING, NULL, 0);
    ece_assert(decodedLen, "Want decoded expected payload length for `%s`",
               t.desc);
    uint8_t* expectedPayload = calloc(decodedLen, sizeof(uint8_t));
    ece_assert(expectedPayload,
               "Want expected payload buffer length %zu for `%s`", decodedLen,
               t.desc);
    size_t expectedPayloadLen = ece_base64url_decode(
      t.payload, expectedPayloadBase64Len, ECE_BASE64URL_REJECT_PADDING,
      expectedPayload, decodedLen);
    ece_assert(expectedPayloadLen, "Want decoded expected payload for `%s`",
               t.desc);

    size_t plaintextLen = strlen(t.plaintext);
    uint8_t* plaintext = calloc(plaintextLen, sizeof(uint8_t));
    ece_assert(plaintext, "Want plaintext buffer length %zu for `%s`",
               plaintextLen, t.desc);
    memcpy(plaintext, t.plaintext, plaintextLen);

    size_t payloadLen =
      ece_aes128gcm_payload_max_length(t.rs, t.pad, plaintextLen);
    ece_assert(payloadLen, "Want maximum payload length for `%s`", t.desc);
    uint8_t* payload = calloc(payloadLen, sizeof(uint8_t));
    ece_assert(payload, "Want payload buffer length %zu for `%s`", payloadLen,
               t.desc);

    int err = ece_aes128gcm_encrypt_with_keys(
      rawSenderPrivKey, 32, authSecret, 16, salt, 16, rawRecvPubKey, 65, t.rs,
      t.pad, plaintext, plaintextLen, payload, &payloadLen);
    ece_assert(!err, "Got %d encrypting payload for `%s`", err, t.desc);

    ece_assert(payloadLen == expectedPayloadLen,
               "Got payload length %zu for `%s`; want %zu", payloadLen, t.desc,
               expectedPayloadLen);
    ece_assert(!memcmp(payload, expectedPayload, payloadLen),
               "Wrong payload for `%s`", t.desc);

    free(expectedPayload);
    free(plaintext);
    free(payload);
  }
}

void
test_webpush_aes128gcm_decrypt_valid_payloads() {
  size_t tests =
    sizeof(webpush_valid_decrypt_tests) / sizeof(webpush_valid_decrypt_test_t);
  for (size_t i = 0; i < tests; i++) {
    webpush_valid_decrypt_test_t t = webpush_valid_decrypt_tests[i];

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
    ece_assert(decodedLen, "Want decoded auth secret for `%s`", t.desc);

    size_t payloadBase64Len = strlen(t.payload);
    decodedLen = ece_base64url_decode(t.payload, payloadBase64Len,
                                      ECE_BASE64URL_REJECT_PADDING, NULL, 0);
    ece_assert(decodedLen, "Want decoded payload length for `%s`", t.desc);
    uint8_t* payload = calloc(decodedLen, sizeof(uint8_t));
    ece_assert(payload, "Want payload buffer length %zu for `%s`", decodedLen,
               t.desc);
    decodedLen =
      ece_base64url_decode(t.payload, payloadBase64Len,
                           ECE_BASE64URL_REJECT_PADDING, payload, decodedLen);
    ece_assert(decodedLen, "Want decoded payload for `%s`", t.desc);

    size_t plaintextLen =
      ece_aes128gcm_plaintext_max_length(payload, decodedLen);
    ece_assert(plaintextLen, "Want maximum plaintext length for `%s`", t.desc);
    uint8_t* plaintext = calloc(plaintextLen, sizeof(uint8_t));
    ece_assert(plaintext, "Want plaintext buffer length %zu for `%s`",
               plaintextLen, t.desc);

    int err =
      ece_webpush_aes128gcm_decrypt(rawRecvPrivKey, 32, authSecret, 16, payload,
                                    decodedLen, plaintext, &plaintextLen);
    ece_assert(!err, "Got %d decrypting payload for `%s`", err, t.desc);

    size_t expectedLen = strlen(t.plaintext);
    ece_assert(plaintextLen == expectedLen,
               "Got plaintext length %zu for `%s`; want %zu", plaintextLen,
               t.desc, expectedLen);
    ece_assert(!memcmp(plaintext, t.plaintext, plaintextLen),
               "Wrong plaintext for `%s`", t.desc);

    free(payload);
    free(plaintext);
  }
}

void
test_aes128gcm_decrypt_invalid_payloads() {
  size_t tests = sizeof(invalid_decrypt_tests) / sizeof(invalid_decrypt_test_t);
  for (size_t i = 0; i < tests; i++) {
    invalid_decrypt_test_t t = invalid_decrypt_tests[i];

    uint8_t ikm[16];
    size_t decodedLen = ece_base64url_decode(
      t.ikm, strlen(t.ikm), ECE_BASE64URL_REJECT_PADDING, ikm, 16);
    ece_assert(decodedLen, "Want decoded IKM for `%s`", t.desc);

    size_t payloadBase64Len = strlen(t.payload);
    decodedLen = ece_base64url_decode(t.payload, payloadBase64Len,
                                      ECE_BASE64URL_REJECT_PADDING, NULL, 0);
    ece_assert(decodedLen, "Want decoded payload length for `%s`", t.desc);
    uint8_t* payload = calloc(decodedLen, sizeof(uint8_t));
    ece_assert(payload, "Want payload buffer length %zu for `%s`", decodedLen,
               t.desc);
    decodedLen =
      ece_base64url_decode(t.payload, payloadBase64Len,
                           ECE_BASE64URL_REJECT_PADDING, payload, decodedLen);
    ece_assert(decodedLen, "Want decoded payload for `%s`", t.desc);

    size_t plaintextLen =
      ece_aes128gcm_plaintext_max_length(payload, decodedLen);
    uint8_t* plaintext = calloc(plaintextLen, sizeof(uint8_t));

    int err = ece_aes128gcm_decrypt(ikm, 16, payload, decodedLen, plaintext,
                                    &plaintextLen);
    ece_assert(err == t.err, "Got %d decrypting payload for `%s`; want %d", err,
               t.desc, t.err);

    free(payload);
    free(plaintext);
  }
}
