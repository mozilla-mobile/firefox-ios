// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import <Foundation/Foundation.h>


typedef NS_OPTIONS(NSUInteger, NSDataBase16DecodingOptions) {
    NSDataBase16DecodingOptionsDefault = 0
};

typedef NS_OPTIONS(NSUInteger, NSDataBase16EncodingOptions) {
    NSDataBase16EncodingOptionsDefault = 0,
    NSDataBase16EncodingOptionsLowerCase = 1
};


@interface NSData (Base16)

- (id) initWithBase16EncodedString:(NSString *)base16String options:(NSDataBase16DecodingOptions)options;
- (NSString *)base16EncodedStringWithOptions:(NSDataBase16EncodingOptions)options;

@end
