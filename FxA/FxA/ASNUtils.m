// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#include "NSData+Utils.h"
#include "CHNumber.h"
#import "ASNUtils.h"


@implementation ASNUtils

//
// 0x30
// 4 + l1 + l2
//
// 0x02
// l1
// d1
//
// 0x02
// l2
// d2
//

+ (NSData*) encodeSequenceOfNumbers: (NSArray*) numbers
{
    NSUInteger totalLength = 0;
    for (CHNumber *number in numbers) {
        totalLength += 2 + [[number dataValue] length];
    }

    NSMutableData *encoded = [NSMutableData data];
    unsigned char header[2];
    header[0] = 0x30; // SEQUENCE
    header[1] = totalLength;
    [encoded appendBytes: header length: sizeof header];

    for (CHNumber *number in numbers) {
        NSData *data = [number dataValue];
        unsigned char itemHeader[2];
        itemHeader[0] = 0x02; // NUMBER
        itemHeader[1] = [data length];
        [encoded appendBytes: itemHeader length: sizeof itemHeader];
        [encoded appendData: data];
    }

    return encoded;
}

+ (NSArray*) decodeSequenceOfNumbers: (NSData*) sequence
{
    unsigned char *p = (unsigned char*) [sequence bytes];
    unsigned char *q = p + [sequence length];

    // TODO: These checks must be way more strict

    if (p[0] != 0x30) {
        return nil;
    }

    if (p[1] != ([sequence length] - 2)) {
        return nil;
    }

    p += 2;

    NSMutableArray *numbers = [NSMutableArray new];

    while (p < q)
    {
        if (p[0] != 0x02) {
            return nil;
        }

        NSUInteger numberLength = p[1];
        p += 2;

        NSData *data = [NSData dataWithBytes: p length: numberLength];
        p += numberLength;

        CHNumber *number = [CHNumber numberWithData: data];
        [numbers addObject: number];
    }

    return [NSArray arrayWithArray:numbers];
}

+ (NSData*) decodeDSASignature: (NSData*) signature
{
    if (signature == nil || [signature length] == 0) {
        return nil;
    }

    NSArray *numbers = [ASNUtils decodeSequenceOfNumbers: signature];
    if (numbers == nil || [numbers count] != 2) {
        return nil;
    }

    return [NSData dataByAppendingDatas: @[
        [[numbers[0] dataValue] dataLeftZeroPaddedToLength: 20],
        [[numbers[1] dataValue] dataLeftZeroPaddedToLength: 20],
    ]];
}

+ (NSData*) encodeDSASignature: (NSData*) flattenedSignature
{
    if (flattenedSignature == nil || [flattenedSignature length] == 0) {
        return nil;
    }

    NSArray *numbers = @[
        [CHNumber numberWithData: [flattenedSignature subdataWithRange: NSMakeRange(0, [flattenedSignature length]/2)]],
        [CHNumber numberWithData: [flattenedSignature subdataWithRange: NSMakeRange([flattenedSignature length]/2, [flattenedSignature length]/2)]]
    ];

    NSData *transformedSignature = [ASNUtils encodeSequenceOfNumbers: numbers];
    return transformedSignature;
}

@end
