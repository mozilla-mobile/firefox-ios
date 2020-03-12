//
//  ADJActivityHandler.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-01.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJActivityPackage.h"
#import "ADJActivityHandler.h"
#import "ADJPackageBuilder.h"
#import "ADJPackageHandler.h"
#import "ADJLogger.h"
#import "ADJTimerCycle.h"
#import "ADJTimerOnce.h"
#import "ADJUtil.h"
#import "UIDevice+ADJAdditions.h"
#import "ADJAdjustFactory.h"
#import "ADJAttributionHandler.h"
#import "NSString+ADJAdditions.h"
#import "ADJSdkClickHandler.h"
#import "ADJUserDefaults.h"

typedef void (^activityHandlerBlockI)(ADJActivityHandler * activityHandler);

static NSString   * const kActivityStateFilename = @"AdjustIoActivityState";
static NSString   * const kAttributionFilename   = @"AdjustIoAttribution";
static NSString   * const kSessionCallbackParametersFilename   = @"AdjustSessionCallbackParameters";
static NSString   * const kSessionPartnerParametersFilename    = @"AdjustSessionPartnerParameters";
static NSString   * const kAdjustPrefix          = @"adjust_";
static const char * const kInternalQueueName     = "io.adjust.ActivityQueue";
static NSString   * const kForegroundTimerName   = @"Foreground timer";
static NSString   * const kBackgroundTimerName   = @"Background timer";
static NSString   * const kDelayStartTimerName   = @"Delay Start timer";

static NSTimeInterval kForegroundTimerInterval;
static NSTimeInterval kForegroundTimerStart;
static NSTimeInterval kBackgroundTimerInterval;
static double kSessionInterval;
static double kSubSessionInterval;

// number of tries
static const int kTryIadV3                       = 2;
static const uint64_t kDelayRetryIad   =  2 * NSEC_PER_SEC; // 1 second

@implementation ADJInternalState

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    return self;
}

- (BOOL)isEnabled { return self.enabled; }
- (BOOL)isDisabled { return !self.enabled; }
- (BOOL)isOffline { return self.offline; }
- (BOOL)isOnline { return !self.offline; }
- (BOOL)isInBackground { return self.background; }
- (BOOL)isInForeground { return !self.background; }
- (BOOL)isInDelayedStart { return self.delayStart; }
- (BOOL)isNotInDelayedStart { return !self.delayStart; }
- (BOOL)itHasToUpdatePackages { return self.updatePackages; }
- (BOOL)isFirstLaunch { return self.firstLaunch; }
- (BOOL)hasSessionResponseNotBeenProcessed { return !self.sessionResponseProcessed; }

@end

@implementation ADJSavedPreLaunch

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    // online by default
    self.offline = NO;
    return self;
}

@end

#pragma mark -
@interface ADJActivityHandler()

@property (nonatomic, strong) dispatch_queue_t internalQueue;
@property (nonatomic, strong) id<ADJPackageHandler> packageHandler;
@property (nonatomic, strong) id<ADJAttributionHandler> attributionHandler;
@property (nonatomic, strong) id<ADJSdkClickHandler> sdkClickHandler;
@property (nonatomic, strong) ADJActivityState *activityState;
@property (nonatomic, strong) ADJTimerCycle *foregroundTimer;
@property (nonatomic, strong) ADJTimerOnce *backgroundTimer;
@property (nonatomic, strong) ADJInternalState *internalState;
@property (nonatomic, strong) ADJDeviceInfo *deviceInfo;
@property (nonatomic, strong) ADJTimerOnce *delayStartTimer;
@property (nonatomic, strong) ADJSessionParameters *sessionParameters;
// weak for object that Activity Handler does not "own"
@property (nonatomic, weak) id<ADJLogger> logger;
@property (nonatomic, weak) NSObject<AdjustDelegate> *adjustDelegate;
// copy for objects shared with the user
@property (nonatomic, copy) ADJConfig *adjustConfig;
@property (nonatomic, copy) NSData* deviceTokenData;
@property (nonatomic, copy) NSString* basePath;
@property (nonatomic, copy) NSString* gdprPath;

@end

// copy from ADClientError
typedef NS_ENUM(NSInteger, AdjADClientError) {
    AdjADClientErrorUnknown = 0,
    AdjADClientErrorLimitAdTracking = 1,
};

#pragma mark -
@implementation ADJActivityHandler

@synthesize attribution = _attribution;

+ (id<ADJActivityHandler>)handlerWithConfig:(ADJConfig *)adjustConfig
                             savedPreLaunch:(ADJSavedPreLaunch *)savedPreLaunch
{
    return [[ADJActivityHandler alloc] initWithConfig:adjustConfig
                                       savedPreLaunch:savedPreLaunch];
}

- (id)initWithConfig:(ADJConfig *)adjustConfig
      savedPreLaunch:(ADJSavedPreLaunch *)savedPreLaunch
{
    self = [super init];
    if (self == nil) return nil;

    if (adjustConfig == nil) {
        [ADJAdjustFactory.logger error:@"AdjustConfig missing"];
        return nil;
    }

    if (![adjustConfig isValid]) {
        [ADJAdjustFactory.logger error:@"AdjustConfig not initialized correctly"];
        return nil;
    }

    self.adjustConfig = adjustConfig;
    self.adjustDelegate = adjustConfig.delegate;

    // init logger to be available everywhere
    self.logger = ADJAdjustFactory.logger;

    [self.logger lockLogLevel];

    // inject app token be available in activity state
    [ADJActivityState saveAppToken:adjustConfig.appToken];

    // read files to have sync values available
    [self readAttribution];
    [self readActivityState];

    self.internalState = [[ADJInternalState alloc] init];

    if (savedPreLaunch.enabled != nil) {
        if (savedPreLaunch.preLaunchActionsArray == nil) {
            savedPreLaunch.preLaunchActionsArray = [[NSMutableArray alloc] init];
        }

        BOOL newEnabled = [savedPreLaunch.enabled boolValue];
        [savedPreLaunch.preLaunchActionsArray addObject:^(ADJActivityHandler * activityHandler){
            [activityHandler setEnabledI:activityHandler enabled:newEnabled];
        }];
    }

    // check if SDK is enabled/disabled
    self.internalState.enabled = savedPreLaunch.enabled != nil ? [savedPreLaunch.enabled boolValue] : YES;
    // reads offline mode from pre launch
    self.internalState.offline = savedPreLaunch.offline;
    // in the background by default
    self.internalState.background = YES;
    // delay start not configured by default
    self.internalState.delayStart = NO;
    // does not need to update packages by default
    if (self.activityState == nil) {
        self.internalState.updatePackages = NO;
    } else {
        self.internalState.updatePackages = self.activityState.updatePackages;
    }
    if (self.activityState == nil) {
        self.internalState.firstLaunch = YES;
    } else {
        self.internalState.firstLaunch = NO;
    }
    // does not have the session response by default
    self.internalState.sessionResponseProcessed = NO;

    if (savedPreLaunch.basePath != nil) {
        self.basePath = savedPreLaunch.basePath;
    }
    if (savedPreLaunch.gdprPath != nil) {
        self.gdprPath = savedPreLaunch.gdprPath;
    }

    self.internalQueue = dispatch_queue_create(kInternalQueueName, DISPATCH_QUEUE_SERIAL);
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI initI:selfI
                preLaunchActionsArray:savedPreLaunch.preLaunchActionsArray];
                     }];

    /* Not needed, done already in initI:preLaunchActionsArray: method.
    // self.deviceTokenData = savedPreLaunch.deviceTokenData;
    if (self.activityState != nil) {
        [self setDeviceToken:[ADJUserDefaults getPushToken]];
    }
    */

    [self addNotificationObserver];

    return self;
}

- (void)applicationDidBecomeActive {
    self.internalState.background = NO;

    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI delayStartI:selfI];

                         [selfI stopBackgroundTimerI:selfI];

                         [selfI startForegroundTimerI:selfI];

                         [selfI.logger verbose:@"Subsession start"];

                         [selfI startI:selfI];
                     }];
}

- (void)applicationWillResignActive {
    self.internalState.background = YES;

    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI stopForegroundTimerI:selfI];

                         [selfI startBackgroundTimerI:selfI];

                         [selfI.logger verbose:@"Subsession end"];

                         [selfI endI:selfI];
                     }];
}

- (void)trackEvent:(ADJEvent *)event {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         // track event called before app started
                         if (selfI.activityState == nil) {
                             [selfI startI:selfI];
                         }
                         [selfI eventI:selfI event:event];
                     }];
}

