//
//  LPUtils.m
//  Leanplum
//
//  Created by Ben Marten on 6/6/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import "LPExceptionHandler.h"
#import "LPAPIConfig.h"
#import "LPConstants.h"


@implementation LPUtils

+ (BOOL)isNullOrEmpty:(id)obj
{
    // Need to check for NSString to support RubyMotion.
    // Ruby String respondsToSelector(count) is true for count: in RubyMotion
    return obj == nil
    || ([obj respondsToSelector:@selector(length)] && [obj length] == 0)
    || ([obj respondsToSelector:@selector(count)]
        && ![obj isKindOfClass:[NSString class]] && [obj count] == 0);
}

+ (BOOL)isBlank:(NSString *)str
{
    return [[str stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}

+ (NSString *)md5OfData:(NSData *)data
{
    if ([LPUtils isNullOrEmpty:data]) {
        return @"";
    }

    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

+ (NSString *)base64EncodedStringFromData:(NSData *)data
{
    if ([data respondsToSelector:
         @selector(base64EncodedStringWithOptions:)]) {
        return [data base64EncodedStringWithOptions:0];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [data base64Encoding];
#pragma clang diagnostic pop

}

+ (void)initExceptionHandling
{
    [LPExceptionHandler sharedExceptionHandler];
}

+ (void)handleException:(NSException *)exception
{
    [[LPExceptionHandler sharedExceptionHandler] reportException:exception];
}

/*
 Must include `Accept-Encoding: gzip` in the header
 Must include the phrase `gzip` in the `User-Agent` header
 https://cloud.google.com/appengine/kb/
 */
+ (NSDictionary *)createHeaders {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *userAgentString = [NSString stringWithFormat:@"%@/%@/%@/%@/%@/%@/%@/%@/%@",
                                 infoDict[(NSString *)kCFBundleNameKey],
                                 infoDict[(NSString *)kCFBundleVersionKey],
                                 [LPAPIConfig sharedConfig].appId,
                                 LEANPLUM_CLIENT,
                                 LEANPLUM_SDK_VERSION,
                                 [[UIDevice currentDevice] systemName],
                                 [[UIDevice currentDevice] systemVersion],
                                 LEANPLUM_SUPPORTED_ENCODING,
                                 LEANPLUM_PACKAGE_IDENTIFIER];
    
    NSString *languageHeader = [NSString stringWithFormat:@"%@, en-us",
                                [[NSLocale preferredLanguages] componentsJoinedByString:@", "]];
    
    return @{@"User-Agent": userAgentString, @"Accept-Language" : languageHeader, @"Accept-Encoding" : LEANPLUM_SUPPORTED_ENCODING};
}

+(BOOL)isSwizzlingEnabled
{
    BOOL swizzlingEnabled = YES;
    
    id plistValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:LP_SWIZZLING_ENABLED];
    if (plistValue && ![plistValue boolValue]) {
        swizzlingEnabled = NO;
    }

    return swizzlingEnabled;
}

@end
