//
//  SentryOptions.m
//  Sentry
//
//  Created by Daniel Griesser on 12.03.19.
//  Copyright © 2019 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryOptions.h>
#import <Sentry/SentryDsn.h>
#import <Sentry/SentryError.h>

#else
#import "SentryOptions.h"
#import "SentryDsn.h"
#import "SentryError.h"
#endif

@implementation SentryOptions

- (_Nullable instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options
                         didFailWithError:(NSError *_Nullable *_Nullable)error {
    self = [super init];
    if (self) {
        [self validateOptions:options didFailWithError:error];
        if (nil != error && nil != *error) {
            return nil;
        }
    }
    return self;
}
    
- (void)validateOptions:(NSDictionary<NSString *, id> *)options
       didFailWithError:(NSError *_Nullable *_Nullable)error {
    if (nil == [options valueForKey:@"dsn"] || ![[options valueForKey:@"dsn"] isKindOfClass:[NSString class]]) {
        *error = NSErrorFromSentryError(kSentryErrorInvalidDsnError, @"Dsn cannot be empty");
        return;
    }
    self.dsn = [[SentryDsn alloc] initWithString:[options valueForKey:@"dsn"] didFailWithError:error];
    
    if ([[options objectForKey:@"release"] isKindOfClass:[NSString class]]) {
        self.releaseName = [options objectForKey:@"release"];
    }
    
    if ([[options objectForKey:@"environment"] isKindOfClass:[NSString class]]) {
        self.environment = [options objectForKey:@"environment"];
    }
    
    if ([[options objectForKey:@"dist"] isKindOfClass:[NSString class]]) {
        self.dist = [options objectForKey:@"dist"];
    }
    
    if (nil != [options objectForKey:@"enabled"]) {
        self.enabled = [NSNumber numberWithBool:[[options objectForKey:@"enabled"] boolValue]];
    }
}
    
@end
