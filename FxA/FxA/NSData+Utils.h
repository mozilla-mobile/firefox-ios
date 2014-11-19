// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import <Foundation/Foundation.h>


@interface NSData (Utils)

+ (id) dataByAppendingDatas: (NSArray*) datas;

- (id) dataLeftZeroPaddedToLength: (NSUInteger) length;
- (id) dataRightZeroPaddedToLength: (NSUInteger) length;

- (id) exclusiveOrWithKey: (NSData*) key;

+ (id) randomDataWithLength: (NSUInteger) length;

- (NSString*) base64URLEncodedStringWithOptions: (NSDataBase64EncodingOptions) options;
- (instancetype) initWithBase64URLEncodedString:(NSString *)base64String options:(NSDataBase64DecodingOptions)options;

@end
