// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#import "openssl/evp.h"
#import "openssl/sha.h"

#import "NSData+SHA.h"
#import "NSData+Utils.h"
#import "NSData+KeyDerivation.h"

#pragma mark - Low Level SCrypt Functions




//#define WORDS_BIGENDIAN 1
#define BLOCK_WORDS 16

static inline uint32_t
ROTL(uint32_t x, int n)
{
  return (x << n) | (x >> (32 - n));
}

#ifdef WORDS_BIGENDIAN
static inline uint32_t
ROTR(uint32_t x, int n)
{
  return (x >> n) | (x << (32 - n));
}

static inline uint32_t
BYTESWAP(uint32_t x)
{
  return (ROTR(x, 8) & 0xff00ff00) |
    (ROTL(x, 8) & 0x00ff00ff);
}
#endif

static void
salsa20_8_core (uint32_t out[BLOCK_WORDS], const uint32_t in[BLOCK_WORDS])
{
  const uint32_t *x;
  uint32_t *z;
  int i;

  memcpy(out, in, sizeof(*out) * BLOCK_WORDS);

  z = out;
  for (i = 8 - 1; i >= 0; i -= 2) {
    z[ 4] ^= ROTL(z[ 0]+z[12], 7);
    z[ 8] ^= ROTL(z[ 4]+z[ 0], 9);
    z[12] ^= ROTL(z[ 8]+z[ 4],13);
    z[ 0] ^= ROTL(z[12]+z[ 8],18);
    z[ 9] ^= ROTL(z[ 5]+z[ 1], 7);
    z[13] ^= ROTL(z[ 9]+z[ 5], 9);
    z[ 1] ^= ROTL(z[13]+z[ 9],13);
    z[ 5] ^= ROTL(z[ 1]+z[13],18);
    z[14] ^= ROTL(z[10]+z[ 6], 7);
    z[ 2] ^= ROTL(z[14]+z[10], 9);
    z[ 6] ^= ROTL(z[ 2]+z[14],13);
    z[10] ^= ROTL(z[ 6]+z[ 2],18);
    z[ 3] ^= ROTL(z[15]+z[11], 7);
    z[ 7] ^= ROTL(z[ 3]+z[15], 9);
    z[11] ^= ROTL(z[ 7]+z[ 3],13);
    z[15] ^= ROTL(z[11]+z[ 7],18);
    z[ 1] ^= ROTL(z[ 0]+z[ 3], 7);
    z[ 2] ^= ROTL(z[ 1]+z[ 0], 9);
    z[ 3] ^= ROTL(z[ 2]+z[ 1],13);
    z[ 0] ^= ROTL(z[ 3]+z[ 2],18);
    z[ 6] ^= ROTL(z[ 5]+z[ 4], 7);
    z[ 7] ^= ROTL(z[ 6]+z[ 5], 9);
    z[ 4] ^= ROTL(z[ 7]+z[ 6],13);
    z[ 5] ^= ROTL(z[ 4]+z[ 7],18);
    z[11] ^= ROTL(z[10]+z[ 9], 7);
    z[ 8] ^= ROTL(z[11]+z[10], 9);
    z[ 9] ^= ROTL(z[ 8]+z[11],13);
    z[10] ^= ROTL(z[ 9]+z[ 8],18);
    z[12] ^= ROTL(z[15]+z[14], 7);
    z[13] ^= ROTL(z[12]+z[15], 9);
    z[14] ^= ROTL(z[13]+z[12],13);
    z[15] ^= ROTL(z[14]+z[13],18);
  }

  x = in;
  for (i = BLOCK_WORDS - 1; i >= 0; i--) {
    *(z++) += *(x++);
  }
}

static void
blockmix_salsa20_8_core (uint32_t out[/* (2 * r * BLOCK_WORDS) */],
			 const uint32_t in[/* (2 * r * BLOCK_WORDS) */],
			 unsigned int r)
{
  uint32_t *even, *odd;
  uint32_t *x;
  uint32_t tmp[BLOCK_WORDS];
  unsigned int i, j;

  even = out;
  odd = &out[r * BLOCK_WORDS];

  memcpy(tmp, &in[(2 * r - 1) * BLOCK_WORDS], sizeof(tmp));

  for (i = r; i > 0; i--) {
    x = tmp;
    for (j = BLOCK_WORDS; j > 0; j--) {
      *(x++) ^= *(in++);
    }
    salsa20_8_core(even, tmp);
    memcpy(tmp, even, sizeof(tmp));
    even += BLOCK_WORDS;

    x = tmp;
    for (j = BLOCK_WORDS; j > 0; j--) {
      *(x++) ^= *(in++);
    }
    salsa20_8_core(odd, tmp);
    memcpy(tmp, odd, sizeof(tmp));
    odd += BLOCK_WORDS;
  }
}

