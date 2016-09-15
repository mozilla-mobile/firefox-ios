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

@interface ADJAdjustFactory : NSObject

+ (id<ADJPackageHandler>)packageHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                              startPaused:(BOOL)startPaused;
+ (id<ADJRequestHandler>)requestHandlerForPackageHandler:(id<ADJPackageHandler>)packageHandler;
+ (id<ADJActivityHandler>)activityHandlerWithConfig:(ADJConfig *)adjustConfig;
+ (id<ADJLogger>)logger;
+ (double)sessionInterval;
+ (double)subsessionInterval;
+ (NSTimeInterval)timerInterval;
+ (NSTimeInterval)timerStart;
+ (id<ADJAttributionHandler>)attributionHandlerForActivityHandler:(id<ADJActivityHandler>)activityHandler
                                           withAttributionPackage:(ADJActivityPackage *) attributionPackage
                                                      startPaused:(BOOL)startPaused
                                                      hasDelegate:(BOOL)hasDelegate;

+ (void)setPackageHandler:(id<ADJPackageHandler>)packageHandler;
+ (void)setRequestHandler:(id<ADJRequestHandler>)requestHandler;
+ (void)setActivityHandler:(id<ADJActivityHandler>)activityHandler;
+ (void)setLogger:(id<ADJLogger>)logger;
+ (void)setSessionInterval:(double)sessionInterval;
+ (void)setSubsessionInterval:(double)subsessionInterval;
+ (void)setTimerInterval:(NSTimeInterval)timerInterval;
+ (void)setTimerStart:(NSTimeInterval)timerStart;
+ (void)setAttributionHandler:(id<ADJAttributionHandler>)attributionHandler;

@end
