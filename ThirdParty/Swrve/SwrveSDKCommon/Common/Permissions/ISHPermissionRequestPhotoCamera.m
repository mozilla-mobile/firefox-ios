//
//  ISHPermissionRequestPhotoCamera.m
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 27.06.14.
//  Modified by Swrve Mobile Inc.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ISHPermissionRequestPhotoCamera.h"
#import "ISHPermissionRequest+Private.h"

#if !defined(SWRVE_NO_PHOTO_CAMERA)

@implementation ISHPermissionRequestPhotoCamera

- (ISHPermissionState)permissionState {
    // Disabled as it would invoke a permission dialog
    //AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    //if (!captureInput) {
    //    return ISHPermissionStateUnsupported;
    //}
    
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        switch (authStatus) {
            case AVAuthorizationStatusAuthorized:
                return ISHPermissionStateAuthorized;

            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
                return ISHPermissionStateDenied;
                
            case AVAuthorizationStatusNotDetermined:
                return [self internalPermissionState];
        }
    }
    
    return ISHPermissionStateUnsupported;
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
    
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ISHPermissionState state = granted ? ISHPermissionStateAuthorized : ISHPermissionStateDenied;
                if (completion != nil) {
                    completion(self, state, nil);
                }
            });
        }];
    } else {
        AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
        if (completion != nil) {
            completion(self, self.permissionState, nil);
        }
    }
}
@end

#endif
