//
//  ADJActivityHandler.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-01.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "Adjust.h"
#import "ADJResponseData.h"
#import "ADJActivityState.h"
#import "ADJDeviceInfo.h"
#import "ADJSessionParameters.h"

@interface ADJInternalState : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL offline;
@property (nonatomic, assign) BOOL background;
@property (nonatomic, assign) BOOL delayStart;
@property (nonatomic, assign) BOOL updatePackages;
@property (nonatomic, assign) BOOL firstLaunch;
@property (nonatomic, assign) BOOL sessionResponseProcessed;

- (id)init;

- (BOOL)isEnabled;
- (BOOL)isDisabled;
- (BOOL)isOffline;
- (BOOL)isOnline;
- (BOOL)isInBackground;
- (BOOL)isInForeground;
- (BOOL)isInDelayedStart;
- (BOOL)isNotInDelayedStart;
- (BOOL)itHasToUpdatePackages;
- (BOOL)isFirstLaunch;
- (BOOL)hasSessionResponseNotBeenProcessed;

@end

@interface ADJSavedPreLaunch : NSObject

@property (nonatomic, strong) NSMutableArray *preLaunchActionsArray;
@property (nonatomic, copy) NSData *deviceTokenData;
@property (nonatomic, copy) NSNumber *enabled;
@property (nonatomic, assign) BOOL offline;
@property (nonatomic, copy) NSString *basePath;
@property (nonatomic, copy) NSString *gdprPath;

- (id)init;

@end

@protocol ADJActivityHandler <NSObject>

@property (nonatomic, copy) ADJAttribution *attribution;
- (NSString *)adid;

- (id)initWithConfig:(ADJConfig *)adjustConfig
      savedPreLaunch:(ADJSavedPreLaunch *)savedPreLaunch;

- (void)applicationDidBecomeActive;
- (void)applicationWillResignActive;

- (void)trackEvent:(ADJEvent *)event;

- (void)finishedTracking:(ADJResponseData *)responseData;
- (void)launchEventResponseTasks:(ADJEventResponseData *)eventResponseData;
- (void)launchSessionResponseTasks:(ADJSessionResponseData *)sessionResponseData;
- (void)launchSdkClickResponseTasks:(ADJSdkClickResponseData *)sdkClickResponseData;
- (void)launchAttributionResponseTasks:(ADJAttributionResponseData *)attributionResponseData;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isEnabled;
- (BOOL)isGdprForgotten;

- (void)appWillOpenUrl:(NSURL*)url withClickTime:(NSDate *)clickTime;
- (void)setDeviceToken:(NSData *)deviceToken;
- (void)setPushToken:(NSString *)deviceToken;
- (void)setGdprForgetMe;
- (void)setTrackingStateOptedOut;
- (void)setAskingAttribution:(BOOL)askingAttribution;

- (BOOL)updateAttributionI:(id<ADJActivityHandler>)selfI attribution:(ADJAttribution *)attribution;
- (void)setAttributionDetails:(NSDictionary *)attributionDetails
                        error:(NSError *)error
                  retriesLeft:(int)retriesLeft;

- (void)setOfflineMode:(BOOL)offline;
- (void)sendFirstPackages;

- (void)addSessionCallbackParameter:(NSString *)key
                              value:(NSString *)value;
- (void)addSessionPartnerParameter:(NSString *)key
                             value:(NSString *)value;
- (void)removeSessionCallbackParameter:(NSString *)key;
- (void)removeSessionPartnerParameter:(NSString *)key;
- (void)resetSessionCallbackParameters;
- (void)resetSessionPartnerParameters;
- (void)trackAdRevenue:(NSString *)soruce payload:(NSData *)payload;
- (NSString *)getBasePath;
- (NSString *)getGdprPath;

- (ADJDeviceInfo *)deviceInfo;
- (ADJActivityState *)activityState;
- (ADJConfig *)adjustConfig;
- (ADJSessionParameters *)sessionParameters;

- (void)teardown;
+ (void)deleteState;
@end

@interface ADJActivityHandler : NSObject <ADJActivityHandler>

+ (id<ADJActivityHandler>)handlerWithConfig:(ADJConfig *)adjustConfig
                             savedPreLaunch:(ADJSavedPreLaunch *)savedPreLaunch;

- (void)addSessionCallbackParameterI:(ADJActivityHandler *)selfI
                                 key:(NSString *)key
                               value:(NSString *)value;

- (void)addSessionPartnerParameterI:(ADJActivityHandler *)selfI
                                key:(NSString *)key
                              value:(NSString *)value;
- (void)removeSessionCallbackParameterI:(ADJActivityHandler *)selfI
                                    key:(NSString *)key;
- (void)removeSessionPartnerParameterI:(ADJActivityHandler *)selfI
                                   key:(NSString *)key;
- (void)resetSessionCallbackParametersI:(ADJActivityHandler *)selfI;
- (void)resetSessionPartnerParametersI:(ADJActivityHandler *)selfI;

@end
