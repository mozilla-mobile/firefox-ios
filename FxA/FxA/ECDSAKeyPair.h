// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "KeyPair.h"
#import "PrivateKey.h"
#import "PublicKey.h"
#import <Foundation/Foundation.h>


@class CHNumber;

typedef NS_ENUM(NSInteger, ECDSAGroup) {
    ECDSAGroupP256,
};

@interface ECDSAPoint : NSObject
@property CHNumber *x;
@property CHNumber *y;
@end


@interface ECDSAPrivateKey : PrivateKey

- (instancetype) initWithPrivateKey: (CHNumber*) d point: (ECDSAPoint*) p group: (ECDSAGroup) group;

- (instancetype) initWithBinaryRepresentation: (NSData*) data group: (ECDSAGroup) group;
- (NSData*) BinaryRepresentation;

- (NSData*) selfSignedCertificateWithName: (NSString*) name slack: (int) slack lifetime: (int) lifetime;

@end


@interface ECDSAPublicKey : PublicKey

- (instancetype) initWithPublicKey: (ECDSAPoint*) p group: (ECDSAGroup) group;

- (instancetype) initWithBinaryRepresentation: (NSData*) data group: (ECDSAGroup) group;
- (NSData*) BinaryRepresentation;

@end


@interface ECDSAKeyPair : KeyPair

+ (instancetype) generateKeyPairForGroup: (ECDSAGroup) group;

@property (readonly) ECDSAPublicKey *publicKey;
@property (readonly) ECDSAPrivateKey *privateKey;

@end