- (void)finishedTracking:(ADJResponseData *)responseData {
    // redirect session responses to attribution handler to check for attribution information
    if ([responseData isKindOfClass:[ADJSessionResponseData class]]) {
        [self.attributionHandler checkSessionResponse:(ADJSessionResponseData*)responseData];
        return;
    }

    // redirect sdk_click responses to attribution handler to check for attribution information
    if ([responseData isKindOfClass:[ADJSdkClickResponseData class]]) {
        [self.attributionHandler checkSdkClickResponse:(ADJSdkClickResponseData*)responseData];
        return;
    }

    // check if it's an event response
    if ([responseData isKindOfClass:[ADJEventResponseData class]]) {
        [self launchEventResponseTasks:(ADJEventResponseData*)responseData];
        return;
    }
}

- (void)launchEventResponseTasks:(ADJEventResponseData *)eventResponseData {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI launchEventResponseTasksI:selfI eventResponseData:eventResponseData];
                     }];
}

- (void)launchSessionResponseTasks:(ADJSessionResponseData *)sessionResponseData {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI launchSessionResponseTasksI:selfI sessionResponseData:sessionResponseData];
                     }];
}

- (void)launchSdkClickResponseTasks:(ADJSdkClickResponseData *)sdkClickResponseData {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI launchSdkClickResponseTasksI:selfI sdkClickResponseData:sdkClickResponseData];
                     }];
}

- (void)launchAttributionResponseTasks:(ADJAttributionResponseData *)attributionResponseData {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI launchAttributionResponseTasksI:selfI attributionResponseData:attributionResponseData];
                     }];
}

- (void)setEnabled:(BOOL)enabled {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI setEnabledI:selfI enabled:enabled];
                     }];
}

- (void)setOfflineMode:(BOOL)offline {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI setOfflineModeI:selfI offline:offline];
                     }];
}

- (BOOL)isEnabled {
    return [self isEnabledI:self];
}

- (BOOL)isGdprForgotten {
    return [self isGdprForgottenI:self];
}

- (NSString *)adid {
    if (self.activityState == nil) {
        return nil;
    }
    return self.activityState.adid;
}

- (void)appWillOpenUrl:(NSURL *)url withClickTime:(NSDate *)clickTime {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI appWillOpenUrlI:selfI url:url clickTime:clickTime];
                     }];
}

- (void)setDeviceToken:(NSData *)deviceToken {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI setDeviceTokenI:selfI deviceToken:deviceToken];
                     }];
}

- (void)setPushToken:(NSString *)pushToken {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI setPushTokenI:selfI pushToken:pushToken];
                     }];
}

- (void)setGdprForgetMe {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI setGdprForgetMeI:selfI];
                     }];
}

- (void)setTrackingStateOptedOut {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI setTrackingStateOptedOutI:selfI];
                     }];
}


- (void)setAttributionDetails:(NSDictionary *)attributionDetails
                        error:(NSError *)error
                  retriesLeft:(int)retriesLeft
{
    if (![ADJUtil isNull:error]) {
        [self.logger warn:@"Unable to read iAd details"];

        if (retriesLeft < 0) {
            [self.logger warn:@"Limit number of retry for iAd v3 surpassed"];
            return;
        }

        if (error.code == AdjADClientErrorUnknown) {
            dispatch_time_t retryTime = dispatch_time(DISPATCH_TIME_NOW, kDelayRetryIad);
            dispatch_after(retryTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[UIDevice currentDevice] adjSetIad:self triesV3Left:retriesLeft];
            });
        }
        return;
    }

    // check if it's a valid attribution details
    if (![ADJUtil checkAttributionDetails:attributionDetails]) {
        return;
    }

    // send immediately if there is no previous attribution details
    if (self.activityState == nil ||
        self.activityState.attributionDetails == nil)
    {
        // send immediately
        [self sendIad3ClickPackage:self attributionDetails:attributionDetails];
        // save in the background queue
        [ADJUtil launchInQueue:self.internalQueue
                    selfInject:self
                         block:^(ADJActivityHandler * selfI) {
                             [selfI saveAttributionDetailsI:selfI
                                         attributionDetails:attributionDetails];

                         }];
        return;
    }

    // check if new updates previous written one
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         if ([attributionDetails isEqualToDictionary:selfI.activityState.attributionDetails]) {
                             return;
                         }

                         [selfI sendIad3ClickPackage:selfI attributionDetails:attributionDetails];

                         // save new iAd details
                         [selfI saveAttributionDetailsI:selfI
                                     attributionDetails:attributionDetails];
                     }];
}

- (void)sendIad3ClickPackage:(ADJActivityHandler *)selfI
          attributionDetails:(NSDictionary *)attributionDetails
 {
     if (![selfI isEnabledI:selfI]) {
         return;
     }
     
     if (ADJAdjustFactory.iAdFrameworkEnabled == NO) {
         [self.logger verbose:@"Sending iAd details to server suppressed."];
         return;
     }

     double now = [NSDate.date timeIntervalSince1970];
     if (selfI.activityState != nil) {
         double lastInterval = now - selfI.activityState.lastActivity;
         selfI.activityState.lastInterval = lastInterval;
     }
     ADJPackageBuilder *clickBuilder = [[ADJPackageBuilder alloc]
                                        initWithDeviceInfo:selfI.deviceInfo
                                        activityState:selfI.activityState
                                        config:selfI.adjustConfig
                                        sessionParameters:self.sessionParameters
                                        createdAt:now];

     clickBuilder.attributionDetails = attributionDetails;

     ADJActivityPackage *clickPackage = [clickBuilder buildClickPackage:@"iad3"];
     [selfI.sdkClickHandler sendSdkClick:clickPackage];
}

- (void)saveAttributionDetailsI:(ADJActivityHandler *)selfI
             attributionDetails:(NSDictionary *)attributionDetails
{
    // save new iAd details
    selfI.activityState.attributionDetails = attributionDetails;
    [selfI writeAttributionI:selfI];
}

- (void)setAskingAttribution:(BOOL)askingAttribution {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI setAskingAttributionI:selfI
                                   askingAttribution:askingAttribution];
                     }];
}

- (void)foregroundTimerFired {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI foregroundTimerFiredI:selfI];
                     }];
}

- (void)backgroundTimerFired {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI backgroundTimerFiredI:selfI];
                     }];
}

- (void)sendFirstPackages {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI sendFirstPackagesI:selfI];
                     }];
}

- (void)addSessionCallbackParameter:(NSString *)key
                              value:(NSString *)value {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI addSessionCallbackParameterI:selfI key:key value:value];
                     }];
}

- (void)addSessionPartnerParameter:(NSString *)key
                             value:(NSString *)value {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI addSessionPartnerParameterI:selfI key:key value:value];
                     }];
}

- (void)removeSessionCallbackParameter:(NSString *)key {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI removeSessionCallbackParameterI:selfI key:key];
                     }];
}

- (void)removeSessionPartnerParameter:(NSString *)key {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI removeSessionPartnerParameterI:selfI key:key];
                     }];
}

- (void)resetSessionCallbackParameters {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI resetSessionCallbackParametersI:selfI];
                     }];
}

- (void)resetSessionPartnerParameters {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI resetSessionPartnerParametersI:selfI];
                     }];
}

- (void)trackAdRevenue:(NSString *)source payload:(NSData *)payload {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJActivityHandler * selfI) {
                         [selfI adRevenueI:selfI source:source payload:payload];
                     }];
}

- (NSString *)getBasePath {
    return _basePath;
}

- (NSString *)getGdprPath {
    return _gdprPath;
}

- (void)teardown
{
    [ADJAdjustFactory.logger verbose:@"ADJActivityHandler teardown"];
    [self removeNotificationObserver];
    if (self.backgroundTimer != nil) {
        [self.backgroundTimer cancel];
    }
    if (self.foregroundTimer != nil) {
        [self.foregroundTimer cancel];
    }
    if (self.delayStartTimer != nil) {
        [self.delayStartTimer cancel];
    }
    if (self.attributionHandler != nil) {
        [self.attributionHandler teardown];
    }
    if (self.packageHandler != nil) {
        [self.packageHandler teardown];
    }
    if (self.sdkClickHandler != nil) {
        [self.sdkClickHandler teardown];
    }
    [self teardownActivityStateS];
    [self teardownAttributionS];
    [self teardownAllSessionParametersS];

    [ADJUtil teardown];

    self.internalQueue = nil;
    self.packageHandler = nil;
    self.attributionHandler = nil;
    self.sdkClickHandler = nil;
    self.foregroundTimer = nil;
    self.backgroundTimer = nil;
    self.adjustDelegate = nil;
    self.adjustConfig = nil;
    self.internalState = nil;
    self.deviceInfo = nil;
    self.delayStartTimer = nil;
    self.logger = nil;
}

