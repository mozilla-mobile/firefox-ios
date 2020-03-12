//
//  SentryLogTests.m
//  Sentry
//
//  Created by Daniel Griesser on 08/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Sentry/Sentry.h>
#import "SentryLog.h"

@interface SentryLogTests : XCTestCase

@end

@implementation SentryLogTests

- (void)testLogTypes {
    SentryClient.logLevel = kSentryLogLevelVerbose;
    [SentryLog logWithMessage:@"1" andLevel:kSentryLogLevelError];
    [SentryLog logWithMessage:@"2" andLevel:kSentryLogLevelDebug];
    [SentryLog logWithMessage:@"3" andLevel:kSentryLogLevelVerbose];
    [SentryLog logWithMessage:@"4" andLevel:kSentryLogLevelNone];
    SentryClient.logLevel = kSentrySeverityError;
}

@end
