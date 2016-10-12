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

@implementation ADJAdjustFactory

+ (id<ADJPackageHandler>)packageHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                            startsSending:(BOOL)startsSending {
    if (internalPackageHandler == nil) {
        return [ADJPackageHandler handlerWithActivityHandler:activityHandler startsSending:startsSending];
    }

    return [internalPackageHandler initWithActivityHandler:activityHandler startsSending:startsSending];
}

+ (id<ADJRequestHandler>)requestHandlerForPackageHandler:(id<ADJPackageHandler>)packageHandler {
    if (internalRequestHandler == nil) {
        return [ADJRequestHandler handlerWithPackageHandler:packageHandler];
    }
    return [internalRequestHandler initWithPackageHandler:packageHandler];
}

+ (id<ADJActivityHandler>)activityHandlerWithConfig:(ADJConfig *)adjustConfig
                     sessionParametersActionsArray:(NSArray*)sessionParametersActionsArray
{
    if (internalActivityHandler == nil) {
        return [ADJActivityHandler handlerWithConfig:adjustConfig
                      sessionParametersActionsArray:sessionParametersActionsArray];
    }
    return [internalActivityHandler initWithConfig:adjustConfig
                    sessionParametersActionsArray:sessionParametersActionsArray];
}

+ (id<ADJLogger>)logger {
    if (internalLogger == nil) {
        //  same instance of logger
        internalLogger = [[ADJLogger alloc] init];
    }
    return internalLogger;
}

+ (double)sessionInterval {
    if (internalSessionInterval == -1) {
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
    if (internalTimerInterval == -1) {
        return 60;                // 1 minute
    }
    return internalTimerInterval;
}

+ (NSTimeInterval)timerStart {
    if (intervalTimerStart == -1) {
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
                                           withAttributionPackage:(ADJActivityPackage *) attributionPackage
                                                    startsSending:(BOOL)startsSending
                                    hasAttributionChangedDelegate:(BOOL)hasAttributionChangedDelegate
{
    if (internalAttributionHandler == nil) {
        return [ADJAttributionHandler handlerWithActivityHandler:activityHandler
                                          withAttributionPackage:attributionPackage
                                                   startsSending:startsSending
                                                     hasAttributionChangedDelegate:hasAttributionChangedDelegate];
    }

    return [internalAttributionHandler initWithActivityHandler:activityHandler
                                        withAttributionPackage:attributionPackage
                                                 startsSending:startsSending
                                 hasAttributionChangedDelegate:hasAttributionChangedDelegate];
}

+ (id<ADJSdkClickHandler>)sdkClickHandlerWithStartsPaused:(BOOL)startsSending
{
    if (internalSdkClickHandler == nil) {
        return [ADJSdkClickHandler handlerWithStartsSending:startsSending];
    }

    return [internalSdkClickHandler initWithStartsSending:startsSending];
}

+ (BOOL)testing {
    return internalTesting;
}

+ (NSTimeInterval)maxDelayStart {
    if (internalMaxDelayStart == -1) {
        return 10.0;               // 10 seconds
    }
    return internalMaxDelayStart;
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

+ (void)setMaxDelayStart:(NSTimeInterval)maxDelayStart {
    internalMaxDelayStart = maxDelayStart;
}

+ (void)teardown {
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
    internalMaxDelayStart = -1;
}
@end
