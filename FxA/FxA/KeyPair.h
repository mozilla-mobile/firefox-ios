// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import <Foundation/Foundation.h>


@class PublicKey;
@class PrivateKey;


@interface KeyPair : NSObject

@property (readonly) PublicKey *publicKey;
@property (readonly) PrivateKey *privateKey;

- (instancetype) initWithPublicKey: (PublicKey*) publicKey privateKey: (PrivateKey*) privateKey;
- (instancetype) initWithJSONRepresentation: (NSDictionary*) object;

- (NSDictionary*) JSONRepresentation;

@end
