/*
 Button SDK
 Copyright Button, Inc. 2016
 */
@import Foundation;
#import "Button_Public.h"


@interface Button : NSObject

/**
 Version of the Button SDK
 **/
+ (nonnull NSString *)sdkVersion;


/**
 Returns the singleton shared Button instance
 @return Button object singleton
 @note Returns nil on iOS7 and older platform versions
 **/
+ (nonnull Button *)sharedButton;

@end


@protocol Button <NSObject>
@required


/**
 Configures a Button instance with the provided applicationId

 @param applicationId Your applicationId (required)
 @param completionHandler A block to be executed upon completion (optional).
 **/
- (void)configureWithApplicationId:(nonnull NSString *)applicationId
                        completion:(nullable void(^)(NSError * __nullable error))completionHandler;


/**
 Configures a Button instance with the provided applicationId

 @param applicationId Your applicationId (required)
 @param userId The user identifier (if known) for the current user to associate with the Button session (optional).
 @param completionHandler A block to be executed upon completion (optional).

 @note If you do not have the Id of your logged in user when you call this method (typically in `-application:didFinishLaunchingWithOptions:`), 
 make sure you call `-setUserIdentifier:` once you've successfully acquired the Id for your logged in user.

 @discussion The completion handler takes two parameters
    - error Will be set in the event of a configuration error.
    - targetURL If not nil, a URL that specifies the user's expected destination in your app.
 **/
- (void)configureWithApplicationId:(nonnull NSString *)applicationId
                            userId:(nullable NSString *)userId
                        completion:(nullable void(^)(NSError * __nullable error, NSURL * __nullable targetURL))completionHandler;


/**
 Checks whether Button has an action available for a buttonId and contextually relevant data.
 @param buttonId The identifier for a button (e.g. btn-xxxxxxxxxxxx).
 @param context A BTNContext object providing context about your user's current activity.
 @param completionHandler A block to be executed upon completion.
 */
- (void)willDisplayButtonWithId:(nonnull NSString *)buttonId
                        context:(nonnull BTNContext *)context
                     completion:(nonnull void(^)(BOOL willDisplay))completionHandler;


/**
 Fetches an app action for a buttonId and contextually relevant data.
 @param buttonId The identifier for a button (e.g. btn-xxxxxxxxxxxx).
 @param context A BTNContext object providing context about your user's current activity.
 @param completionHandler A block to be executed upon completion.
 
 @discussion The completion handler takes two parameters
    - appAction A BTNAppAction instance or nil if no action was found for the provided context.
    - error An error will be present if a network or server error occurred.

 @note You should not cache app actions yourself. App actions are automatically cached for as long as their data is valid.
       For example, calling this method again with the same `buttonId` and `context` will return a previously fetched 
       and cached app action if the action is still valid.
 */
- (void)fetchAppActionWithButtonId:(nonnull NSString *)buttonId
                           context:(nonnull BTNContext *)context
                        completion:(nonnull void(^)(BTNAppAction * __nullable appAction, NSError * __nullable error))completionHandler;



///-------------------------
/// @name Deep Link Handling
///-------------------------


/**
 Continues incoming NSUserActivity objects from Universal Links (e.g. Button Links). 
 This method should be called from your application delegate method: @c
 
 -application:continueUserActivity:userActivity:restorationHandler:
 
 @return BOOL indicating whether the Button SDK can & *will* handle the userActivity.
 **/
- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity;


/**
 Handles an incoming URL to your App. 
 This method should be called from your Application Delegate method: @c

 -application:openURL:sourceApplication:annotation:
 
 @return BOOL indicating whether the Button SDK can & *will* handle the URL.
 **/
- (BOOL)handleURL:(nonnull NSURL *)url;



///------------------
/// @name Attribution
///------------------

/**
 Returns the current referrerToken for the last inbound link from
 the Button marketplace or nil if none is present.
 @return String value of the last inbound referrerToken
 **/
- (nullable NSString *)referrerToken;


/**
 Associate your ID for the current user with the Button session.
 @param userIdentifier your identifier for the user.
 @note This is required for attribution.
 
 @discussion To correctly configure Button for attribution, make sure to:
 1. Pass your logged in user's Id when configuring Button (use `-configureWithApplicationId:userId:completion:`).
 2. Call this method with your user's id after a user successfully logs into your app.
 
 If you don't have the Id of your logged in user in at the time you call `-configureWithApplicationId:userId:completion:` 
 (typically in `-application:didFinishLaunchingWithOptions:`), make sure you call this method once you've successfully 
 acquired the Id for your logged in user.
 
 Note that passing nil here is a noop and will not remove the user Id from the session. 
 If your user is logging out, call `-logOut` to reset the session and user data in Button.
 **/
- (void)setUserIdentifier:(nonnull NSString *)userIdentifier;



///------------------------------
/// @name Reporting Custom Events
///------------------------------

/**
 Report an event to Button.
 @param eventName The name of the event.
 @param properties A dictionary of key-value string pairs for adding detail to the event.
 */
- (void)reportEventWithName:(nonnull NSString *)eventName
                 properties:(nullable NSDictionary <NSString *, NSString *> *)properties;



///---------------------
/// @name Button Session
///---------------------


/*
 The current Button session.
 */
@property (nullable, nonatomic, copy, readonly) BTNSession *session;



///--------------
/// @name Log Out
///--------------

/**
 Discards the current session, discards any user unique data, and creates a new session.
 **/
- (void)logOut;



///--------------------
/// @name Debug Logging
///--------------------

/**
 Sets whether the Button SDK will output debug log messages to the console.
 @discussion You should ship to the App Store with this disabled.
 
 @param enabled Pass YES to enable debug log messages to the console.
 @note The default value is NO.
 */
- (void)setDebugLoggingEnabled:(BOOL)enabled;


@end


@interface Button () <Button, ButtonDeprecated>

///------------------
/// @name Permissions
///------------------


/**
 Sets whether the Button SDK is allowed to request system level location permission.
 @discussion Button will never ask your users for system level permissions unless you explicitly allow it.

 @param isAllowed A boolean indicating whether requesting location permission is allowed.
 @note The default value is NO.
 */
+ (void)allowButtonToRequestLocationPermission:(BOOL)isAllowed;


///----------------------
/// @name Developer Setup
///----------------------


/**
 Reports associated domain configuration when your build is developer signed ONLY (enabled by default).
 @note This should be enabled when you're setting up the SDK to make sure your bttn.io domains are 
 set up correctly in the Button Dashboard. If you have a large binary, you can pass `NO` to disable this 
 feature after you've confirmed your bttn.io universal links are properly configured.
 @param enabled Pass NO to disable developer build reporting.
 */
+ (void)setDeveloperBuildReportingEnabled:(BOOL)enabled;



///----------------------------
/// @name Automatic Attribution
///----------------------------


/**
 Incoming URLs are automatically routed to Button for attribution by default.
 @note It is highly recommended that you leave this feature enabled.
 @discussion If you prefer to follow the manual integration steps to route incoming URLs to Button
 for attribution, you can disable this feature by overriding +load in you app delegate:
 @code
 + (void)load {
    [Button setAutomaticAttributionEnabled:NO];
 }
 @endcode
 */
+ (void)setAutomaticAttributionEnabled:(BOOL)enabled;

@end
