//
//  ATAAdjustCommandExecutor.m
//  AdjustTestApp
//
//  Created by Pedro Silva (@nonelse) on 23rd August 2017.
//  Copyright © 2017-2018 Adjust GmbH. All rights reserved.
//

#import "Adjust.h"
#import "ADJAdjustFactory.h"
#import "ATAAdjustDelegate.h"
#import "ATAAdjustDelegateAttribution.h"
#import "ATAAdjustDelegateEventFailure.h"
#import "ATAAdjustDelegateEventSuccess.h"
#import "ATAAdjustDelegateSessionSuccess.h"
#import "ATAAdjustDelegateSessionFailure.h"
#import "ATAAdjustDelegateDeferredDeeplink.h"
#import "ATAAdjustCommandExecutor.h"
#import "ViewController.h"

@interface ATAAdjustCommandExecutor ()

@property (nonatomic, copy) NSString *basePath;
@property (nonatomic, copy) NSString *gdprPath;
@property (nonatomic, strong) NSMutableDictionary *savedConfigs;
@property (nonatomic, strong) NSMutableDictionary *savedEvents;
@property (nonatomic, strong) NSObject<AdjustDelegate> *adjustDelegate;

@end

@implementation ATAAdjustCommandExecutor

- (id)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.savedConfigs = [NSMutableDictionary dictionary];
    self.savedEvents = [NSMutableDictionary dictionary];
    self.adjustDelegate = nil;
    self.basePath = nil;
    self.gdprPath = nil;

    return self;
}

- (void)executeCommand:(NSString *)className
            methodName:(NSString *)methodName
            parameters:(NSDictionary *)parameters {
    NSLog(@"executeCommand className: %@, methodName: %@, parameters: %@", className, methodName, parameters);

    if ([methodName isEqualToString:@"testOptions"]) {
        [self testOptions:parameters];
    } else if ([methodName isEqualToString:@"config"]) {
        [self config:parameters];
    } else if ([methodName isEqualToString:@"start"]) {
        [self start:parameters];
    } else if ([methodName isEqualToString:@"event"]) {
        [self event:parameters];
    } else if ([methodName isEqualToString:@"trackEvent"]) {
        [self trackEvent:parameters];
    } else if ([methodName isEqualToString:@"resume"]) {
        [self resume:parameters];
    } else if ([methodName isEqualToString:@"pause"]) {
        [self pause:parameters];
    } else if ([methodName isEqualToString:@"setEnabled"]) {
        [self setEnabled:parameters];
    } else if ([methodName isEqualToString:@"setOfflineMode"]) {
        [self setOfflineMode:parameters];
    } else if ([methodName isEqualToString:@"sendFirstPackages"]) {
        [self sendFirstPackages:parameters];
    } else if ([methodName isEqualToString:@"addSessionCallbackParameter"]) {
        [self addSessionCallbackParameter:parameters];
    } else if ([methodName isEqualToString:@"addSessionPartnerParameter"]) {
        [self addSessionPartnerParameter:parameters];
    } else if ([methodName isEqualToString:@"removeSessionCallbackParameter"]) {
        [self removeSessionCallbackParameter:parameters];
    } else if ([methodName isEqualToString:@"removeSessionPartnerParameter"]) {
        [self removeSessionPartnerParameter:parameters];
    } else if ([methodName isEqualToString:@"resetSessionCallbackParameters"]) {
        [self resetSessionCallbackParameters:parameters];
    } else if ([methodName isEqualToString:@"resetSessionPartnerParameters"]) {
        [self resetSessionPartnerParameters:parameters];
    } else if ([methodName isEqualToString:@"setPushToken"]) {
        [self setPushToken:parameters];
    } else if ([methodName isEqualToString:@"openDeeplink"]) {
        [self openDeeplink:parameters];
    } else if ([methodName isEqualToString:@"gdprForgetMe"]) {
        [self gdprForgetMe:parameters];
    } else if ([methodName isEqualToString:@"trackAdRevenue"]) {
        [self trackAdRevenue:parameters];
    }
}

