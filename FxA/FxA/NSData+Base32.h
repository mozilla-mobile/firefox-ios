// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import <Foundation/Foundation.h>


typedef NS_OPTIONS(NSUInteger, NSDataBase32DecodingOptions) {
    NSDataBase32DecodingOptionsDefault = 0,
    NSDataBase32DecodingOptionsUserFriendly = 1UL << 0
};

typedef NS_OPTIONS(NSUInteger, NSDataBase32EncodingOptions) {
    NSDataBase32EncodingOptionsDefault = 0,
    NSDataBase32EncodingOptionsUserFriendly = 1UL << 0
};


@interface NSData (Base32)

- (id) initWithBase32EncodedString:(NSString *)base32String options:(NSDataBase32DecodingOptions)options;
- (NSString *)base32EncodedStringWithOptions:(NSDataBase32EncodingOptions)options;

@end
