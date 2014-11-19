// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "NSData+SHA.h"


@implementation NSData (SHA)

// TODO: Needs a test
- (NSData*) SHA1Hash
{
    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([self bytes], [self length], md);
    return [NSData dataWithBytes: md length: CC_SHA1_DIGEST_LENGTH];
}

- (NSData*) SHA256Hash
{
    unsigned char md[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([self bytes], [self length], md);
    return [NSData dataWithBytes: md length: CC_SHA256_DIGEST_LENGTH];
}

- (NSData*) HMACSHA256WithKey: (NSData*) key
{
    // This is kind of odd, but we do this because [NSData dataWithBytes "" length: 0] results in an object that is invalid.

    if ([key length] == 0) {
        key = [NSMutableData data];
    }

    unsigned char mac[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, [key bytes], [key length], [self bytes], [self length], mac);
    return [NSData dataWithBytes: mac length: CC_SHA256_DIGEST_LENGTH];
}

@end
