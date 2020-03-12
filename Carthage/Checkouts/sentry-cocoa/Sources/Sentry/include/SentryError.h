//
//  SentryError.h
//  Sentry
//
//  Created by Daniel Griesser on 03/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDefines.h>

#else
#import "SentryDefines.h"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SentryError) {
    kSentryErrorUnknownError = -1,
    kSentryErrorInvalidDsnError = 100,
    kSentryErrorSentryCrashNotInstalledError = 101,
    kSentryErrorInvalidCrashReportError = 102,
    kSentryErrorCompressionError = 103,
    kSentryErrorJsonConversionError = 104,
    kSentryErrorCouldNotFindDirectory = 105,
    kSentryErrorRequestError = 106,
    kSentryErrorEventNotSent = 107,
};

SENTRY_EXTERN NSError *_Nullable NSErrorFromSentryError(SentryError error, NSString *description);

SENTRY_EXTERN NSString *const SentryErrorDomain;

NS_ASSUME_NONNULL_END
