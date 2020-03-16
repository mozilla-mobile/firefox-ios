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
+ (id<ADJRequestHandler>)requestHandlerForPackageHandler:(id<ADJPackageHandler>)packageHandler
                                      andActivityHandler:(id<ADJActivityHandler>)activityHandler;
+ (id<ADJActivityHandler>)activityHandlerWithConfig:(ADJConfig *)adjustConfig
                     savedPreLaunch:(ADJSavedPreLaunch *)savedPreLaunch;
+ (id<ADJSdkClickHandler>)sdkClickHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                              startsSending:(BOOL)startsSending;

+ (id<ADJLogger>)logger;
+ (double)sessionInterval;
+ (double)subsessionInterval;
+ (NSTimeInterval)timerInterval;
+ (NSTimeInterval)timerStart;
+ (ADJBackoffStrategy *)packageHandlerBackoffStrategy;
+ (ADJBackoffStrategy *)sdkClickHandlerBackoffStrategy;

+ (id<ADJAttributionHandler>)attributionHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                                    startsSending:(BOOL)startsSending;
+ (BOOL)testing;
+ (NSTimeInterval)maxDelayStart;
+ (NSString *)baseUrl;
+ (NSString *)gdprUrl;
+ (BOOL)iAdFrameworkEnabled;

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
+ (void)setiAdFrameworkEnabled:(BOOL)iAdFrameworkEnabled;
+ (void)setMaxDelayStart:(NSTimeInterval)maxDelayStart;
+ (void)setBaseUrl:(NSString *)baseUrl;
+ (void)setGdprUrl:(NSString *)gdprUrl;

+ (void)teardown:(BOOL)deleteState;
@end
