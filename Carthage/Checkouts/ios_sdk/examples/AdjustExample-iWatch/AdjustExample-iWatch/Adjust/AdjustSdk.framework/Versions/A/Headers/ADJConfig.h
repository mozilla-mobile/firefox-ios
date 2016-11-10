//
//  ADJConfig.h
//  adjust
//
//  Created by Pedro Filipe on 30/10/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJLogger.h"
#import "ADJAttribution.h"
#import "ADJSessionSuccess.h"
#import "ADJSessionFailure.h"
#import "ADJEventSuccess.h"
#import "ADJEventFailure.h"

/**
 * Optional delegate that will get informed about tracking results
 */
@protocol AdjustDelegate
@optional

/**
 * Optional delegate method that gets called when the attribution information changed
 *
 * @param attribution   The attribution information.
 *                      See ADJAttribution for details
 */
- (void)adjustAttributionChanged:(ADJAttribution *)attribution;

/**
 * Optional delegate method that gets called when an event is tracked with success
 *
 * @param eventSuccessResponseData  The response information from tracking with success
 *                                  See ADJEventSuccess for details
 */
- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData;

/**
 * Optional delegate method that gets called when an event is tracked with failure
 *
 * @param eventFailureResponseData  The response information from tracking with failure
 *                                  See ADJEventFailure for details
 */
- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData;

/**
 * Optional delegate method that gets called when an session is tracked with success
 *
 * @param sessionSuccessResponseData    The response information from tracking with success
 *                                      See ADJSessionSuccess for details
 */
- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData;

/**
 * Optional delegate method that gets called when an session is tracked with failure
 *
 * @param sessionFailureResponseData    The response information from tracking with failure
 *                                      See ADJSessionFailure for details
 */
- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData;

/**
 * Optional delegate method that gets called when a deeplink is about to be opened by the adjust SDK
 *
 * @param   deeplink    The deeplink url that was received by the adjust SDK to be opened
 * @return  boolean     Value that indicates whether the deeplink should be opened by the adjust SDK
 */
- (BOOL)adjustDeeplinkResponse:(NSURL *)deeplink;

@end

@interface ADJConfig : NSObject<NSCopying>

@property (nonatomic, copy) NSString *sdkPrefix;
@property (nonatomic, copy) NSString *defaultTracker;
@property (nonatomic, copy, readonly) NSString *appToken;
@property (nonatomic, copy, readonly) NSString *environment;

/**
 * Configuration object for the initialization of the Adjust SDK
 *
 * @param appToken      The App Token of your app. This unique identifier can
 *                      be found it in your dashboard at http://adjust.com and should always
 *                      be 12 characters long
 * @param environment   The current environment your app. We use this environment to
 *                      distinguish between real traffic and artificial traffic from test devices.
 *                      It is very important that you keep this value meaningful at all times!
 *                      Especially if you are tracking revenue
 */
+ (ADJConfig *)configWithAppToken:(NSString *)appToken
                      environment:(NSString *)environment;
- (id)initWithAppToken:(NSString *)appToken
           environment:(NSString *)environment;

/**
 * Configuration object for the initialization of the Adjust SDK.
 *
 * @param appToken              The App Token of your app. This unique identifier can
 *                              be found it in your dashboard at http://adjust.com and should always
 *                              be 12 characters long
 * @param environment           The current environment your app. We use this environment to
 *                              distinguish between real traffic and artificial traffic from test devices.
 *                              It is very important that you keep this value meaningful at all times!
 *                              Especially if you are tracking revenue
 * @param allowSuppressLogLevel  If set to true, it allows usage of ADJLogLevelSuppress
 *                              and replaces the default value for production environment
 */
+ (ADJConfig *)configWithAppToken:(NSString *)appToken
                      environment:(NSString *)environment
             allowSuppressLogLevel:(BOOL)allowSuppressLogLevel;
- (id)initWithAppToken:(NSString *)appToken
           environment:(NSString *)environment
  allowSuppressLogLevel:(BOOL)allowSuppressLogLevel;

/**
 * Change the verbosity of Adjust's logs
 *
 * You can increase or reduce the amount of logs from Adjust by passing
 * one of the following parameters. Use ADJLogLevelSuppress to disable all logging
 *
 * @var logLevel The desired minimum log level (default: info)
 *     Must be one of the following:
 *      - ADJLogLevelVerbose    (enable all logging)
 *      - ADJLogLevelDebug      (enable more logging)
 *      - ADJLogLevelInfo       (the default)
 *      - ADJLogLevelWarn       (disable info logging)
 *      - ADJLogLevelError      (disable warnings as well)
 *      - ADJLogLevelAssert     (disable errors as well)
 *      - ADJLogLevelSuppress   (suppress all logging)
 */
@property (nonatomic, assign) ADJLogLevel logLevel;

/**
 * Enable event buffering if your app triggers a lot of events.
 * When enabled, events get buffered and only get tracked each
 * minute. Buffered events are still persisted, of course
 *
 * @var eventBufferingEnabled   Enable or disable event buffering
 */
@property (nonatomic, assign) BOOL eventBufferingEnabled;

/**
 * Set the optional delegate that will inform you about attribution or events
 *
 * See the AdjustDelegate declaration above for details
 *
 * @var delegate    The delegate that might implement the optional delegate methods
 */
@property (nonatomic, weak) NSObject<AdjustDelegate> *delegate;

/**
 * Enables sending in the background
 *
 * @var sendInBackground    Enable or disable sending in the background
 */
@property (nonatomic, assign) BOOL sendInBackground;

/**
 * Enables delayed start of the SDK
 *
 * @var delayStart  Number of seconds after which SDK will start
 */
@property (nonatomic, assign) double delayStart;

/**
 * User agent for the requests.
 *
 * @var userAgent   User agent value.
 */
@property (nonatomic, copy) NSString *userAgent;

@property (nonatomic, assign, readonly) BOOL hasResponseDelegate;
@property (nonatomic, assign, readonly) BOOL hasAttributionChangedDelegate;

- (BOOL) isValid;
@end
