//
//  ADJActivityHandler.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-01.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJActivityPackage.h"
#import "ADJActivityHandler.h"
#import "ADJActivityState.h"
#import "ADJPackageBuilder.h"
#import "ADJPackageHandler.h"
#import "ADJLogger.h"
#import "ADJTimerCycle.h"
#import "ADJUtil.h"
#import "UIDevice+ADJAdditions.h"
#import "ADJAdjustFactory.h"
#import "ADJAttributionHandler.h"

static NSString   * const kActivityStateFilename = @"AdjustIoActivityState";
static NSString   * const kAttributionFilename   = @"AdjustIoAttribution";
static NSString   * const kAdjustPrefix          = @"adjust_";
static const char * const kInternalQueueName     = "io.adjust.ActivityQueue";

#pragma mark -
@interface ADJActivityHandler()

@property (nonatomic) dispatch_queue_t internalQueue;
@property (nonatomic, retain) id<ADJPackageHandler> packageHandler;
@property (nonatomic, retain) id<ADJAttributionHandler> attributionHandler;
@property (nonatomic, retain) ADJActivityState *activityState;
@property (nonatomic, retain) ADJTimerCycle *timer;
@property (nonatomic, retain) id<ADJLogger> logger;
@property (nonatomic, weak) NSObject<AdjustDelegate> *delegate;
@property (nonatomic, copy) ADJAttribution *attribution;
@property (nonatomic, copy) ADJConfig *adjustConfig;

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL offline;

@property (nonatomic, copy) ADJDeviceInfo* deviceInfo;

@end

#pragma mark -
@implementation ADJActivityHandler

+ (id<ADJActivityHandler>)handlerWithConfig:(ADJConfig *)adjustConfig {
    return [[ADJActivityHandler alloc] initWithConfig:adjustConfig];
}


- (id)initWithConfig:(ADJConfig *)adjustConfig {
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
    self.delegate = adjustConfig.delegate;

    self.logger = ADJAdjustFactory.logger;
    [self addNotificationObserver];
    self.internalQueue = dispatch_queue_create(kInternalQueueName, DISPATCH_QUEUE_SERIAL);
    _enabled = YES;

    dispatch_async(self.internalQueue, ^{
        [self initInternal];
    });

    return self;
}

- (void)trackSubsessionStart {
    dispatch_async(self.internalQueue, ^{
        [self startInternal];
    });
}

- (void)trackSubsessionEnd {
    dispatch_async(self.internalQueue, ^{
        [self endInternal];
    });
}

- (void)trackEvent:(ADJEvent *)event
{
    dispatch_async(self.internalQueue, ^{
        [self eventInternal:event];
    });
}

- (void)finishedTracking:(NSDictionary *)jsonDict{
    if ([ADJUtil isNull:jsonDict]) return;

    [self launchDeepLink:jsonDict];
    [self.attributionHandler checkAttribution:jsonDict];
}

- (void)launchDeepLink:(NSDictionary *)jsonDict{
    if ([ADJUtil isNull:jsonDict]) return;

    NSString *deepLink = [jsonDict objectForKey:@"deeplink"];
    if (deepLink == nil) return;

    NSURL* deepLinkUrl = [NSURL URLWithString:deepLink];

    [self.logger info:@"Open deep link (%@)", deepLink];

    BOOL success = [[UIApplication sharedApplication] openURL:deepLinkUrl];

    if (!success) {
        [self.logger error:@"Unable to open deep link (%@)", deepLink];
    }
}

- (void)setEnabled:(BOOL)enabled {
    if (![self hasChangedState:[self isEnabled]
                     nextState:enabled
                   trueMessage:@"Adjust already enabled"
                  falseMessage:@"Adjust already disabled"])
    {
        return;
    }

    _enabled = enabled;
    if (self.activityState != nil) {
        self.activityState.enabled = enabled;
        [self writeActivityState];
    }

    [self updateState:!enabled
       pausingMessage:@"Pausing package handler and attribution handler to disable the SDK"
 remainsPausedMessage:@"Package and attribution handler remain paused due to the SDK is offline"
     unPausingMessage:@"Resuming package handler and attribution handler to enabled the SDK"];
}

