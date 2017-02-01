#import "BTNModelObject.h"

/**
 App action metadata objects contain information about the referrer, 
 destination app, and expiration of an app action.
 */

@interface BTNAppActionMeta : BTNModelObject

/// The app action identifier.
@property (nullable, nonatomic, copy, readonly) NSString *appActionId;


/// The store id of the app represented by an app action.
@property (nullable, nonatomic, copy, readonly) NSString *storeId;


/// The source/referrer token associated with an app action.
@property (nullable, nonatomic, copy, readonly) NSString *sourceToken;


/// The maximum age in seconds an app action is valid.
@property (nullable, nonatomic, copy, readonly) NSNumber *maxAgeSeconds;


/// The deep link scheme for enabling attended install.
@property (nullable, nonatomic, copy, readonly) NSURL *deepLinkScheme;


/// The name of the app represented by an app action.
@property (nullable, nonatomic, copy, readonly) NSString *appDisplayName;


/**
 Indicated whether or not the action has expired.
 @return YES is the action is expired, otherwise NO.
 */
- (BOOL)isExpired;

@end
