// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "PublicKey.h"
#import "PrivateKey.h"
#import "KeyPair.h"


@implementation KeyPair

- (instancetype) initWithPublicKey: (PublicKey*) publicKey privateKey: (PrivateKey*) privateKey
{
    if ((self = [super init]) != nil) {
        _publicKey = publicKey;
        _privateKey = privateKey;
    }
    return self;
}

- (instancetype) initWithJSONRepresentation: (NSDictionary*) object
{
    if ((self = [super init]) != nil) {
    }
    return self;
}

- (NSDictionary*) JSONRepresentation
{
    return @{
        @"publicKey": [[self publicKey] JSONRepresentation],
        @"privateKey": [[self privateKey] JSONRepresentation]
    };
}

@end
