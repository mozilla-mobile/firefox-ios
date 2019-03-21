//
//  LPActionManager.h
//  Leanplum
//
//  Created by Andrew First on 9/12/13.
//  Copyright (c) 2013 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "Leanplum.h"

#import <Foundation/Foundation.h>
#import "LPContextualValues.h"
#if LP_NOT_TV
#import <UserNotifications/UserNotifications.h>
#endif

struct LeanplumMessageMatchResult {
    BOOL matchedTrigger;
    BOOL matchedUnlessTrigger;
    BOOL matchedLimit;
    BOOL matchedActivePeriod;
};
typedef struct LeanplumMessageMatchResult LeanplumMessageMatchResult;

LeanplumMessageMatchResult LeanplumMessageMatchResultMake(BOOL matchedTrigger, BOOL matchedUnlessTrigger, BOOL matchedLimit, BOOL matchedActivePeriod);

typedef enum {
    kLeanplumActionFilterForeground = 0b1,
    kLeanplumActionFilterBackground = 0b10,
    kLeanplumActionFilterAll = 0b11
} LeanplumActionFilter;

#define  LP_PUSH_NOTIFICATION_ACTION @"__Push Notification"
#define  LP_HELD_BACK_ACTION @"__held_back"

@interface LPActionManager : NSObject {
  @package
    BOOL swizzledApplicationDidRegisterRemoteNotifications;
    BOOL swizzledApplicationDidRegisterUserNotificationSettings;
    BOOL swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError;
    BOOL swizzledApplicationDidReceiveRemoteNotification;
    BOOL swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler;
    BOOL swizzledApplicationDidReceiveLocalNotification;
    BOOL swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler;
}

+ (LPActionManager*) sharedManager;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && LP_NOT_TV
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings;
#endif

+ (void)getForegroundRegionNames:(NSMutableSet **)foregroundRegionNames
        andBackgroundRegionNames:(NSMutableSet **)backgroundRegionNames;

- (void)setShouldHandleNotification:(LeanplumShouldHandleNotificationBlock)block;

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
                          withAction:(NSString *)action
              fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler;

- (LeanplumMessageMatchResult)shouldShowMessage:(NSString *)messageId
                                     withConfig:(NSDictionary *)messageConfig
                                           when:(NSString *)when
                                  withEventName:(NSString *)eventName
                               contextualValues:(LPContextualValues *)contextualValues;

- (void)recordMessageTrigger:(NSString *)messageId;
- (void)recordMessageImpression:(NSString *)messageId;
- (void)recordHeldBackImpression:(NSString *)messageId
               originalMessageId:(NSString *)originalMessageId;

- (void)muteFutureMessagesOfKind:(NSString *)messageId;

#pragma mark - Leanplum Tests
+ (void)reset;

@end