- (void)setOfflineMode:(BOOL)offline {
    if (![self hasChangedState:self.offline
                     nextState:offline
                   trueMessage:@"Adjust already in offline mode"
                  falseMessage:@"Adjust already in online mode"])
    {
        return;
    }

    self.offline = offline;

    [self updateState:offline
       pausingMessage:@"Pausing package and attribution handler to put in offline mode"
 remainsPausedMessage:@"Package and attribution handler remain paused because the SDK is disabled"
     unPausingMessage:@"Resuming package handler and attribution handler to put in online mode"];
}

- (BOOL)isEnabled {
    if (self.activityState != nil) {
        return self.activityState.enabled;
    } else {
        return _enabled;
    }
}

- (BOOL)hasChangedState:(BOOL)previousState
              nextState:(BOOL)nextState
            trueMessage:(NSString *)trueMessage
           falseMessage:(NSString *)falseMessage
{
    if (previousState != nextState) {
        return YES;
    }

    if (previousState) {
        [self.logger debug:trueMessage];
    } else {
        [self.logger debug:falseMessage];
    }

    return NO;
}

- (void)updateState:(BOOL)pausingState
     pausingMessage:(NSString *)pausingMessage
remainsPausedMessage:(NSString *)remainsPausedMessage
   unPausingMessage:(NSString *)unPausingMessage
{
    if (pausingState) {
        [self.logger info:pausingMessage];
        [self trackSubsessionEnd];
        return;
    }

    if ([self paused]) {
        [self.logger info:remainsPausedMessage];
    } else {
        [self.logger info:unPausingMessage];
        [self trackSubsessionStart];
    }
}

- (void)appWillOpenUrl:(NSURL*)url {
    dispatch_async(self.internalQueue, ^{
        [self appWillOpenUrlInternal:url];
    });
}

- (void)setDeviceToken:(NSData *)deviceToken {
    dispatch_async(self.internalQueue, ^{
        [self setDeviceTokenInternal:deviceToken];
    });
}

- (void)setIadDate:(NSDate *)iAdImpressionDate withPurchaseDate:(NSDate *)appPurchaseDate {
    if (iAdImpressionDate == nil) {
        return;
    }

    double now = [NSDate.date timeIntervalSince1970];
    ADJPackageBuilder *clickBuilder = [[ADJPackageBuilder alloc]
                                       initWithDeviceInfo:self.deviceInfo
                                       activityState:self.activityState
                                       config:self.adjustConfig
                                       createdAt:now];

    [clickBuilder setPurchaseTime:appPurchaseDate];

    ADJActivityPackage *clickPackage = [clickBuilder buildClickPackage:@"iad" clickTime:iAdImpressionDate];
    [self.packageHandler addPackage:clickPackage];
}

- (BOOL)updateAttribution:(ADJAttribution *)attribution {
    if (attribution == nil) {
        return NO;
    }
    if ([attribution isEqual:self.attribution]) {
        return NO;
    }
    self.attribution = attribution;
    [self writeAttribution];

    [self launchAttributionDelegate];

    return YES;
}

- (void)launchAttributionDelegate{
    if (self.delegate == nil) {
        return;
    }
    if (![self.delegate respondsToSelector:@selector(adjustAttributionChanged:)]) {
        return;
    }
    [self.delegate performSelectorOnMainThread:@selector(adjustAttributionChanged:)
                                    withObject:self.attribution waitUntilDone:NO];
}

- (void)setAskingAttribution:(BOOL)askingAttribution {
    self.activityState.askingAttribution = askingAttribution;
    [self writeActivityState];
}

- (void)updateStatus {
    dispatch_async(self.internalQueue, ^{
        [self updateStatusInternal];
    });
}

