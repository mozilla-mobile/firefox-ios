// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#include <openssl/dsa.h>
#include <openssl/evp.h>
#include <openssl/err.h>

#include "NSData+Utils.h"
#include "NSData+SHA.h"
#include "CHNumber.h"

#import "ASNUtils.h"
#import "DSAKeyPair.h"


@implementation DSAParameters
@end


@implementation DSAPrivateKey {
    DSA *_dsa;
}

- (id) initWithJSONRepresentation: (NSDictionary*) object
{
    CHNumber *x = [CHNumber numberWithHexString: object[@"x"]];

    DSAParameters *parameters = [DSAParameters new];
    parameters.p = [CHNumber numberWithHexString: object[@"p"]];
    parameters.q = [CHNumber numberWithHexString: object[@"q"]];
    parameters.g = [CHNumber numberWithHexString: object[@"g"]];

    if (x == nil || parameters.g == nil || parameters.p == nil || parameters.q == nil) {
        return nil;
    }

    return [self initWithPrivateKey: x parameters: parameters];
}

- (instancetype) initWithPrivateKey: (CHNumber*) x parameters: (DSAParameters*) parameters;
{
    if ((self = [super init]) != nil) {
        _dsa = DSA_new();
        DSA_set0_key(_dsa, NULL, BN_dup([x bigNumValue]));
        DSA_set0_pqg(_dsa, BN_dup([parameters.p bigNumValue]), BN_dup([parameters.q bigNumValue]), BN_dup([parameters.g bigNumValue]));
    }
    return self;
}

- (void) dealloc
{
    if (_dsa != NULL) {
        DSA_free(_dsa);
        _dsa = NULL;
    }
}

- (NSDictionary*) JSONRepresentation
{
    const BIGNUM *g, *q, *p, *priv_key;
    DSA_get0_pqg(_dsa, &p, &q, &g);
    DSA_get0_key(_dsa, NULL, &priv_key);

    return @{
         @"algorithm": @"DS",
         @"x": [[CHNumber numberWithOpenSSLNumber: priv_key] hexStringValue],
         @"p": [[CHNumber numberWithOpenSSLNumber: p] hexStringValue],
         @"q": [[CHNumber numberWithOpenSSLNumber: q] hexStringValue],
         @"g": [[CHNumber numberWithOpenSSLNumber: g] hexStringValue],
     };
}

- (NSString*) algorithm
{
    const BIGNUM *p;
    DSA_get0_pqg(_dsa, &p, NULL, NULL);
    int sizeInBytes = (BN_num_bits(p) + 7)/8;
    return [NSString stringWithFormat: @"DS%d", sizeInBytes];
}

- (NSData*) signMessageString: (NSString*) string encoding: (NSStringEncoding) encoding
{
    return [self signMessage: [string dataUsingEncoding: encoding]];
}

- (NSData*) signMessage: (NSData*) message
{
    NSData *signature = nil;

    EVP_PKEY *pkey = EVP_PKEY_new();
    if (pkey != NULL) {
        if (EVP_PKEY_set1_DSA(pkey, _dsa)) {
            EVP_MD_CTX *ctx = EVP_MD_CTX_create();
            if (ctx != NULL) {
                if (EVP_SignInit_ex(ctx, EVP_sha1(), NULL)) {
                    if (EVP_SignUpdate(ctx, [message bytes], [message length])) {
                        unsigned int sig_size;
                        unsigned char *sig_data = malloc(EVP_PKEY_size(pkey));
                        if (sig_data != NULL) {
                            if (EVP_SignFinal(ctx, sig_data, &sig_size, pkey)) {
                                signature = [ASNUtils decodeDSASignature:
                                    [NSData dataWithBytesNoCopy: sig_data length: sig_size freeWhenDone: YES]];
                            }
                        }
                    }
                }
                EVP_MD_CTX_destroy(ctx);
            }
        }
        EVP_PKEY_free(pkey);
    }

    return signature;

//    unsigned char signature[1024];
//    unsigned int signature_length;
//
//    NSData *digest = [message SHA1Hash];
//
//    DSA_sign(
//        0,
//        [digest bytes],
//        [digest length],
//        signature,
//        &signature_length,
//        _dsa
//    );
//
//    //return [NSData dataWithBytes: signature length:signature_length];
//
//    return [ASNUtils decodeDSASignature: [NSData dataWithBytes: signature length:signature_length]];
}

@end


@implementation DSAPublicKey {
    DSA *_dsa;
}

- (id) initWithJSONRepresentation: (NSDictionary*) object
{
    CHNumber *y = [CHNumber numberWithHexString: object[@"y"]];

    DSAParameters *parameters = [DSAParameters new];
    parameters.p = [CHNumber numberWithHexString: object[@"p"]];
    parameters.q = [CHNumber numberWithHexString: object[@"q"]];
    parameters.g = [CHNumber numberWithHexString: object[@"g"]];

    if (y == nil || parameters.g == nil || parameters.p == nil || parameters.q == nil) {
        return nil;
    }

    return [self initWithPublicKey: y parameters: parameters];
}

