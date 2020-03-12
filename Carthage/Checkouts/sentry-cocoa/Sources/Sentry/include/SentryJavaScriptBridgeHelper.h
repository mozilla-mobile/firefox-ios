//
//  SentryJavaScriptBridgeHelper.h
//  Sentry
//
//  Created by Daniel Griesser on 23.10.17.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)
#import <Sentry/SentryDefines.h>
#else
#import "SentryDefines.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class SentryEvent, SentryUser, SentryFrame, SentryBreadcrumb;

@interface SentryJavaScriptBridgeHelper : NSObject
SENTRY_NO_INIT

+ (SentryEvent *)createSentryEventFromJavaScriptEvent:(NSDictionary *)jsonEvent;
+ (SentryBreadcrumb *)createSentryBreadcrumbFromJavaScriptBreadcrumb:(NSDictionary *)jsonBreadcrumb;
+ (SentryLogLevel)sentryLogLevelFromJavaScriptLevel:(int)level;
+ (SentryUser *_Nullable)createSentryUserFromJavaScriptUser:(NSDictionary *)user;
+ (NSArray *)parseJavaScriptStacktrace:(NSString *)stacktrace;
+ (NSDictionary *)sanitizeDictionary:(NSDictionary *)dictionary;
+ (NSArray<SentryFrame *> *)convertReactNativeStacktrace:(NSArray *)stacktrace;

@end

NS_ASSUME_NONNULL_END
