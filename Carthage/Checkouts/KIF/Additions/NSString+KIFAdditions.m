//
//  NSString+KIFAdditions.m
//  KIF
//
//  Created by Alex Odawa on 1/28/16.
//
//

#import "NSString+KIFAdditions.h"

#pragma mark - NSString
@implementation NSString (KIFAdditions)

- (BOOL)KIF_isEqualToStringOrAttributedString:(id)aString;
{
    // Somtimes Accessibility Elements will return an AXAttributedString.
    // This compares the raw backing string against a vanilla NSString, ignoring any attributes.
    if ([aString respondsToSelector:@selector(string)]) {
        return [self isEqualToString:[(id)aString string]];
    }
    return [self isEqualToString:aString];
}

@end
