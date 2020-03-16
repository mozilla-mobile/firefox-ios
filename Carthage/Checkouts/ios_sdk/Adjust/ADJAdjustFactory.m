//
//  ADJAdjustFactory.m
//  Adjust
//
//  Created by Pedro Filipe on 07/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJAdjustFactory.h"

static id<ADJPackageHandler> internalPackageHandler = nil;
static id<ADJRequestHandler> internalRequestHandler = nil;
static id<ADJActivityHandler> internalActivityHandler = nil;
static id<ADJLogger> internalLogger = nil;
static id<ADJAttributionHandler> internalAttributionHandler = nil;
static id<ADJSdkClickHandler> internalSdkClickHandler = nil;

static double internalSessionInterval    = -1;
static double intervalSubsessionInterval = -1;
static NSTimeInterval internalTimerInterval = -1;
static NSTimeInterval intervalTimerStart = -1;
static ADJBackoffStrategy * packageHandlerBackoffStrategy = nil;
static ADJBackoffStrategy * sdkClickHandlerBackoffStrategy = nil;
static BOOL internalTesting = NO;
static NSTimeInterval internalMaxDelayStart = -1;
static BOOL internaliAdFrameworkEnabled = YES;

static NSString * const kBaseUrl = @"https://app.adjust.com";
static NSString * internalBaseUrl = @"https://app.adjust.com";
static NSString * const kGdprUrl = @"https://gdpr.adjust.com";
static NSString * internalGdprUrl = @"https://gdpr.adjust.com";

@implementation ADJAdjustFactory

+ (id<ADJPackageHandler>)packageHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                            startsSending:(BOOL)startsSending {
    if (internalPackageHandler == nil) {
        return [ADJPackageHandler handlerWithActivityHandler:activityHandler startsSending:startsSending];
    }

    return [internalPackageHandler initWithActivityHandler:activityHandler startsSending:startsSending];
}

+ (id<ADJRequestHandler>)requestHandlerForPackageHandler:(id<ADJPackageHandler>)packageHandler
                                      andActivityHandler:(id<ADJActivityHandler>)activityHandler {
    if (internalRequestHandler == nil) {
        return [ADJRequestHandler handlerWithPackageHandler:packageHandler
                                         andActivityHandler:activityHandler];
    }
    return [internalRequestHandler initWithPackageHandler:packageHandler
                                       andActivityHandler:activityHandler];
}

+ (id<ADJActivityHandler>)activityHandlerWithConfig:(ADJConfig *)adjustConfig
                     savedPreLaunch:(ADJSavedPreLaunch *)savedPreLaunch
{
    if (internalActivityHandler == nil) {
        return [ADJActivityHandler handlerWithConfig:adjustConfig
                                      savedPreLaunch:savedPreLaunch
                ];
    }
    return [internalActivityHandler initWithConfig:adjustConfig
                                    savedPreLaunch:savedPreLaunch];
}

+ (id<ADJLogger>)logger {
    if (internalLogger == nil) {
        //  same instance of logger
        internalLogger = [[ADJLogger alloc] init];
    }
    return internalLogger;
}

+ (double)sessionInterval {
    if (internalSessionInterval < 0) {
        return 30 * 60;           // 30 minutes
    }
    return internalSessionInterval;
}

+ (double)subsessionInterval {
    if (intervalSubsessionInterval == -1) {
        return 1;                 // 1 second
    }
    return intervalSubsessionInterval;
}

+ (NSTimeInterval)timerInterval {
    if (internalTimerInterval < 0) {
        return 60;                // 1 minute
    }
    return internalTimerInterval;
}

+ (NSTimeInterval)timerStart {
    if (intervalTimerStart < 0) {
        return 60;                 // 1 minute
    }
    return intervalTimerStart;
}

+ (ADJBackoffStrategy *)packageHandlerBackoffStrategy {
    if (packageHandlerBackoffStrategy == nil) {
        return [ADJBackoffStrategy backoffStrategyWithType:ADJLongWait];
    }
    return packageHandlerBackoffStrategy;
}

+ (ADJBackoffStrategy *)sdkClickHandlerBackoffStrategy {
    if (sdkClickHandlerBackoffStrategy == nil) {
        return [ADJBackoffStrategy backoffStrategyWithType:ADJShortWait];
    }
    return sdkClickHandlerBackoffStrategy;
}

