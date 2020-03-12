//
//  UIDevice+ADJAdditions.h
//  Adjust
//
//  Created by Christian Wellenbrock (@wellle) on 23rd July 2012.
//  Copyright © 2012-2018 Adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ADJActivityHandler.h"

@interface UIDevice(ADJAdditions)

- (BOOL)adjTrackingEnabled;
- (NSString *)adjIdForAdvertisers;
- (NSString *)adjFbAnonymousId;
- (NSString *)adjDeviceType;
- (NSString *)adjDeviceName;
- (NSString *)adjCreateUuid;
- (NSString *)adjVendorId;
- (void)adjSetIad:(ADJActivityHandler *)activityHandler
      triesV3Left:(int)triesV3Left;
@end