+ (void)deleteState
{
    [ADJActivityHandler deleteActivityState];
    [ADJActivityHandler deleteAttribution];
    [ADJActivityHandler deleteSessionCallbackParameter];
    [ADJActivityHandler deleteSessionPartnerParameter];

    [ADJUserDefaults clearAdjustStuff];
}

+ (void)deleteActivityState {
    [ADJUtil deleteFileWithName:kActivityStateFilename];
}

+ (void)deleteAttribution {
    [ADJUtil deleteFileWithName:kAttributionFilename];
}

+ (void)deleteSessionCallbackParameter {
    [ADJUtil deleteFileWithName:kSessionCallbackParametersFilename];
}

+ (void)deleteSessionPartnerParameter {
    [ADJUtil deleteFileWithName:kSessionPartnerParametersFilename];
}

#pragma mark - internal
- (void)initI:(ADJActivityHandler *)selfI
preLaunchActionsArray:(NSArray*)preLaunchActionsArray
{
    // get session values
    kSessionInterval = ADJAdjustFactory.sessionInterval;
    kSubSessionInterval = ADJAdjustFactory.subsessionInterval;
    // get timer values
    kForegroundTimerStart = ADJAdjustFactory.timerStart;
    kForegroundTimerInterval = ADJAdjustFactory.timerInterval;
    kBackgroundTimerInterval = ADJAdjustFactory.timerInterval;

    selfI.deviceInfo = [ADJDeviceInfo deviceInfoWithSdkPrefix:selfI.adjustConfig.sdkPrefix];

    // read files that are accessed only in Internal sections
    selfI.sessionParameters = [[ADJSessionParameters alloc] init];
    [selfI readSessionCallbackParametersI:selfI];
    [selfI readSessionPartnerParametersI:selfI];

    if (selfI.adjustConfig.eventBufferingEnabled)  {
        [selfI.logger info:@"Event buffering is enabled"];
    }

    if (selfI.adjustConfig.defaultTracker != nil) {
        [selfI.logger info:@"Default tracker: '%@'", selfI.adjustConfig.defaultTracker];
    }

    if (selfI.deviceTokenData != nil) {
        [selfI.logger info:@"Push token: '%@'", selfI.deviceTokenData];
        if (selfI.activityState != nil) {
            [selfI setDeviceToken:selfI.deviceTokenData];
        }
    } else {
        if (selfI.activityState != nil) {
            NSData *deviceToken = [ADJUserDefaults getPushTokenData];
            [selfI setDeviceToken:deviceToken];
            NSString *pushToken = [ADJUserDefaults getPushTokenString];
            [selfI setPushToken:pushToken];
        }
    }

    if (selfI.activityState != nil) {
        if ([ADJUserDefaults getGdprForgetMe]) {
            [selfI setGdprForgetMe];
        }
    }

    selfI.foregroundTimer = [ADJTimerCycle timerWithBlock:^{
        [selfI foregroundTimerFired];
    }
                                                    queue:selfI.internalQueue
                                                startTime:kForegroundTimerStart
                                             intervalTime:kForegroundTimerInterval
                                                     name:kForegroundTimerName
    ];

    if (selfI.adjustConfig.sendInBackground) {
        [selfI.logger info:@"Send in background configured"];
        selfI.backgroundTimer = [ADJTimerOnce timerWithBlock:^{ [selfI backgroundTimerFired]; }
                                                      queue:selfI.internalQueue
                                                        name:kBackgroundTimerName];
    }

    if (selfI.activityState == nil &&
        selfI.adjustConfig.delayStart > 0)
    {
        [selfI.logger info:@"Delay start configured"];
        selfI.internalState.delayStart = YES;
        selfI.delayStartTimer = [ADJTimerOnce timerWithBlock:^{ [selfI sendFirstPackages]; }
                                                       queue:selfI.internalQueue
                                                        name:kDelayStartTimerName];
    }

    [ADJUtil updateUrlSessionConfiguration:selfI.adjustConfig];

    selfI.packageHandler = [ADJAdjustFactory packageHandlerForActivityHandler:selfI
                                                                startsSending:[selfI toSendI:selfI
                                                                         sdkClickHandlerOnly:NO]];

    // update session parameters in package queue
    if ([selfI itHasToUpdatePackagesI:selfI]) {
        [selfI updatePackagesI:selfI];
     }

    selfI.attributionHandler = [ADJAdjustFactory attributionHandlerForActivityHandler:selfI
                                                                        startsSending:[selfI toSendI:selfI
                                                                                 sdkClickHandlerOnly:NO]];

    selfI.sdkClickHandler = [ADJAdjustFactory sdkClickHandlerForActivityHandler:selfI
                                                                  startsSending:[selfI toSendI:selfI
                                                                           sdkClickHandlerOnly:YES]];

    [[UIDevice currentDevice] adjSetIad:selfI triesV3Left:kTryIadV3];

    [selfI preLaunchActionsI:selfI preLaunchActionsArray:preLaunchActionsArray];

    [ADJUtil launchInMainThreadWithInactive:^(BOOL isInactive) {
        [ADJUtil launchInQueue:self.internalQueue selfInject:self block:^(ADJActivityHandler * selfI) {
            if (!isInactive) {
                [selfI.logger debug:@"Start sdk, since the app is already in the foreground"];
                selfI.internalState.background = NO;
                [selfI startI:selfI];
            } else {
                [selfI.logger debug:@"Wait for the app to go to the foreground to start the sdk"];
            }
        }];
    }];
}

- (void)startI:(ADJActivityHandler *)selfI {
    // it shouldn't start if it was disabled after a first session
    if (selfI.activityState != nil
        && !selfI.activityState.enabled) {
        return;
    }

    [selfI updateHandlersStatusAndSendI:selfI];

    [selfI processSessionI:selfI];

    [selfI checkAttributionStateI:selfI];

    [selfI processCachedDeeplinkI:selfI];
}

- (void)processSessionI:(ADJActivityHandler *)selfI {
    double now = [NSDate.date timeIntervalSince1970];

    // very first session
    if (selfI.activityState == nil) {
        selfI.activityState = [[ADJActivityState alloc] init];

        // selfI.activityState.deviceToken = [ADJUtil convertDeviceToken:selfI.deviceTokenData];
        NSData *deviceToken = [ADJUserDefaults getPushTokenData];
        NSString *deviceTokenString = [ADJUtil convertDeviceToken:deviceToken];
        NSString *pushToken = [ADJUserDefaults getPushTokenString];
        selfI.activityState.deviceToken = deviceTokenString != nil ? deviceTokenString : pushToken;

        // track the first session package only if it's enabled
        if ([selfI.internalState isEnabled]) {
            // If user chose to be forgotten before install has ever tracked, don't track it.
            if (![ADJUserDefaults getGdprForgetMe]) {
                selfI.activityState.sessionCount = 1; // this is the first session
                [selfI transferSessionPackageI:selfI now:now];
            } else {
                [selfI setGdprForgetMeI:selfI];
            }
        }

        [selfI.activityState resetSessionAttributes:now];
        selfI.activityState.enabled = [selfI.internalState isEnabled];
        selfI.activityState.updatePackages = [selfI.internalState itHasToUpdatePackages];

        [selfI writeActivityStateI:selfI];
        [ADJUserDefaults removePushToken];

        return;
    }

    double lastInterval = now - selfI.activityState.lastActivity;
    if (lastInterval < 0) {
        [selfI.logger error:@"Time travel!"];
        selfI.activityState.lastActivity = now;
        [selfI writeActivityStateI:selfI];
        return;
    }

    // new session
    if (lastInterval > kSessionInterval) {
        [self trackNewSessionI:now withActivityHandler:selfI];
        return;
    }

    // new subsession
    if (lastInterval > kSubSessionInterval) {
        selfI.activityState.subsessionCount++;
        selfI.activityState.sessionLength += lastInterval;
        selfI.activityState.lastActivity = now;
        [selfI.logger verbose:@"Started subsession %d of session %d",
         selfI.activityState.subsessionCount,
         selfI.activityState.sessionCount];
        [selfI writeActivityStateI:selfI];
        return;
    }

    [selfI.logger verbose:@"Time span since last activity too short for a new subsession"];
}

