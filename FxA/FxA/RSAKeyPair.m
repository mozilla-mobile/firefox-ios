// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#include <openssl/rsa.h>
#include <openssl/evp.h>

#include "CHNumber.h"
#import "RSAKeyPair.h"


@implementation RSAPrivateKey {
    RSA *_rsa;
}

- (id) initWithJSONRepresentation: (NSDictionary*) object
{
    CHNumber *n = [CHNumber numberWithString: object[@"n"]];
    CHNumber *d = [CHNumber numberWithString: object[@"d"]];
    if (n == nil || d == nil) {
        return nil;
    }

    return [self initWithModulus: n privateExponent: d];
}

- (id) initWithModulus: (CHNumber*) n privateExponent: (CHNumber*) d
{
    if ((self = [super init]) != nil) {
        _rsa = RSA_new();
        _rsa->n = BN_dup([n bigNumValue]);
        _rsa->d = BN_dup([d bigNumValue]);
        BIGNUM* exp = BN_new();
        BN_set_word(exp, RSA_F4);
        _rsa->e = exp; // TODO: Is this the right thing to do?
        // Maybe there is some secret communication between a Java KeyPair where the Private Key can discover e from the associated Public Key?
//        _rsa->p = BN_dup([p bigNumValue]);
//        _rsa->q = BN_dup([q bigNumValue]);
    }
    return self;
}

- (void) dealloc
{
    RSA_free(_rsa);
    _rsa = NULL;
}

- (NSDictionary*) JSONRepresentation
{
    return @{
        @"algorithm": @"RS",
        @"n": [[CHNumber numberWithOpenSSLNumber: _rsa->n] stringValue],
        @"d": [[CHNumber numberWithOpenSSLNumber: _rsa->d] stringValue]
    };
}

- (NSString*) algorithm
{
    int sizeInBytes = (BN_num_bits(_rsa->n) + 7)/8;
    return [NSString stringWithFormat: @"RS%d", sizeInBytes];
}

- (NSData*) signMessageString: (NSString*) string encoding: (NSStringEncoding) encoding
{
    return [self signMessage: [string dataUsingEncoding: encoding]];
}

- (NSData*) signMessage: (NSData*) data
{
    NSData *signature = nil;

    EVP_PKEY *pkey = EVP_PKEY_new();
    if (pkey != NULL) {
        if (EVP_PKEY_set1_RSA(pkey, _rsa)) {
            EVP_MD_CTX *ctx = EVP_MD_CTX_create();
            if (ctx != NULL) {
                if (EVP_SignInit_ex(ctx, EVP_sha256(), NULL)) {
                    if (EVP_SignUpdate(ctx, [data bytes], [data length])) {
                        unsigned int sig_size;
                        unsigned char *sig_data = malloc(EVP_PKEY_size(pkey));
                        if (sig_data != NULL) {
                            if (EVP_SignFinal(ctx, sig_data, &sig_size, pkey)) {
                                signature = [NSData dataWithBytesNoCopy: sig_data length: sig_size freeWhenDone: YES];
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
}

@end


@implementation RSAPublicKey {
    RSA *_rsa;
}

- (id) initWithJSONRepresentation: (NSDictionary*) object
{
    CHNumber *n = [CHNumber numberWithString: object[@"n"]];
    CHNumber *e = [CHNumber numberWithString: object[@"e"]];
    if (n == nil || e == nil) {
        return nil;
    }

    return [self initWithModulus: n publicExponent: e];
}


- (id) initWithModulus: (CHNumber*) n publicExponent: (CHNumber*) e;
{
    if ((self = [super init]) != nil) {
        _rsa = RSA_new();
        _rsa->n = BN_dup([n bigNumValue]);
        _rsa->e = BN_dup([e bigNumValue]);
    }
    return self;
}

- (void) dealloc
{
    RSA_free(_rsa);
    _rsa = NULL;
}

- (NSDictionary*) JSONRepresentation
{
    return @{
        @"algorithm": @"RS",
        @"n": [[CHNumber numberWithOpenSSLNumber: _rsa->n] stringValue],
        @"e": [[CHNumber numberWithOpenSSLNumber: _rsa->e] stringValue]
    };
}

- (NSString*) algorithm
{
    int sizeInBytes = (BN_num_bits(_rsa->n) + 7)/8;
    return [NSString stringWithFormat: @"RS%d", sizeInBytes];
}

- (BOOL) verifySignature: (NSData*) signature againstMessage: (NSData*) message
{
    BOOL verified = NO;

    EVP_PKEY *pkey = EVP_PKEY_new();
    if (pkey != NULL) {
        if (EVP_PKEY_set1_RSA(pkey, _rsa)) {
            EVP_MD_CTX *ctx = EVP_MD_CTX_create();
            if (ctx != NULL) {
                if (EVP_VerifyInit_ex(ctx, EVP_sha256(), NULL)) {
                    if (EVP_VerifyUpdate(ctx, [message bytes], [message length])) {
                        if (EVP_VerifyFinal(ctx, [signature bytes], [signature length], pkey)) {
                            verified = YES;
                        }
                    }
                }
                EVP_MD_CTX_destroy(ctx);
            }
        }
        EVP_PKEY_free(pkey);
    }

    return verified;
}

- (BOOL) verifySignature: (NSData*) signature againstMessageString: (NSString*) message encoding: (NSStringEncoding) encoding
{
    return [self verifySignature: signature againstMessage: [message dataUsingEncoding: encoding]];
}

@end


@implementation RSAKeyPair

+ (instancetype) generateKeyPairWithModulusSize: (int) modulusSize
{
    RSA* rsa = RSA_new();
    if (rsa == NULL) {
        return nil;
    }

    BIGNUM* exp = BN_new();
    BN_set_word(exp, RSA_F4);
    if (!RSA_generate_key_ex(rsa, modulusSize, exp, NULL)) {
        RSA_free(rsa);
        return nil;
    }

    RSAPublicKey *publicKey = [[RSAPublicKey alloc] initWithModulus: [CHNumber numberWithOpenSSLNumber: rsa->n]
        publicExponent: [CHNumber numberWithOpenSSLNumber: rsa->e]];
    RSAPrivateKey *privateKey = [[RSAPrivateKey alloc] initWithModulus: [CHNumber numberWithOpenSSLNumber: rsa->n]
        privateExponent: [CHNumber numberWithOpenSSLNumber: rsa->d]];

    RSA_free(rsa);

    return [[self alloc] initWithPublicKey: publicKey privateKey: privateKey];
}

- (instancetype) initWithModulus: (CHNumber*) n privateExponent: (CHNumber*) d publicExponent: (CHNumber*) e
{
    RSAPrivateKey *privateKey = [[RSAPrivateKey alloc] initWithModulus: n privateExponent: d];
    if (privateKey == nil) {
        return nil;
    }

    RSAPublicKey *publicKey = [[RSAPublicKey alloc] initWithModulus: n publicExponent: e];
    if (privateKey == nil) {
        return nil;
    }

    return [self initWithPublicKey: publicKey privateKey: privateKey];
}

- (instancetype) initWithJSONRepresentation: (NSDictionary*) object
{
    RSAPublicKey *publicKey = [[RSAPublicKey alloc] initWithJSONRepresentation: object[@"publicKey"]];
    if (publicKey == nil) {
        return nil;
    }

    RSAPrivateKey *privateKey = [[RSAPrivateKey alloc] initWithJSONRepresentation: object[@"privateKey"]];
    if (privateKey == nil) {
        return nil;
    }

    return [self initWithPublicKey: publicKey privateKey: privateKey];
}

@end