#pragma mark - internal
- (void)initInternal {
    self.deviceInfo = [ADJDeviceInfo deviceInfoWithSdkPrefix:self.adjustConfig.sdkPrefix];

    if ([self.adjustConfig.environment isEqualToString:ADJEnvironmentProduction]) {
        [self.logger setLogLevel:ADJLogLevelAssert];
    } else {
        [self.logger setLogLevel:self.adjustConfig.logLevel];
    }

    if (!self.adjustConfig.macMd5TrackingEnabled) {
        [self.logger info:@"Tracking of macMd5 is disabled"];
    }

    if (self.adjustConfig.eventBufferingEnabled)  {
        [self.logger info:@"Event buffering is enabled"];
    }

    if (self.adjustConfig.defaultTracker != nil) {
        [self.logger info:@"Default tracker: %@", self.adjustConfig.defaultTracker];
    }

    [self readAttribution];
    [self readActivityState];

    self.packageHandler = [ADJAdjustFactory packageHandlerForActivityHandler:self
                                                                 startPaused:[self paused]];

    double now = [NSDate.date timeIntervalSince1970];
    ADJPackageBuilder *attributionBuilder = [[ADJPackageBuilder alloc]
                                             initWithDeviceInfo:self.deviceInfo
                                             activityState:self.activityState
                                             config:self.adjustConfig
                                             createdAt:now];
    ADJActivityPackage *attributionPackage = [attributionBuilder buildAttributionPackage];
    self.attributionHandler = [ADJAdjustFactory attributionHandlerForActivityHandler:self
                                                              withAttributionPackage:attributionPackage
                                                                         startPaused:[self paused]
                                                                         hasDelegate:(self.delegate != nil)];

    self.timer = [ADJTimerCycle timerWithBlock:^{ [self timerFiredInternal]; }
                                    queue:self.internalQueue
                                startTime:ADJAdjustFactory.timerStart
                             intervalTime:ADJAdjustFactory.timerInterval];

    [[UIDevice currentDevice] adjSetIad:self];

    [self startInternal];
}

- (void)startInternal {
    // it shouldn't start if it was disabled after a first session
    if (self.activityState != nil
        && !self.activityState.enabled) {
        return;
    }

    [self updateStatusInternal];

    [self processSession];

    [self checkAttributionState];

    [self startTimer];
}

- (void)processSession {
    double now = [NSDate.date timeIntervalSince1970];

    // very first session
    if (self.activityState == nil) {
        self.activityState = [[ADJActivityState alloc] init];
        self.activityState.sessionCount = 1; // this is the first session

        [self transferSessionPackage:now];
        [self.activityState resetSessionAttributes:now];
        self.activityState.enabled = _enabled;
        [self writeActivityState];
        return;
    }

    double lastInterval = now - self.activityState.lastActivity;
    if (lastInterval < 0) {
        [self.logger error:@"Time travel!"];
        self.activityState.lastActivity = now;
        [self writeActivityState];
        return;
    }

    // new session
    if (lastInterval > ADJAdjustFactory.sessionInterval) {
        self.activityState.sessionCount++;
        self.activityState.lastInterval = lastInterval;

        [self transferSessionPackage:now];
        [self.activityState resetSessionAttributes:now];
        [self writeActivityState];
        return;
    }

    // new subsession
    if (lastInterval > ADJAdjustFactory.subsessionInterval) {
        self.activityState.subsessionCount++;
        self.activityState.sessionLength += lastInterval;
        self.activityState.lastActivity = now;
        [self writeActivityState];
        [self.logger info:@"Started subsession %d of session %d",
         self.activityState.subsessionCount,
         self.activityState.sessionCount];
    }
}

- (void)checkAttributionState {
    // if it' a new session
    if (self.activityState.subsessionCount <= 1) {
        return;
    }

    // if there is already an attribution saved and there was no attribution being asked
    if (self.attribution != nil && !self.activityState.askingAttribution) {
        return;
    }

    [self.attributionHandler getAttribution];
}