- (void)trackNewSessionI:(double)now withActivityHandler:(ADJActivityHandler *)selfI {
    if (selfI.activityState.isGdprForgotten) {
        return;
    }

    double lastInterval = now - selfI.activityState.lastActivity;
    selfI.activityState.sessionCount++;
    selfI.activityState.lastInterval = lastInterval;
    [selfI transferSessionPackageI:selfI now:now];
    [selfI.activityState resetSessionAttributes:now];
    [selfI writeActivityStateI:selfI];
}

- (void)transferSessionPackageI:(ADJActivityHandler *)selfI
                            now:(double)now {
    ADJPackageBuilder *sessionBuilder = [[ADJPackageBuilder alloc]
                                         initWithDeviceInfo:selfI.deviceInfo
                                         activityState:selfI.activityState
                                         config:selfI.adjustConfig
                                         sessionParameters:selfI.sessionParameters
                                         createdAt:now];
    ADJActivityPackage *sessionPackage = [sessionBuilder buildSessionPackage:[selfI.internalState isInDelayedStart]];
    [selfI.packageHandler addPackage:sessionPackage];
    [selfI.packageHandler sendFirstPackage];
}

- (void)checkAttributionStateI:(ADJActivityHandler *)selfI {
    if (![selfI checkActivityStateI:selfI]) return;

    // if it's the first launch
    if ([selfI.internalState isFirstLaunch]) {
        // and it hasn't received the session response
        if ([selfI.internalState hasSessionResponseNotBeenProcessed]) {
            return;
        }
    }

    // if there is already an attribution saved and there was no attribution being asked
    if (selfI.attribution != nil && !selfI.activityState.askingAttribution) {
        return;
    }

    [selfI.attributionHandler getAttribution];
}

- (void)processCachedDeeplinkI:(ADJActivityHandler *)selfI {
    if (![selfI checkActivityStateI:selfI]) return;

    NSURL *cachedDeeplinkUrl = [ADJUserDefaults getDeeplinkUrl];
    if (cachedDeeplinkUrl == nil) {
        return;
    }
    NSDate *cachedDeeplinkClickTime = [ADJUserDefaults getDeeplinkClickTime];
    if (cachedDeeplinkClickTime == nil) {
        return;
    }

    [selfI appWillOpenUrlI:selfI url:cachedDeeplinkUrl clickTime:cachedDeeplinkClickTime];
    [ADJUserDefaults removeDeeplink];
}

- (void)endI:(ADJActivityHandler *)selfI {
    // pause sending if it's not allowed to send
    if (![selfI toSendI:selfI]) {
        [selfI pauseSendingI:selfI];
    }

    double now = [NSDate.date timeIntervalSince1970];
    if ([selfI updateActivityStateI:selfI now:now]) {
        [selfI writeActivityStateI:selfI];
    }
}

- (void)eventI:(ADJActivityHandler *)selfI
         event:(ADJEvent *)event {
    if (![selfI isEnabledI:selfI]) return;
    if (![selfI checkEventI:selfI event:event]) return;
    if (![selfI checkTransactionIdI:selfI transactionId:event.transactionId]) return;
    if (selfI.activityState.isGdprForgotten) { return; }

    double now = [NSDate.date timeIntervalSince1970];

    selfI.activityState.eventCount++;
    [selfI updateActivityStateI:selfI now:now];

    // create and populate event package
    ADJPackageBuilder *eventBuilder = [[ADJPackageBuilder alloc]
                                       initWithDeviceInfo:selfI.deviceInfo
                                       activityState:selfI.activityState
                                       config:selfI.adjustConfig
                                       sessionParameters:selfI.sessionParameters
                                       createdAt:now];
    ADJActivityPackage *eventPackage = [eventBuilder buildEventPackage:event
                                                             isInDelay:[selfI.internalState isInDelayedStart]];
    [selfI.packageHandler addPackage:eventPackage];

    if (selfI.adjustConfig.eventBufferingEnabled) {
        [selfI.logger info:@"Buffered event %@", eventPackage.suffix];
    } else {
        [selfI.packageHandler sendFirstPackage];
    }

    // if it is in the background and it can send, start the background timer
    if (selfI.adjustConfig.sendInBackground && [selfI.internalState isInBackground]) {
        [selfI startBackgroundTimerI:selfI];
    }

    [selfI writeActivityStateI:selfI];
}

- (void)adRevenueI:(ADJActivityHandler *)selfI
            source:(NSString *)source
           payload:(NSData *)payload {
    if (!selfI.activityState) {
        return;
    }
    if (![selfI isEnabledI:selfI]) {
        return;
    }
    if (selfI.activityState.isGdprForgotten) {
        return;
    }

    double now = [NSDate.date timeIntervalSince1970];

    // Create and submit ad revenue package.
    ADJPackageBuilder *adRevenueBuilder = [[ADJPackageBuilder alloc] initWithDeviceInfo:selfI.deviceInfo
                                                                          activityState:selfI.activityState
                                                                                 config:selfI.adjustConfig
                                                                      sessionParameters:selfI.sessionParameters
                                                                              createdAt:now];
    ADJActivityPackage *adRevenuePackage = [adRevenueBuilder buildAdRevenuePackage:source payload:payload];
    [selfI.packageHandler addPackage:adRevenuePackage];
    [selfI.packageHandler sendFirstPackage];
}

- (void)launchEventResponseTasksI:(ADJActivityHandler *)selfI
                eventResponseData:(ADJEventResponseData *)eventResponseData {
    [selfI updateAdidI:selfI adid:eventResponseData.adid];

    // event success callback
    if (eventResponseData.success
        && [selfI.adjustDelegate respondsToSelector:@selector(adjustEventTrackingSucceeded:)])
    {
        [selfI.logger debug:@"Launching success event tracking delegate"];
        [ADJUtil launchInMainThread:selfI.adjustDelegate
                           selector:@selector(adjustEventTrackingSucceeded:)
                         withObject:[eventResponseData successResponseData]];
        return;
    }
    // event failure callback
    if (!eventResponseData.success
        && [selfI.adjustDelegate respondsToSelector:@selector(adjustEventTrackingFailed:)])
    {
        [selfI.logger debug:@"Launching failed event tracking delegate"];
        [ADJUtil launchInMainThread:selfI.adjustDelegate
                           selector:@selector(adjustEventTrackingFailed:)
                         withObject:[eventResponseData failureResponseData]];
        return;
    }
}

- (void)launchSessionResponseTasksI:(ADJActivityHandler *)selfI
                sessionResponseData:(ADJSessionResponseData *)sessionResponseData {
    [selfI updateAdidI:selfI adid:sessionResponseData.adid];

    BOOL toLaunchAttributionDelegate = [selfI updateAttributionI:selfI attribution:sessionResponseData.attribution];

    // mark install as tracked on success
    if (sessionResponseData.success) {
        [ADJUserDefaults setInstallTracked];
    }

    // session success callback
    if (sessionResponseData.success
        && [selfI.adjustDelegate respondsToSelector:@selector(adjustSessionTrackingSucceeded:)])
    {
        [selfI.logger debug:@"Launching success session tracking delegate"];
        [ADJUtil launchInMainThread:selfI.adjustDelegate
                           selector:@selector(adjustSessionTrackingSucceeded:)
                         withObject:[sessionResponseData successResponseData]];
    }
    // session failure callback
    if (!sessionResponseData.success
        && [selfI.adjustDelegate respondsToSelector:@selector(adjustSessionTrackingFailed:)])
    {
        [selfI.logger debug:@"Launching failed session tracking delegate"];
        [ADJUtil launchInMainThread:selfI.adjustDelegate
                           selector:@selector(adjustSessionTrackingFailed:)
                         withObject:[sessionResponseData failureResponseData]];
    }

    // try to update and launch the attribution changed delegate
    if (toLaunchAttributionDelegate) {
        [selfI.logger debug:@"Launching attribution changed delegate"];
        [ADJUtil launchInMainThread:selfI.adjustDelegate
                           selector:@selector(adjustAttributionChanged:)
                         withObject:sessionResponseData.attribution];
    }

    // if attribution didn't update and it's still null -> ask for attribution
    if (selfI.attribution == nil && selfI.activityState.askingAttribution == NO) {
        [selfI.attributionHandler getAttribution];
    }

    selfI.internalState.sessionResponseProcessed = YES;
}

- (void)launchSdkClickResponseTasksI:(ADJActivityHandler *)selfI
                sdkClickResponseData:(ADJSdkClickResponseData *)sdkClickResponseData {
    [selfI updateAdidI:selfI adid:sdkClickResponseData.adid];

    BOOL toLaunchAttributionDelegate = [selfI updateAttributionI:selfI attribution:sdkClickResponseData.attribution];

    // try to update and launch the attribution changed delegate
    if (toLaunchAttributionDelegate) {
        [selfI.logger debug:@"Launching attribution changed delegate"];
        [ADJUtil launchInMainThread:selfI.adjustDelegate
                           selector:@selector(adjustAttributionChanged:)
                         withObject:sdkClickResponseData.attribution];
    }
}

