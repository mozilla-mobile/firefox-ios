#include "test.h"

#include <string.h>

typedef struct valid_payload_test_s {
  const char* desc;
  const char* plaintext;
  const char* recvPrivKey;
  const char* authSecret;
  const char* payload;
} valid_payload_test_t;

static valid_payload_test_t valid_payload_tests[] = {
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

void
test_aes128gcm_valid_payloads() {
  size_t tests = sizeof(valid_payload_tests) / sizeof(valid_payload_test_t);
  for (size_t i = 0; i < tests; i++) {
    valid_payload_test_t t = valid_payload_tests[i];

    ece_buf_t rawRecvPrivKey;
    int err =
      ece_base64url_decode(t.recvPrivKey, strlen(t.recvPrivKey),
                           ECE_BASE64URL_REJECT_PADDING, &rawRecvPrivKey);
    ece_assert(!err, "Got %d decoding private key for `%s`", err, t.desc);

    ece_buf_t authSecret;
    err = ece_base64url_decode(t.authSecret, strlen(t.authSecret),
                               ECE_BASE64URL_REJECT_PADDING, &authSecret);
    ece_assert(!err, "Got %d decoding auth secret for `%s`", err, t.desc);

    ece_buf_t payload;
    err = ece_base64url_decode(t.payload, strlen(t.payload),
                               ECE_BASE64URL_REJECT_PADDING, &payload);
    ece_assert(!err, "Got %d decoding payload for `%s`", err, t.desc);

    ece_buf_t plaintext;
    err =
      ece_aes128gcm_decrypt(&rawRecvPrivKey, &authSecret, &payload, &plaintext);
    ece_assert(!err, "Got %d decrypting payload for `%s`", err, t.desc);

    size_t expectedLen = strlen(t.plaintext);
    ece_assert(plaintext.length == expectedLen,
               "Got plaintext length %zu for `%s`; want %zu", plaintext.length,
               t.desc, expectedLen);
    ece_assert(!memcmp(t.plaintext, plaintext.bytes, plaintext.length),
               "Wrong plaintext for `%s`", t.desc);

    ece_buf_free(&rawRecvPrivKey);
    ece_buf_free(&authSecret);
    ece_buf_free(&payload);
    ece_buf_free(&plaintext);
  }
}