+ (id<ADJAttributionHandler>)attributionHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                                    startsSending:(BOOL)startsSending
{
    if (internalAttributionHandler == nil) {
        return [ADJAttributionHandler handlerWithActivityHandler:activityHandler
                                                   startsSending:startsSending];
    }

    return [internalAttributionHandler initWithActivityHandler:activityHandler
                                                 startsSending:startsSending];
}

+ (id<ADJSdkClickHandler>)sdkClickHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                              startsSending:(BOOL)startsSending
{
    if (internalSdkClickHandler == nil) {
        return [ADJSdkClickHandler handlerWithActivityHandler:activityHandler startsSending:startsSending];
    }

    return [internalSdkClickHandler initWithActivityHandler:activityHandler startsSending:startsSending];
}

+ (BOOL)testing {
    return internalTesting;
}

+ (BOOL)iAdFrameworkEnabled {
    return internaliAdFrameworkEnabled;
}

+ (NSTimeInterval)maxDelayStart {
    if (internalMaxDelayStart < 0) {
        return 10.0;               // 10 seconds
    }
    return internalMaxDelayStart;
}

+ (NSString *)baseUrl {
    return internalBaseUrl;
}

+ (NSString *)gdprUrl {
    return internalGdprUrl;
}

+ (void)setPackageHandler:(id<ADJPackageHandler>)packageHandler {
    internalPackageHandler = packageHandler;
}

+ (void)setRequestHandler:(id<ADJRequestHandler>)requestHandler {
    internalRequestHandler = requestHandler;
}

+ (void)setActivityHandler:(id<ADJActivityHandler>)activityHandler {
    internalActivityHandler = activityHandler;
}

+ (void)setLogger:(id<ADJLogger>)logger {
    internalLogger = logger;
}

+ (void)setSessionInterval:(double)sessionInterval {
    internalSessionInterval = sessionInterval;
}

+ (void)setSubsessionInterval:(double)subsessionInterval {
    intervalSubsessionInterval = subsessionInterval;
}

+ (void)setTimerInterval:(NSTimeInterval)timerInterval {
    internalTimerInterval = timerInterval;
}

+ (void)setTimerStart:(NSTimeInterval)timerStart {
    intervalTimerStart = timerStart;
}

+ (void)setAttributionHandler:(id<ADJAttributionHandler>)attributionHandler {
    internalAttributionHandler = attributionHandler;
}

+ (void)setSdkClickHandler:(id<ADJSdkClickHandler>)sdkClickHandler {
    internalSdkClickHandler = sdkClickHandler;
}

+ (void)setPackageHandlerBackoffStrategy:(ADJBackoffStrategy *)backoffStrategy {
    packageHandlerBackoffStrategy = backoffStrategy;
}

+ (void)setSdkClickHandlerBackoffStrategy:(ADJBackoffStrategy *)backoffStrategy {
    sdkClickHandlerBackoffStrategy = backoffStrategy;
}

+ (void)setTesting:(BOOL)testing {
    internalTesting = testing;
}

+ (void)setiAdFrameworkEnabled:(BOOL)iAdFrameworkEnabled {
    internaliAdFrameworkEnabled = iAdFrameworkEnabled;
}

+ (void)setMaxDelayStart:(NSTimeInterval)maxDelayStart {
    internalMaxDelayStart = maxDelayStart;
}

+ (void)setBaseUrl:(NSString *)baseUrl {
    internalBaseUrl = baseUrl;
}

+ (void)setGdprUrl:(NSString *)gdprUrl {
    internalGdprUrl = gdprUrl;
}

+ (void)teardown:(BOOL)deleteState {
    if (deleteState) {
        [ADJActivityHandler deleteState];
        [ADJPackageHandler deleteState];
    }
    internalPackageHandler = nil;
    internalRequestHandler = nil;
    internalActivityHandler = nil;
    internalLogger = nil;
    internalAttributionHandler = nil;
    internalSdkClickHandler = nil;

    internalSessionInterval    = -1;
    intervalSubsessionInterval = -1;
    internalTimerInterval = -1;
    intervalTimerStart = -1;
    packageHandlerBackoffStrategy = nil;
    sdkClickHandlerBackoffStrategy = nil;
    internalTesting = NO;
    internalMaxDelayStart = -1;
    internalBaseUrl = kBaseUrl;
    internalGdprUrl = kGdprUrl;
    internaliAdFrameworkEnabled = YES;
}
@end