- (void)endInternal {
    [self.packageHandler pauseSending];
    [self.attributionHandler pauseSending];
    [self stopTimer];
    double now = [NSDate.date timeIntervalSince1970];
    [self updateActivityState:now];
    [self writeActivityState];
}

- (void)eventInternal:(ADJEvent *)event
{
    if (![self isEnabled]) return;
    if (![self checkEvent:event]) return;
    if (![self checkTransactionId:event.transactionId]) return;

    double now = [NSDate.date timeIntervalSince1970];

    self.activityState.eventCount++;
    [self updateActivityState:now];

    // create and populate event package
    ADJPackageBuilder *eventBuilder = [[ADJPackageBuilder alloc]
                                       initWithDeviceInfo:self.deviceInfo
                                       activityState:self.activityState
                                       config:self.adjustConfig
                                       createdAt:now];
    ADJActivityPackage *eventPackage = [eventBuilder buildEventPackage:event];
    [self.packageHandler addPackage:eventPackage];

    if (self.adjustConfig.eventBufferingEnabled) {
        [self.logger info:@"Buffered event %@", eventPackage.suffix];
    } else {
        [self.packageHandler sendFirstPackage];
    }

    [self writeActivityState];
}

- (void) appWillOpenUrlInternal:(NSURL *)url {
    if ([ADJUtil isNull:url]) {
        return;
    }

    NSArray* queryArray = [url.query componentsSeparatedByString:@"&"];
    if (queryArray == nil) {
        return;
    }

    NSMutableDictionary* adjustDeepLinks = [NSMutableDictionary dictionary];
    ADJAttribution *deeplinkAttribution = [[ADJAttribution alloc] init];
    BOOL hasDeepLink = NO;

    for (NSString* fieldValuePair in queryArray) {
        if([self readDeeplinkQueryString:fieldValuePair adjustDeepLinks:adjustDeepLinks attribution:deeplinkAttribution]) {
            hasDeepLink = YES;
        }
    }

    if (!hasDeepLink) {
        return;
    }

    double now = [NSDate.date timeIntervalSince1970];
    ADJPackageBuilder *clickBuilder = [[ADJPackageBuilder alloc]
                                       initWithDeviceInfo:self.deviceInfo
                                       activityState:self.activityState
                                       config:self.adjustConfig
                                       createdAt:now];
    clickBuilder.deeplinkParameters = adjustDeepLinks;
    clickBuilder.attribution = deeplinkAttribution;

    ADJActivityPackage *clickPackage = [clickBuilder buildClickPackage:@"deeplink" clickTime:[NSDate date]];
    [self.packageHandler addPackage:clickPackage];
}

- (BOOL) readDeeplinkQueryString:(NSString *)queryString
                 adjustDeepLinks:(NSMutableDictionary*)adjustDeepLinks
                     attribution:(ADJAttribution *)deeplinkAttribution
{
    NSArray* pairComponents = [queryString componentsSeparatedByString:@"="];
    if (pairComponents.count != 2) return NO;

    NSString* key = [pairComponents objectAtIndex:0];
    if (![key hasPrefix:kAdjustPrefix]) return NO;

    NSString* value = [pairComponents objectAtIndex:1];
    if (value.length == 0) return NO;

    NSString* keyWOutPrefix = [key substringFromIndex:kAdjustPrefix.length];
    if (keyWOutPrefix.length == 0) return NO;

    if (![self trySetAttributionDeeplink:deeplinkAttribution withKey:keyWOutPrefix withValue:value]) {
        [adjustDeepLinks setObject:value forKey:keyWOutPrefix];
    }

    return YES;
}

