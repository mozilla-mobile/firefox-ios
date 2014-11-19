// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import "NSString+Utils.h"


@implementation NSString (Utils)

+ (NSString*) randomAlphanumericStringWithLength: (NSUInteger) length
{
    sranddev();

    static char alphanumeric[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    NSMutableString *s = [NSMutableString string];

    for (NSUInteger i = 0; i < length; i++) {
        [s appendString: [NSString stringWithFormat: @"%c", alphanumeric[rand() % (sizeof alphanumeric - 1)]]];
    }

    return s;
}

@end
