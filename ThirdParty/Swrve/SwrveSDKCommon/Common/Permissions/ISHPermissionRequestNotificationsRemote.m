//
//  ISHPermissionRequestNotificationsRemote.m
//  ISHPermissionKit
//
//  Created by Sergio Mira on 21.04.15.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "ISHPermissionRequestNotificationsRemote.h"
#import "ISHPermissionRequest+Private.h"

@interface ISHPermissionRequestNotificationsRemote ()
@property (atomic, copy) ISHPermissionRequestCompletionBlock completionBlock;
@end

@implementation ISHPermissionRequestNotificationsRemote

@synthesize notificationSettings;
@synthesize completionBlock;

- (BOOL)allowsConfiguration {
    return YES;
}

- (ISHPermissionState)permissionState {
    return ISHPermissionStateUnknown;
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
    
    self.completionBlock = completion;
    [ISHPermissionRequestNotificationsRemote registerForRemoteNotifications:self.notificationSettings];
}

-(void)requestUserPermissionWithoutCompleteBlock {
    [ISHPermissionRequestNotificationsRemote registerForRemoteNotifications:self.notificationSettings];
}

+(void)registerForRemoteNotifications:(UIUserNotificationSettings*)notificationSettings {
    UIApplication* app = [UIApplication sharedApplication];
#if defined(__IPHONE_8_0)
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    // Check if the new push API is not available
    if (![app respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        // Use the old API
        [app registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
    else
#endif //__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    {
        NSAssert(notificationSettings, @"Requested notification settings should be set for request before requesting user permission", nil);
        [app registerUserNotificationSettings:notificationSettings];
        [app registerForRemoteNotifications];
    }
#else
    // Not building with the latest XCode that contains iOS 8 definitions
    [app registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif //defined(__IPHONE_8_0)
}

@end