- (void)launchAttributionResponseTasksI:(ADJActivityHandler *)selfI
                attributionResponseData:(ADJAttributionResponseData *)attributionResponseData {
    [selfI updateAdidI:selfI adid:attributionResponseData.adid];

    BOOL toLaunchAttributionDelegate = [selfI updateAttributionI:selfI
                                                     attribution:attributionResponseData.attribution];

    // try to update and launch the attribution changed delegate non-blocking
    if (toLaunchAttributionDelegate) {
        [selfI.logger debug:@"Launching attribution changed delegate"];
        [ADJUtil launchInMainThread:selfI.adjustDelegate
                           selector:@selector(adjustAttributionChanged:)
                         withObject:attributionResponseData.attribution];
    }

    [selfI prepareDeeplinkI:selfI responseData:attributionResponseData];
}

- (void)prepareDeeplinkI:(ADJActivityHandler *)selfI
            responseData:(ADJAttributionResponseData *)attributionResponseData {
    if (attributionResponseData == nil) {
        return;
    }

    if (attributionResponseData.deeplink == nil) {
        return;
    }

    [selfI.logger info:@"Open deep link (%@)", attributionResponseData.deeplink.absoluteString];

    [ADJUtil launchInMainThread:^{
        BOOL toLaunchDeeplink = YES;

        if ([selfI.adjustDelegate respondsToSelector:@selector(adjustDeeplinkResponse:)]) {
            toLaunchDeeplink = [selfI.adjustDelegate adjustDeeplinkResponse:attributionResponseData.deeplink];
        }

        if (toLaunchDeeplink) {
            [ADJUtil launchDeepLinkMain:attributionResponseData.deeplink];
        }
    }];
}

- (void)updateAdidI:(ADJActivityHandler *)selfI
               adid:(NSString *)adid {
    if (adid == nil) {
        return;
    }

    if ([adid isEqualToString:selfI.activityState.adid]) {
        return;
    }

    selfI.activityState.adid = adid;
    [selfI writeActivityStateI:selfI];
}

- (BOOL)updateAttributionI:(ADJActivityHandler *)selfI
               attribution:(ADJAttribution *)attribution {
    if (attribution == nil) {
        return NO;
    }
    if ([attribution isEqual:selfI.attribution]) {
        return NO;
    }
    // copy attribution property
    //  to avoid using the same object for the delegate
    selfI.attribution = attribution;
    [selfI writeAttributionI:selfI];

    if (selfI.adjustDelegate == nil) {
        return NO;
    }

    if (![selfI.adjustDelegate respondsToSelector:@selector(adjustAttributionChanged:)]) {
        return NO;
    }

    return YES;
}

- (void)setEnabledI:(ADJActivityHandler *)selfI enabled:(BOOL)enabled {
    // compare with the saved or internal state
    if (![selfI hasChangedStateI:selfI
                   previousState:[selfI isEnabled]
                       nextState:enabled
                     trueMessage:@"Adjust already enabled"
                    falseMessage:@"Adjust already disabled"]) {
        return;
    }

    // If user is forgotten, forbid re-enabling.
    if (enabled) {
        if ([selfI isGdprForgottenI:selfI]) {
            [selfI.logger debug:@"Re-enabling SDK for forgotten user not allowed"];
            return;
        }
    }

    // save new enabled state in internal state
    selfI.internalState.enabled = enabled;

    if (selfI.activityState == nil) {
        [selfI checkStatusI:selfI
               pausingState:!enabled
              pausingMessage:@"Handlers will start as paused due to the SDK being disabled"
        remainsPausedMessage:@"Handlers will still start as paused"
            unPausingMessage:@"Handlers will start as active due to the SDK being enabled"];
        return;
    }

    // Save new enabled state in activity state.
    selfI.activityState.enabled = enabled;
    [selfI writeActivityStateI:selfI];

    // Check if upon enabling install has been tracked.
    if (enabled) {
        if (![ADJUserDefaults getInstallTracked]) {
            double now = [NSDate.date timeIntervalSince1970];
            [self trackNewSessionI:now withActivityHandler:selfI];
        }
        NSData *deviceToken = [ADJUserDefaults getPushTokenData];
        if (deviceToken != nil && ![selfI.activityState.deviceToken isEqualToString:[ADJUtil convertDeviceToken:deviceToken]]) {
            [self setDeviceToken:deviceToken];
        }
        NSString *pushToken = [ADJUserDefaults getPushTokenString];
        if (pushToken != nil && ![selfI.activityState.deviceToken isEqualToString:pushToken]) {
            [self setPushToken:pushToken];
        }
        if ([ADJUserDefaults getGdprForgetMe]) {
            [selfI setGdprForgetMe];
        }
        [[UIDevice currentDevice] adjSetIad:selfI triesV3Left:kTryIadV3];
    }

    [selfI checkStatusI:selfI
           pausingState:!enabled
          pausingMessage:@"Pausing handlers due to SDK being disabled"
    remainsPausedMessage:@"Handlers remain paused"
        unPausingMessage:@"Resuming handlers due to SDK being enabled"];
}

- (void)setOfflineModeI:(ADJActivityHandler *)selfI
                offline:(BOOL)offline {
    // compare with the internal state
    if (![selfI hasChangedStateI:selfI
                   previousState:[selfI.internalState isOffline]
                       nextState:offline
                     trueMessage:@"Adjust already in offline mode"
                    falseMessage:@"Adjust already in online mode"])
    {
        return;
    }

    // save new offline state in internal state
    selfI.internalState.offline = offline;

    if (selfI.activityState == nil) {
        [selfI checkStatusI:selfI
               pausingState:offline
             pausingMessage:@"Handlers will start paused due to SDK being offline"
       remainsPausedMessage:@"Handlers will still start as paused"
           unPausingMessage:@"Handlers will start as active due to SDK being online"];
        return;
    }

    [selfI checkStatusI:selfI
           pausingState:offline
         pausingMessage:@"Pausing handlers to put SDK offline mode"
   remainsPausedMessage:@"Handlers remain paused"
       unPausingMessage:@"Resuming handlers to put SDK in online mode"];
}

- (BOOL)hasChangedStateI:(ADJActivityHandler *)selfI
           previousState:(BOOL)previousState
               nextState:(BOOL)nextState
             trueMessage:(NSString *)trueMessage
            falseMessage:(NSString *)falseMessage
{
    if (previousState != nextState) {
        return YES;
    }

    if (previousState) {
        [selfI.logger debug:trueMessage];
    } else {
        [selfI.logger debug:falseMessage];
    }

    return NO;
}

- (void)checkStatusI:(ADJActivityHandler *)selfI
        pausingState:(BOOL)pausingState
      pausingMessage:(NSString *)pausingMessage
remainsPausedMessage:(NSString *)remainsPausedMessage
    unPausingMessage:(NSString *)unPausingMessage
{
    // it is changing from an active state to a pause state
    if (pausingState) {
        [selfI.logger info:pausingMessage];
    }
    // check if it's remaining in a pause state
    else if ([selfI pausedI:selfI sdkClickHandlerOnly:NO]) {
        // including the sdk click handler
        if ([selfI pausedI:selfI sdkClickHandlerOnly:YES]) {
            [selfI.logger info:remainsPausedMessage];
        } else {
            // or except it
            [selfI.logger info:[remainsPausedMessage stringByAppendingString:@", except the Sdk Click Handler"]];
        }
    } else {
        // it is changing from a pause state to an active state
        [selfI.logger info:unPausingMessage];
    }

    [selfI updateHandlersStatusAndSendI:selfI];
}

