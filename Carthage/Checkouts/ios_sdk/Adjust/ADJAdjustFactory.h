//
//  ADJAdjustFactory.h
//  Adjust
//
//  Created by Pedro Filipe on 07/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "ADJActivityHandler.h"
#import "ADJPackageHandler.h"
#import "ADJRequestHandler.h"
#import "ADJLogger.h"
#import "ADJAttributionHandler.h"
#import "ADJActivityPackage.h"
#import "ADJBackoffStrategy.h"
#import "ADJSdkClickHandler.h"

@interface ADJAdjustFactory : NSObject

+ (id<ADJPackageHandler>)packageHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                            startsSending:(BOOL)startsSending;
+ (id<ADJRequestHandler>)requestHandlerForPackageHandler:(id<ADJPackageHandler>)packageHandler;
+ (id<ADJActivityHandler>)activityHandlerWithConfig:(ADJConfig *)adjustConfig
                     sessionParametersActionsArray:(NSArray*)sessionParametersActionsArray;
+ (id<ADJSdkClickHandler>)sdkClickHandlerWithStartsPaused:(BOOL)startsSending;

+ (id<ADJLogger>)logger;
+ (double)sessionInterval;
+ (double)subsessionInterval;
+ (NSTimeInterval)timerInterval;
+ (NSTimeInterval)timerStart;
+ (ADJBackoffStrategy *)packageHandlerBackoffStrategy;
+ (ADJBackoffStrategy *)sdkClickHandlerBackoffStrategy;

+ (id<ADJAttributionHandler>)attributionHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                           withAttributionPackage:(ADJActivityPackage *) attributionPackage
                                                    startsSending:(BOOL)startsSending
                                    hasAttributionChangedDelegate:(BOOL)hasAttributionChangedDelegate;
+ (BOOL)testing;
+ (NSTimeInterval)maxDelayStart;

+ (void)setPackageHandler:(id<ADJPackageHandler>)packageHandler;
+ (void)setRequestHandler:(id<ADJRequestHandler>)requestHandler;
+ (void)setActivityHandler:(id<ADJActivityHandler>)activityHandler;
+ (void)setSdkClickHandler:(id<ADJSdkClickHandler>)sdkClickHandler;
+ (void)setLogger:(id<ADJLogger>)logger;
+ (void)setSessionInterval:(double)sessionInterval;
+ (void)setSubsessionInterval:(double)subsessionInterval;
+ (void)setTimerInterval:(NSTimeInterval)timerInterval;
+ (void)setTimerStart:(NSTimeInterval)timerStart;
+ (void)setAttributionHandler:(id<ADJAttributionHandler>)attributionHandler;
+ (void)setPackageHandlerBackoffStrategy:(ADJBackoffStrategy *)backoffStrategy;
+ (void)setSdkClickHandlerBackoffStrategy:(ADJBackoffStrategy *)backoffStrategy;
+ (void)setTesting:(BOOL)testing;
+ (void)setMaxDelayStart:(NSTimeInterval)maxDelayStart;

+ (void)teardown;
@end
