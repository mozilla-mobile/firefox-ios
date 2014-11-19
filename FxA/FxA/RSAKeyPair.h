// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#import "KeyPair.h"
#import "PrivateKey.h"
#import "PublicKey.h"
#import <Foundation/Foundation.h>


@class CHNumber;
@class RSAKeyPair;


@interface RSAPrivateKey : PrivateKey
- (id) initWithModulus: (CHNumber*) n privateExponent: (CHNumber*) d;
@end


@interface RSAPublicKey : PublicKey
- (id) initWithModulus: (CHNumber*) n publicExponent: (CHNumber*) e;
@end


@interface RSAKeyPair : KeyPair

+ (instancetype) generateKeyPairWithModulusSize: (int) size;

- (instancetype) initWithModulus: (CHNumber*) n privateExponent: (CHNumber*) d publicExponent: (CHNumber*) e;

@property (readonly) RSAPublicKey *publicKey;
@property (readonly) RSAPrivateKey *privateKey;

@end