- (void)testOptions:(NSDictionary *)parameters {
    AdjustTestOptions *testOptions = [[AdjustTestOptions alloc] init];
    testOptions.baseUrl = baseUrl;
    testOptions.gdprUrl = gdprUrl;

    if ([parameters objectForKey:@"basePath"]) {
        self.basePath = [parameters objectForKey:@"basePath"][0];
        self.gdprPath = [parameters objectForKey:@"basePath"][0];
    }
    if ([parameters objectForKey:@"timerInterval"]) {
        NSString *timerIntervalMilliS = [parameters objectForKey:@"timerInterval"][0];
        testOptions.timerIntervalInMilliseconds = [ATAAdjustCommandExecutor convertMilliStringToNumber:timerIntervalMilliS];
    }
    if ([parameters objectForKey:@"timerStart"]) {
        NSString *timerStartMilliS = [parameters objectForKey:@"timerStart"][0];
        testOptions.timerStartInMilliseconds = [ATAAdjustCommandExecutor convertMilliStringToNumber:timerStartMilliS];
    }
    if ([parameters objectForKey:@"sessionInterval"]) {
        NSString *sessionIntervalMilliS = [parameters objectForKey:@"sessionInterval"][0];
        testOptions.sessionIntervalInMilliseconds = [ATAAdjustCommandExecutor convertMilliStringToNumber:sessionIntervalMilliS];
    }
    if ([parameters objectForKey:@"subsessionInterval"]) {
        NSString *subsessionIntervalMilliS = [parameters objectForKey:@"subsessionInterval"][0];
        testOptions.subsessionIntervalInMilliseconds = [ATAAdjustCommandExecutor convertMilliStringToNumber:subsessionIntervalMilliS];
    }
    if ([parameters objectForKey:@"noBackoffWait"]) {
        NSString *noBackoffWaitStr = [parameters objectForKey:@"noBackoffWait"][0];
        testOptions.noBackoffWait = NO;
        if ([noBackoffWaitStr isEqualToString:@"true"]) {
            testOptions.noBackoffWait = YES;
        }
    }
    testOptions.iAdFrameworkEnabled = NO; // default value -> NO - iAd will not be used in test app by default
    if ([parameters objectForKey:@"iAdFrameworkEnabled"]) {
        NSString *iAdFrameworkEnabledStr = [parameters objectForKey:@"iAdFrameworkEnabled"][0];
        if ([iAdFrameworkEnabledStr isEqualToString:@"true"]) {
            testOptions.iAdFrameworkEnabled = YES;
        }
    }
    if ([parameters objectForKey:@"teardown"]) {
        NSArray *teardownOptions = [parameters objectForKey:@"teardown"];
        for (int i = 0; i < teardownOptions.count; i = i + 1) {
            NSString *teardownOption = teardownOptions[i];
            if ([teardownOption isEqualToString:@"resetSdk"]) {
                testOptions.teardown = YES;
                testOptions.basePath = self.basePath;
                testOptions.gdprPath = self.gdprPath;
            }
            if ([teardownOption isEqualToString:@"deleteState"]) {
                testOptions.deleteState = YES;
            }
            if ([teardownOption isEqualToString:@"resetTest"]) {
                self.savedConfigs = [NSMutableDictionary dictionary];
                self.savedEvents = [NSMutableDictionary dictionary];
                testOptions.timerIntervalInMilliseconds = [NSNumber numberWithInt:-1000];
                testOptions.timerStartInMilliseconds = [NSNumber numberWithInt:-1000];
                testOptions.sessionIntervalInMilliseconds = [NSNumber numberWithInt:-1000];
                testOptions.subsessionIntervalInMilliseconds = [NSNumber numberWithInt:-1000];
            }
            if ([teardownOption isEqualToString:@"sdk"]) {
                testOptions.teardown = YES;
                testOptions.basePath = nil;
                testOptions.gdprPath = nil;
            }
            if ([teardownOption isEqualToString:@"test"]) {
                self.savedConfigs = nil;
                self.savedEvents = nil;
                self.adjustDelegate = nil;
                self.basePath = nil;
                self.gdprPath = nil;
                testOptions.timerIntervalInMilliseconds = [NSNumber numberWithInt:-1000];
                testOptions.timerStartInMilliseconds = [NSNumber numberWithInt:-1000];
                testOptions.sessionIntervalInMilliseconds = [NSNumber numberWithInt:-1000];
                testOptions.subsessionIntervalInMilliseconds = [NSNumber numberWithInt:-1000];
            }
        }
    }

    [Adjust setTestOptions:testOptions];
}

+ (NSNumber *)convertMilliStringToNumber:(NSString *)milliS {
    NSNumber * number = [NSNumber numberWithInt:[milliS intValue]];
    return number;
}

