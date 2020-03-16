//
//  LPAppIconManager.m
//  Leanplum
//
//  Created by Alexis Oyama on 2/23/17.
//  Copyright (c) 2017 Leanplum, Inc. All rights reserved.
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

#import "LPAppIconManager.h"
#import "LeanplumInternal.h"
#import "LPUtils.h"
#import "LPRequestFactory.h"
#import "LPRequestSender.h"
#import "LPCountAggregator.h"

@implementation LPAppIconManager

+ (void)uploadAppIconsOnDevMode
{
    if (![LPConstantsState sharedState].isDevelopmentModeEnabled ||
        ![LPAppIconManager supportsAlternateIcons]) {
        return;
    }

    NSDictionary *alternativeIcons = [LPAppIconManager alternativeIconsBundle];
    if ([LPUtils isNullOrEmpty:alternativeIcons]) {
        LPLog(LPWarning, @"Your project does not contain any alternate app icons. "
              "Add one or more alternate icons to the info.plist. "
              "https://support.leanplum.com/hc/en-us/articles/115001519046");
        return;
    }

    // Prepare to upload primary and alternative icons.
    NSMutableArray *requestParam = [NSMutableArray new];
    NSMutableDictionary *requestDatas = [NSMutableDictionary new];
    [LPAppIconManager prepareUploadRequestParam:requestParam
                            iconDataWithFileKey:requestDatas
                                 withIconBundle:[LPAppIconManager primaryIconBundle]
                                       iconName:LP_APP_ICON_PRIMARY_NAME];
    [alternativeIcons enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isEqualToString:LP_APP_ICON_PRIMARY_NAME]) {
            LPLog(LPWarning, @"%@ is reserved for primary icon."
                  "This alternative icon will not be uploaded.", LP_APP_ICON_PRIMARY_NAME);
            return;
        }
        [LPAppIconManager prepareUploadRequestParam:requestParam
                                iconDataWithFileKey:requestDatas
                                     withIconBundle:obj
                                           iconName:key];
    }];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory uploadFileWithParams:@{@"data":
                                                    [LPJSON stringFromJSON:requestParam]}];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        LPLog(LPVerbose, @"App icons uploaded.");
    }];
    [request onError:^(NSError *error) {
        LPLog(LPError, @"Fail to upload app icons: %@", error.localizedDescription);
    }];
    [[LPRequestSender sharedInstance] sendNow:request withDatas:requestDatas];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"upload_app_icons_on_dev_mode"];
}

#pragma mark - Private methods

/**
 * Returns whether app supports alternate icons
 */
+ (BOOL)supportsAlternateIcons
{
    // Run on main thread.
    if (![NSThread isMainThread]) {
        BOOL __block outputValue = NO;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            outputValue = [self supportsAlternateIcons];
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, 0.01*NSEC_PER_SEC);
        return outputValue;
    }
    
    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(supportsAlternateIcons)]) {
        if (@available(iOS 10.3, *)) {
            return [app supportsAlternateIcons];
        } else {
            // Fallback on earlier versions
        }
    }
    return NO;
}

/**
 * Returns primary icon bundle
 */
+ (NSDictionary *)primaryIconBundle
{
    NSDictionary *bundleIcons = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIcons"];
    return bundleIcons[@"CFBundlePrimaryIcon"];
}

/**
 * Returns alternative icons bundle
 */
+ (NSDictionary *)alternativeIconsBundle
{
    NSDictionary *bundleIcons = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIcons"];
    return bundleIcons[@"CFBundleAlternateIcons"];
}

/**
 * Helper method that prepares request parameters and dats to upload icons in batch.
 * It loops through all the possible image files and uses the first one.
 */
+ (void)prepareUploadRequestParam:(NSMutableArray *)requestParam
              iconDataWithFileKey:(NSMutableDictionary *)requestDatas
                   withIconBundle:(NSDictionary *)bundle
                         iconName:(NSString *)iconName
{
    for (NSString *iconImageName in bundle[@"CFBundleIconFiles"]) {
        if ([LPUtils isNullOrEmpty:iconName]) {
            continue;
        }

        UIImage *iconImage = [UIImage imageNamed:iconImageName];
        if (!iconImage) {
            continue;
        }

        NSData *iconData = UIImagePNGRepresentation(iconImage);
        if (!iconData) {
            continue;
        }

        NSString *filekey = [NSString stringWithFormat:LP_PARAM_FILES_PATTERN, requestParam.count];
        requestDatas[filekey] = iconData;

        NSString *filename = [NSString stringWithFormat:@"%@%@.png", LP_APP_ICON_FILE_PREFIX,
                              iconName];
        NSDictionary *param = @{LP_KEY_FILENAME: filename,
                                LP_KEY_HASH: [LPUtils md5OfData:iconData],
                                LP_KEY_SIZE: @(iconData.length)};
        [requestParam addObject:param];
        return;
    }
}

@end
