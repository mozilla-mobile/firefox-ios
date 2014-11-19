// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "KeyPair.h"
#import "CHNumber.h"
#import "DSAKeyPair.h"
#import "JSONWebTokenUtils.h"
#import "MockMyIDTokenFactory.h"


@implementation MockMyIDTokenFactory {
    DSAKeyPair *_mockMyIDKeyPair;
}

+ (instancetype) defaultFactory
{
    static MockMyIDTokenFactory *instance = NULL;

    @synchronized (self) {
        if (instance == NULL) {
            instance = [MockMyIDTokenFactory new];
        }
    }

    return instance;
}

- (instancetype) init
{
    if ((self = [super init]) != nil) {
        DSAParameters *parameters = [DSAParameters new];
        parameters.p = [CHNumber numberWithHexString: @"ff600483db6abfc5b45eab78594b3533d550d9f1bf2a992a7a8daa6dc34f8045ad4e6e0c429d334eeeaaefd7e23d4810be00e4cc1492cba325ba81ff2d5a5b305a8d17eb3bf4a06a349d392e00d329744a5179380344e82a18c47933438f891e22aeef812d69c8f75e326cb70ea000c3f776dfdbd604638c2ef717fc26d02e17"];
        parameters.q = [CHNumber numberWithHexString: @"e21e04f911d1ed7991008ecaab3bf775984309c3"];
        parameters.g = [CHNumber numberWithHexString: @"c52a4a0ff3b7e61fdf1867ce84138369a6154f4afa92966e3c827e25cfa6cf508b90e5de419e1337e07a2e9e2a3cd5dea704d175f8ebf6af397d69e110b96afb17c7a03259329e4829b0d03bbc7896b15b4ade53e130858cc34d96269aa89041f409136c7242a38895c9d5bccad4f389af1d7a4bd1398bd072dffa896233397a"];

        CHNumber *x = [CHNumber numberWithHexString: @"385cb3509f086e110c5e24bdd395a84b335a09ae"];
        DSAPrivateKey *privateKey = [[DSAPrivateKey alloc] initWithPrivateKey: x parameters: parameters];

        CHNumber *y = [CHNumber numberWithHexString: @"738ec929b559b604a232a9b55a5295afc368063bb9c20fac4e53a74970a4db7956d48e4c7ed523405f629b4cc83062f13029c4d615bbacb8b97f5e56f0c7ac9bc1d4e23809889fa061425c984061fca1826040c399715ce7ed385c4dd0d402256912451e03452d3c961614eb458f188e3e8d2782916c43dbe2e571251ce38262"];
        DSAPublicKey *publicKey = [[DSAPublicKey alloc] initWithPublicKey: y parameters: parameters];

        _mockMyIDKeyPair = [[DSAKeyPair alloc] initWithPublicKey: publicKey privateKey:privateKey];
    }

    return self;
}

- (NSString*) createCertificateWithPublicKey: (PublicKey*) publicKey username: (NSString*) username issuedAt: (unsigned long long) issuedAt duration: (unsigned long long) duration
{
    if (![username hasSuffix: @"@mockmyid.com"]) {
        username = [username stringByAppendingString: @"@mockmyid.com"];
    }

    unsigned long long expiresAt = issuedAt + duration;
    return [JSONWebTokenUtils certificateWithPublicKeyToSign:publicKey email:username issuer: @"mockmyid.com"
        issuedAt: issuedAt expiresAt: expiresAt signingPrivateKey: _mockMyIDKeyPair.privateKey];
}

- (NSString*) createCertificateWithPublicKey: (PublicKey*) publicKey username: (NSString*) username
{
    unsigned long long now = [[NSDate date] timeIntervalSince1970] * 1000;

    return [self createCertificateWithPublicKey: publicKey username:username issuedAt:now
        duration:JSONWebTokenUtilsDefaultCertificateDuration];
}


- (NSString*) createAssertionWithKeyPair: (KeyPair*) keyPair username: (NSString*) username audience: (NSString*) audience certifcateIssuedAt: (unsigned long long) certificateIssuedAt certificateDuration: (unsigned long long) certificateDuration assertionIssuedAt: (unsigned long long) assertionIssuedAt assertionDuration: (unsigned long long) assertionDuration
{
    NSString *certificate = [self createCertificateWithPublicKey: keyPair.publicKey username:username
        issuedAt: certificateIssuedAt duration: certificateDuration];

    return [JSONWebTokenUtils createAssertionWithPrivateKeyToSignWith: keyPair.privateKey certificate: certificate
        audience: audience issuer: JSONWebTokenUtilsDefaultAssertionIssuer issuedAt:assertionIssuedAt duration:assertionDuration];
}

- (NSString*) createAssertionWithKeyPair: (KeyPair*) keyPair username: (NSString*) username audience: (NSString*) audience
{
    unsigned long long now = [[NSDate date] timeIntervalSince1970] * 1000;

    return [self createAssertionWithKeyPair: keyPair username:username audience:audience
        certifcateIssuedAt: now-60000 certificateDuration: JSONWebTokenUtilsDefaultCertificateDuration
            assertionIssuedAt:now-30000 assertionDuration: JSONWebTokenUtilsDefaultAssertionDuration];
}

@end
