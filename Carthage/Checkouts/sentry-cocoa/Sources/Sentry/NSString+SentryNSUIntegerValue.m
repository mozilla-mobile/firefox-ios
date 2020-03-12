//
//  SentryNSUIntegerValue.m
//  Sentry
//
//  Created by Crazy凡 on 2019/3/21.
//  Copyright © 2019 Sentry. All rights reserved.
//



#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/NSString+SentryNSUIntegerValue.h>

#else
#import "NSString+SentryNSUIntegerValue.h"
#endif

@implementation NSString (SentryNSUIntegerValue)

- (NSUInteger)unsignedLongLongValue {
    return strtoull([self UTF8String], NULL, 0);
}

@end
