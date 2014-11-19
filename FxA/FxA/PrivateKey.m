// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "PrivateKey.h"


@implementation PrivateKey

- (id) initWithJSONRepresentation: (NSDictionary*) object
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (NSDictionary*) JSONRepresentation
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (NSString*) algorithm
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (NSData*) signMessageString: (NSString*) string encoding: (NSStringEncoding) encoding
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (NSData*) signMessage: (NSData*) data
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

@end
