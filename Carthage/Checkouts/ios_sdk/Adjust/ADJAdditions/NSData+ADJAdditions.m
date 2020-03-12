//
//  NSData+ADJAdditions.m
//  adjust
//
//  Created by Pedro Filipe on 26/03/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import "NSData+ADJAdditions.h"

@implementation NSData(ADJAdditions)

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// http://stackoverflow.com/a/4727124
- (NSString *)adjEncodeBase64 {
    const unsigned char * objRawData = self.bytes;
    char * objPointer;
    char * strResult;

    // Get the Raw Data length and ensure we actually have data
    NSUInteger intLength = self.length;
    if (intLength == 0) return nil;

    // Setup the String-based Result placeholder and pointer within that placeholder
    strResult = (char *)calloc((((intLength + 2) / 3) * 4) + 1, sizeof(char));
    objPointer = strResult;

    // Iterate through everything
    while (intLength > 2) { // keep going until we have less than 24 bits
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
        *objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
        *objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];

        // we just handled 3 octets (24 bits) of data
        objRawData += 3;
        intLength -= 3;
    }

    // now deal with the tail end of things
    if (intLength != 0) {
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        if (intLength > 1) {
            *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
            *objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
            *objPointer++ = '=';
        } else {
            *objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
            *objPointer++ = '=';
            *objPointer++ = '=';
        }
    }

    // Terminate the string-based result
    *objPointer = '\0';

    // Return the results as an NSString object
    NSString *encodedString = [NSString stringWithCString:strResult encoding:NSASCIIStringEncoding];
    free(strResult);
    return encodedString;
}

@end
