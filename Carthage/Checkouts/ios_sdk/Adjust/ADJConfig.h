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

/**
 * Optional delegate that will get informed about tracking results
 */
@protocol  AdjustDelegate
@optional

/**
 * Optional delegate method that gets called when the attribution information changed
 *
 * @param attribution The attribution information. See ADJAttribution for details.
 */
- (void)adjustAttributionChanged:(ADJAttribution *)attribution;

@end

@interface ADJConfig : NSObject<NSCopying>

@property (nonatomic, copy, readonly) NSString *appToken;
@property (nonatomic, copy, readonly) NSString *environment;
@property (nonatomic, copy) NSString *sdkPrefix;
@property (nonatomic, copy) NSString *defaultTracker;

/**
 * Configuration object for the initialization of the Adjust SDK.
 *
 * @param appToken The App Token of your app. This unique identifier can
 *     be found it in your dashboard at http://adjust.com and should always
 *     be 12 characters long.
 * @param environment The current environment your app. We use this environment to
 *     distinguish between real traffic and artificial traffic from test devices.
 *     It is very important that you keep this value meaningful at all times!
 *     Especially if you are tracking revenue.
 */
+ (ADJConfig*)configWithAppToken:(NSString *)appToken environment:(NSString *)environment;
- (id)initWithAppToken:(NSString *)appToken environment:(NSString *)environment;

/**
 * Change the verbosity of Adjust's logs.
 *
 * You can increase or reduce the amount of logs from Adjust by passing
 * one of the following parameters. Use Log.ASSERT to disable all logging.
 *
 * @param logLevel The desired minimum log level (default: info)
 *     Must be one of the following:
 *      - ADJLogLevelVerbose (enable all logging)
 *      - ADJLogLevelDebug   (enable more logging)
 *      - ADJLogLevelInfo    (the default)
 *      - ADJLogLevelWarn    (disable info logging)
 *      - ADJLogLevelError   (disable warnings as well)
 *      - ADJLogLevelAssert  (disable errors as well)
 */
@property (nonatomic, assign) ADJLogLevel logLevel;

/**
 * Enable event buffering if your app triggers a lot of events.
 * When enabled, events get buffered and only get tracked each
 * minute. Buffered events are still persisted, of course.
 *
 * @param eventBufferingEnabled Enable or disable event buffering
 */
@property (nonatomic, assign) BOOL eventBufferingEnabled;

/**
 * Set the optional delegate that will inform you about attribution
 *
 * See the AdjustDelegate declaration above for details
 *
 * @param delegate The delegate that might implement the optional delegate
 *     methods like adjustAttributionChanged:
 */
@property (nonatomic, weak) NSObject<AdjustDelegate> *delegate;
@property (nonatomic, assign) BOOL hasDelegate;

- (BOOL) isValid;
@end
