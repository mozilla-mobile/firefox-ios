// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
// MockMyIDTokenFactory.h


#import <Foundation/Foundation.h>


@class KeyPair;


@interface MockMyIDTokenFactory : NSObject

+ (instancetype) defaultFactory;

- (NSString*) createCertificateWithPublicKey: (PublicKey*) publicKey username: (NSString*) username issuedAt: (unsigned long long) issuedAt duration: (unsigned long long) duration;
- (NSString*) createCertificateWithPublicKey: (PublicKey*) publicKey username: (NSString*) username;

- (NSString*) createAssertionWithKeyPair: (KeyPair*) keyPair username: (NSString*) username audience: (NSString*) audience certifcateIssuedAt: (unsigned long long) certificateIssuedAt certificateDuration: (unsigned long long) certificateDuration assertionIssuedAt: (unsigned long long) assertionIssuedAt assertionDuration: (unsigned long long) assertionDuration;
- (NSString*) createAssertionWithKeyPair: (KeyPair*) keyPair username: (NSString*) username audience: (NSString*) audience;

@end