- (void)appWillOpenUrlI:(ADJActivityHandler *)selfI
                    url:(NSURL *)url
              clickTime:(NSDate *)clickTime {
    if (![selfI isEnabledI:selfI]) {
        return;
    }
    if ([ADJUtil isNull:url]) {
        return;
    }
    if (![ADJUtil isDeeplinkValid:url]) {
        return;
    }

    NSArray *queryArray = [url.query componentsSeparatedByString:@"&"];
    if (queryArray == nil) {
        queryArray = @[];
    }

    NSMutableDictionary *adjustDeepLinks = [NSMutableDictionary dictionary];
    ADJAttribution *deeplinkAttribution = [[ADJAttribution alloc] init];
    for (NSString *fieldValuePair in queryArray) {
        [selfI readDeeplinkQueryStringI:selfI queryString:fieldValuePair adjustDeepLinks:adjustDeepLinks attribution:deeplinkAttribution];
    }

    double now = [NSDate.date timeIntervalSince1970];
    double lastInterval = now - selfI.activityState.lastActivity;
    selfI.activityState.lastInterval = lastInterval;
    ADJPackageBuilder *clickBuilder = [[ADJPackageBuilder alloc] initWithDeviceInfo:selfI.deviceInfo
                                                                      activityState:selfI.activityState
                                                                             config:selfI.adjustConfig
                                                                  sessionParameters:selfI.sessionParameters
                                                                          createdAt:now];
    clickBuilder.deeplinkParameters = adjustDeepLinks;
    clickBuilder.attribution = deeplinkAttribution;
    clickBuilder.clickTime = clickTime;
    clickBuilder.deeplink = [url absoluteString];

    ADJActivityPackage *clickPackage = [clickBuilder buildClickPackage:@"deeplink"];
    [selfI.sdkClickHandler sendSdkClick:clickPackage];
}

- (BOOL)readDeeplinkQueryStringI:(ADJActivityHandler *)selfI
                     queryString:(NSString *)queryString
                 adjustDeepLinks:(NSMutableDictionary*)adjustDeepLinks
                     attribution:(ADJAttribution *)deeplinkAttribution
{
    NSArray* pairComponents = [queryString componentsSeparatedByString:@"="];
    if (pairComponents.count != 2) return NO;

    NSString* key = [pairComponents objectAtIndex:0];
    if (![key hasPrefix:kAdjustPrefix]) return NO;

    NSString* keyDecoded = [key adjUrlDecode];

    NSString* value = [pairComponents objectAtIndex:1];
    if (value.length == 0) return NO;

    NSString* valueDecoded = [value adjUrlDecode];

    NSString* keyWOutPrefix = [keyDecoded substringFromIndex:kAdjustPrefix.length];
    if (keyWOutPrefix.length == 0) return NO;

    if (![selfI trySetAttributionDeeplink:deeplinkAttribution withKey:keyWOutPrefix withValue:valueDecoded]) {
        [adjustDeepLinks setObject:valueDecoded forKey:keyWOutPrefix];
    }

    return YES;
}

- (BOOL)trySetAttributionDeeplink:(ADJAttribution *)deeplinkAttribution
                          withKey:(NSString *)key
                        withValue:(NSString*)value
{
    if ([key isEqualToString:@"tracker"]) {
        deeplinkAttribution.trackerName = value;
        return YES;
    }

    if ([key isEqualToString:@"campaign"]) {
        deeplinkAttribution.campaign = value;
        return YES;
    }

    if ([key isEqualToString:@"adgroup"]) {
        deeplinkAttribution.adgroup = value;
        return YES;
    }

    if ([key isEqualToString:@"creative"]) {
        deeplinkAttribution.creative = value;
        return YES;
    }

    return NO;
}

- (void)setDeviceTokenI:(ADJActivityHandler *)selfI
            deviceToken:(NSData *)deviceToken {
    if (![selfI isEnabledI:selfI]) {
        return;
    }
    if (!selfI.activityState) {
        return;
    }
    if (selfI.activityState.isGdprForgotten) {
        return;
    }

    NSString *deviceTokenString = [ADJUtil convertDeviceToken:deviceToken];

    if (deviceTokenString == nil) {
        return;
    }

    if ([deviceTokenString isEqualToString:selfI.activityState.deviceToken]) {
        return;
    }

    // save new push token
    selfI.activityState.deviceToken = deviceTokenString;
    [selfI writeActivityStateI:selfI];

    // send info package
    double now = [NSDate.date timeIntervalSince1970];
    ADJPackageBuilder *infoBuilder = [[ADJPackageBuilder alloc] initWithDeviceInfo:selfI.deviceInfo
                                                                     activityState:selfI.activityState
                                                                            config:selfI.adjustConfig
                                                                 sessionParameters:selfI.sessionParameters
                                                                         createdAt:now];

    ADJActivityPackage *infoPackage = [infoBuilder buildInfoPackage:@"push"];

    [selfI.packageHandler addPackage:infoPackage];

    // if push token was cached, remove it
    [ADJUserDefaults removePushToken];

    if (selfI.adjustConfig.eventBufferingEnabled) {
        [selfI.logger info:@"Buffered info %@", infoPackage.suffix];
    } else {
        [selfI.packageHandler sendFirstPackage];
    }
}

- (void)setPushTokenI:(ADJActivityHandler *)selfI
            pushToken:(NSString *)pushToken {
    if (![selfI isEnabledI:selfI]) {
        return;
    }
    if (!selfI.activityState) {
        return;
    }
    if (selfI.activityState.isGdprForgotten) {
        return;
    }
    if (pushToken == nil) {
        return;
    }
    if ([pushToken isEqualToString:selfI.activityState.deviceToken]) {
        return;
    }

    // save new push token
    selfI.activityState.deviceToken = pushToken;
    [selfI writeActivityStateI:selfI];

    // send info package
    double now = [NSDate.date timeIntervalSince1970];
    ADJPackageBuilder *infoBuilder = [[ADJPackageBuilder alloc] initWithDeviceInfo:selfI.deviceInfo
                                                                     activityState:selfI.activityState
                                                                            config:selfI.adjustConfig
                                                                 sessionParameters:selfI.sessionParameters
                                                                         createdAt:now];
    ADJActivityPackage *infoPackage = [infoBuilder buildInfoPackage:@"push"];
    [selfI.packageHandler addPackage:infoPackage];

    // if push token was cached, remove it
    [ADJUserDefaults removePushToken];

    if (selfI.adjustConfig.eventBufferingEnabled) {
        [selfI.logger info:@"Buffered info %@", infoPackage.suffix];
    } else {
        [selfI.packageHandler sendFirstPackage];
    }
}

- (void)setGdprForgetMeI:(ADJActivityHandler *)selfI {
    if (![selfI isEnabledI:selfI]) {
        return;
    }
    if (!selfI.activityState) {
        return;
    }
    if (selfI.activityState.isGdprForgotten == YES) {
        [ADJUserDefaults removeGdprForgetMe];
        return;
    }

    selfI.activityState.isGdprForgotten = YES;
    [selfI writeActivityStateI:selfI];

    // Send GDPR package
    double now = [NSDate.date timeIntervalSince1970];
    ADJPackageBuilder *gdprBuilder = [[ADJPackageBuilder alloc] initWithDeviceInfo:selfI.deviceInfo
                                                                     activityState:selfI.activityState
                                                                            config:selfI.adjustConfig
                                                                 sessionParameters:selfI.sessionParameters
                                                                         createdAt:now];

    ADJActivityPackage *gdprPackage = [gdprBuilder buildGdprPackage];
    [selfI.packageHandler addPackage:gdprPackage];

    [ADJUserDefaults removeGdprForgetMe];

    if (selfI.adjustConfig.eventBufferingEnabled) {
        [selfI.logger info:@"Buffered gdpr %@", gdprPackage.suffix];
    } else {
        [selfI.packageHandler sendFirstPackage];
    }
}

- (void)setTrackingStateOptedOutI:(ADJActivityHandler *)selfI {
    // In case of web opt out, once response from backend arrives isGdprForgotten field in this moment defaults to NO.
    // Set it to YES regardless of state, since at this moment it should be YES.
    selfI.activityState.isGdprForgotten = YES;
    [selfI writeActivityStateI:selfI];

    [selfI setEnabled:NO];
    [selfI.packageHandler flush];
}

#pragma mark - private

- (BOOL)isEnabledI:(ADJActivityHandler *)selfI {
    if (selfI.activityState != nil) {
        return selfI.activityState.enabled;
    } else {
        return [selfI.internalState isEnabled];
    }
}

- (BOOL)isGdprForgottenI:(ADJActivityHandler *)selfI {
    if (selfI.activityState != nil) {
        return selfI.activityState.isGdprForgotten;
    } else {
        return NO;
    }
}

- (BOOL)itHasToUpdatePackagesI:(ADJActivityHandler *)selfI {
    if (selfI.activityState != nil) {
        return selfI.activityState.updatePackages;
    } else {
        return [selfI.internalState itHasToUpdatePackages];
    }
}

