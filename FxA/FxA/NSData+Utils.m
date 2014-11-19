// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import <Security/Security.h>
#import "NSData+Utils.h"


@implementation NSData (Utils)

+ (id) dataByAppendingDatas: (NSArray*) datas
{
    NSMutableData *result = [NSMutableData data];
    for (NSData *data in datas) {
        [result appendData: data];
    }
    return result;
}

- (id) dataLeftZeroPaddedToLength: (NSUInteger) length
{
    if ([self length] < length) {
        return [NSData dataByAppendingDatas: @[[NSMutableData dataWithLength: (length - [self length])], self]];
    } else {
        return self;
    }
}

- (id) dataRightZeroPaddedToLength: (NSUInteger) length
{
    if ([self length] < length) {
        return [NSData dataByAppendingDatas: @[self, [NSMutableData dataWithLength: (length - [self length])]]];
    } else {
        return self;
    }
}

- (id) exclusiveOrWithKey: (NSData*) key
{
    if ([self length] != [key length]) {
        return nil;
    }

    unsigned char *o = (unsigned char*) malloc([self length]);
    unsigned char *p = (unsigned char*) [self bytes];
    unsigned char *q = (unsigned char*) [key bytes];

    for (NSUInteger i = 0; i < [self length]; i++) {
        o[i] = p[i] ^ q[i];
    }

    return [NSData dataWithBytesNoCopy: o length: [self length] freeWhenDone: YES];
}

+ (id) randomDataWithLength: (NSUInteger) length
{
    void *bytes = malloc(length);
    if (bytes == NULL) {
        return nil;
    }

    if (SecRandomCopyBytes(kSecRandomDefault, length, bytes) != 0) {
        free(bytes);
        return nil;
    }

    return [NSData dataWithBytesNoCopy: bytes length:length freeWhenDone: YES];
}

- (NSString*) base64URLEncodedStringWithOptions: (NSDataBase64EncodingOptions) options
{
    // This is not awesome but it works.
    NSMutableString *encodedString = [NSMutableString stringWithString: [self base64EncodedStringWithOptions: options]];
    if (encodedString != nil)
    {
        [encodedString replaceOccurrencesOfString: @"+" withString: @"-" options:NSLiteralSearch range: NSMakeRange(0, [encodedString length])];
        [encodedString replaceOccurrencesOfString: @"/" withString: @"_" options:NSLiteralSearch range: NSMakeRange(0, [encodedString length])];

        if ([encodedString hasSuffix: @"=="]) {
            return [encodedString substringToIndex: [encodedString length] - 2];
        }

        if ([encodedString hasSuffix: @"="]) {
            return [encodedString substringToIndex: [encodedString length] - 1];
        }
    }
    return encodedString;
}

- (instancetype) initWithBase64URLEncodedString:(NSString *)base64String options:(NSDataBase64DecodingOptions)options
{
    NSMutableString *encodedString = [NSMutableString stringWithString: base64String];
    if (encodedString != nil)
    {
        [encodedString replaceOccurrencesOfString: @"-" withString: @"+" options:NSLiteralSearch range: NSMakeRange(0, [encodedString length])];
        [encodedString replaceOccurrencesOfString: @"_" withString: @"/" options:NSLiteralSearch range: NSMakeRange(0, [encodedString length])];

        switch ([encodedString length] % 4) {
            case 2:
                [encodedString appendString: @"=="];
                break;
            case 3:
                [encodedString appendString: @"="];
                break;
        }
    }

    return [self initWithBase64EncodedString: encodedString options: options];
}

@end
