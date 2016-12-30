//
//  ISHPermissionRequest.h
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 25.06.14.
//  Modified by Swrve Mobile Inc.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISHPermissionCategory.h"

/**
 *  Enumeration for possible permission states.
 *  These are used inlieu of the permission state values 
 *  provided by the system.
 */
typedef NS_ENUM(NSUInteger, ISHPermissionState) {
    /**
     *  The state of the permission could not be determined.
     */
    ISHPermissionStateUnknown = 0,
    
    /**
     *  The permission is not supported on the current device or SDK. 
     *  This may be the case for CoreMotion related APIs on devices
     *  such as the iPhone 4S or for Camera permission on the Simulator.
     *
     * @note Does not allow user prompt.
     */
    ISHPermissionStateUnsupported = 501,

    /**
     *  The user denied the permission through system UI. 
     *  To recover the user must go to the system settings.
     *
     *  @note Does not allow user prompt.
     */
    ISHPermissionStateDenied = 403,
    
    /**
     *  The user granted the permission through system UI.
     *
     *  @note Does not allow user prompt.
     */
    ISHPermissionStateAuthorized = 200,
};

@class ISHPermissionRequest;

typedef void (^ISHPermissionRequestCompletionBlock)(ISHPermissionRequest *request, ISHPermissionState state, NSError *error);

/**
 *  Permission requests provide information about the current permission state of the associated category.
 *  It can also be used to request the user's permission via the system dialogue or to remember the user's
 *  desire not to be asked again.
 *
 *  The actual interaction is handled by subclasses. With the exception of those subclasses that 
 *  require more configuration, subclasses are "hidden" and should be transparent to the developer 
 *  using this framework.
 *
 *  Instances should be created via the category class method:
 *  @code
 *  + (ISHPermissionRequest *)requestForCategory:(ISHPermissionCategory)category;
 *  @endcode
 */
@interface ISHPermissionRequest : NSObject

/// The permission category associated with the request.
@property (nonatomic, readonly) ISHPermissionCategory permissionCategory;

/**
 *  Subclasses must implement this method to reflect the correct state.
 *
 *  Ideally, permissionState should check the system authorization state first
 *  and should return appropriate internal enum values from ISHPermissionState. 
 *  If the system state is unavailable or is similar to e.g. kCLAuthorizationStatusNotDetermined 
 *  then this method should return the persisted internalPermissionState.
 *  Subclasses should try to map system provided states to ISHPermissionState without 
 *  resorting to the internalPermissionState as much as possible.
 *
 *  @return The current permission state.
 *  @note Calling this method does not trigger any user interaction.
 */
- (ISHPermissionState)permissionState;

/**
 *  If possible, this presents the user permissions dialogue. This might not be possible
 *  if, e.g., it has already been denied, authorized, or the user does not want to be asked again.
 *
 *  @param completion The block is called once the user has made a decision. 
 *                    The block is called right away if no dialogue was presented.
 */
- (void)requestUserPermissionWithCompletionBlock:(ISHPermissionRequestCompletionBlock)completion;

/**
 *  Some permission requests allow or require further configuration
 *  (such as those for local notifications and Health app). Subclasses for such
 *  permission categories should overwrite this method and return YES.
 *  The default implementation returns NO. 
 *
 *  @return Boolean value indicating if the request  
 *          allows further configuration.
 */
- (BOOL)allowsConfiguration;

@end


/**
 *  Used for debugging purposes.
 *
 *  @param state A permission state value.
 *
 *  @return A string representation of a permission state enum value.
 */
static inline NSString *ISHStringFromPermissionState(ISHPermissionState state) {
    switch (state) {
        case ISHPermissionStateUnknown:
            return @"ISHPermissionStateUnknown";
        case ISHPermissionStateUnsupported:
            return @"ISHPermissionStateUnsupported";
        case ISHPermissionStateDenied:
            return @"ISHPermissionStateDenied";
        case ISHPermissionStateAuthorized:
            return @"ISHPermissionStateAuthorized";

    }
}

/**
 *  @param state A permission state value.
 *
 *  @return A boolean value determining whether the user should be prompted again
 *          regarding the given permission state.
 */
static inline BOOL ISHPermissionStateAllowsUserPrompt(ISHPermissionState state) {
    return (state == ISHPermissionStateUnknown);
}

/**
 *  When using ISHPermissionKit to register for UILocalNotifications, the app delegate must implement 
 *  -application:didRegisterUserNotificationSettings: and post a notification with name 
 *  'ISHPermissionNotificationApplicationDidRegisterUserNotificationSettings' to inform any pending 
 *  requests that a change occured.
 */
extern NSString * const ISHPermissionNotificationApplicationDidRegisterUserNotificationSettings;