// returns whether or not the activity state should be written
- (BOOL)updateActivityStateI:(ADJActivityHandler *)selfI
                         now:(double)now {
    if (![selfI checkActivityStateI:selfI]) return NO;

    double lastInterval = now - selfI.activityState.lastActivity;

    // ignore late updates
    if (lastInterval > kSessionInterval) return NO;

    selfI.activityState.lastActivity = now;

    if (lastInterval < 0) {
        [selfI.logger error:@"Time travel!"];
        return YES;
    } else {
        selfI.activityState.sessionLength += lastInterval;
        selfI.activityState.timeSpent += lastInterval;
    }

    return YES;
}

- (void)writeActivityStateI:(ADJActivityHandler *)selfI
{
    @synchronized ([ADJActivityState class]) {
        if (selfI.activityState == nil) {
            return;
        }
        [ADJUtil writeObject:selfI.activityState fileName:kActivityStateFilename objectName:@"Activity state"];
    }
}

- (void)teardownActivityStateS
{
    @synchronized ([ADJActivityState class]) {
        if (self.activityState == nil) {
            return;
        }
        self.activityState = nil;
    }
}

- (void)writeAttributionI:(ADJActivityHandler *)selfI {
    @synchronized ([ADJAttribution class]) {
        if (selfI.attribution == nil) {
            return;
        }
        [ADJUtil writeObject:selfI.attribution fileName:kAttributionFilename objectName:@"Attribution"];
    }
}

- (void)teardownAttributionS
{
    @synchronized ([ADJAttribution class]) {
        if (self.attribution == nil) {
            return;
        }
        self.attribution = nil;
    }
}

- (void)readActivityState {
    [NSKeyedUnarchiver setClass:[ADJActivityState class] forClassName:@"AIActivityState"];
    self.activityState = [ADJUtil readObject:kActivityStateFilename
                                  objectName:@"Activity state"
                                       class:[ADJActivityState class]];
}

- (void)readAttribution {
    self.attribution = [ADJUtil readObject:kAttributionFilename
                                objectName:@"Attribution"
                                     class:[ADJAttribution class]];
}

- (void)writeSessionCallbackParametersI:(ADJActivityHandler *)selfI {
    @synchronized ([ADJSessionParameters class]) {
        if (selfI.sessionParameters == nil) {
            return;
        }
        [ADJUtil writeObject:selfI.sessionParameters.callbackParameters
                    fileName:kSessionCallbackParametersFilename
                  objectName:@"Session Callback parameters"];
    }
}

- (void)writeSessionPartnerParametersI:(ADJActivityHandler *)selfI {
    @synchronized ([ADJSessionParameters class]) {
        if (selfI.sessionParameters == nil) {
            return;
        }
        [ADJUtil writeObject:selfI.sessionParameters.partnerParameters
                    fileName:kSessionPartnerParametersFilename
                  objectName:@"Session Partner parameters"];
    }
}

- (void)teardownAllSessionParametersS {
    @synchronized ([ADJSessionParameters class]) {
        if (self.sessionParameters == nil) {
            return;
        }
        [self.sessionParameters.callbackParameters removeAllObjects];
        [self.sessionParameters.partnerParameters removeAllObjects];
        self.sessionParameters = nil;
    }
}

- (void)readSessionCallbackParametersI:(ADJActivityHandler *)selfI {
    selfI.sessionParameters.callbackParameters = [ADJUtil readObject:kSessionCallbackParametersFilename
                                                         objectName:@"Session Callback parameters"
                                                              class:[NSDictionary class]];
}

- (void)readSessionPartnerParametersI:(ADJActivityHandler *)selfI {
    selfI.sessionParameters.partnerParameters = [ADJUtil readObject:kSessionPartnerParametersFilename
                                                        objectName:@"Session Partner parameters"
                                                             class:[NSDictionary class]];
}

# pragma mark - handlers status
- (void)updateHandlersStatusAndSendI:(ADJActivityHandler *)selfI {
    // check if it should stop sending
    if (![selfI toSendI:selfI]) {
        [selfI pauseSendingI:selfI];
        return;
    }

    [selfI resumeSendingI:selfI];

    // try to send if it's the first launch and it hasn't received the session response
    //  even if event buffering is enabled
    if ([selfI.internalState isFirstLaunch] &&
        [selfI.internalState hasSessionResponseNotBeenProcessed])
    {
        [selfI.packageHandler sendFirstPackage];
    }

    // try to send
    if (!selfI.adjustConfig.eventBufferingEnabled) {
        [selfI.packageHandler sendFirstPackage];
    }
}

- (void)pauseSendingI:(ADJActivityHandler *)selfI {
    [selfI.attributionHandler pauseSending];
    [selfI.packageHandler pauseSending];
    // the conditions to pause the sdk click handler are less restrictive
    // it's possible for the sdk click handler to be active while others are paused
    if (![selfI toSendI:selfI sdkClickHandlerOnly:YES]) {
        [selfI.sdkClickHandler pauseSending];
    } else {
        [selfI.sdkClickHandler resumeSending];
    }
}

- (void)resumeSendingI:(ADJActivityHandler *)selfI {
    [selfI.attributionHandler resumeSending];
    [selfI.packageHandler resumeSending];
    [selfI.sdkClickHandler resumeSending];
}

- (BOOL)pausedI:(ADJActivityHandler *)selfI {
    return [selfI pausedI:selfI sdkClickHandlerOnly:NO];
}

- (BOOL)pausedI:(ADJActivityHandler *)selfI
sdkClickHandlerOnly:(BOOL)sdkClickHandlerOnly
{
    if (sdkClickHandlerOnly) {
        // sdk click handler is paused if either:
        return [selfI.internalState isOffline] ||    // it's offline
         ![selfI isEnabledI:selfI];                  // is disabled
    }
    // other handlers are paused if either:
    return [selfI.internalState isOffline] ||        // it's offline
            ![selfI isEnabledI:selfI] ||             // is disabled
            [selfI.internalState isInDelayedStart];      // is in delayed start
}

- (BOOL)toSendI:(ADJActivityHandler *)selfI {
    return [selfI toSendI:selfI sdkClickHandlerOnly:NO];
}

- (BOOL)toSendI:(ADJActivityHandler *)selfI
sdkClickHandlerOnly:(BOOL)sdkClickHandlerOnly
{
    // don't send when it's paused
    if ([selfI pausedI:selfI sdkClickHandlerOnly:sdkClickHandlerOnly]) {
        return NO;
    }

    // has the option to send in the background -> is to send
    if (selfI.adjustConfig.sendInBackground) {
        return YES;
    }

    // doesn't have the option -> depends on being on the background/foreground
    return [selfI.internalState isInForeground];
}

- (void)setAskingAttributionI:(ADJActivityHandler *)selfI
            askingAttribution:(BOOL)askingAttribution
{
    selfI.activityState.askingAttribution = askingAttribution;
    [selfI writeActivityStateI:selfI];
}

# pragma mark - timer
- (void)startForegroundTimerI:(ADJActivityHandler *)selfI {
    // don't start the timer when it's disabled
    if (![selfI isEnabledI:selfI]) {
        return;
    }

    [selfI.foregroundTimer resume];
}

- (void)stopForegroundTimerI:(ADJActivityHandler *)selfI {
    [selfI.foregroundTimer suspend];
}

- (void)foregroundTimerFiredI:(ADJActivityHandler *)selfI {
    // stop the timer cycle when it's disabled
    if (![selfI isEnabledI:selfI]) {
        [selfI stopForegroundTimerI:selfI];
        return;
    }

    if ([selfI toSendI:selfI]) {
        [selfI.packageHandler sendFirstPackage];
    }

    double now = [NSDate.date timeIntervalSince1970];
    if ([selfI updateActivityStateI:selfI now:now]) {
        [selfI writeActivityStateI:selfI];
    }
}

- (void)startBackgroundTimerI:(ADJActivityHandler *)selfI {
    if (selfI.backgroundTimer == nil) {
        return;
    }

    // check if it can send in the background
    if (![selfI toSendI:selfI]) {
        return;
    }

    // background timer already started
    if ([selfI.backgroundTimer fireIn] > 0) {
        return;
    }

    [selfI.backgroundTimer startIn:kBackgroundTimerInterval];
}

- (void)stopBackgroundTimerI:(ADJActivityHandler *)selfI {
    if (selfI.backgroundTimer == nil) {
        return;
    }

    [selfI.backgroundTimer cancel];
}

- (void)backgroundTimerFiredI:(ADJActivityHandler *)selfI {
    if ([selfI toSendI:selfI]) {
        [selfI.packageHandler sendFirstPackage];
    }
}

