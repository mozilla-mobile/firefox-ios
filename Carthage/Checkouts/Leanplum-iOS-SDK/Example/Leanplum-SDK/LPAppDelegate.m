//
//  LPAppDelegate.m
//  Leanplum-SDK
//
//  Created by Ben Marten on 08/29/2016.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
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

#import "LPAppDelegate.h"
#import <UserNotifications/UserNotifications.h>

@implementation LPAppDelegate

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 100000
        [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:
         UNAuthorizationOptionAlert|UNAuthorizationOptionBadge|UNAuthorizationOptionSound
                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
                            NSLog(@"Granted? %@", granted ? @"YES" : @"NO");
                            NSLog(@"Error: %@", error);
                        }];
#endif
    return YES;
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    NSLog(@"Will present notification: %@", notification);
    completionHandler(UNNotificationPresentationOptionAlert|
                      UNNotificationPresentationOptionBadge|
                      UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler
{
    NSLog(@"didReceiveNotificationResponse: %@", response);
    completionHandler();
}

@end
