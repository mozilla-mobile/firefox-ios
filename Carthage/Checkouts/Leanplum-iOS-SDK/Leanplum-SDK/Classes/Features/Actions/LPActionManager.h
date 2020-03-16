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
#import <UserNotifications/UserNotifications.h>

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
    
}

+ (LPActionManager*) sharedManager;

#pragma mark - Push Notifications

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler;
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response
                 withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification;

- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings;
#pragma clang diagnostic pop

+ (void)getForegroundRegionNames:(NSMutableSet **)foregroundRegionNames
        andBackgroundRegionNames:(NSMutableSet **)backgroundRegionNames;

- (void)setShouldHandleNotification:(LeanplumShouldHandleNotificationBlock)block;

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
                          withAction:(NSString *)action
              fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler;

#pragma mark - Messages

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
