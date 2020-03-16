//
//  SentryLog.h
//  Sentry
//
//  Created by Daniel Griesser on 02/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDefines.h>

#else
#import "SentryDefines.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SentryLog : NSObject

+ (void)logWithMessage:(NSString *)message andLevel:(SentryLogLevel)level;

@end

NS_ASSUME_NONNULL_END
