//
//  SentryCrashInstallation.m
//  Sentry
//
//  Created by Daniel Griesser on 10/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDefines.h>
#import <Sentry/SentryInstallation.h>
#import <Sentry/SentryCrashReportSink.h>
#import <Sentry/SentryLog.h>

#import <Sentry/SentryCrash.h>
#import <Sentry/SentryCrashInstallation+Private.h>

#else
#import "SentryDefines.h"
#import "SentryInstallation.h"
#import "SentryCrashReportSink.h"
#import "SentryLog.h"

#import "SentryCrash.h"
#import "SentryCrashInstallation+Private.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation SentryInstallation

- (id)init {
    return [super initWithRequiredProperties:[NSArray new]];
}

- (id<SentryCrashReportFilter>)sink {
    return [[SentryCrashReportSink alloc] init];
}

- (void)sendAllReports {
    [self sendAllReportsWithCompletion:NULL];
}

- (void)sendAllReportsWithCompletion:(SentryCrashReportFilterCompletion)onCompletion {
    [super sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if (nil != error) {
            [SentryLog logWithMessage:error.localizedDescription andLevel:kSentryLogLevelError];
        }
        [SentryLog logWithMessage:[NSString stringWithFormat:@"Sent %lu crash report(s)", (unsigned long)filteredReports.count] andLevel:kSentryLogLevelDebug];
        if (completed && onCompletion) {
            onCompletion(filteredReports, completed, error);
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
