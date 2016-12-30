//
//  ISHPermissionRequestPhotoLibrary.m
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 27.06.14.
//  Modified by Swrve Inc.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#if defined(__IPHONE_9_0)
#import <Photos/Photos.h>
#endif //defined(__IPHONE_9_0)
#import "ISHPermissionRequestPhotoLibrary.h"
#import "ISHPermissionRequest+Private.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#if !defined(SWRVE_NO_PHOTO_LIBRARY)

@interface ISHPermissionRequestPhotoLibrary ()
@end

@implementation ISHPermissionRequestPhotoLibrary
- (ISHPermissionState)permissionState {
#if defined(__IPHONE_9_0)
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        PHAuthorizationStatus systemState = [PHPhotoLibrary authorizationStatus];
        switch (systemState) {
            case PHAuthorizationStatusAuthorized:
                return ISHPermissionStateAuthorized;
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusRestricted:
                return ISHPermissionStateDenied;
            default:
                return [self internalPermissionState];
        }
    }
#endif //defined(__IPHONE_9_0)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    ALAuthorizationStatus systemState = [ALAssetsLibrary authorizationStatus];
    switch (systemState) {
        case ALAuthorizationStatusAuthorized:
            return ISHPermissionStateAuthorized;
        case ALAuthorizationStatusDenied:
        case ALAuthorizationStatusRestricted:
            return ISHPermissionStateDenied;
        default:
            return [self internalPermissionState];
    }
#pragma clang diagnostic pop
}

- (void)requestUserPermissionWithCompletionBlock:(ISHPermissionRequestCompletionBlock)completion {
    NSAssert(completion, @"requestUserPermissionWithCompletionBlock requires a completion block", nil);
    ISHPermissionState currentState = self.permissionState;
    if (!ISHPermissionStateAllowsUserPrompt(currentState)) {
        if (completion != nil) {
            completion(self, currentState, nil);
        }
        return;
    }
    
#if defined(__IPHONE_9_0)
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
#pragma unused(status)
            // ensure that completion is only called once
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion != nil) {
                    completion(self, self.permissionState, nil);
                }
            });
        }];
        return;
    }
#endif //defined(__IPHONE_9_0)
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    ALAssetsLibrary *assetsLibrary = [ALAssetsLibrary new];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
#pragma unused(stop)
        if (!group) {
            // ensure that completion is only called once
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion != nil) {
                    completion(self, self.permissionState, nil);
                }
            });
        }
    } failureBlock:^(NSError *error) {
#pragma unused(error)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion != nil) {
                completion(self, self.permissionState, nil);
            }
        });
    }];
#pragma clang diagnostic pop
}

@end

#endif //!defined(SWRVE_NO_PHOTO_LIBRARY)