#pragma mark - delay
- (void)delayStartI:(ADJActivityHandler *)selfI {
    // it's not configured to start delayed or already finished
    if ([selfI.internalState isNotInDelayedStart]) {
        return;
    }

    // the delay has already started
    if ([selfI itHasToUpdatePackagesI:selfI]) {
        return;
    }

    // check against max start delay
    double delayStart = selfI.adjustConfig.delayStart;
    double maxDelayStart = [ADJAdjustFactory maxDelayStart];

    if (delayStart > maxDelayStart) {
        NSString * delayStartFormatted = [ADJUtil secondsNumberFormat:delayStart];
        NSString * maxDelayStartFormatted = [ADJUtil secondsNumberFormat:maxDelayStart];

        [selfI.logger warn:@"Delay start of %@ seconds bigger than max allowed value of %@ seconds", delayStartFormatted, maxDelayStartFormatted];
        delayStart = maxDelayStart;
    }

    NSString * delayStartFormatted = [ADJUtil secondsNumberFormat:delayStart];
    [selfI.logger info:@"Waiting %@ seconds before starting first session", delayStartFormatted];

    [selfI.delayStartTimer startIn:delayStart];

    selfI.internalState.updatePackages = YES;

    if (selfI.activityState != nil) {
        selfI.activityState.updatePackages = YES;
        [selfI writeActivityStateI:selfI];
    }
}

- (void)sendFirstPackagesI:(ADJActivityHandler *)selfI {
    if ([selfI.internalState isNotInDelayedStart]) {
        [selfI.logger info:@"Start delay expired or never configured"];
        return;
    }
    // update packages in queue
    [selfI updatePackagesI:selfI];
    // no longer is in delay start
    selfI.internalState.delayStart = NO;
    // cancel possible still running timer if it was called by user
    [selfI.delayStartTimer cancel];
    // and release timer
    selfI.delayStartTimer = nil;
    // update the status and try to send first package
    [selfI updateHandlersStatusAndSendI:selfI];
}

- (void)updatePackagesI:(ADJActivityHandler *)selfI {
    // update activity packages
    [selfI.packageHandler updatePackages:selfI.sessionParameters];
    // no longer needs to update packages
    selfI.internalState.updatePackages = NO;
    if (selfI.activityState != nil) {
        selfI.activityState.updatePackages = NO;
        [selfI writeActivityStateI:selfI];
    }
}

#pragma mark - session parameters
- (void)addSessionCallbackParameterI:(ADJActivityHandler *)selfI
                                 key:(NSString *)key
                              value:(NSString *)value
{
    if (![ADJUtil isValidParameter:key
                  attributeType:@"key"
                  parameterName:@"Session Callback"]) return;

    if (![ADJUtil isValidParameter:value
                  attributeType:@"value"
                  parameterName:@"Session Callback"]) return;

    if (selfI.sessionParameters.callbackParameters == nil) {
        selfI.sessionParameters.callbackParameters = [NSMutableDictionary dictionary];
    }

    NSString * oldValue = [selfI.sessionParameters.callbackParameters objectForKey:key];

    if (oldValue != nil) {
        if ([oldValue isEqualToString:value]) {
            [selfI.logger verbose:@"Key %@ already present with the same value", key];
            return;
        }
        [selfI.logger warn:@"Key %@ will be overwritten", key];
    }

    [selfI.sessionParameters.callbackParameters setObject:value forKey:key];

    [selfI writeSessionCallbackParametersI:selfI];
}

- (void)addSessionPartnerParameterI:(ADJActivityHandler *)selfI
                               key:(NSString *)key
                             value:(NSString *)value
{
    if (![ADJUtil isValidParameter:key
                     attributeType:@"key"
                     parameterName:@"Session Partner"]) return;

    if (![ADJUtil isValidParameter:value
                     attributeType:@"value"
                     parameterName:@"Session Partner"]) return;

    if (selfI.sessionParameters.partnerParameters == nil) {
        selfI.sessionParameters.partnerParameters = [NSMutableDictionary dictionary];
    }

    NSString * oldValue = [selfI.sessionParameters.partnerParameters objectForKey:key];

    if (oldValue != nil) {
        if ([oldValue isEqualToString:value]) {
            [selfI.logger verbose:@"Key %@ already present with the same value", key];
            return;
        }
        [selfI.logger warn:@"Key %@ will be overwritten", key];
    }


    [selfI.sessionParameters.partnerParameters setObject:value forKey:key];

    [selfI writeSessionPartnerParametersI:selfI];
}

- (void)removeSessionCallbackParameterI:(ADJActivityHandler *)selfI
                                    key:(NSString *)key {
    if (![ADJUtil isValidParameter:key
                     attributeType:@"key"
                     parameterName:@"Session Callback"]) return;

    if (selfI.sessionParameters.callbackParameters == nil) {
        [selfI.logger warn:@"Session Callback parameters are not set"];
        return;
    }

    NSString * oldValue = [selfI.sessionParameters.callbackParameters objectForKey:key];
    if (oldValue == nil) {
        [selfI.logger warn:@"Key %@ does not exist", key];
        return;
    }

    [selfI.logger debug:@"Key %@ will be removed", key];
    [selfI.sessionParameters.callbackParameters removeObjectForKey:key];
    [selfI writeSessionCallbackParametersI:selfI];
}

- (void)removeSessionPartnerParameterI:(ADJActivityHandler *)selfI
                                   key:(NSString *)key {
    if (![ADJUtil isValidParameter:key
                     attributeType:@"key"
                     parameterName:@"Session Partner"]) return;

    if (selfI.sessionParameters.partnerParameters == nil) {
        [selfI.logger warn:@"Session Partner parameters are not set"];
        return;
    }

    NSString * oldValue = [selfI.sessionParameters.partnerParameters objectForKey:key];
    if (oldValue == nil) {
        [selfI.logger warn:@"Key %@ does not exist", key];
        return;
    }

    [selfI.logger debug:@"Key %@ will be removed", key];
    [selfI.sessionParameters.partnerParameters removeObjectForKey:key];
    [selfI writeSessionPartnerParametersI:selfI];
}

- (void)resetSessionCallbackParametersI:(ADJActivityHandler *)selfI {
    if (selfI.sessionParameters.callbackParameters == nil) {
        [selfI.logger warn:@"Session Callback parameters are not set"];
        return;
    }
    selfI.sessionParameters.callbackParameters = nil;
    [selfI writeSessionCallbackParametersI:selfI];
}

- (void)resetSessionPartnerParametersI:(ADJActivityHandler *)selfI {
    if (selfI.sessionParameters.partnerParameters == nil) {
        [selfI.logger warn:@"Session Partner parameters are not set"];
        return;
    }
    selfI.sessionParameters.partnerParameters = nil;
    [selfI writeSessionPartnerParametersI:selfI];
}

- (void)preLaunchActionsI:(ADJActivityHandler *)selfI
    preLaunchActionsArray:(NSArray*)preLaunchActionsArray
{
    if (preLaunchActionsArray == nil) {
        return;
    }
    for (activityHandlerBlockI activityHandlerActionI in preLaunchActionsArray) {
        activityHandlerActionI(selfI);
    }
}

#pragma mark - notifications
- (void)addNotificationObserver {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;

    [center removeObserver:self];
    [center addObserver:self
               selector:@selector(applicationDidBecomeActive)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(applicationWillResignActive)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(removeNotificationObserver)
                   name:UIApplicationWillTerminateNotification
                 object:nil];
}

- (void)removeNotificationObserver {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - checks

- (BOOL)checkTransactionIdI:(ADJActivityHandler *)selfI
              transactionId:(NSString *)transactionId {
    if (transactionId == nil || transactionId.length == 0) {
        return YES; // no transaction ID given
    }

    if ([selfI.activityState findTransactionId:transactionId]) {
        [selfI.logger info:@"Skipping duplicate transaction ID '%@'", transactionId];
        [selfI.logger verbose:@"Found transaction ID in %@", selfI.activityState.transactionIds];
        return NO; // transaction ID found -> used already
    }
    
    [selfI.activityState addTransactionId:transactionId];
    [selfI.logger verbose:@"Added transaction ID %@", selfI.activityState.transactionIds];
    // activity state will get written by caller
    return YES;
}

- (BOOL)checkEventI:(ADJActivityHandler *)selfI
              event:(ADJEvent *)event {
    if (event == nil) {
        [selfI.logger error:@"Event missing"];
        return NO;
    }

    if (![event isValid]) {
        [selfI.logger error:@"Event not initialized correctly"];
        return NO;
    }

    return YES;
}

- (BOOL)checkActivityStateI:(ADJActivityHandler *)selfI {
    if (selfI.activityState == nil) {
        [selfI.logger error:@"Missing activity state"];
        return NO;
    }
    return YES;
}
@end
