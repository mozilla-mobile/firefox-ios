#import <Foundation/Foundation.h>
#import "SwrveCommon.h"
#import "ISHPermissionRequest.h"

static NSString* swrve_permission_status_unknown        = @"unknown";
static NSString* swrve_permission_status_unsupported    = @"unsupported";
static NSString* swrve_permission_status_denied         = @"denied";
static NSString* swrve_permission_status_authorized     = @"authorized";
static NSString* swrve_permission_status                = @"swrve_permission_status";

static NSString* swrve_permission_location_always       = @"Swrve.permission.ios.location.always";
static NSString* swrve_permission_location_when_in_use  = @"Swrve.permission.ios.location.when_in_use";
static NSString* swrve_permission_photos                = @"Swrve.permission.ios.photos";
static NSString* swrve_permission_camera                = @"Swrve.permission.ios.camera";
static NSString* swrve_permission_contacts              = @"Swrve.permission.ios.contacts";
static NSString* swrve_permission_push_notifications    = @"Swrve.permission.ios.push_notifications";

static NSString* swrve_permission_requestable           = @".requestable";

/*! Used internally to offer permission request support */
@interface SwrvePermissions : NSObject

+ (BOOL)processPermissionRequest:(NSString*)action withSDK:(id<SwrveCommonDelegate>)sdk;
+ (NSDictionary*) currentStatusWithSDK:(id<SwrveCommonDelegate>)sdk;
+ (void)compareStatusAndQueueEventsWithSDK:(id<SwrveCommonDelegate>)sdk;
+ (NSArray*) currentPermissionFiltersWithSDK:(id<SwrveCommonDelegate>)sdk;

#if !defined(SWRVE_NO_LOCATION)
+ (ISHPermissionState)checkLocationAlways;
+ (void)requestLocationAlways:(id<SwrveCommonDelegate>)sdk;
#endif //!defined(SWRVE_NO_LOCATION)

#if !defined(SWRVE_NO_PHOTO_LIBRARY)
+ (ISHPermissionState)checkPhotoLibrary;
+ (void)requestPhotoLibrary:(id<SwrveCommonDelegate>)sdk;
#endif //!defined(SWRVE_NO_PHOTO_LIBRARY)

#if !defined(SWRVE_NO_PHOTO_CAMERA)
+ (ISHPermissionState)checkCamera;
+ (void)requestCamera:(id<SwrveCommonDelegate>)sdk;
#endif //!defined(SWRVE_NO_PHOTO_CAMERA)

#if !defined(SWRVE_NO_ADDRESS_BOOK)
+ (ISHPermissionState)checkContacts;
+ (void)requestContacts:(id<SwrveCommonDelegate>)sdk;
#endif //!defined(SWRVE_NO_ADDRESS_BOOK)

#if !defined(SWRVE_NO_PUSH)
+ (ISHPermissionState)checkPushNotificationsWithSDK:(id<SwrveCommonDelegate>)sdk;
+ (void)requestPushNotifications:(id<SwrveCommonDelegate>)sdk withCallback:(BOOL)callback;
#endif //!defined(SWRVE_NO_PUSH)

@end

static inline NSString *stringFromPermissionState(ISHPermissionState state) {
    switch (state) {
        case ISHPermissionStateUnknown:
            return swrve_permission_status_unknown;
        case ISHPermissionStateUnsupported:
            return swrve_permission_status_unsupported;
        case ISHPermissionStateDenied:
            return swrve_permission_status_denied;
        case ISHPermissionStateAuthorized:
            return swrve_permission_status_authorized;
            
    }
}
