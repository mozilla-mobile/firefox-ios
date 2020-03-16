//
//  SentryCrashReportSink.m
//  Sentry
//
//  Created by Daniel Griesser on 10/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDefines.h>
#import <Sentry/SentryCrashReportSink.h>
#import <Sentry/SentryCrashReportConverter.h>
#import <Sentry/SentryClient+Internal.h>
#import <Sentry/SentryClient.h>
#import <Sentry/SentryEvent.h>
#import <Sentry/SentryException.h>
#import <Sentry/SentryLog.h>
#import <Sentry/SentryThread.h>

#import <Sentry/SentryCrash.h>

#else
#import "SentryDefines.h"
#import "SentryCrashReportSink.h"
#import "SentryCrashReportConverter.h"
#import "SentryClient.h"
#import "SentryClient+Internal.h"
#import "SentryEvent.h"
#import "SentryException.h"
#import "SentryLog.h"
#import "SentryThread.h"

#import "SentryCrash.h"
#endif


@implementation SentryCrashReportSink

- (void)handleConvertedEvent:(SentryEvent *)event report:(NSDictionary *)report sentReports:(NSMutableArray *)sentReports {
    if (nil != event.exceptions.firstObject && [event.exceptions.firstObject.value isEqualToString:@"SENTRY_SNAPSHOT"]) {
        [SentryLog logWithMessage:@"Snapshotting stacktrace" andLevel:kSentryLogLevelDebug];
        SentryClient.sharedClient._snapshotThreads = @[event.exceptions.firstObject.thread];
        SentryClient.sharedClient._debugMeta = event.debugMeta;
    } else {
        [sentReports addObject:report];
        [SentryClient.sharedClient sendEvent:event withCompletionHandler:NULL];
    }
}

- (void)filterReports:(NSArray *)reports
          onCompletion:(SentryCrashReportFilterCompletion)onCompletion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSMutableArray *sentReports = [NSMutableArray new];
        for (NSDictionary *report in reports) {
            SentryCrashReportConverter *reportConverter = [[SentryCrashReportConverter alloc] initWithReport:report];
            if (nil != SentryClient.sharedClient) {
                reportConverter.userContext = SentryClient.sharedClient.lastContext;
                SentryEvent *event = [reportConverter convertReportToEvent];
                [self handleConvertedEvent:event report:report sentReports:sentReports];
            } else {
                [SentryLog logWithMessage:@"Crash reports were found but no SentryClient.sharedClient is set. Cannot send crash reports to Sentry. This is probably a misconfiguration, make sure you set SentryClient.sharedClient before calling startCrashHandlerWithError:." andLevel:kSentryLogLevelError];
            }
        }
        if (onCompletion) {
            onCompletion(sentReports, TRUE, nil);
        }
    });

}

@end
