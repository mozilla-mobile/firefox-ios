//
//  AdjustTrackingHelper.h
//  AdjustExample-iWatch
//
//  Created by Uglješa Erceg on 29/04/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AdjustDelegate;

@interface AdjustTrackingHelper : NSObject

+ (id)sharedInstance;

- (void)initialize:(NSObject<AdjustDelegate> *)delegate;

- (void)trackSimpleEvent;
- (void)trackRevenueEvent;
- (void)trackCallbackEvent;
- (void)trackPartnerEvent;

@end
