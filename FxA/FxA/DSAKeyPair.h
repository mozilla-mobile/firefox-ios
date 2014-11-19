// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "KeyPair.h"
#import "PrivateKey.h"
#import "PublicKey.h"
#import <Foundation/Foundation.h>


@class CHNumber;


@interface DSAParameters : NSObject
@property CHNumber *g;
@property CHNumber *p;
@property CHNumber *q;
@end


@interface DSAPrivateKey : PrivateKey
- (instancetype) initWithPrivateKey: (CHNumber*) x parameters: (DSAParameters*) parameters;
@end


@interface DSAPublicKey : PublicKey
- (instancetype) initWithPublicKey: (CHNumber*) y parameters: (DSAParameters*) parameters;
@end


@interface DSAKeyPair : KeyPair

+ (instancetype) generateKeyPairWithSize: (int) size;

@property (readonly) DSAPublicKey *publicKey;
@property (readonly) DSAPrivateKey *privateKey;

@end