- (void)config:(NSDictionary *)parameters {
    NSNumber *configNumber = [NSNumber numberWithInt:0];

    if ([parameters objectForKey:@"configName"]) {
        NSString *configName = [parameters objectForKey:@"configName"][0];
        NSString *configNumberS = [configName substringFromIndex:[configName length] - 1];
        configNumber = [NSNumber numberWithInt:[configNumberS intValue]];
    }

    ADJConfig *adjustConfig = nil;

    if ([self.savedConfigs objectForKey:configNumber]) {
        adjustConfig = [self.savedConfigs objectForKey:configNumber];
    } else {
        NSString *environment = [parameters objectForKey:@"environment"][0];
        NSString *appToken = [parameters objectForKey:@"appToken"][0];

        adjustConfig = [ADJConfig configWithAppToken:appToken environment:environment];
        [self.savedConfigs setObject:adjustConfig forKey:configNumber];
    }

    if ([parameters objectForKey:@"logLevel"]) {
        NSString *logLevelS = [parameters objectForKey:@"logLevel"][0];
        ADJLogLevel logLevel = [ADJLogger logLevelFromString:logLevelS];
        [adjustConfig setLogLevel:logLevel];
    }

    if ([parameters objectForKey:@"sdkPrefix"]) {
        NSString *sdkPrefix;
        if ([[parameters objectForKey:@"sdkPrefix"] count] == 0) {
            sdkPrefix = nil;
        } else {
            sdkPrefix = [parameters objectForKey:@"sdkPrefix"][0];
            if (sdkPrefix == (id)[NSNull null]) {
                sdkPrefix = nil;
            }
        }
        [adjustConfig setSdkPrefix:sdkPrefix];
    }

    if ([parameters objectForKey:@"defaultTracker"]) {
        NSString *defaultTracker;
        if ([[parameters objectForKey:@"defaultTracker"] count] == 0) {
            defaultTracker = nil;
        } else {
            defaultTracker = [parameters objectForKey:@"defaultTracker"][0];
            if (defaultTracker == (id)[NSNull null]) {
                defaultTracker = nil;
            }
        }
        [adjustConfig setDefaultTracker:defaultTracker];
    }

    if ([parameters objectForKey:@"appSecret"]) {
        NSArray *appSecretList = [parameters objectForKey:@"appSecret"];
        if ([appSecretList count] == 5 &&
            [appSecretList[0] length] > 0 &&
            [appSecretList[1] length] > 0 &&
            [appSecretList[2] length] > 0 &&
            [appSecretList[3] length] > 0 &&
            [appSecretList[4] length] > 0) {
            NSUInteger secretId = [appSecretList[0] integerValue];
            NSUInteger part1 = [appSecretList[1] integerValue];
            NSUInteger part2 = [appSecretList[2] integerValue];
            NSUInteger part3 = [appSecretList[3] integerValue];
            NSUInteger part4 = [appSecretList[4] integerValue];

            [adjustConfig setAppSecret:secretId info1:part1 info2:part2 info3:part3 info4:part4];
        }
    }

    if ([parameters objectForKey:@"delayStart"]) {
        NSString *delayStartS = [parameters objectForKey:@"delayStart"][0];
        double delayStart = [delayStartS doubleValue];
        [adjustConfig setDelayStart:delayStart];
    }

    if ([parameters objectForKey:@"deviceKnown"]) {
        NSString *deviceKnownS = [parameters objectForKey:@"deviceKnown"][0];
        [adjustConfig setIsDeviceKnown:[deviceKnownS boolValue]];
    }

    if ([parameters objectForKey:@"eventBufferingEnabled"]) {
        NSString *eventBufferingEnabledS = [parameters objectForKey:@"eventBufferingEnabled"][0];
        [adjustConfig setEventBufferingEnabled:[eventBufferingEnabledS boolValue]];
    }

    if ([parameters objectForKey:@"sendInBackground"]) {
        NSString *sendInBackgroundS = [parameters objectForKey:@"sendInBackground"][0];
        [adjustConfig setSendInBackground:[sendInBackgroundS boolValue]];
    }

    if ([parameters objectForKey:@"userAgent"]) {
        NSString *userAgent = [parameters objectForKey:@"userAgent"][0];
        [adjustConfig setUserAgent:userAgent];
    }

    if ([parameters objectForKey:@"attributionCallbackSendAll"]) {
        NSLog(@"attributionCallbackSendAll detected");
        self.adjustDelegate = [[ATAAdjustDelegateAttribution alloc] initWithTestLibrary:self.testLibrary
                                                                            andBasePath:self.basePath];
    }
    
    if ([parameters objectForKey:@"sessionCallbackSendSuccess"]) {
        NSLog(@"sessionCallbackSendSuccess detected");
        self.adjustDelegate = [[ATAAdjustDelegateSessionSuccess alloc] initWithTestLibrary:self.testLibrary
                                                                               andBasePath:self.basePath];
    }
    
    if ([parameters objectForKey:@"sessionCallbackSendFailure"]) {
        NSLog(@"sessionCallbackSendFailure detected");
        self.adjustDelegate = [[ATAAdjustDelegateSessionFailure alloc] initWithTestLibrary:self.testLibrary
                                                                               andBasePath:self.basePath];
    }
    
    if ([parameters objectForKey:@"eventCallbackSendSuccess"]) {
        NSLog(@"eventCallbackSendSuccess detected");
        self.adjustDelegate = [[ATAAdjustDelegateEventSuccess alloc] initWithTestLibrary:self.testLibrary
                                                                             andBasePath:self.basePath];
    }
    
    if ([parameters objectForKey:@"eventCallbackSendFailure"]) {
        NSLog(@"eventCallbackSendFailure detected");
        self.adjustDelegate = [[ATAAdjustDelegateEventFailure alloc] initWithTestLibrary:self.testLibrary
                                                                             andBasePath:self.basePath];
    }

    if ([parameters objectForKey:@"deferredDeeplinkCallback"]) {
        NSLog(@"deferredDeeplinkCallback detected");
        NSString *shouldOpenDeeplinkS = [parameters objectForKey:@"deferredDeeplinkCallback"][0];
        self.adjustDelegate = [[ATAAdjustDelegateDeferredDeeplink alloc] initWithTestLibrary:self.testLibrary
                                                                                    basePath:self.basePath
                                                                              andReturnValue:[shouldOpenDeeplinkS boolValue]];
    }

    [adjustConfig setDelegate:self.adjustDelegate];
}

