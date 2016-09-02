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

static double internalSessionInterval    = -1;
static double intervalSubsessionInterval = -1;
static NSTimeInterval internalTimerInterval = -1;
static NSTimeInterval intervalTimerStart = -1;


@implementation ADJAdjustFactory

+ (id<ADJPackageHandler>)packageHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                              startPaused:(BOOL)startPaused {
    if (internalPackageHandler == nil) {
        return [ADJPackageHandler handlerWithActivityHandler:activityHandler startPaused:startPaused];
    }

    return [internalPackageHandler initWithActivityHandler:activityHandler startPaused:startPaused];
}

+ (id<ADJRequestHandler>)requestHandlerForPackageHandler:(id<ADJPackageHandler>)packageHandler {
    if (internalRequestHandler == nil) {
        return [ADJRequestHandler handlerWithPackageHandler:packageHandler];
    }
    return [internalRequestHandler initWithPackageHandler:packageHandler];
}

+ (id<ADJActivityHandler>)activityHandlerWithConfig:(ADJConfig *)adjustConfig {
    if (internalActivityHandler == nil) {
        return [ADJActivityHandler handlerWithConfig:adjustConfig];
    }
    return [internalActivityHandler initWithConfig:adjustConfig];
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
        return 0;                 // 0 seconds
    }
    return intervalTimerStart;
}

+ (id<ADJAttributionHandler>)attributionHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                           withAttributionPackage:(ADJActivityPackage *) attributionPackage
                                                      startPaused:(BOOL)startPaused
                                                      hasDelegate:(BOOL)hasDelegate
{
    if (internalAttributionHandler == nil) {
        return [ADJAttributionHandler handlerWithActivityHandler:activityHandler
                                          withAttributionPackage:attributionPackage
                                                     startPaused:startPaused
                                                     hasDelegate:hasDelegate];
    }

    return [internalAttributionHandler initWithActivityHandler:activityHandler
                                        withAttributionPackage:attributionPackage
                                                   startPaused:startPaused
                                                   hasDelegate:hasDelegate];
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
@end
