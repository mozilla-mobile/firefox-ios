//
//  NSString+ADJAdditions.m
//  Adjust
//
//  Created by Christian Wellenbrock on 23.07.12.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "NSString+ADJAdditions.h"

@implementation NSString(ADJAdditions)

- (NSString *)adjTrim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString *)adjUrlEncode {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
#pragma clang diagnostic pop

    // Alternative:
    // return [self stringByAddingPercentEncodingWithAllowedCharacters:
    //        [NSCharacterSet characterSetWithCharactersInString:@"!*'\"();:@&=+$,/?%#[]% "]];
}

-(NSString *)adjUrlDecode {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(
                                                                                 kCFAllocatorDefault,
                                                                                 (CFStringRef)self,
                                                                                 CFSTR("")));
}

- (NSString *)adjRemoveColons {
    return [self stringByReplacingOccurrencesOfString:@":" withString:@""];
}

- (NSString *)adjMd5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return  output;
}

- (NSString *)adjSha1 {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];

    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output;
}

- (NSString *)adjSha256 {
    const char* str = [self UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

+ (NSString *)adjJoin:(NSString *)first, ... {
    NSString *iter, *result = first;
    va_list strings;
    va_start(strings, first);

    while ((iter = va_arg(strings, NSString*))) {
        NSString *capitalized = iter.capitalizedString;
        result = [result stringByAppendingString:capitalized];
    }
    
    va_end(strings);

    return result;
}

+ (BOOL)adjIsEqual:(NSString *)first toString:(NSString *)second {
    if (first == nil && second == nil) {
        return YES;
    }
    
    return [first isEqualToString:second];
}

@end
