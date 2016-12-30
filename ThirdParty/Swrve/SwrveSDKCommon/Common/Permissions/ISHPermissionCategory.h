//
//  ISHPermissionCategory.h
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 25.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//


/**
 *  Permission categories describe types of permissions on iOS.
 *  Each is related to a specific PermissionRequest.
 *  @note Values assigned to each category must not be changed, as 
 *        they may have been persisted on user devices.
 */
typedef NS_ENUM(NSUInteger, ISHPermissionCategory) {
    /**
     *  Permission required for step counting and motion activity queries. 
     *  See reference documentation for CoreMotion.
     */
    ISHPermissionCategoryActivity = 1000,
    
    /**
     *  Permission required to use HealthKit data.
     *  Make sure to comply with sections 27.4 - 27.6 of the review guidelines.
     *  Use the `ISHPermissionKitLib+HealthKit` static library or
     *  the `ISHPermissionKit+HealthKit` framework if
     *  you want to use this permission category.
     *
     *  @note: The Health app and HealthKit are not available on iPad.
     */
    ISHPermissionCategoryHealth = 2000,
    
    /**
     *  Permission required to use the user's location at any time,
     *  including monitoring for regions, visits, or significant location changes.
     *  If you want to request both Always and WhenInUse, you should ask for 
     *  WhenInUse first. You can do so by passing both categories to the
     *  ISHPermissionsViewController with WhenInUse before Always.
     */
    ISHPermissionCategoryLocationAlways = 3100,
    /**
     *  Permission required to use the user's location only when your app
     *  is visible to them.
     */
    ISHPermissionCategoryLocationWhenInUse = 3200,
    
    /**
     *  Permission required to record the user's microphone input.
     */
    ISHPermissionCategoryMicrophone = 4000,
    
    /**
     *  Permission required to access the user's photo library.
     */
    ISHPermissionCategoryPhotoLibrary = 5000,
    /**
     *  Permission required to access the user's camera.
     */
    ISHPermissionCategoryPhotoCamera = 5100,
    
    /**
     *  Permission required to schedule local notifications. 
     *  @note Requests for this permission might require further 
     *        configuration via the ISHPermissionsViewControllerDataSource.
     *
     *  @warning Your app delegate will need to implement the following lines:
     *  @code
     *  - (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
     *       [[NSNotificationCenter defaultCenter] postNotificationName:ISHPermissionNotificationApplicationDidRegisterUserNotificationSettings
     *                                                           object:self];
     *  }
     *  @endcode
     */
    ISHPermissionCategoryNotificationLocal = 6100,
    
    /**
     *  Permission required to access the user's Facebook acounts.
     *  @note Requests for this permission require further
     *        configuration via the ISHPermissionsViewControllerDataSource.
     *        The request will require an options dictionary including e.g. ACFacebookAppIdKey.
     */
    ISHPermissionCategorySocialFacebook = 7100,
    /**
     *  Permission required to access the user's Twitter acounts.
     */
    ISHPermissionCategorySocialTwitter = 7110,
    /**
     *  Permission required to access the user's SinaWeibo acounts.
     */
    ISHPermissionCategorySocialSinaWeibo = 7120,
    /**
     *  Permission required to access the user's TencentWeibo acounts.
     */
    ISHPermissionCategorySocialTencentWeibo = 7130,
    
    /**
     *  Permission required to access the user's contacts.
     */
    ISHPermissionCategoryAddressBook = 8100,
    
    /**
     *  Permission required to access the user's calendar.
     */
    ISHPermissionCategoryEvents = 8200,
    /**
     *  Permission required to access the user's reminders.
     */
    ISHPermissionCategoryReminders = 8250,
    
    /**
     *  Permission required to schedule remote notifications.
     *  @endcode
     */
    ISHPermissionCategoryNotificationRemote = 8300
};


/**
 *  @param category A value from the ISHPermissionCategory enum.
 *
 *  @return A string representation of an ISHPermissionCategory enum value. (Used mainly for debugging).
 */
static inline NSString *ISHStringFromPermissionCategory(ISHPermissionCategory category) {
    switch (category) {
        case ISHPermissionCategoryActivity:
            return @"ISHPermissionCategoryActivity";
        case ISHPermissionCategoryHealth:
            return @"ISHPermissionCategoryHealth";
        case ISHPermissionCategoryLocationAlways:
            return @"ISHPermissionCategoryLocationAlways";
        case ISHPermissionCategoryLocationWhenInUse:
            return @"ISHPermissionCategoryLocationWhenInUse";
        case ISHPermissionCategoryMicrophone:
            return @"ISHPermissionCategoryMicrophone";
        case ISHPermissionCategoryPhotoLibrary:
            return @"ISHPermissionCategoryPhotoLibrary";
        case ISHPermissionCategoryPhotoCamera:
            return @"ISHPermissionCategoryPhotoCamera";
        case ISHPermissionCategoryNotificationLocal:
            return @"ISHPermissionCategoryNotificationLocal";
        case ISHPermissionCategorySocialFacebook:
            return @"ISHPermissionCategorySocialFacebook";
        case ISHPermissionCategorySocialTwitter:
            return @"ISHPermissionCategorySocialTwitter";
        case ISHPermissionCategorySocialSinaWeibo:
            return @"ISHPermissionCategorySocialSinaWeibo";
        case ISHPermissionCategorySocialTencentWeibo:
            return @"ISHPermissionCategorySocialTencentWeibo";
        case ISHPermissionCategoryAddressBook:
            return @"ISHPermissionCategoryAddressBook";
        case ISHPermissionCategoryEvents:
            return @"ISHPermissionCategoryEvents";
        case ISHPermissionCategoryReminders:
            return @"ISHPermissionCategoryReminders";
        case ISHPermissionCategoryNotificationRemote:
            return @"ISHPermissionCategoryNotificationRemote";
    }
}
