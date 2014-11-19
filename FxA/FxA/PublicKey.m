// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "PublicKey.h"


@implementation PublicKey

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

- (BOOL) verifySignature: (NSData*) signature againstMessage: (NSData*) message
{
    [self doesNotRecognizeSelector: _cmd];
    return FALSE;
}

- (BOOL) verifySignature: (NSData*) signature againstMessageString: (NSString*) message encoding: (NSStringEncoding) encoding
{
    [self doesNotRecognizeSelector: _cmd];
    return FALSE;
}

@end
