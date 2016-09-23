//
//  Adjust.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2012-07-23.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//

#import "ADJEvent.h"
#import "ADJAttribution.h"
#import "ADJConfig.h"

/**
 * Constants for our supported tracking environments
 */
extern NSString * const ADJEnvironmentSandbox;
extern NSString * const ADJEnvironmentProduction;

/**
 * The main interface to Adjust
 *
 * Use the methods of this class to tell Adjust about the usage of your app.
 * See the README for details.
 */
@interface Adjust : NSObject

/**
 * Tell Adjust that the application did launch
 *
 * This is required to initialize Adjust. Call this in the didFinishLaunching
 * method of your AppDelegate.
 *
 * See ADJConfig.h for more configuration options
 *
 * @param adjustConfig  The configuration object that includes the environment
 *                      and the App Token of your app. This unique identifier can
 *                      be found it in your dashboard at http://adjust.com and should always
 *                      be 12 characters long.
 */
+ (void)appDidLaunch:(ADJConfig *)adjustConfig;

/**
 * Tell Adjust that a particular event has happened
 *
 * See ADJEvent.h for more event options.
 *
 * @param event The Event object for this kind of event. It needs a event token
 *              that is  created in the dashboard at http://adjust.com and should be six
 *              characters long.
 */
+ (void)trackEvent:(ADJEvent *)event;

/**
 * Tell adjust that the application resumed
 *
 * Only necessary if the native notifications can't be used
 */
+ (void)trackSubsessionStart;

/**
 * Tell adjust that the application paused
 *
 * Only necessary if the native notifications can't be used
 */
+ (void)trackSubsessionEnd;

/**
 * Enable or disable the adjust SDK. This setting is saved for future sessions
 *
 * @param enabled   The flag to enable or disable the adjust SDK
 */
+ (void)setEnabled:(BOOL)enabled;

/**
 * Check if the SDK is enabled or disabled
 *
 * return   Boolean indicating whether SDK is enabled or not
 */
+ (BOOL)isEnabled;

/**
 * Read the URL that opened the application to search for an adjust deep link
 *
 * @param url   URL object which contains info about adjust deep link
 */
+ (void)appWillOpenUrl:(NSURL *)url;

/**
 * Set the device token used by push notifications
 *
 * @param deviceToken   Apple push notification token for iOS device
 */
+ (void)setDeviceToken:(NSData *)deviceToken;

/**
 * Enable or disable offline mode. Activities won't be sent but they are saved when
 * offline mode is disabled. This feature is not saved for future sessions
 *
 * @param enabled   The flag to enable or disable offline mode
 */
+ (void)setOfflineMode:(BOOL)enabled;

/**
 * Convert a universal link style url to a deeplink style url with the corresponding scheme
 *
 * @param url       URL object which contains info about adjust deep link
 * @param scheme    Desired scheme to which you want your resulting URL object to be prefixed with
 *
 * @return          URL object in custom URL scheme style prefixed with given scheme name
 */
+ (NSURL *)convertUniversalLink:(NSURL *)url scheme:(NSString *)scheme;

/**
 * Retrieve iOS device IDFA value
 *
 * @return  Device IDFA value
 */
+ (NSString *)idfa;

/**
 * Tell the adjust SDK to stop waiting for delayed initialisation timer to complete but rather to start
 * upon this call. This should be called if you have obtained needed callback/partner parameters which you
 * wanted to put as default ones before the delayedStart value you have set on ADJConfig has expired
 */
+ (void)sendFirstPackages;

/**
 * Tell adjust to send the request to Google and check if the installation 
 * belongs to Google AdWords campaign
 */
+ (void)sendAdWordsRequest;

/**
 * Add default callback parameter key-value pair which is going to be sent with each tracked session
 *
 * @param key   Default callback parameter key
 * @param value Default callback parameter value
 */
+ (void)addSessionCallbackParameter:(NSString *)key value:(NSString *)value;

/**
 * Add default partner parameter key-value pair which is going to be sent with each tracked session
 *
 * @param key   Default partner parameter key
 * @param value Default partner parameter value
 */
+ (void)addSessionPartnerParameter:(NSString *)key value:(NSString *)value;

/**
 * Remove default callback parameter from the session packages
 *
 * @param key   Default callback parameter key
 */
+ (void)removeSessionCallbackParameter:(NSString *)key;

/**
 * Remove default partner parameter from the session packages
 *
 * @param key   Default partner parameter key
 */
+ (void)removeSessionPartnerParameter:(NSString *)key;

/**
 * Remove all default callback parameters from the session packages
 */
+ (void)resetSessionCallbackParameters;

/**
 * Remove all default partner parameters from the session packages
 */
+ (void)resetSessionPartnerParameters;

/**
 * Obtain singleton Adjust object
 */
+ (id)getInstance;

- (void)appDidLaunch:(ADJConfig *)adjustConfig;
- (void)trackEvent:(ADJEvent *)event;
- (void)setEnabled:(BOOL)enabled;
- (void)teardown:(BOOL)deleteState;
- (void)appWillOpenUrl:(NSURL *)url;
- (void)setOfflineMode:(BOOL)enabled;
- (void)setDeviceToken:(NSData *)deviceToken;

- (BOOL)isEnabled;
- (NSString *)idfa;
- (NSURL *)convertUniversalLink:(NSURL *)url scheme:(NSString *)scheme;

- (void)sendFirstPackages;
- (void)trackSubsessionEnd;
- (void)trackSubsessionStart;
- (void)resetSessionPartnerParameters;
- (void)resetSessionCallbackParameters;
- (void)removeSessionPartnerParameter:(NSString *)key;
- (void)removeSessionCallbackParameter:(NSString *)key;
- (void)addSessionPartnerParameter:(NSString *)key value:(NSString *)value;
- (void)addSessionCallbackParameter:(NSString *)key value:(NSString *)value;

@end