static void
smix (void *out /* (sizeof(uint32_t) * 2 * r * BLOCK_WORDS) */,
      const void *in /* (sizeof(uint32_t) * 2 * r * BLOCK_WORDS) */,
      unsigned int N, unsigned int r,
      uint32_t tmp[/* (2 * r * BLOCK_WORDS * (N + 2)) */])
{
  uint32_t *v;
  uint32_t *X, *T, *x, *t;
  uint32_t j;
  unsigned int i, k;

  memcpy(tmp, in, sizeof(*tmp) * 2 * r * BLOCK_WORDS);

#ifdef WORDS_BIGENDIAN
  v = tmp;
  for (i = 2 * r * BLOCK_WORDS; i > 0; i--) {
    *v = BYTESWAP(*v);
    v++;
  }
#endif /* WORDS_BIGENDIAN */

  v = tmp;
  for (i = N; i > 0; i--) {
    blockmix_salsa20_8_core(v + 2 * r * BLOCK_WORDS, v, r);
    v += 2 * r * BLOCK_WORDS;
  }
  X = v;
  T = &X[2 * r * BLOCK_WORDS];

  for (i = N; i > 0; i--) {
    j = X[(2 * r - 1) * BLOCK_WORDS] % N;

    x = X;
    v = &tmp[2 * r * BLOCK_WORDS * j];
    for (k = 2 * r * BLOCK_WORDS; k > 0; k--) {
      *(x++) ^= *(v++);
    }

    blockmix_salsa20_8_core(T, X, r);

    /* swap X & T */
    t = T;
    T = X;
    X = t;
  }

#ifdef WORDS_BIGENDIAN
  x = X;
  for (i = 2 * r * BLOCK_WORDS; i > 0; i--) {
    *x = BYTESWAP(*x);
    x++;
  }
#endif /* WORDS_BIGENDIAN */

  memcpy (out, X, sizeof(*X) * 2 * r * BLOCK_WORDS);
}

int
scrypt (const void *password, size_t passwordLen,
	const void *salt, size_t saltLen,
	unsigned int N, unsigned int r, unsigned int p,
	uint8_t *derivedKey, size_t dkLen)
{
  size_t MFLen = sizeof(uint32_t) * 2 * r * BLOCK_WORDS;
  uint8_t *B, *b;
  uint32_t *tmp;
  unsigned int i;

  if ((B = malloc(p * MFLen)) == NULL)
    return -1;

  if (PKCS5_PBKDF2_HMAC(password, passwordLen, salt, saltLen, 1, EVP_sha256(), p * MFLen, B)) {
    //return -1;
}

  if ((tmp = malloc(sizeof(*tmp) * 2 * r * BLOCK_WORDS * (N + 2))) == NULL) {
    free(B);
    return -1;
  }

  b = B;
  for (i = p; i > 0; i--) {
    smix(b, b, N, r, tmp);
    b += MFLen;
  }

  if (PKCS5_PBKDF2_HMAC(password, passwordLen, B, p * MFLen, 1, EVP_sha256(), dkLen, derivedKey)) {
    //return -1;
    }

  free(tmp);
  free(B);
  return 0;
}






@implementation NSData (KeyDerivation)

- (NSData*) deriveHKDFSHA256KeyWithSalt: (NSData*) salt contextInfo: (NSData*) contextInfo length: (NSUInteger) length
{
    // If salt is not specified then we use a zero salt

    if (salt == nil) {
        salt = [NSMutableData dataWithLength: SHA256_DIGEST_LENGTH];
    }

    // Extract

    NSData *prk = [self HMACSHA256WithKey: salt];

    // Expand

    NSUInteger iterations = (length + SHA256_DIGEST_LENGTH - 1) / SHA256_DIGEST_LENGTH;

    NSMutableData* tr = [NSMutableData dataWithCapacity: (iterations * SHA256_DIGEST_LENGTH)];

    NSData* tn = [NSData data];
	for (NSUInteger i = 1; i <= iterations; i++) {
        unsigned char n = i;
        tn = [[NSData dataByAppendingDatas: @[tn, contextInfo, [NSData dataWithBytes: &n length: 1]]] HMACSHA256WithKey: prk];
        [tr appendData: tn];
	}

	return [tr subdataWithRange: NSMakeRange(0, length)];
}

- (NSData*) derivePBKDF2HMACSHA256KeyWithSalt: (NSData*) salt iterations: (NSUInteger) iterations length: (NSUInteger) length
{
    unsigned char *key = malloc(length);
    if (key == NULL) {
        return nil;
    }

    PKCS5_PBKDF2_HMAC(
        [self bytes],
        [self length],
        [salt bytes],
        [salt length],
        iterations,
        EVP_sha256(),
        length,
        key
    );

    return [NSData dataWithBytesNoCopy: key length: length freeWhenDone: YES];
}

- (NSData*) deriveSCryptKeyWithSalt: (NSData*) salt n: (uint32_t) n r: (uint32_t) r p: (uint32_t) p length: (NSUInteger) length
{
    uint8_t *buffer = (uint8_t*) malloc(length);
    if (buffer == NULL) {
        return nil;
    }

    if (scrypt([self bytes], [self length], [salt bytes], [salt length], n, r, p, buffer, length) != 0) {
        free(buffer);
        return nil;
    }

    return [NSData dataWithBytesNoCopy: buffer length:length freeWhenDone:YES];
}

@end
