//
//  UIDevice+ADJAdditions.h
//  Adjust
//
//  Created by Christian Wellenbrock on 23.07.12.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ADJActivityHandler.h"

@interface UIDevice(ADJAdditions)

- (BOOL)adjTrackingEnabled;
- (NSString *)adjIdForAdvertisers;
- (NSString *)adjFbAttributionId;
- (NSString *)adjDeviceType;
- (NSString *)adjDeviceName;
- (NSString *)adjCreateUuid;
- (NSString *)adjVendorId;
- (void)adjSetIad:(ADJActivityHandler *)activityHandler
      triesV3Left:(int)triesV3Left;
@end
