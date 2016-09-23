//
//  ADJPackageHandler.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-03.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "ADJActivityPackage.h"
#import "ADJPackageHandler.h"
#import "ADJActivityHandler.h"
#import "ADJResponseData.h"
#import "ADJSessionParameters.h"

@protocol ADJPackageHandler

- (id)initWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                startsSending:(BOOL)startsSending;

- (void)addPackage:(ADJActivityPackage *)package;
- (void)sendFirstPackage;
- (void)sendNextPackage:(ADJResponseData *)responseData;
- (void)closeFirstPackage:(ADJResponseData *)responseData
          activityPackage:(ADJActivityPackage *)activityPackage;
- (void)pauseSending;
- (void)resumeSending;
- (void)updatePackages:(ADJSessionParameters *)sessionParameters;
- (void)teardown:(BOOL)deleteState;
@end

@interface ADJPackageHandler : NSObject <ADJPackageHandler>

+ (id<ADJPackageHandler>)handlerWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                                      startsSending:(BOOL)startsSending;

@end
