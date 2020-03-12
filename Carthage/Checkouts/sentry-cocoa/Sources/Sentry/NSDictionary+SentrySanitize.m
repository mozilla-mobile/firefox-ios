//
//  NSDictionary+SentrySanitize.m
//  Sentry
//
//  Created by Daniel Griesser on 16/06/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/NSDictionary+SentrySanitize.h>
#import <Sentry/NSDate+SentryExtras.h>

#else
#import "NSDictionary+SentrySanitize.h"
#import "NSDate+SentryExtras.h"
#endif

@implementation NSDictionary (SentrySanitize)

- (NSDictionary *)sentry_sanitize {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *key in self.allKeys) {
        if ([[self objectForKey:key] isKindOfClass:NSDictionary.class]) {
            [dict setValue:[((NSDictionary *)[self objectForKey:key]) sentry_sanitize] forKey:key];
        } else if ([[self objectForKey:key] isKindOfClass:NSDate.class]) {
            [dict setValue:[((NSDate *)[self objectForKey:key]) sentry_toIso8601String] forKey:key];
        } else if ([key hasPrefix:@"__sentry"]) {
            continue; // We don't want to add __sentry variables
        } else {
            [dict setValue:[self objectForKey:key] forKey:key];
        }
    }
    return dict;
}

@end