- (void)start:(NSDictionary *)parameters {
    [self config:parameters];

    NSNumber *configNumber = [NSNumber numberWithInt:0];
    if ([parameters objectForKey:@"configName"]) {
        NSString *configName = [parameters objectForKey:@"configName"][0];
        NSString *configNumberS = [configName substringFromIndex:[configName length] - 1];
        configNumber = [NSNumber numberWithInt:[configNumberS intValue]];
    }

    ADJConfig *adjustConfig = [self.savedConfigs objectForKey:configNumber];
    [Adjust appDidLaunch:adjustConfig];
    [self.savedConfigs removeObjectForKey:[NSNumber numberWithInt:0]];
}

- (void)event:(NSDictionary *)parameters {
    NSNumber *eventNumber = [NSNumber numberWithInt:0];
    if ([parameters objectForKey:@"eventName"]) {
        NSString *eventName = [parameters objectForKey:@"eventName"][0];
        NSString *eventNumberS = [eventName substringFromIndex:[eventName length] - 1];
        eventNumber = [NSNumber numberWithInt:[eventNumberS intValue]];
    }

    ADJEvent *adjustEvent = nil;

    if ([self.savedEvents objectForKey:eventNumber]) {
        adjustEvent = [self.savedEvents objectForKey:eventNumber];
    } else {
        NSString *eventToken;
        if ([[parameters objectForKey:@"eventToken"] count] == 0) {
            eventToken = nil;
        } else {
            eventToken = [parameters objectForKey:@"eventToken"][0];
        }
        adjustEvent = [ADJEvent eventWithEventToken:eventToken];
        [self.savedEvents setObject:adjustEvent forKey:eventNumber];
    }

    if ([parameters objectForKey:@"revenue"]) {
        NSArray *currencyAndRevenue = [parameters objectForKey:@"revenue"];
        NSString *currency = currencyAndRevenue[0];
        double revenue = [currencyAndRevenue[1] doubleValue];
        [adjustEvent setRevenue:revenue currency:currency];
    }

    if ([parameters objectForKey:@"callbackParams"]) {
        NSArray *callbackParams = [parameters objectForKey:@"callbackParams"];
        for (int i = 0; i < callbackParams.count; i = i + 2) {
            NSString *key = callbackParams[i];
            NSString *value = callbackParams[i + 1];
            [adjustEvent addCallbackParameter:key value:value];
        }
    }

    if ([parameters objectForKey:@"partnerParams"]) {
        NSArray *partnerParams = [parameters objectForKey:@"partnerParams"];
        for (int i = 0; i < partnerParams.count; i = i + 2) {
            NSString *key = partnerParams[i];
            NSString *value = partnerParams[i + 1];
            [adjustEvent addPartnerParameter:key value:value];
        }
    }

    if ([parameters objectForKey:@"orderId"]) {
        NSString *transactionId;
        if ([[parameters objectForKey:@"orderId"] count] == 0) {
            transactionId = nil;
        } else {
            transactionId = [parameters objectForKey:@"orderId"][0];
            if (transactionId == (id)[NSNull null]) {
                transactionId = nil;
            }
        }
        [adjustEvent setTransactionId:transactionId];
    }

    if ([parameters objectForKey:@"callbackId"]) {
        NSString *callbackId = [parameters objectForKey:@"callbackId"][0];
        if (callbackId == (id)[NSNull null]) {
            callbackId = nil;
        }
        [adjustEvent setCallbackId:callbackId];
    }
}

