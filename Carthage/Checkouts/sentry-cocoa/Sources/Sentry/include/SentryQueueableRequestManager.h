//
//  SentryQueueableRequestManager.h
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDefines.h>

#else
#import "SentryDefines.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol SentryRequestManager

@property(nonatomic, readonly, getter = isReady) BOOL ready;

- (instancetype)initWithSession:(NSURLSession *)session;

- (void)addRequest:(NSURLRequest *)request completionHandler:(_Nullable SentryRequestOperationFinished)completionHandler;

- (void)cancelAllOperations;

@end

@interface SentryQueueableRequestManager : NSObject <SentryRequestManager>

@end

NS_ASSUME_NONNULL_END