- (instancetype) initWithPublicKey: (CHNumber*) y parameters: (DSAParameters*) parameters
{
    if ((self = [super init]) != nil) {
        _dsa = DSA_new();
        DSA_set0_key(_dsa, BN_dup([y bigNumValue]), NULL);
        DSA_set0_pqg(_dsa, BN_dup([parameters.p bigNumValue]), BN_dup([parameters.q bigNumValue]), BN_dup([parameters.g bigNumValue]));
    }
    return self;
}

- (void) dealloc
{
    if (_dsa != NULL) {
        DSA_free(_dsa);
        _dsa = NULL;
    }
}

- (NSDictionary*) JSONRepresentation
{
    const BIGNUM *g, *q, *p, *pub_key;
    DSA_get0_pqg(_dsa, &p, &q, &g);
    DSA_get0_key(_dsa, &pub_key, NULL);

    return @{
        @"algorithm": @"DS",
        @"y": [[CHNumber numberWithOpenSSLNumber: pub_key] hexStringValue],
        @"g": [[CHNumber numberWithOpenSSLNumber: g] hexStringValue],
        @"p": [[CHNumber numberWithOpenSSLNumber: p] hexStringValue],
        @"q": [[CHNumber numberWithOpenSSLNumber: q] hexStringValue]
    };
}

- (NSString*) algorithm
{
    const BIGNUM *p;
    DSA_get0_pqg(_dsa, &p, NULL, NULL);
    int sizeInBytes = (BN_num_bits(p) + 7)/8;
    return [NSString stringWithFormat: @"DS%d", sizeInBytes];
}

- (BOOL) verifySignature: (NSData*) signature againstMessage: (NSData*) message
{
    NSData *encodedSignature = [ASNUtils encodeDSASignature: signature];

    BOOL verified = NO;

    EVP_PKEY *pkey = EVP_PKEY_new();
    if (pkey != NULL) {
        if (EVP_PKEY_set1_DSA(pkey, _dsa) == 1) {
            EVP_MD_CTX *ctx = EVP_MD_CTX_create();
            if (ctx != NULL) {
                if (EVP_VerifyInit_ex(ctx, EVP_sha1(), NULL) == 1) {
                    if (EVP_VerifyUpdate(ctx, [message bytes], [message length]) ==  1) {
                        int err = EVP_VerifyFinal(ctx, [encodedSignature bytes], [encodedSignature length], pkey);
                        if (err == 1) {
                            verified = YES;
                        } else if (err == -1) {
                            unsigned long e = ERR_get_error();

                            char buf[120];
                            ERR_error_string(e, buf);
                            NSLog(@"Error: %s", buf);
                        }
                    }
                }
                EVP_MD_CTX_destroy(ctx);
            }
        }
        EVP_PKEY_free(pkey);
    }

    return verified;

//    NSData *digest = [message SHA1Hash];
//
//    int err = DSA_verify(
//        0,
//        [digest bytes],
//        [digest length],
//        [encodedSignature bytes],
//        [encodedSignature length],
//        _dsa
//    );
//
//    return (err == 1);
}

- (BOOL) verifySignature: (NSData*) signature againstMessageString: (NSString*) message encoding: (NSStringEncoding) encoding
{
    return [self verifySignature: signature againstMessage: [message dataUsingEncoding: encoding]];
}

@end


@implementation DSAKeyPair

+ (instancetype) generateKeyPairWithSize: (int) size
{
    // TODO: There must be a better way to do this?
    if (size != 512 && size != 1024 && size != 2048 && size != 4096) {
        return nil;
    }

    DSA *dsa = DSA_new();

    if (DSA_generate_parameters_ex(dsa, size, NULL, 0, NULL, NULL, NULL) == 0) {
        DSA_free(dsa);
        return nil;
    }

    if (DSA_generate_key(dsa) == 0) {
        DSA_free(dsa);
        return nil;
    }

    const BIGNUM *g, *q, *p, *pub_key, *priv_key;
    DSA_get0_pqg(dsa, &p, &q, &g);
    DSA_get0_key(dsa, &pub_key, &priv_key);

    DSAParameters *parameters = [DSAParameters new];
    parameters.p = [CHNumber numberWithOpenSSLNumber: p];
    parameters.q = [CHNumber numberWithOpenSSLNumber: q];
    parameters.g = [CHNumber numberWithOpenSSLNumber: g];

    CHNumber *x = [CHNumber numberWithOpenSSLNumber: priv_key];
    CHNumber *y = [CHNumber numberWithOpenSSLNumber: pub_key];

    DSAPrivateKey *privateKey = [[DSAPrivateKey alloc] initWithPrivateKey: x parameters: parameters];
    DSAPublicKey *publicKey = [[DSAPublicKey alloc] initWithPublicKey: y parameters: parameters];

    DSA_free(dsa);

    return [[self alloc] initWithPublicKey: publicKey privateKey: privateKey];
}

@end
