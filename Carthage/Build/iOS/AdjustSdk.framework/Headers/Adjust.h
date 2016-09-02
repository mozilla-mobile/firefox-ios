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
 * Constants for our supported tracking environments.
 */
extern NSString * const ADJEnvironmentSandbox;
extern NSString * const ADJEnvironmentProduction;

/**
 * The main interface to Adjust.
 *
 * Use the methods of this class to tell Adjust about the usage of your app.
 * See the README for details.
 */
@interface Adjust : NSObject

/**
 * Tell Adjust that the application did launch.
 *
 * This is required to initialize Adjust. Call this in the didFinishLaunching
 * method of your AppDelegate.
 *
 * See ADJConfig.h for more configuration options
 *
 * @param adjustConfig The configuration object that includes the environment
 *     and the App Token of your app. This unique identifier can
 *     be found it in your dashboard at http://adjust.com and should always
 *     be 12 characters long.
 */
+ (void)appDidLaunch:(ADJConfig *)adjustConfig;

/**
 * Tell Adjust that a particular event has happened.
 *
 * See ADJEvent.h for more event options
 *
 * @param event The Event object for this kind of event. It needs a event token
 * that is  created in the dashboard at http://adjust.com and should be six
 * characters long.
 */
+ (void)trackEvent:(ADJEvent *)event;

/**
 * Tell adjust that the application resumed.
 *
 * Only necessary if the native notifications can't be used
 */
+ (void)trackSubsessionStart;

/**
 * Tell adjust that the application paused.
 *
 * Only necessary if the native notifications can't be used
 */
+ (void)trackSubsessionEnd;

/**
 * Enable or disable the adjust SDK. This setting is saved
 * for future sessions
 *
 * @param enabled The flag to enable or disable the adjust SDK
 */
+ (void)setEnabled:(BOOL)enabled;

/**
 * Check if the SDK is enabled or disabled
 */
+ (BOOL)isEnabled;

/**
 * Read the URL that opened the application to search for
 * an adjust deep link
 */
+ (void)appWillOpenUrl:(NSURL *)url;

/**
 * Set the device token used by push notifications
 */
+ (void)setDeviceToken:(NSData *)deviceToken;

/**
 * Enable or disable offline mode. Activities won't be sent
 * but they are saved when offline mode is disabled. This
 * feature is not saved for future sessions
 */
+ (void)setOfflineMode:(BOOL)enabled;

/**
 * Obtain singleton Adjust object
 */
+ (id)getInstance;

- (void)appDidLaunch:(ADJConfig *)adjustConfig;
- (void)trackEvent:(ADJEvent *)event;
- (void)trackSubsessionStart;
- (void)trackSubsessionEnd;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isEnabled;
- (void)appWillOpenUrl:(NSURL *)url;
- (void)setDeviceToken:(NSData *)deviceToken;
- (void)setOfflineMode:(BOOL)enabled;

@end

