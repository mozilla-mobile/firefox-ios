//
//  NSDate+SentryExtras.m
//  Sentry
//
//  Created by Daniel Griesser on 19/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//


#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/NSDate+SentryExtras.h>

#else
#import "NSDate+SentryExtras.h"
#endif


NS_ASSUME_NONNULL_BEGIN

@implementation NSDate (SentryExtras)

+ (NSDateFormatter *)getIso8601Formatter {
    static NSDateFormatter *isoFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isoFormatter = [[NSDateFormatter alloc] init];
        [isoFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        isoFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [isoFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    });

    return isoFormatter;
}

+ (NSDate *)sentry_fromIso8601String:(NSString *)string {
    return [[self.class getIso8601Formatter] dateFromString:string];
}

- (NSString *)sentry_toIso8601String {
    return [[self.class getIso8601Formatter] stringFromDate:self];
}

@end

NS_ASSUME_NONNULL_END