- (void)trackEvent:(NSDictionary *)parameters {
    [self event:parameters];

    NSNumber *eventNumber = [NSNumber numberWithInt:0];
    if ([parameters objectForKey:@"eventName"]) {
        NSString *eventName = [parameters objectForKey:@"eventName"][0];
        NSString *eventNumberS = [eventName substringFromIndex:[eventName length] - 1];
        eventNumber = [NSNumber numberWithInt:[eventNumberS intValue]];
    }

    ADJEvent *adjustEvent = [self.savedEvents objectForKey:eventNumber];
    [Adjust trackEvent:adjustEvent];
    [self.savedEvents removeObjectForKey:[NSNumber numberWithInt:0]];
}

- (void)resume:(NSDictionary *)parameters {
    [Adjust trackSubsessionStart];
}

- (void)pause:(NSDictionary *)parameters {
    [Adjust trackSubsessionEnd];
}

- (void)setEnabled:(NSDictionary *)parameters {
    NSString *enabledS = [parameters objectForKey:@"enabled"][0];
    [Adjust setEnabled:[enabledS boolValue]];
}

- (void)setOfflineMode:(NSDictionary *)parameters {
    NSString *enabledS = [parameters objectForKey:@"enabled"][0];
    [Adjust setOfflineMode:[enabledS boolValue]];
}

- (void)sendFirstPackages:(NSDictionary *)parameters {
    [Adjust sendFirstPackages];
}

- (void)addSessionCallbackParameter:(NSDictionary *)parameters {
    NSArray *keyValuesPairs = [parameters objectForKey:@"KeyValue"];
    for (int i = 0; i < keyValuesPairs.count; i = i + 2) {
        NSString *key = keyValuesPairs[i];
        NSString *value = keyValuesPairs[i + 1];
        [Adjust addSessionCallbackParameter:key value:value];
    }
}

- (void)addSessionPartnerParameter:(NSDictionary *)parameters {
    NSArray *keyValuesPairs = [parameters objectForKey:@"KeyValue"];
    for (int i = 0; i < keyValuesPairs.count; i = i + 2) {
        NSString *key = keyValuesPairs[i];
        NSString *value = keyValuesPairs[i + 1];
        [Adjust addSessionPartnerParameter:key value:value];
    }
}

- (void)removeSessionCallbackParameter:(NSDictionary *)parameters {
    NSArray *keys = [parameters objectForKey:@"key"];
    for (int i = 0; i < keys.count; i = i + 1) {
        NSString *key = keys[i];
        [Adjust removeSessionCallbackParameter:key];
    }
}

- (void)removeSessionPartnerParameter:(NSDictionary *)parameters {
    NSArray *keys = [parameters objectForKey:@"key"];
    for (int i = 0; i < keys.count; i = i + 1) {
        NSString *key = keys[i];
        [Adjust removeSessionPartnerParameter:key];
    }
}

- (void)resetSessionCallbackParameters:(NSDictionary *)parameters {
    [Adjust resetSessionCallbackParameters];
}

- (void)resetSessionPartnerParameters:(NSDictionary *)parameters {
    [Adjust resetSessionPartnerParameters];
}

- (void)setPushToken:(NSDictionary *)parameters {
    NSString *deviceTokenS = [parameters objectForKey:@"pushToken"][0];
    NSData *deviceToken = [deviceTokenS dataUsingEncoding:NSUTF8StringEncoding];
    [Adjust setDeviceToken:deviceToken];
}

- (void)openDeeplink:(NSDictionary *)parameters {
    NSString *deeplinkS = [parameters objectForKey:@"deeplink"][0];
    NSURL *deeplink = [NSURL URLWithString:deeplinkS];
    [Adjust appWillOpenUrl:deeplink];
}

- (void)gdprForgetMe:(NSDictionary *)parameters {
    [Adjust gdprForgetMe];
}

- (void)trackAdRevenue:(NSDictionary *)parameters {
    NSString *sourceS = [parameters objectForKey:@"adRevenueSource"][0];
    NSString *payloadS = [parameters objectForKey:@"adRevenueJsonString"][0];
    NSData *payload = [payloadS dataUsingEncoding:NSUTF8StringEncoding];
    [Adjust trackAdRevenue:sourceS payload:payload];
}

@end
