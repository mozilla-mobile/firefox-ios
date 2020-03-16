//
//  SentryLog.m
//  Sentry
//
//  Created by Daniel Griesser on 02/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryClient.h>
#import <Sentry/SentryLog.h>

#else
#import "SentryClient.h"
#import "SentryLog.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation SentryLog

+ (void)logWithMessage:(NSString *)message andLevel:(SentryLogLevel)level {
    SentryLogLevel defaultLevel = kSentryLogLevelError;
    if (SentryClient.logLevel > 0) {
        defaultLevel = SentryClient.logLevel;
    }
    if (level <= defaultLevel && level != kSentryLogLevelNone) {
        NSLog(@"Sentry - %@:: %@", [self.class logLevelToString:level], message);
    }
}

+ (NSString *)logLevelToString:(SentryLogLevel)level {
    switch (level) {
        case kSentryLogLevelDebug:
            return @"Debug";
        case kSentryLogLevelVerbose:
            return @"Verbose";
        default:
            return @"Error";
    }
}
@end

NS_ASSUME_NONNULL_END
