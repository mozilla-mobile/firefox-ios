// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "NSData+Base16.h"


static const char kBase16AlphabetUpperCase[] = "0123456789ABCDEF";
static const char kBase16AlphabetLowerCase[] = "0123456789abcdef";


@implementation NSData (Base16)

- (id) initWithBase16EncodedString:(NSString *)base16String options:(NSDataBase16DecodingOptions)options
{
    if ([base16String length] & 1) {
        return nil;
    }

    if ([base16String length] == 0) {
        return [self init];
    }

    unsigned char *decoded = (unsigned char*) malloc([base16String length] / 2);
    unsigned char *dst = decoded;

    for (NSUInteger i = 0; i < [base16String length]; i += 2) {
        unichar h = [base16String characterAtIndex: i];
        unichar l = [base16String characterAtIndex: i+1];

        if (isxdigit(h) == 0 || isxdigit(l) == 0) {
            free(decoded);
            return nil;
        }

        if (isdigit(h)) {
            *dst = (h - '0') << 4;
        } else {
            if (h >= 'a') {
                *dst = (h - 'a' + 10) << 4;
            } else {
                *dst = (h - 'A' + 10) << 4;
            }
        }

        if (isdigit(l)) {
            *dst |= (l - '0');
        } else {
            if (l >= 'a') {
                *dst |= (10 + (l - 'a')) & 0x0f;
            } else {
                *dst |= (10 + (l - 'A')) & 0x0f;
            }
        }

        dst++;
    }

    return [self initWithBytesNoCopy: decoded length: [base16String length] / 2 freeWhenDone: YES];
}

- (NSString *)base16EncodedStringWithOptions:(NSDataBase16EncodingOptions)options
{
    char *encoded = (char*) malloc([self length] * 2);

    const char *src = [self bytes];
    char *dst = encoded;

    const char *alphabet =  (options & NSDataBase16EncodingOptionsLowerCase) ? kBase16AlphabetLowerCase : kBase16AlphabetUpperCase;

    for (NSUInteger i = 0; i < [self length]; i++, src++) {
        *dst++ = alphabet[(*src >> 4) & 0b00001111];
        *dst++ = alphabet[(*src >> 0) & 0b00001111];
    }

    return [[NSString alloc] initWithBytesNoCopy: encoded length: [self length] * 2 encoding: NSASCIIStringEncoding freeWhenDone: YES];
}

@end