- (BOOL) trySetAttributionDeeplink:(ADJAttribution *)deeplinkAttribution
                           withKey:(NSString *)key
                         withValue:(NSString*)value {

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

- (void) setDeviceTokenInternal:(NSData *)deviceToken {
    if (deviceToken == nil) {
        return;
    }

    NSString *token = [deviceToken.description stringByTrimmingCharactersInSet:
                       [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];

    self.deviceInfo.pushToken = token;
}

#pragma mark - private

// returns whether or not the activity state should be written
- (BOOL)updateActivityState:(double)now {
    double lastInterval = now - self.activityState.lastActivity;

    if (lastInterval < 0) {
        [self.logger error:@"Time travel!"];
        self.activityState.lastActivity = now;
        return YES;
    }

    // ignore late updates
    if (lastInterval > ADJAdjustFactory.sessionInterval) return NO;

    self.activityState.sessionLength += lastInterval;
    self.activityState.timeSpent += lastInterval;
    self.activityState.lastActivity = now;

    return (lastInterval > ADJAdjustFactory.subsessionInterval);
}

- (void)writeActivityState {
    [ADJUtil writeObject:self.activityState filename:kActivityStateFilename objectName:@"Activity state"];
}

- (void)writeAttribution {
    [ADJUtil writeObject:self.attribution filename:kAttributionFilename objectName:@"Attribution"];
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

- (void)transferSessionPackage:(double)now {
    ADJPackageBuilder *sessionBuilder = [[ADJPackageBuilder alloc]
                                         initWithDeviceInfo:self.deviceInfo
                                         activityState:self.activityState
                                         config:self.adjustConfig
                                         createdAt:now];
    ADJActivityPackage *sessionPackage = [sessionBuilder buildSessionPackage];
    [self.packageHandler addPackage:sessionPackage];
    [self.packageHandler sendFirstPackage];
}

# pragma mark - handlers status
- (void)updateStatusInternal {
    [self updateAttributionHandlerStatus];
    [self updatePackageHandlerStatus];
}

- (void)updateAttributionHandlerStatus {
    if ([self paused]) {
        [self.attributionHandler pauseSending];
    } else {
        [self.attributionHandler resumeSending];
    }
}

- (void)updatePackageHandlerStatus {
    if ([self paused]) {
        [self.packageHandler pauseSending];
    } else {
        [self.packageHandler resumeSending];
    }
}

- (BOOL)paused {
    return self.offline || !self.isEnabled;
}

# pragma mark - timer
- (void)startTimer {
    // don't start the timer if it's disabled/offline
    if ([self paused]) {
        return;
    }

    [self.timer resume];
}

- (void)stopTimer {
    [self.timer suspend];
}

- (void)timerFiredInternal {
    if ([self paused]) {
        // stop the timer cycle if it's disabled/offline
        [self stopTimer];
        return;
    }
    [self.logger debug:@"Session timer fired"];
    [self.packageHandler sendFirstPackage];
    double now = [NSDate.date timeIntervalSince1970];
    if ([self updateActivityState:now]) {
        [self writeActivityState];
    }
}

#pragma mark - notifications
- (void)addNotificationObserver {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;

    [center removeObserver:self];
    [center addObserver:self
               selector:@selector(trackSubsessionStart)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(trackSubsessionEnd)
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

- (BOOL)checkTransactionId:(NSString *)transactionId {
    if (transactionId == nil || transactionId.length == 0) {
        return YES; // no transaction ID given
    }

    if ([self.activityState findTransactionId:transactionId]) {
        [self.logger info:@"Skipping duplicate transaction ID '%@'", transactionId];
        [self.logger verbose:@"Found transaction ID in %@", self.activityState.transactionIds];
        return NO; // transaction ID found -> used already
    }
    
    [self.activityState addTransactionId:transactionId];
    [self.logger verbose:@"Added transaction ID %@", self.activityState.transactionIds];
    // activity state will get written by caller
    return YES;
}

- (BOOL)checkEvent:(ADJEvent *)event {
    if (event == nil) {
        [self.logger error:@"Event missing"];
        return NO;
    }

    if (![event isValid]) {
        [self.logger error:@"Event not initialized correctly"];
        return NO;
    }

    return YES;
}

@end
