//
//  SentryError.m
//  Sentry
//
//  Created by Daniel Griesser on 03/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryError.h>

#else
#import "SentryError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

NSString *const SentryErrorDomain = @"SentryErrorDomain";

NSError *_Nullable NSErrorFromSentryError(SentryError error, NSString *description) {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:SentryErrorDomain code:error userInfo:userInfo];
}

NS_ASSUME_NONNULL_END
