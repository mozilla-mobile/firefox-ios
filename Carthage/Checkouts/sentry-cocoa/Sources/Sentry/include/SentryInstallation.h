//
//  SentryCrashInstallation.h
//  Sentry
//
//  Created by Daniel Griesser on 10/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)
#import <Sentry/SentryCrash.h>
#import <Sentry/SentryCrashInstallation.h>
#else
#import "SentryCrash.h"
#import "SentryCrashInstallation.h"
#endif

@interface SentryInstallation : SentryCrashInstallation

- (void)sendAllReports;

@end
