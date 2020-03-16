//
//  ADJPackageBuilder.h
//  Adjust SDK
//
//  Created by Christian Wellenbrock (@wellle) on 3rd July 2013.
//  Copyright (c) 2013-2018 Adjust GmbH. All rights reserved.
//

#import "ADJEvent.h"
#import "ADJConfig.h"
#import "ADJDeviceInfo.h"
#import "ADJActivityState.h"
#import "ADJActivityPackage.h"
#import "ADJSessionParameters.h"
#import <Foundation/Foundation.h>

@interface ADJPackageBuilder : NSObject

@property (nonatomic, copy) NSString *deeplink;

@property (nonatomic, copy) NSDate *clickTime;

@property (nonatomic, copy) NSDate *purchaseTime;

@property (nonatomic, strong) NSDictionary *attributionDetails;

@property (nonatomic, strong) NSDictionary *deeplinkParameters;

@property (nonatomic, copy) ADJAttribution *attribution;

- (id)initWithDeviceInfo:(ADJDeviceInfo *)deviceInfo
           activityState:(ADJActivityState *)activityState
                  config:(ADJConfig *)adjustConfig
       sessionParameters:(ADJSessionParameters *)sessionParameters
               createdAt:(double)createdAt;

- (ADJActivityPackage *)buildSessionPackage:(BOOL)isInDelay;

- (ADJActivityPackage *)buildEventPackage:(ADJEvent *)event
                                isInDelay:(BOOL)isInDelay;

- (ADJActivityPackage *)buildInfoPackage:(NSString *)infoSource;

- (ADJActivityPackage *)buildAdRevenuePackage:(NSString *)source payload:(NSData *)payload;

- (ADJActivityPackage *)buildClickPackage:(NSString *)clickSource;

- (ADJActivityPackage *)buildAttributionPackage:(NSString *)initiatedBy;

- (ADJActivityPackage *)buildGdprPackage;

+ (void)parameters:(NSMutableDictionary *)parameters
     setDictionary:(NSDictionary *)dictionary
            forKey:(NSString *)key;

+ (void)parameters:(NSMutableDictionary *)parameters
         setString:(NSString *)value
            forKey:(NSString *)key;

@end
