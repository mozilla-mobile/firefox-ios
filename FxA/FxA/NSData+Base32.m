// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "NSData+Base32.h"


static const char kBase32Alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
static const NSUInteger kBase32BlockSize = 5;


static void *base32_decode(const char *buf, unsigned int *outlen);


@implementation NSData (Base32)

- (id) initWithBase32EncodedString:(NSString *)base32String options:(NSDataBase32DecodingOptions)options
{
	NSData* result = nil;

    if (options & NSDataBase32DecodingOptionsUserFriendly) {
         base32String = [[[base32String uppercaseString]
            stringByReplacingOccurrencesOfString: @"8" withString: @"l"]
                stringByReplacingOccurrencesOfString: @"9" withString: @"o"];
    }

    unsigned int length = 0;
    void* bytes = base32_decode([base32String UTF8String], &length);
    if (bytes != NULL) {
        result = [self initWithBytesNoCopy: bytes length: length freeWhenDone: YES];
    }

	return result;
}

- (NSString *)base32EncodedStringWithOptions:(NSDataBase32EncodingOptions)options
{
    NSMutableString *encoded = [NSMutableString new];

    const unsigned char *bytes = [self bytes];
    NSUInteger bytesAvailable = [self length];

    while (bytesAvailable > 0)
    {
        unsigned char blockData[kBase32BlockSize] = { 0, 0, 0, 0, 0 };
        NSUInteger  blockSize = MIN(bytesAvailable, kBase32BlockSize);

        memcpy(blockData, bytes, blockSize);

        bytes += blockSize;
        bytesAvailable -= blockSize;

        [encoded appendFormat: @"%c", kBase32Alphabet[((blockData[0] & 0b11111000) >> 3)]];
        [encoded appendFormat: @"%c", kBase32Alphabet[((blockData[0] & 0b00000111) << 2) | ((blockData[1] & 0b11000000) >> 6)]];
        [encoded appendFormat: @"%c", kBase32Alphabet[((blockData[1] & 0b00111110) >> 1)]];
        [encoded appendFormat: @"%c", kBase32Alphabet[((blockData[1] & 0b00000001) << 4) | ((blockData[2] & 0b11110000) >> 4)]];
        [encoded appendFormat: @"%c", kBase32Alphabet[((blockData[2] & 0b00001111) << 1) | ((blockData[3] & 0b10000000) >> 7)]];
        [encoded appendFormat: @"%c", kBase32Alphabet[((blockData[3] & 0b01111100) >> 2)]];
        [encoded appendFormat: @"%c", kBase32Alphabet[((blockData[3] & 0b00000011) << 3) | ((blockData[4] & 0b11100000) >> 5)]];
        [encoded appendFormat: @"%c", kBase32Alphabet[((blockData[4] & 0b00011111))]];
    }

    NSUInteger rest = [self length] % kBase32BlockSize;
    if (rest != 0)
    {
        switch (rest)
        {
            case 1:
                [encoded replaceCharactersInRange: NSMakeRange([encoded length] - 6, 6) withString: @"======"];
                break;
            case 2:
                [encoded replaceCharactersInRange: NSMakeRange([encoded length] - 4, 4) withString: @"===="];
                break;
            case 3:
                [encoded replaceCharactersInRange: NSMakeRange([encoded length] - 3, 3) withString: @"==="];
                break;
            case 4:
                [encoded replaceCharactersInRange: NSMakeRange([encoded length] - 1, 1) withString: @"="];
                break;
        }
    }

    if (options & NSDataBase32EncodingOptionsUserFriendly) {
        return [[encoded stringByReplacingOccurrencesOfString: @"L" withString: @"8"] stringByReplacingOccurrencesOfString: @"O" withString: @"9"];
    } else {
        return encoded;
    }
}

@end


#pragma mark -


// Public domain Base32 code taken from http://bitzi.com/publicdomain

#define BASE32_LOOKUP_MAX 43

static unsigned char base32Lookup[BASE32_LOOKUP_MAX][2] =
{
    { '0', 0xFF },
    { '1', 0xFF },
    { '2', 0x1A },
    { '3', 0x1B },
    { '4', 0x1C },
    { '5', 0x1D },
    { '6', 0x1E },
    { '7', 0x1F },
    { '8', 0xFF },
    { '9', 0xFF },
    { ':', 0xFF },
    { ';', 0xFF },
    { '<', 0xFF },
    { '=', 0xFF },
    { '>', 0xFF },
    { '?', 0xFF },
    { '@', 0xFF },
    { 'A', 0x00 },
    { 'B', 0x01 },
    { 'C', 0x02 },
    { 'D', 0x03 },
    { 'E', 0x04 },
    { 'F', 0x05 },
    { 'G', 0x06 },
    { 'H', 0x07 },
    { 'I', 0x08 },
    { 'J', 0x09 },
    { 'K', 0x0A },
    { 'L', 0x0B },
    { 'M', 0x0C },
    { 'N', 0x0D },
    { 'O', 0x0E },
    { 'P', 0x0F },
    { 'Q', 0x10 },
    { 'R', 0x11 },
    { 'S', 0x12 },
    { 'T', 0x13 },
    { 'U', 0x14 },
    { 'V', 0x15 },
    { 'W', 0x16 },
    { 'X', 0x17 },
    { 'Y', 0x18 },
    { 'Z', 0x19 }
};

static int base32_decode_length(int base32Length)
{
    return ((base32Length * 5) / 8);
}

static int base32_decode_into(const char *base32Buffer, unsigned int base32BufLen, void *_buffer)
{
    unsigned long max;
    int i, index, lookup, offset;
    unsigned char  word;
    unsigned char *buffer = _buffer;

    memset(buffer, 0, base32_decode_length(base32BufLen));
    max = strlen(base32Buffer);
    for(i = 0, index = 0, offset = 0; i < max; i++)
    {
        lookup = toupper(base32Buffer[i]) - '0';
        /* Check to make sure that the given word falls inside
           a valid range */
        if ( lookup < 0 && lookup >= BASE32_LOOKUP_MAX)
            word = 0xFF;
        else
            word = base32Lookup[lookup][1];

        /* If this word is not in the table, ignore it */
        if (word == 0xFF)
            continue;

        if (index <= 3)
        {
            index = (index + 5) % 8;
            if (index == 0)
            {
                buffer[offset] |= word;
                offset++;
            }
            else
                buffer[offset] |= word << (8 - index);
        }
        else
        {
            index = (index + 5) % 8;
            buffer[offset] |= (word >> index);
            offset++;

            buffer[offset] |= word << (8 - index);
        }
    }
    return offset;
}

static void *base32_decode(const char *buf, unsigned int *outlen)
{
    unsigned int len = strlen(buf);
    char *tmp = malloc(base32_decode_length(len));
    unsigned int x = base32_decode_into(buf, len, tmp);
    if(outlen)
        *outlen = x;
    return tmp;
}
