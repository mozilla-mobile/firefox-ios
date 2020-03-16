//
//  SentryCrashExceptionApplication.m
//  Sentry
//
//  Created by Daniel Griesser on 31.08.17.
//  Copyright © 2017 Sentry. All rights reserved.
//


#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDefines.h>
#import <Sentry/SentryCrashExceptionApplication.h>
#import <Sentry/SentryCrash.h>

#else
#import "SentryDefines.h"
#import "SentryCrashExceptionApplication.h"
#import "SentryCrash.h"
#endif


@implementation SentryCrashExceptionApplication

#if TARGET_OS_OSX

- (void)reportException:(NSException *)exception {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
    if (nil != SentryCrash.sharedInstance.uncaughtExceptionHandler && nil != exception) {
        SentryCrash.sharedInstance.uncaughtExceptionHandler(exception);
    }
    [super reportException:exception];
}
#endif

@end
