//
//  Leanplum.m
//  Leanplum
//
//  Created by Andrew First on 4/30/12.
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "LPConstants.h"
#import "UIDevice+IdentifierAddition.h"
#import "LPVarCache.h"
#import "Leanplum_SocketIO.h"
#import "LeanplumSocket.h"
#import "LPJSON.h"
#import "LPRegisterDevice.h"
#import "LPFileManager.h"
#import <QuartzCore/QuartzCore.h>
#import "LPFileManager.h"
#import "NSTimer+Blocks.h"
#import "LPActionManager.h"
#import "LPMessageTemplates.h"
#include <sys/sysctl.h>
#import "LPRevenueManager.h"
#import "LPSwizzle.h"
#import "LPInbox.h"
#import "LPUIAlert.h"
#import "LPUtils.h"
#import "LPAppIconManager.h"
#import "LPUIEditorWrapper.h"
#import "LPCountAggregator.h"
#import "LPRequestFactory.h"
#import "LPFileTransferManager.h"
#import "LPRequestSender.h"
#import "LPAPIConfig.h"

static NSString *leanplum_deviceId = nil;
static NSString *registrationEmail = nil;
__weak static NSExtensionContext *_extensionContext = nil;
static LeanplumPushSetupBlock pushSetupBlock;

@implementation NSExtensionContext (Leanplum)

- (void)leanplum_completeRequestReturningItems:(NSArray *)items
                             completionHandler:(void(^)(BOOL expired))completionHandler
{
    [self leanplum_completeRequestReturningItems:items completionHandler:completionHandler];
    LP_TRY
    [Leanplum pause];
    LP_END_TRY
}

- (void)leanplum_cancelRequestWithError:(NSError *)error
{
    [self leanplum_cancelRequestWithError:error];
    LP_TRY
    [Leanplum pause];
    LP_END_TRY
}

@end

void leanplumExceptionHandler(NSException *exception);

BOOL inForeground = NO;

@implementation Leanplum

+ (void)throwError:(NSString *)reason
{
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        @throw([NSException
            exceptionWithName:@"Leanplum Error"
                       reason:[NSString stringWithFormat:@"Leanplum: %@ This error is only thrown "
                                                         @"in development mode.", reason]
                     userInfo:nil]);
    } else {
        NSLog(@"Leanplum: Error: %@", reason);
    }
}

// _initPush is a hidden method so that Unity can do swizzling early enough

+ (void)_initPush
{
    [LPActionManager sharedManager];
}

+ (void)setApiHostName:(NSString *)hostName
       withServletName:(NSString *)servletName
              usingSsl:(BOOL)ssl
{
    if ([LPUtils isNullOrEmpty:hostName]) {
        [self throwError:@"[Leanplum setApiHostName:withServletName:usingSsl:] Empty hostname "
         @"parameter provided."];
        return;
    }
    if ([LPUtils isNullOrEmpty:servletName]) {
        [self throwError:@"[Leanplum setApiHostName:withServletName:usingSsl:] Empty servletName "
         @"parameter provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].apiHostName = hostName;
    [LPConstantsState sharedState].apiServlet = servletName;
    [LPConstantsState sharedState].apiSSL = ssl;
    LP_END_TRY
}

+ (void)setSocketHostName:(NSString *)hostName withPortNumber:(int)port
{
    if ([LPUtils isNullOrEmpty:hostName]) {
        [self throwError:@"[Leanplum setSocketHostName:withPortNumber] Empty hostname parameter "
         @"provided."];
        return;
    }

    [LPConstantsState sharedState].socketHost = hostName;
    [LPConstantsState sharedState].socketPort = port;
}

+ (void)setClient:(NSString *)client withVersion:(NSString *)version
{
    [LPConstantsState sharedState].client = client;
    [LPConstantsState sharedState].sdkVersion = version;
}

+ (void)setFileHashingEnabledInDevelopmentMode:(BOOL)enabled
{
    LP_TRY
    [LPConstantsState sharedState].checkForUpdatesInDevelopmentMode = enabled;
    LP_END_TRY
}

+ (void)setVerboseLoggingInDevelopmentMode:(BOOL)enabled
{
    LP_TRY
    [LPConstantsState sharedState].verboseLoggingInDevelopmentMode = enabled;
    LP_END_TRY
}

+ (void)setNetworkTimeoutSeconds:(int)seconds
{
    if (seconds < 0) {
        [self throwError:@"[Leanplum setNetworkTimeoutSeconds:] Invalid seconds parameter "
         @"provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].networkTimeoutSeconds = seconds;
    [LPConstantsState sharedState].networkTimeoutSecondsForDownloads = seconds;
    LP_END_TRY
}

+ (void)setNetworkTimeoutSeconds:(int)seconds forDownloads:(int)downloadSeconds
{
    if (seconds < 0) {
        [self throwError:@"[Leanplum setNetworkTimeoutSeconds:forDownloads:] Invalid seconds "
         @"parameter provided."];
        return;
    }
    if (downloadSeconds < 0) {
        [self throwError:@"[Leanplum setNetworkTimeoutSeconds:forDownloads:] Invalid "
         @"downloadSeconds parameter provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].networkTimeoutSeconds = seconds;
    [LPConstantsState sharedState].networkTimeoutSecondsForDownloads = downloadSeconds;
    LP_END_TRY
}

+ (void)setNetworkActivityIndicatorEnabled:(BOOL)enabled
{
    LP_TRY
    [LPConstantsState sharedState].networkActivityIndicatorEnabled = enabled;
    LP_END_TRY
}

+ (void)setCanDownloadContentMidSessionInProductionMode:(BOOL)value
{
    LP_TRY
    [LPConstantsState sharedState].canDownloadContentMidSessionInProduction = value;
    LP_END_TRY
}

+ (BOOL)isRichPushEnabled
{
    NSString *plugInsPath = [NSBundle mainBundle].builtInPlugInsPath;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
                                         enumeratorAtPath:plugInsPath];
    NSString *filePath;
    while (filePath = [enumerator nextObject]) {
        if([filePath hasSuffix:@".appex/Info.plist"]) {
            NSString *newPath = [[plugInsPath stringByAppendingPathComponent:filePath]
                                 stringByDeletingLastPathComponent];
            NSBundle *currentBundle = [NSBundle bundleWithPath:newPath];
            NSDictionary *extensionKey =
                [currentBundle objectForInfoDictionaryKey:@"NSExtension"];
            if ([[extensionKey objectForKey:@"NSExtensionPrincipalClass"]
                 isEqualToString:@"NotificationService"]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (void)setInAppPurchaseEventName:(NSString *)event
{
    if ([LPUtils isNullOrEmpty:event]) {
        [self throwError:@"[Leanplum setInAppPurchaseEventName:] Empty event parameter provided."];
        return;
    }

    LP_TRY
    [LPRevenueManager sharedManager].eventName = event;
    LP_END_TRY
}

+ (void)setAppId:(NSString *)appId withDevelopmentKey:(NSString *)accessKey
{
    if ([LPUtils isNullOrEmpty:appId]) {
        [self throwError:@"[Leanplum setAppId:withDevelopmentKey:] Empty appId parameter "
         @"provided."];
        return;
    }
    if ([LPUtils isNullOrEmpty:accessKey]) {
        [self throwError:@"[Leanplum setAppId:withDevelopmentKey:] Empty accessKey parameter "
         @"provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].isDevelopmentModeEnabled = YES;
    [[LPAPIConfig sharedConfig] setAppId:appId withAccessKey:accessKey];
    [LeanplumRequest initializeStaticVars];
    LP_END_TRY
}

+ (void)setAppVersion:(NSString *)appVersion
{
    LP_TRY
    [LPInternalState sharedState].appVersion = appVersion;
    LP_END_TRY
}

+ (void)setAppId:(NSString *)appId withProductionKey:(NSString *)accessKey
{
    if ([LPUtils isNullOrEmpty:appId]) {
        [self throwError:@"[Leanplum setAppId:withProductionKey:] Empty appId parameter provided."];
        return;
    }
    if ([LPUtils isNullOrEmpty:accessKey]) {
        [self throwError:@"[Leanplum setAppId:withProductionKey:] Empty accessKey parameter "
         @"provided."];
        return;
    }

    LP_TRY
    [LPConstantsState sharedState].isDevelopmentModeEnabled = NO;
    [[LPAPIConfig sharedConfig] setAppId:appId withAccessKey:accessKey];
    [LeanplumRequest initializeStaticVars];
    LP_END_TRY
}

+ (void)setExtensionContext:(NSExtensionContext *)context
{
    LP_TRY
    _extensionContext = context;
    LP_END_TRY
}

+ (void)allowInterfaceEditing
{
    [self throwError:@"Leanplum UI Editor has moved to separate Pod."
     "Please remove this method call and include this "
     "line in your Podfile: pod 'Leanplum-iOS-UIEditor'"];
}

+ (BOOL)interfaceEditingEnabled
{
    [self throwError:@"Leanplum UI Editor has moved to separate Pod."
     "Please remove this method call and include this "
     "line in your Podfile: pod 'Leanplum-iOS-UIEditor'"];
    return NO;
}

+ (void)setDeviceId:(NSString *)deviceId
{
    if ([LPUtils isBlank:deviceId]) {
        [self throwError:@"[Leanplum setDeviceId:] Empty deviceId parameter provided."];
        return;
    }
    if ([deviceId isEqualToString:LP_INVALID_IDFA]) {
        [self throwError:[NSString stringWithFormat:@"[Leanplum setDeviceId:] Failed to set '%@' "
                          "as deviceId. You are most likely attempting to use the IDFA as deviceId "
                          "when the user has limited ad tracking on iOS10 or above.",
                          LP_INVALID_IDFA]];
        return;
    }
    LP_TRY
    [LPInternalState sharedState].deviceId = deviceId;
    LP_END_TRY
}

+ (void)syncResources
{
    [self syncResourcesAsync:NO];
}

+ (void)syncResourcesAsync:(BOOL)async
{
    LP_TRY
    [LPFileManager initAsync:async];
    LP_END_TRY
    [[LPCountAggregator sharedAggregator] incrementCount:@"sync_resources"];
}

+ (void)syncResourcePaths:(NSArray *)patternsToIncludeOrNil
                excluding:(NSArray *)patternsToExcludeOrNil
{
    [self syncResourcePaths:patternsToIncludeOrNil excluding:patternsToExcludeOrNil async:NO];
}

+ (void)syncResourcePaths:(NSArray *)patternsToIncludeOrNil
                excluding:(NSArray *)patternsToExcludeOrNil
                    async:(BOOL)async
{
    LP_TRY
    [LPFileManager initWithInclusions:patternsToIncludeOrNil andExclusions:patternsToExcludeOrNil
                                async:async];
    LP_END_TRY
    [[LPCountAggregator sharedAggregator] incrementCount:@"sync_resource_paths"];
}

+ (void)synchronizeDefaults
{
    static dispatch_queue_t queue = NULL;
    if (!queue) {
        queue = dispatch_queue_create("com.leanplum.defaultsSyncQueue", NULL);
    }
    static BOOL isSyncing = NO;
    if (isSyncing) {
        return;
    }
    isSyncing = YES;
    dispatch_async(queue, ^{
        isSyncing = NO;
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

+ (NSString *)pushTokenKey
{
    return [NSString stringWithFormat: LEANPLUM_DEFAULTS_PUSH_TOKEN_KEY,
            [LPAPIConfig sharedConfig].appId, [LPAPIConfig sharedConfig].userId, [LPAPIConfig sharedConfig].deviceId];
}

+ (void)start
{
    [self startWithUserId:nil userAttributes:nil responseHandler:nil];
}

+ (void)startWithResponseHandler:(LeanplumStartBlock)response
{
    [self startWithUserId:nil userAttributes:nil responseHandler:response];
}

+ (void)startWithUserAttributes:(NSDictionary *)attributes
{
    [self startWithUserId:nil userAttributes:attributes responseHandler:nil];
}

+ (void)startWithUserId:(NSString *)userId
{
    [self startWithUserId:userId userAttributes:nil responseHandler:nil];
}

+ (void)startWithUserId:(NSString *)userId responseHandler:(LeanplumStartBlock)response
{
    [self startWithUserId:userId userAttributes:nil responseHandler:response];
}

+ (void)startWithUserId:(NSString *)userId userAttributes:(NSDictionary *)attributes
{
    [self startWithUserId:userId userAttributes:attributes responseHandler:nil];
}

+ (void)triggerStartIssued
{
    [LPInternalState sharedState].issuedStart = YES;
    for (LeanplumStartIssuedBlock block in [LPInternalState sharedState].startIssuedBlocks.copy) {
        block();
    }
    [[LPInternalState sharedState].startIssuedBlocks removeAllObjects];
}

+ (void)triggerStartResponse:(BOOL)success
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState].startResponders.copy) {
        [invocation setArgument:&success atIndex:2];
        [invocation invoke];
    }

    for (LeanplumStartBlock block in [LPInternalState sharedState].startBlocks.copy) {
        block(success);
    }
    LP_END_USER_CODE
    [[LPInternalState sharedState].startResponders removeAllObjects];
    [[LPInternalState sharedState].startBlocks removeAllObjects];
}

+ (void)triggerVariablesChanged
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState]
            .variablesChangedResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumVariablesChangedBlock block in [LPInternalState sharedState]
             .variablesChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

+ (void)triggerInterfaceChanged
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState]
             .interfaceChangedResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumInterfaceChangedBlock block in [LPInternalState sharedState]
             .interfaceChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

+ (void)triggerEventsChanged
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState].eventsChangedResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumEventsChangedBlock block in [LPInternalState sharedState]
             .eventsChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

+ (void)triggerVariablesChangedAndNoDownloadsPending
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in [LPInternalState sharedState].noDownloadsResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumVariablesChangedBlock block in [LPInternalState sharedState]
             .noDownloadsBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
    NSArray *onceNoDownloadsBlocksCopy;
    @synchronized ([LPInternalState sharedState].onceNoDownloadsBlocks) {
        onceNoDownloadsBlocksCopy = [LPInternalState sharedState].onceNoDownloadsBlocks.copy;
        [[LPInternalState sharedState].onceNoDownloadsBlocks removeAllObjects];
    }
    LP_BEGIN_USER_CODE
    for (LeanplumVariablesChangedBlock block in onceNoDownloadsBlocksCopy) {
        block();
    }
    LP_END_USER_CODE
}

+ (void)triggerMessageDisplayed:(LPActionContext *)context
{
    LP_BEGIN_USER_CODE
    LPMessageArchiveData *messageArchiveData = [self messageArchiveDataFromContext:context];
    for (LeanplumMessageDisplayedCallbackBlock block in [LPInternalState sharedState]
         .messageDisplayedBlocks.copy) {
        block(messageArchiveData);
    }
    LP_END_USER_CODE
}

+ (LPMessageArchiveData *)messageArchiveDataFromContext:(LPActionContext *)context {
    NSString *messageID = context.messageId;
    NSString *messageBody = [self messageBodyFromContext:context];
    NSString *recipientUserID = [Leanplum userId];
    NSDate *deliveryDateTime = [NSDate date];

    return [[LPMessageArchiveData alloc] initWithMessageID: messageID
                                               messageBody:messageBody
                                           recipientUserID:recipientUserID
                                          deliveryDateTime:deliveryDateTime];
}

+ (NSString *)messageBodyFromContext:(LPActionContext *)context {
    NSString *messageBody = @"";
    NSString *messageKey = @"Message";
    id messageObject = [context.args valueForKey:messageKey];
    if (messageObject) {
        if ([messageObject isKindOfClass:[NSString class]]) {
            messageBody = messageObject;
        } else if ([messageObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *messageDict = (NSDictionary *) messageObject;
            if ([[messageDict objectForKey:@"Text"] isKindOfClass:[NSString class]]) {
                messageBody = [messageDict objectForKey:@"Text"];
            } else if ([[messageDict objectForKey:@"Text value"] isKindOfClass:[NSString class]]) {
                messageBody = [messageDict objectForKey:@"Text value"];
            }
        }
    }
    return messageBody;
}

+ (void)triggerAction:(LPActionContext *)context
{
    [self triggerAction:context handledBlock:nil];
}

+ (void)triggerAction:(LPActionContext *)context handledBlock:(LeanplumHandledBlock)handledBlock
{
    LeanplumVariablesChangedBlock triggerBlock = ^{
        BOOL handled = NO;
        LP_BEGIN_USER_CODE
        for (NSInvocation *invocation in [[LPInternalState sharedState].actionResponders
                                          objectForKey:context.actionName]) {
            [invocation setArgument:(void *)&context atIndex:2];
            [invocation invoke];
            BOOL invocationHandled = NO;
            [invocation getReturnValue:&invocationHandled];
            handled |= invocationHandled;
        }

        for (LeanplumActionBlock block in [LPInternalState sharedState].actionBlocks
                                           [context.actionName]) {
            handled |= block(context);
        }
        LP_END_USER_CODE

        if (handledBlock) {
            handledBlock(handled);
            if (handled) {
                [Leanplum triggerMessageDisplayed:context];
            }
        }
    };

    if ([context hasMissingFiles]) {
        [Leanplum onceVariablesChangedAndNoDownloadsPending:triggerBlock];
    } else {
        triggerBlock();
    }
}

+ (void)setDeveloperEmail:(NSString *)email __deprecated
{
    registrationEmail = email;
}

+ (void)onHasStartedAndRegisteredAsDeveloper
{
    if ([LPFileManager initializing]) {
        [LPFileManager setResourceSyncingReady:^{
            [self onHasStartedAndRegisteredAsDeveloperAndFinishedSyncing];
        }];
    } else {
        [self onHasStartedAndRegisteredAsDeveloperAndFinishedSyncing];
    }
}

+ (void)onHasStartedAndRegisteredAsDeveloperAndFinishedSyncing
{
    if (![LPInternalState sharedState].hasStartedAndRegisteredAsDeveloper) {
        [LPInternalState sharedState].hasStartedAndRegisteredAsDeveloper = YES;
    }
}

+ (NSDictionary *)validateAttributes:(NSDictionary *)attributes named:(NSString *)argName
                          allowLists:(BOOL)allowLists
{
    NSMutableDictionary *validAttributes = [NSMutableDictionary dictionary];
    for (id key in attributes) {
        if (![key isKindOfClass:NSString.class]) {
            [self throwError:[NSString stringWithFormat:
                              @"%@ keys must be of type NSString.", argName]];
            continue;
        }
        id value = attributes[key];
        if (allowLists &&
            ([value isKindOfClass:NSArray.class] ||
             [value isKindOfClass:NSSet.class])) {
            BOOL valid = YES;
            for (id item in value) {
                if (![self validateScalarValue:item argName:argName]) {
                    valid = NO;
                    break;
                }
            }
            if (!valid) {
                continue;
            }
        } else {
            if ([value isKindOfClass:NSDate.class]) {
                value = [NSNumber numberWithUnsignedLongLong:
                         [(NSDate *) value timeIntervalSince1970] * 1000];
            }
            if (![self validateScalarValue:value argName:argName]) {
                continue;
            }
        }
        validAttributes[key] = value;
    }
    return validAttributes;
}

+ (BOOL)validateScalarValue:(id)value argName:(NSString *)argName
{
    if (![value isKindOfClass:NSString.class] &&
        ![value isKindOfClass:NSNumber.class] &&
        ![value isKindOfClass:NSNull.class]) {
        [self throwError:[NSString stringWithFormat:
                          @"%@ values must be of type NSString, NSNumber, or NSNull.", argName]];
        return NO;
    }
    if ([value isKindOfClass:NSNumber.class]) {
        if ([value isEqualToNumber:[NSDecimalNumber notANumber]]) {
            [self throwError:[NSString stringWithFormat:
                              @"%@ values must not be [NSDecimalNumber notANumber].", argName]];
            return NO;
        }
    }
    return YES;
}

+ (void)reset
{
    LPInternalState *state = [LPInternalState sharedState];
    state.calledStart = NO;
    state.hasStarted = NO;
    state.hasStartedAndRegisteredAsDeveloper = NO;
    state.startSuccessful = NO;
    [state.startBlocks removeAllObjects];
    [state.startResponders removeAllObjects];
    [state.actionBlocks removeAllObjects];
    [state.actionResponders removeAllObjects];
    [state.variablesChangedBlocks removeAllObjects];
    [state.interfaceChangedBlocks removeAllObjects];
    [state.eventsChangedBlocks removeAllObjects];
    [state.variablesChangedResponders removeAllObjects];
    [state.interfaceChangedResponders removeAllObjects];
    [state.eventsChangedResponders removeAllObjects];
    [state.noDownloadsBlocks removeAllObjects];
    [state.onceNoDownloadsBlocks removeAllObjects];
    [state.noDownloadsResponders removeAllObjects];
    @synchronized([LPInternalState sharedState].userAttributeChanges) {
        [state.userAttributeChanges removeAllObjects];
    }
    state.calledHandleNotification = NO;

    [[LPInbox sharedState] reset];
}

+ (NSString *)platform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);

    if ([results isEqualToString:@"i386"] ||
        [results isEqualToString:@"x86_64"]) {
        results = [[UIDevice currentDevice] model];
    }

    return results;
}

+ (void)startWithUserId:(NSString *)userId
         userAttributes:(NSDictionary *)attributes
        responseHandler:(LeanplumStartBlock)startResponse
{
    if ([LPAPIConfig sharedConfig].appId == nil) {
        [self throwError:@"Please provide your app ID using one of the [Leanplum setAppId:] "
         @"methods."];
        return;
    }
    
    // Leanplum should not be started in background.
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self startWithUserId:userId userAttributes:attributes responseHandler:startResponse];
        });
        return;
    }
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"start_with_user_id"];
    
    LP_TRY
    NSDate *startTime = [NSDate date];
    if (startResponse) {
        [self onStartResponse:startResponse];
    }
    LPInternalState *state = [LPInternalState sharedState];
    if (IS_NOOP) {
        state.hasStarted = YES;
        state.startSuccessful = YES;
        [[LPVarCache sharedCache] applyVariableDiffs:@{} messages:@{} updateRules:@[] eventRules:@[]
                              variants:@[] regions:@{} variantDebugInfo:@{}];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self triggerStartResponse:YES];
            [self triggerVariablesChanged];
            [self triggerInterfaceChanged];
            [self triggerEventsChanged];
            [self triggerVariablesChangedAndNoDownloadsPending];
            [[self inbox] updateMessages:[[NSMutableDictionary alloc] init] unreadCount:0];
        });
        return;
    }

    if (state.calledStart) {
        // With iOS extensions, Leanplum may already be loaded when the extension runs.
        // This is because Leanplum can stay loaded when the extension is opened and closed
        // multiple times.
        if (_extensionContext) {
            [Leanplum resume];
            return;
        }
        [self throwError:@"Already called start."];
    }

    [LPMessageTemplatesClass sharedTemplates];
    attributes = [self validateAttributes:attributes named:@"userAttributes" allowLists:YES];
    if (attributes != nil) {
        @synchronized([LPInternalState sharedState].userAttributeChanges) {
            [state.userAttributeChanges addObject:attributes];
        }
    }
    state.calledStart = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [Leanplum trackCrashes];
    });
    state.actionManager = [LPActionManager sharedManager];

    [[LPAPIConfig sharedConfig] loadToken];
    [[LPVarCache sharedCache] setSilent:YES];
    [[LPVarCache sharedCache] loadDiffs];
    [[LPVarCache sharedCache] setSilent:NO];
    [[self inbox] load];

    // Setup class members.
    [[LPVarCache sharedCache] onUpdate:^{
        [self triggerVariablesChanged];

        if (LeanplumRequest.numPendingDownloads == 0) {
            [self triggerVariablesChangedAndNoDownloadsPending];
        }
    }];
    [[LPVarCache sharedCache] onInterfaceUpdate:^{
        [self triggerInterfaceChanged];
    }];
    [[LPVarCache sharedCache] onEventsUpdate:^{
        [self triggerEventsChanged];
    }];
    [LeanplumRequest onNoPendingDownloads:^{
        [self triggerVariablesChangedAndNoDownloadsPending];
    }];

    // Set device ID.
    NSString *deviceId = [LPAPIConfig sharedConfig].deviceId;
    // This is the device ID set when the MAC address is used on iOS 7.
    // This is to allow apps who upgrade to the new ID to forget the old one.
    if ([deviceId isEqualToString:@"0f607264fc6318a92b9e13c65db7cd3c"]) {
        deviceId = nil;
    }
    if (!deviceId) {
        if (state.deviceId) {
            deviceId = state.deviceId;
        } else {
            deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
        if (!deviceId) {
            deviceId = [[UIDevice currentDevice] leanplum_uniqueGlobalDeviceIdentifier];
        }
        [[LPAPIConfig sharedConfig] setDeviceId:deviceId];
    }

    // Set user ID.
    if (!userId) {
        userId = [LPAPIConfig sharedConfig].userId;
        if (!userId) {
            userId = [LPAPIConfig sharedConfig].deviceId;
        }
    }
    [[LPAPIConfig sharedConfig] setUserId:userId];

    // Setup parameters.
    NSString *versionName = [LPInternalState sharedState].appVersion;
    if (!versionName) {
        versionName = [[[NSBundle mainBundle] infoDictionary]
                       objectForKey:@"CFBundleVersion"];
    }
    UIDevice *device = [UIDevice currentDevice];
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *currentLocaleString = [NSString stringWithFormat:@"%@_%@",
                                     [[NSLocale preferredLanguages] objectAtIndex:0],
                                     [currentLocale objectForKey:NSLocaleCountryCode]];
    // Set the device name. But only if running in development mode.
    NSString *deviceName = @"";
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        deviceName = device.name ?: @"";
    }
    NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
    NSNumber *timezoneOffsetSeconds =
        [NSNumber numberWithInteger:[localTimeZone secondsFromGMTForDate:[NSDate date]]];
    NSMutableDictionary *params = [@{
        LP_PARAM_INCLUDE_DEFAULTS: @(NO),
        LP_PARAM_VERSION_NAME: versionName,
        LP_PARAM_DEVICE_NAME: deviceName,
        LP_PARAM_DEVICE_MODEL: [self platform],
        LP_PARAM_DEVICE_SYSTEM_NAME: device.systemName,
        LP_PARAM_DEVICE_SYSTEM_VERSION: device.systemVersion,
        LP_KEY_LOCALE: currentLocaleString,
        LP_KEY_TIMEZONE: [localTimeZone name],
        LP_KEY_TIMEZONE_OFFSET_SECONDS: timezoneOffsetSeconds,
        LP_KEY_COUNTRY: LP_VALUE_DETECT,
        LP_KEY_REGION: LP_VALUE_DETECT,
        LP_KEY_CITY: LP_VALUE_DETECT,
        LP_KEY_LOCATION: LP_VALUE_DETECT,
        LP_PARAM_RICH_PUSH_ENABLED: @([self isRichPushEnabled])
    } mutableCopy];
    if ([LPInternalState sharedState].isVariantDebugInfoEnabled) {
        params[LP_PARAM_INCLUDE_VARIANT_DEBUG_INFO] = @(YES);
    }

    BOOL startedInBackground = NO;
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground &&
        !_extensionContext) {
        params[LP_PARAM_BACKGROUND] = @(YES);
        startedInBackground = YES;
    }

    if (attributes != nil) {
        params[LP_PARAM_USER_ATTRIBUTES] = attributes ?
                [LPJSON stringFromJSON:attributes] : @"";
    }
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        params[LP_PARAM_DEV_MODE] = @(YES);
    }

    NSDictionary *timeParams = [self initializePreLeanplumInstall];
    if (timeParams) {
        [params addEntriesFromDictionary:timeParams];
    }

    // Get the current Inbox messages on the device.
    params[LP_PARAM_INBOX_MESSAGES] = [self.inbox messagesIds];
    
    // Push token.
    NSString *pushTokenKey = [Leanplum pushTokenKey];
    NSString *pushToken = [[NSUserDefaults standardUserDefaults] stringForKey:pushTokenKey];
    if (pushToken) {
        params[LP_PARAM_DEVICE_PUSH_TOKEN] = pushToken;
    }

    // Issue start API call.
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory startWithParams:params];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
        LP_TRY
        state.hasStarted = YES;
        state.startSuccessful = YES;
        NSDictionary *values = response[LP_KEY_VARS];
        NSString *token = response[LP_KEY_TOKEN];
        NSDictionary *messages = response[LP_KEY_MESSAGES];
        NSArray *updateRules = response[LP_KEY_UPDATE_RULES];
        NSArray *eventRules = response[LP_KEY_EVENT_RULES];
        NSArray *variants = response[LP_KEY_VARIANTS];
        NSDictionary *regions = response[LP_KEY_REGIONS];
        NSDictionary *variantDebugInfo = [self parseVariantDebugInfoFromResponse:response];
        [[LPVarCache sharedCache] setVariantDebugInfo:variantDebugInfo];
        NSSet<NSString *> *enabledCounters = [self parseEnabledCountersFromResponse:response];
        [LPCountAggregator sharedAggregator].enabledCounters = enabledCounters;
        NSSet<NSString *> *enabledFeatureFlags = [self parseEnabledFeatureFlagsFromResponse:response];
        [LPFeatureFlagManager sharedManager].enabledFeatureFlags = enabledFeatureFlags;
        NSDictionary *filenameToURLs = [self parseFileURLsFromResponse:response];
        [LPFileTransferManager sharedInstance].filenameToURLs = filenameToURLs;

        [[LPAPIConfig sharedConfig] setToken:token];
        [[LPAPIConfig sharedConfig] saveToken];
        [[LPVarCache sharedCache] applyVariableDiffs:values
                              messages:messages
                           updateRules:updateRules
                            eventRules:eventRules
                              variants:variants
                               regions:regions
                      variantDebugInfo:variantDebugInfo];

        if ([response[LP_KEY_SYNC_INBOX] boolValue]) {
            [[self inbox] downloadMessages];
        }

        if ([response[LP_KEY_LOGGING_ENABLED] boolValue]) {
            [LPConstantsState sharedState].loggingEnabled = YES;
        }

        // TODO: Need to call this if we fix encryption.
        // [LPVarCache saveUserAttributes];
        [self triggerStartResponse:YES];

        // Allow bidirectional realtime variable updates.
        if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
            // Register device.
            if (registrationEmail && ![response[LP_KEY_IS_REGISTERED] boolValue]) {
                state.registration = [[LPRegisterDevice alloc] initWithCallback:^(BOOL success) {
                                    if (success) {
                                        [Leanplum onHasStartedAndRegisteredAsDeveloper];
                                    }}];
                [state.registration registerDevice:registrationEmail];
            } else if ([response[LP_KEY_IS_REGISTERED_FROM_OTHER_APP] boolValue]) {
                // Show if registered from another app ID.
                [LPUIAlert showWithTitle:@"Leanplum"
                                 message:@"Your device is registered."
                       cancelButtonTitle:NSLocalizedString(@"OK", nil)
                       otherButtonTitles:nil
                                   block:nil];
            } else {
                // Check for updates.
                NSString *latestVersion = response[LP_KEY_LATEST_VERSION];
                if (latestVersion) {
                    NSLog(@"Leanplum: A newer version of the SDK, %@, is available. Please go to "
                          @"leanplum.com to download it.", latestVersion);
                }
            }

            NSDictionary *valuesFromCode = response[LP_KEY_VARS_FROM_CODE];
            NSDictionary *actionDefinitions = response[LP_PARAM_ACTION_DEFINITIONS];
            NSDictionary *fileAttributes = response[LP_PARAM_FILE_ATTRIBUTES];

            [LeanplumRequest setUploadUrl:response[LP_KEY_UPLOAD_URL]];
            [[LPVarCache sharedCache] setDevModeValuesFromServer:valuesFromCode
                                    fileAttributes:fileAttributes
                                 actionDefinitions:actionDefinitions];
            [[LeanplumSocket sharedSocket] connectToAppId:[LPAPIConfig sharedConfig].appId
                                                 deviceId:[LPAPIConfig sharedConfig].deviceId];
            if ([response[LP_KEY_IS_REGISTERED] boolValue]) {
                [Leanplum onHasStartedAndRegisteredAsDeveloper];
            }
        } else {
            // Report latency for 0.1% of users.
            NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:startTime];
            if (arc4random() % 1000 == 0) {
                LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                                initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
                id<LPRequesting> request = [reqFactory logWithParams:@{
                                        LP_PARAM_TYPE: LP_VALUE_SDK_START_LATENCY,
                                        @"startLatency": [@(latency) description]
                                        }];
                [[LPRequestSender sharedInstance] send:request];
            }
        }

        // Upload alternative app icons.
        [LPAppIconManager uploadAppIconsOnDevMode];

        if (!startedInBackground) {
            inForeground = YES;
            [self maybePerformActions:@[@"start", @"resume"]
                        withEventName:nil
                           withFilter:kLeanplumActionFilterAll
                        fromMessageId:nil
                 withContextualValues:nil];
            [self recordAttributeChanges];
        }
        LP_END_TRY
    }];
    [request onError:^(NSError *err) {
        LP_TRY
        state.hasStarted = YES;
        state.startSuccessful = NO;

        // Load the variables that were stored on the device from the last session.
        [[LPVarCache sharedCache] loadDiffs];
        LP_END_TRY

        [self triggerStartResponse:NO];
    }];
    [[LPRequestSender sharedInstance] sendIfConnected:request];
    [self triggerStartIssued];

    // Pause.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidEnterBackgroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                    RETURN_IF_NOOP;
                    LP_TRY
                    if (![[[[NSBundle mainBundle] infoDictionary]
                            objectForKey:@"UIApplicationExitsOnSuspend"] boolValue]) {
                        [Leanplum pause];
                    }
                    LP_END_TRY
                }];

    // Resume.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillEnterForegroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                    RETURN_IF_NOOP;
                    LP_TRY
                    if ([[UIApplication sharedApplication]
                            respondsToSelector:@selector(currentUserNotificationSettings)]) {
                        [[LPActionManager sharedManager] sendUserNotificationSettingsIfChanged:
                                                             [[UIApplication sharedApplication]
                                                                 currentUserNotificationSettings]];
                    }
                    [Leanplum resume];
                    if (startedInBackground && !inForeground) {
                        inForeground = YES;
                        [self maybePerformActions:@[@"start", @"resume"]
                                    withEventName:nil
                                       withFilter:kLeanplumActionFilterAll
                                    fromMessageId:nil
                             withContextualValues:nil];
                        [self recordAttributeChanges];
                    } else {
                        [self maybePerformActions:@[@"resume"]
                                    withEventName:nil
                                       withFilter:kLeanplumActionFilterAll
                                    fromMessageId:nil
                             withContextualValues:nil];
                    }
                    LP_END_TRY
                }];

    // Stop.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillTerminateNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                    RETURN_IF_NOOP;
                    LP_TRY
                    BOOL exitOnSuspend = [[[[NSBundle mainBundle] infoDictionary]
                        objectForKey:@"UIApplicationExitsOnSuspend"] boolValue];
                    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
                    id<LPRequesting> request = [reqFactory stopWithParams:nil];
                    [[LPRequestSender sharedInstance] sendIfConnected:request sync:exitOnSuspend];
                    LP_END_TRY
                }];

    // Heartbeat.
    [LPTimerBlocks scheduledTimerWithTimeInterval:HEARTBEAT_INTERVAL block:^() {
        RETURN_IF_NOOP;
        LP_TRY
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                            initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
            id<LPRequesting> request = [reqFactory heartbeatWithParams:nil];
            [[LPRequestSender sharedInstance] sendIfDelayed:request];

        }
        LP_END_TRY
    } repeats:YES];

    // Extension close.
    if (_extensionContext) {
        [LPSwizzle
            swizzleMethod:@selector(completeRequestReturningItems:completionHandler:)
               withMethod:@selector(leanplum_completeRequestReturningItems:completionHandler:)
                    error:nil
                    class:[NSExtensionContext class]];
        [LPSwizzle swizzleMethod:@selector(cancelRequestWithError:)
                      withMethod:@selector(leanplum_cancelRequestWithError:)
                           error:nil
                           class:[NSExtensionContext class]];
    }
    [self maybeRegisterForNotifications];
    LP_END_TRY
    
    LP_TRY
    [LPUtils initExceptionHandling];
    LP_END_TRY
}

// On first run with Leanplum, determine if this app was previously installed without Leanplum.
// This is useful for detecting if the user may have already rejected notifications.
+ (NSDictionary *)initializePreLeanplumInstall
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[[defaults dictionaryRepresentation] allKeys]
            containsObject:LEANPLUM_DEFAULTS_PRE_LEANPLUM_INSTALL_KEY]) {
        return nil;
    } else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *urlToDocumentsFolder = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                           inDomains:NSUserDomainMask] lastObject];
        __autoreleasing NSError *error;
        NSDate *installDate =
            [[fileManager attributesOfItemAtPath:urlToDocumentsFolder.path error:&error]
                objectForKey:NSFileCreationDate];
        NSString *pathToInfoPlist = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSString *pathToAppBundle = [pathToInfoPlist stringByDeletingLastPathComponent];
        NSDate *updateDate = [[fileManager attributesOfItemAtPath:pathToAppBundle error:&error]
            objectForKey:NSFileModificationDate];

        // Considered pre-Leanplum install if its been more than a day (86400 seconds) since
        // install.
        NSTimeInterval secondsBetween = [updateDate timeIntervalSinceDate:installDate];
        [[NSUserDefaults standardUserDefaults] setBool:(secondsBetween > 86400)
                                                forKey:LEANPLUM_DEFAULTS_PRE_LEANPLUM_INSTALL_KEY];
        return @{
            LP_PARAM_INSTALL_DATE:
                [NSString stringWithFormat:@"%f", [installDate timeIntervalSince1970]],
            LP_PARAM_UPDATE_DATE:
                [NSString stringWithFormat:@"%f", [updateDate timeIntervalSince1970]]
        };
    }
}

// If the app has already accepted notifications, register for this instance of the app and trigger
// sending push tokens to server.
+ (void)maybeRegisterForNotifications
{
    Class userMessageTemplatesClass = NSClassFromString(@"LPMessageTemplates");
    if (userMessageTemplatesClass
        && [[userMessageTemplatesClass sharedTemplates]
            respondsToSelector:@selector(refreshPushPermissions)]) {
        [[userMessageTemplatesClass sharedTemplates] refreshPushPermissions];
    } else {
        [[LPMessageTemplatesClass sharedTemplates] refreshPushPermissions];
    }
}

+ (void)pause
{
    UIApplication *application = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier __block backgroundTask;
    
    // Block that finish task.
    void (^finishTaskHandler)(void) = ^(){
        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    };
    
    // Start background task to make sure it runs when the app is in background.
    backgroundTask = [application beginBackgroundTaskWithExpirationHandler:finishTaskHandler];
    
    // Send pause event.
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory pauseSessionWithParams:nil];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        finishTaskHandler();
    }];
    [request onError:^(NSError *error) {
        finishTaskHandler();
    }];
    [[LPRequestSender sharedInstance] sendIfConnected:request];
}

+ (void)resume
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory resumeSessionWithParams:nil];
    [[LPRequestSender sharedInstance] sendIfDelayed:request];
}

+ (void)trackCrashes
{
    LP_TRY
    Class crittercism = NSClassFromString(@"Crittercism");
    SEL selector = NSSelectorFromString(@"didCrashOnLastLoad:");
    if (crittercism && [crittercism respondsToSelector:selector]) {
        IMP imp = [crittercism methodForSelector:selector];
        BOOL (*func)(id, SEL) = (void *)imp;
        BOOL didCrash = func(crittercism, selector);
        if (didCrash) {
            [Leanplum track:@"Crash"];
        }
    }
    LP_END_TRY
}

+ (BOOL)hasStarted
{
    LP_TRY
    return [LPInternalState sharedState].hasStarted;
    LP_END_TRY
    return NO;
}

+ (BOOL)hasStartedAndRegisteredAsDeveloper
{
    LP_TRY
    return [LPInternalState sharedState].hasStartedAndRegisteredAsDeveloper;
    LP_END_TRY
    return NO;
}

+ (NSInvocation *)createInvocationWithResponder:(id)responder selector:(SEL)selector
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [responder methodSignatureForSelector:selector]];
    invocation.target = responder;
    invocation.selector = selector;
    return invocation;
}

+ (void)addInvocation:(NSInvocation *)invocation toSet:(NSMutableSet *)responders
{
    for (NSInvocation *savedResponder in responders) {
        if (savedResponder.target == invocation.target &&
           savedResponder.selector == invocation.selector) {
            return;
        }
    }
    [responders addObject:invocation];
}

+ (void)removeResponder:(id)responder withSelector:(SEL)selector fromSet:(NSMutableSet *)responders
{
    LP_TRY
    for (NSInvocation *invocation in responders.copy) {
        if (invocation.target == responder && invocation.selector == selector) {
            [responders removeObject:invocation];
        }
    }
    LP_END_TRY
}

+ (void)onStartIssued:(LeanplumStartIssuedBlock)block
{
    if ([LPInternalState sharedState].issuedStart) {
        block();
    } else {
        if (![LPInternalState sharedState].startIssuedBlocks) {
            [LPInternalState sharedState].startIssuedBlocks = [NSMutableArray array];
        }
        [[LPInternalState sharedState].startIssuedBlocks addObject:[block copy]];
    }
}

+ (void)onStartResponse:(LeanplumStartBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onStartResponse:] Nil block parameter provided."];
        return;
    }

    if ([LPInternalState sharedState].hasStarted) {
        block([LPInternalState sharedState].startSuccessful);
    } else {
        LP_TRY
        if (![LPInternalState sharedState].startBlocks) {
            [LPInternalState sharedState].startBlocks = [NSMutableArray array];
        }
        [[LPInternalState sharedState].startBlocks addObject:[block copy]];
        LP_END_TRY
    }
    [[LPCountAggregator sharedAggregator] incrementCount:@"on_start_response"];
}

+ (void)addStartResponseResponder:(id)responder withSelector:(SEL)selector
{
    if (!responder) {
        [self throwError:@"[Leanplum addStartResponseResponder:withSelector:] Empty responder "
         @"parameter provided."];
        return;
    }
    if (!selector) {
        [self throwError:@"[Leanplum addStartResponseResponder:withSelector:] Empty selector "
         @"parameter provided."];
        return;
    }

    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    if ([LPInternalState sharedState].hasStarted) {
        BOOL startSuccessful = [LPInternalState sharedState].startSuccessful;
        [invocation setArgument:&startSuccessful atIndex:2];
        [invocation invoke];
    } else {
        LP_TRY
        if (![LPInternalState sharedState].startResponders) {
            [LPInternalState sharedState].startResponders = [NSMutableSet set];
        }
        [self addInvocation:invocation toSet:[LPInternalState sharedState].startResponders];
        LP_END_TRY
    }
}

+ (void)removeStartResponseResponder:(id)responder withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].startResponders];
}

+ (void)onVariablesChanged:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onVariablesChanged:] Nil block parameter provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].variablesChangedBlocks) {
        [LPInternalState sharedState].variablesChangedBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].variablesChangedBlocks addObject:[block copy]];
    LP_END_TRY
    if ([[LPVarCache sharedCache] hasReceivedDiffs]) {
        block();
    }
}

+ (void)onInterfaceChanged:(LeanplumInterfaceChangedBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onStartResponse:] Nil block parameter provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].interfaceChangedBlocks) {
        [LPInternalState sharedState].interfaceChangedBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].interfaceChangedBlocks addObject:[block copy]];
    LP_END_TRY
    if ([[LPVarCache sharedCache] hasReceivedDiffs]) {
        block();
    }
}

+ (void)onEventsChanged:(LeanplumEventsChangedBlock)block
{
    if (![LPInternalState sharedState].eventsChangedBlocks) {
        [LPInternalState sharedState].eventsChangedBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].eventsChangedBlocks addObject:[block copy]];
    if ([[LPVarCache sharedCache] hasReceivedDiffs]) {
        block();
    }
}

+ (void)addVariablesChangedResponder:(id)responder withSelector:(SEL)selector
{
    if (!responder) {
        [self throwError:@"[Leanplum addVariablesChangedResponder:withSelector:] Nil block "
         @"parameter provided."];
        return;
    }
    if (!selector) {
        [self throwError:@"[Leanplum addVariablesChangedResponder:withSelector:] Nil selector "
         @"parameter provided."];
        return;
    }

    if (![LPInternalState sharedState].variablesChangedResponders) {
        [LPInternalState sharedState].variablesChangedResponders = [NSMutableSet set];
    }
    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:[LPInternalState sharedState].variablesChangedResponders];
    if ([[LPVarCache sharedCache] hasReceivedDiffs]) {
        [invocation invoke];
    }
}

+ (void)addInterfaceChangedResponder:(id)responder withSelector:(SEL)selector
{
    if (!responder) {
        [self throwError:@"[Leanplum addVariablesChangedResponder:withSelector:] Nil block "
         @"parameter provided."];
        return;
    }
    if (!selector) {
        [self throwError:@"[Leanplum addVariablesChangedResponder:withSelector:] Nil selector "
         @"parameter provided."];
        return;
    }

    if (![LPInternalState sharedState].interfaceChangedResponders) {
        [LPInternalState sharedState].interfaceChangedResponders = [NSMutableSet set];
    }
    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:[LPInternalState sharedState].interfaceChangedResponders];
    if ([[LPVarCache sharedCache] hasReceivedDiffs] && invocation) {
        [invocation invoke];
    }
}

+ (void)addEventsChangedResponder:(id)responder withSelector:(SEL)selector
{
    if (![LPInternalState sharedState].eventsChangedResponders) {
        [LPInternalState sharedState].eventsChangedResponders = [NSMutableSet set];
    }

    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:[LPInternalState sharedState].eventsChangedResponders];
    if ([[LPVarCache sharedCache] hasReceivedDiffs] && invocation) {
        [invocation invoke];
    }
}

+ (void)removeVariablesChangedResponder:(id)responder withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].variablesChangedResponders];
}

+ (void)removeInterfaceChangedResponder:(id)responder withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].interfaceChangedResponders];
}

+ (void)removeEventsChangedResponder:(id)responder withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].eventsChangedResponders];
}

+ (void)onVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onVariablesChangedAndNoDownloadsPending:] Nil block parameter "
         @"provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].noDownloadsBlocks) {
        [LPInternalState sharedState].noDownloadsBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].noDownloadsBlocks addObject:[block copy]];
    LP_END_TRY
    if ([[LPVarCache sharedCache] hasReceivedDiffs] && LeanplumRequest.numPendingDownloads == 0) {
        block();
    }
}

+ (void)onceVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum onceVariablesChangedAndNoDownloadsPending:] Nil block "
         @"parameter provided."];
        return;
    }

    if ([[LPVarCache sharedCache] hasReceivedDiffs] && LeanplumRequest.numPendingDownloads == 0) {
        block();
    } else {
        LP_TRY
        static dispatch_once_t onceNoDownloadsBlocksToken;
        dispatch_once(&onceNoDownloadsBlocksToken, ^{
            [LPInternalState sharedState].onceNoDownloadsBlocks = [NSMutableArray array];
        });
        @synchronized ([LPInternalState sharedState].onceNoDownloadsBlocks) {
            [[LPInternalState sharedState].onceNoDownloadsBlocks addObject:[block copy]];
        }
        LP_END_TRY
    }
}


+ (void)onMessageDisplayed:(LeanplumMessageDisplayedCallbackBlock)block {
    if (!block) {
        [self throwError:@"[Leanplum onMessageDisplayed:] Nil block "
         @"parameter provided."];
        return;
    }
    LP_TRY
    if (![LPInternalState sharedState].messageDisplayedBlocks) {
        [LPInternalState sharedState].messageDisplayedBlocks = [NSMutableArray array];
    }
    [[LPInternalState sharedState].messageDisplayedBlocks addObject:[block copy]];
    LP_END_TRY
}

+ (void)clearUserContent {
    [[LPVarCache sharedCache] clearUserContent];
    [[LPCountAggregator sharedAggregator] incrementCount:@"clear_user_content"];
}

+ (void)addVariablesChangedAndNoDownloadsPendingResponder:(id)responder withSelector:(SEL)selector
{
    if (!responder) {
        [self throwError:@"[Leanplum "
         @"addVariablesChangedAndNoDownloadsPendingResponder:withSelector:] Nil "
         @"responder parameter provided."];
    }
    if (!selector) {
        [self throwError:@"[Leanplum onceVariablesChangedAndNoDownloadsPending:] Nil selector "
         @"parameter provided."];
    }

    if (![LPInternalState sharedState].noDownloadsResponders) {
        [LPInternalState sharedState].noDownloadsResponders = [NSMutableSet set];
    }
    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:[LPInternalState sharedState].noDownloadsResponders];
    if ([[LPVarCache sharedCache] hasReceivedDiffs]
        && LeanplumRequest.numPendingDownloads == 0) {
        [invocation invoke];
    }
}

+ (void)removeVariablesChangedAndNoDownloadsPendingResponder:(id)responder
                                                withSelector:(SEL)selector
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].noDownloadsResponders];
}

+ (void)defineAction:(NSString *)name
              ofKind:(LeanplumActionKind)kind
       withArguments:(NSArray *)args
{
    [self defineAction:name ofKind:kind withArguments:args withOptions:@{} withResponder:nil];
}

+ (void)defineAction:(NSString *)name
              ofKind:(LeanplumActionKind)kind
       withArguments:(NSArray *)args
         withOptions:(NSDictionary *)options
{
    [self defineAction:name ofKind:kind withArguments:args withOptions:options withResponder:nil];
}

+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
       withResponder:(LeanplumActionBlock)responder
{
    [self defineAction:name ofKind:kind withArguments:args withOptions:@{} withResponder:responder];
}

+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
         withOptions:(NSDictionary *)options
       withResponder:(LeanplumActionBlock)responder
{
    if ([LPUtils isNullOrEmpty:name]) {
        [self throwError:@"[Leanplum defineAction:ofKind:withArguments:] Empty name parameter "
         @"provided."];
        return;
    }
    if (!kind) {
        [self throwError:@"[Leanplum defineAction:ofKind:withArguments:] Nil kind parameter "
         @"provided."];
        return;
    }
    if (!args) {
        [self throwError:@"[Leanplum defineAction:ofKind:withArguments:] Nil args parameter "
         @"provided."];
        return;
    }

    LP_TRY
    [[LPInternalState sharedState].actionBlocks removeObjectForKey:name];
    [[LPVarCache sharedCache] registerActionDefinition:name ofKind:kind withArguments:args andOptions:options];
    if (responder) {
        [Leanplum onAction:name invoke:responder];
    }
    LP_END_TRY
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"define_action"];
}

+ (void)onAction:(NSString *)actionName invoke:(LeanplumActionBlock)block
{
    if ([LPUtils isNullOrEmpty:actionName]) {
        [self throwError:@"[Leanplum onAction:invoke:] Empty actionName parameter provided."];
        return;
    }
    if (!block) {
        [self throwError:@"[Leanplum onAction:invoke::] Nil block parameter provided."];
        return;
    }

    LP_TRY
    if (![LPInternalState sharedState].actionBlocks) {
        [LPInternalState sharedState].actionBlocks = [NSMutableDictionary dictionary];
    }
    NSMutableArray *blocks = [LPInternalState sharedState].actionBlocks[actionName];
    if (!blocks) {
        blocks = [NSMutableArray array];
        [LPInternalState sharedState].actionBlocks[actionName] = blocks;
    }
    [blocks addObject:[block copy]];
    LP_END_TRY
}

+ (void)handleNotification:(NSDictionary *)userInfo
    fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler
{
    LP_TRY
    [LPInternalState sharedState].calledHandleNotification = YES;
    [[LPActionManager sharedManager] didReceiveRemoteNotification:userInfo
                                                       withAction:nil
                                           fetchCompletionHandler:completionHandler];
    LP_END_TRY
    [[LPCountAggregator sharedAggregator] incrementCount:@"handle_notification"];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token
{
    LP_TRY
    if (![LPUtils isSwizzlingEnabled])
    {
        [[LPActionManager sharedManager] didRegisterForRemoteNotificationsWithDeviceToken:token];
    }
    else
    {
        LPLog(LPDebug, @"Call to didRegisterForRemoteNotificationsWithDeviceToken will be ignored due to swizzling.");
    }
    LP_END_TRY
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    LP_TRY
    if (![LPUtils isSwizzlingEnabled])
    {
        [[LPActionManager sharedManager] didFailToRegisterForRemoteNotificationsWithError:error];
    }
    else
    {
        LPLog(LPDebug, @"Call to didFailToRegisterForRemoteNotificationsWithError will be ignored due to swizzling.");
    }
    LP_END_TRY
}

+ (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    LP_TRY
    if (![LPUtils isSwizzlingEnabled])
    {
        [[LPActionManager sharedManager] didRegisterUserNotificationSettings:notificationSettings];
    }
    else
    {
        LPLog(LPDebug, @"Call to didRegisterUserNotificationSettings will be ignored due to swizzling.");
    }
    LP_END_TRY
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    LP_TRY
    if (![LPUtils isSwizzlingEnabled])
    {
        [[LPActionManager sharedManager] didReceiveRemoteNotification:userInfo];
    }
    else
    {
        LPLog(LPDebug, @"Call to didReceiveRemoteNotification will be ignored due to swizzling.");
    }
    LP_END_TRY
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler
{
    LP_TRY
    if (![LPUtils isSwizzlingEnabled])
    {
        [[LPActionManager sharedManager] didReceiveRemoteNotification:userInfo
                                               fetchCompletionHandler:completionHandler];
    }
    else
    {
        LPLog(LPDebug, @"Call to didReceiveRemoteNotification:fetchCompletionHandler: will be ignored due to swizzling.");
    }
    LP_END_TRY
}

+ (void)didReceiveNotificationResponse:(UNNotificationResponse *)response
                 withCompletionHandler:(void (^)(void))completionHandler
{
    LP_TRY
    if (![LPUtils isSwizzlingEnabled])
    {
        [[LPActionManager sharedManager] didReceiveNotificationResponse:response
                                                  withCompletionHandler:completionHandler];
    }
    else
    {
        LPLog(LPDebug, @"Call to didReceiveNotificationResponse:withCompletionHandler: will be ignored due to swizzling.");
    }
    LP_END_TRY
}

+ (void)didReceiveLocalNotification:(UILocalNotification *)localNotification
{
    LP_TRY
    if (![LPUtils isSwizzlingEnabled])
    {
        [[LPActionManager sharedManager] didReceiveLocalNotification:localNotification];
    }
    else
    {
        LPLog(LPDebug, @"Call to didReceiveLocalNotification will be ignored due to swizzling");
    }
    LP_END_TRY
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
+ (void)handleActionWithIdentifier:(NSString *)identifier
              forLocalNotification:(UILocalNotification *)notification
                 completionHandler:(void (^)())completionHandler
{
    LP_TRY
    [[LPActionManager sharedManager] didReceiveRemoteNotification:[notification userInfo]
                                                       withAction:identifier
                                           fetchCompletionHandler:completionHandler];
    LP_END_TRY
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
+ (void)handleActionWithIdentifier:(NSString *)identifier
             forRemoteNotification:(NSDictionary *)notification
                 completionHandler:(void (^)())completionHandler
{
    LP_TRY
    [[LPActionManager sharedManager] didReceiveRemoteNotification:notification
                                                       withAction:identifier
                                           fetchCompletionHandler:completionHandler];
    LP_END_TRY
}
#pragma clang diagnostic pop

+ (void)setShouldOpenNotificationHandler:(LeanplumShouldHandleNotificationBlock)block
{
    if (!block) {
        [self throwError:@"[Leanplum setShouldOpenNotificationHandler:] Nil block parameter "
         @"provided."];
        return;
    }
    LP_TRY
    [[LPActionManager sharedManager] setShouldHandleNotification:block];
    LP_END_TRY
}

+ (void)addResponder:(id)responder withSelector:(SEL)selector forActionNamed:(NSString *)actionName
{
    if (!responder) {
        [self throwError:@"[Leanplum addResponder:withSelector:forActionNamed:] Nil responder "
         @"parameter provided."];
    }
    if (!selector) {
        [self throwError:@"[Leanplum addResponder:withSelector:forActionNamed:] Nil selector "
         @"parameter provided."];
    }

    LP_TRY
    if (![LPInternalState sharedState].actionResponders) {
        [LPInternalState sharedState].actionResponders = [NSMutableDictionary dictionary];
    }
    NSMutableSet *responders =
        [LPInternalState sharedState].actionResponders[actionName];
    if (!responders) {
        responders = [NSMutableSet set];
        [LPInternalState sharedState].actionResponders[actionName] = responders;
    }
    NSInvocation *invocation = [self createInvocationWithResponder:responder selector:selector];
    [self addInvocation:invocation toSet:responders];
    LP_END_TRY
}

+ (void)removeResponder:(id)responder withSelector:(SEL)selector
         forActionNamed:(NSString *)actionName
{
    [self removeResponder:responder
             withSelector:selector
                  fromSet:[LPInternalState sharedState].actionResponders[actionName]];
}

+ (void)maybePerformActions:(NSArray *)whenConditions
              withEventName:(NSString *)eventName
                 withFilter:(LeanplumActionFilter)filter
              fromMessageId:(NSString *)sourceMessage
       withContextualValues:(LPContextualValues *)contextualValues
{
    NSDictionary *messages = [[LPVarCache sharedCache] messages];
    NSMutableArray *actionContexts = [NSMutableArray array];
    
    for (NSString *messageId in [messages allKeys]) {
        if (sourceMessage != nil && [messageId isEqualToString:sourceMessage]) {
            continue;
        }
        NSDictionary *messageConfig = messages[messageId];
        NSString *actionType = messageConfig[@"action"];
        if (![actionType isKindOfClass:NSString.class]) {
            continue;
        }

        NSString *internalMessageId;
        if ([actionType isEqualToString:LP_HELD_BACK_ACTION]) {
            // Spoof the message ID if this is a held back message.
            internalMessageId = [LP_HELD_BACK_MESSAGE_PREFIX stringByAppendingString:messageId];
        } else {
            internalMessageId = messageId;
        }

        // Filter action types that don't match the filtering criteria.
        BOOL isForeground = ![actionType isEqualToString:LP_PUSH_NOTIFICATION_ACTION];
        if (isForeground) {
            if (!(filter & kLeanplumActionFilterForeground)) {
                continue;
            }
        } else {
            if (!(filter & kLeanplumActionFilterBackground)) {
                continue;
            }
        }

        LeanplumMessageMatchResult result = LeanplumMessageMatchResultMake(NO, NO, NO, NO);
        for (NSString *when in whenConditions) {
            LeanplumMessageMatchResult conditionResult =
            [[LPInternalState sharedState].actionManager shouldShowMessage:internalMessageId
                                                                withConfig:messageConfig
                                                                      when:when
                                                             withEventName:eventName
                                                          contextualValues:contextualValues];
            result.matchedTrigger |= conditionResult.matchedTrigger;
            result.matchedUnlessTrigger |= conditionResult.matchedUnlessTrigger;
            result.matchedLimit |= conditionResult.matchedLimit;
            result.matchedActivePeriod |= conditionResult.matchedActivePeriod;
        }

        // Make sure it's within the active period.
        if (!result.matchedActivePeriod) {
            continue;
        }
        
        // Make sure we cancel before matching in case the criteria overlap.
        if (result.matchedUnlessTrigger) {
            NSString *cancelActionName = [@"__Cancel" stringByAppendingString:actionType];
            LPActionContext *context = [LPActionContext actionContextWithName:cancelActionName
                                                                         args:@{}
                                                                    messageId:messageId];
            [self triggerAction:context handledBlock:^(BOOL success) {
                if (success) {
                    // Track cancel.
                    [Leanplum track:@"Cancel" withValue:0.0 andInfo:nil
                            andArgs:@{LP_PARAM_MESSAGE_ID: messageId} andParameters:nil];
                }
            }];
        }
        if (result.matchedTrigger) {
            [[LPInternalState sharedState].actionManager recordMessageTrigger:internalMessageId];
            if (result.matchedLimit) {
                NSNumber *priority = messageConfig[@"priority"] ?: @(DEFAULT_PRIORITY);
                LPActionContext *context = [LPActionContext
                                            actionContextWithName:actionType
                                            args:[messageConfig objectForKey:LP_KEY_VARS]
                                            messageId:internalMessageId
                                            originalMessageId:messageId
                                            priority:priority];
                context.contextualValues = contextualValues;
                [actionContexts addObject:context];
            }
        }
    }

    // Return if there are no action to trigger.
    if ([actionContexts count] == 0) {
        return;
    }

    // Sort the action by priority and only show one message.
    // Make sure to capture the held back.
    [LPActionContext sortByPriority:actionContexts];
    NSNumber *priorityThreshold = [((LPActionContext *) [actionContexts firstObject]) priority];
    NSNumber *countDownThreshold = [self fetchCountDownForContext: (LPActionContext *) [actionContexts firstObject] withMessages:messages];
    BOOL isPrioritySame = NO;
    for (LPActionContext *actionContext in actionContexts) {
        NSNumber *priority = [actionContext priority];
        if (priority.intValue > priorityThreshold.intValue) {
            break;
        }
        if (isPrioritySame) {//priority is same
            NSNumber *currentCountDown = [self fetchCountDownForContext:actionContext withMessages:messages];
            //multiple messages have same priority and same countDown, only display one message
            if (currentCountDown == countDownThreshold) {
                break;
            }
        }
        isPrioritySame = YES;
        if ([[actionContext actionName] isEqualToString:LP_HELD_BACK_ACTION]) {
            [[LPInternalState sharedState].actionManager
                 recordHeldBackImpression:[actionContext messageId]
                        originalMessageId:[actionContext originalMessageId]];
        } else {
            [self triggerAction:actionContext handledBlock:^(BOOL success) {
                if (success) {
                    [[LPInternalState sharedState].actionManager
                         recordMessageImpression:[actionContext messageId]];
                }
            }];
        }
    }
}

+ (NSNumber *)fetchCountDownForContext:(LPActionContext *)actionContext withMessages:(NSDictionary *)messageDict
{
    NSDictionary *messageConfig = messageDict[actionContext.messageId];
    NSNumber *countdown = messageConfig[@"countdown"];
    if (actionContext.isPreview) {
        countdown = @(5.0);
    }
    return countdown;
}

+ (LPActionContext *)createActionContextForMessageId:(NSString *)messageId
{
    NSDictionary *messageConfig = [[LPVarCache sharedCache] messages][messageId];
    LPActionContext *context =
        [LPActionContext actionContextWithName:messageConfig[@"action"]
                                          args:messageConfig[LP_KEY_VARS]
                                     messageId:messageId];
    return context;
}

+  (void)setVariantDebugInfoEnabled:(BOOL)variantDebugInfoEnabled
{
    [LPInternalState sharedState].isVariantDebugInfoEnabled = variantDebugInfoEnabled;
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"set_variant_debug_info_enabled"];
}

+ (void)trackAllAppScreens
{
    [Leanplum trackAllAppScreensWithMode:LPTrackScreenModeDefault];
}

+ (void)trackAllAppScreensWithMode:(LPTrackScreenMode)trackScreenMode;
{
    RETURN_IF_NOOP;
    LP_TRY
    if (![LPInternalState sharedState].isInterfaceEditingEnabled) {
        LPLog(LPWarning, @"LeanplumUIEditor module is required to track all screens. "
                         @"Call allowInterfaceEditing before this method.");
    }
    
    BOOL stripViewControllerFromState = trackScreenMode == LPTrackScreenModeStripViewController;
    [[LPInternalState sharedState] setStripViewControllerFromState:stripViewControllerFromState];
    [LPUIEditorWrapper enableAutomaticScreenTracking];
    LP_END_TRY
}

+ (void)trackPurchase:(NSString *)event withValue:(double)value
      andCurrencyCode:(NSString *)currencyCode andParameters:(NSDictionary *)params
{
    RETURN_IF_NOOP;
    LP_TRY
    NSMutableDictionary *arguments = [NSMutableDictionary new];
    if (currencyCode) {
        arguments[LP_PARAM_CURRENCY_CODE] = currencyCode;
    }

    [Leanplum track:event
          withValue:value
            andArgs:arguments
      andParameters:params];
    LP_END_TRY
}

+ (void)trackInAppPurchases
{
    RETURN_IF_NOOP;
    LP_TRY
    [[LPRevenueManager sharedManager] trackRevenue];
    LP_END_TRY
}

+ (void)trackInAppPurchase:(SKPaymentTransaction *)transaction
{
    RETURN_IF_NOOP;
    LP_TRY
    if (!transaction) {
        [self throwError:@"[Leanplum trackInAppPurchase:] Nil transaction parameter provided."];
    } else if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
        [[LPRevenueManager sharedManager] addTransaction:transaction];
    } else {
        [self throwError:@"You are trying to track a transaction that is not purchased yet!"];
    }
    LP_END_TRY
}

+ (NSMutableDictionary *)makeTrackArgs:(NSString *)event withValue:(double)value andInfo: (NSString *)info andArgs:(NSDictionary *)args andParameters:(NSDictionary *)params {
    NSString *valueStr = [NSString stringWithFormat:@"%f", value];
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      valueStr, LP_PARAM_VALUE, nil];
    if (args) {
        [arguments addEntriesFromDictionary:args];
    }
    if (event) {
        arguments[LP_PARAM_EVENT] = event;
    }
    if (info) {
        arguments[LP_PARAM_INFO] = info;
    }
    if (params) {
        params = [Leanplum validateAttributes:params named:@"params" allowLists:NO];
        arguments[LP_PARAM_PARAMS] = [LPJSON stringFromJSON:params];
    }
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        arguments[@"allowOffline"] = @YES;
    }
    return arguments;
}

+ (void)track:(NSString *)event withValue:(double)value andInfo:(NSString *)info
      andArgs:(NSDictionary *)args andParameters:(NSDictionary *)params
{
    RETURN_IF_NOOP;
    LP_TRY
    
    // Track should not be called in background.
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self track:event withValue:value andInfo:info andArgs:args andParameters:params];
        });
        return;
    }
    
    NSMutableDictionary *arguments = [self makeTrackArgs:event withValue:value andInfo:info andArgs:args andParameters:params];
    
    [self onStartIssued:^{
        [self trackInternal:event withArgs:arguments andParameters:params];
    }];
    LP_END_TRY
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"track"];
}

+ (void)trackGeofence:(LPGeofenceEventType)event withInfo:(NSString *)info {
    if ([[LPFeatureFlagManager sharedManager] isFeatureFlagEnabled:@"track_geofence"]) {
        [self trackGeofence:event withValue:0.0 andInfo:info andArgs:nil andParameters:nil];
    } else {
        [[LPCountAggregator sharedAggregator] incrementCount:@"track_geofence_disabled"];
    }
}

+ (void)trackGeofence:(LPGeofenceEventType)event withValue:(double)value andInfo:(NSString *)info
                           andArgs:(NSDictionary *)args andParameters:(NSDictionary *)params
{
    RETURN_IF_NOOP;
    LP_TRY
    
    // TrackGeofence should not be called in background.
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self trackGeofence:event withValue:value andInfo:info andArgs:args andParameters:params];
        });
        return;
    }
    
    NSString *eventName = [LPEnumConstants getEventNameFromGeofenceType:event];
    
    NSMutableDictionary *arguments = [self makeTrackArgs:eventName withValue:value andInfo:info andArgs:args andParameters:params];
    
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory trackGeofenceWithParams:arguments];
    [[LPRequestSender sharedInstance] sendIfConnected:request];
    LP_END_TRY
}

+ (void)trackInternal:(NSString *)event withArgs:(NSDictionary *)args
        andParameters:(NSDictionary *)params
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory trackWithParams:args];
    [[LPRequestSender sharedInstance] send:request];

    // Perform event actions.
    NSString *messageId = args[LP_PARAM_MESSAGE_ID];
    if (messageId) {
        if (event && event.length > 0) {
            event = [NSString stringWithFormat:@".m%@ %@", messageId, event];
        } else {
            event = [NSString stringWithFormat:@".m%@", messageId];
        }
    }

    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];
    contextualValues.parameters = params;
    NSMutableDictionary *contextualArguments = [args mutableCopy];
    if (args[LP_PARAM_PARAMS]) {
        contextualArguments[LP_PARAM_PARAMS] = [LPJSON JSONFromString:args[LP_PARAM_PARAMS]];
    }
    contextualValues.arguments = contextualArguments;

    [self maybePerformActions:@[@"event"]
                withEventName:event
                   withFilter:kLeanplumActionFilterAll
                fromMessageId:messageId
         withContextualValues:contextualValues];
}

+ (void)track:(NSString *)event
{
    [self track:event withValue:0.0 andInfo:nil andParameters:nil];
}

+ (void)track:(NSString *)event withValue:(double)value
{
    [self track:event withValue:value andInfo:nil andParameters:nil];
}

+ (void)track:(NSString *)event withInfo:(NSString *)info
{
    [self track:event withValue:0.0 andInfo:info andParameters:nil];
}

+ (void)track:(NSString *)event withParameters:(NSDictionary *)params
{
    [self track:event withValue:0.0 andInfo:nil andParameters:params];
}

+ (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params
{
    [self track:event withValue:value andInfo:nil andParameters:params];
}

+ (void)track:(NSString *)event withValue:(double)value andInfo:(NSString *)info
{
    [self track:event withValue:value andInfo:info andParameters:nil];
}

+ (void)track:(NSString *)event
    withValue:(double)value
      andArgs:(NSDictionary *)args
andParameters:(NSDictionary *)params
{
    [self track:event withValue:value andInfo:nil andArgs:args andParameters:params];
}

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(NSString *)info
andParameters:(NSDictionary *)params
{
    [self track:event withValue:value andInfo:info andArgs:nil andParameters:params];
}

+ (void)trackException:(NSException *) exception
{
    RETURN_IF_NOOP;
    LP_TRY
    NSDictionary *exceptionDict = @{
        LP_KEY_REASON: exception.reason,
        LP_KEY_USER_INFO: exception.userInfo,
        LP_KEY_STACK_TRACE: exception.callStackSymbols
    };
    NSString *info = [LPJSON stringFromJSON:exceptionDict];
    [self track:LP_EVENT_EXCEPTION withInfo:info];
    LP_END_TRY
}

+ (void)setUserAttributes:(NSDictionary *)attributes
{
    [self setUserId:@"" withUserAttributes:attributes];
}

+ (void)setUserId:(NSString *)userId
{
    [self setUserId:userId withUserAttributes:@{}];
}

+ (void)setUserId:(NSString *)userId withUserAttributes:(NSDictionary *)attributes
{
    RETURN_IF_NOOP;
    // TODO(aleksandar): Allow this to be called before start, which will
    // modify the arguments to start rather than issuing a separate API call.
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"You cannot call setUserId before calling start"];
        return;
    }
    LP_END_USER_CODE // Catch when setUser is called in start response.
    LP_TRY
    attributes = [self validateAttributes:attributes named:@"userAttributes" allowLists:YES];
    [self onStartIssued:^{
        [self setUserIdInternal:userId withAttributes:attributes];
    }];
    LP_END_TRY
    LP_BEGIN_USER_CODE
}

+ (void)setUserIdInternal:(NSString *)userId withAttributes:(NSDictionary *)attributes
{
    // Some clients are calling this method with NSNumber. Handle it gracefully.
    id tempUserId = userId;
    if ([tempUserId isKindOfClass:[NSNumber class]]) {
        LPLog(LPWarning, @"setUserId is called with NSNumber. Please use NSString.");
        userId = [tempUserId stringValue];
    }

    // Attributes can't be nil
    if (!attributes) {
        attributes = @{};
    }

    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory setUserAttributesWithParams:@{
        LP_PARAM_USER_ATTRIBUTES: attributes ? [LPJSON stringFromJSON:attributes] : @"",
        LP_PARAM_NEW_USER_ID: userId ? userId : @""
        }];
    [[LPRequestSender sharedInstance] send:request];

    if (userId.length) {
        [[LPAPIConfig sharedConfig] setUserId:userId];
        if ([LPInternalState sharedState].hasStarted) {
            [[LPVarCache sharedCache] saveDiffs];
        }
    }

    if (attributes != nil) {
        @synchronized([LPInternalState sharedState].userAttributeChanges) {
            [[LPInternalState sharedState].userAttributeChanges addObject:attributes];
        }
    }

    [Leanplum onStartResponse:^(BOOL success) {
        LP_END_USER_CODE
        [self recordAttributeChanges];
        LP_BEGIN_USER_CODE
    }];

}

// Returns if attributes have changed.
+ (void)recordAttributeChanges
{
    @synchronized([LPInternalState sharedState].userAttributeChanges){
        BOOL __block madeChanges = NO;
        NSMutableDictionary *existingAttributes = [[LPVarCache sharedCache] userAttributes];
        for (NSDictionary *attributes in [LPInternalState sharedState].userAttributeChanges) {
            [attributes enumerateKeysAndObjectsUsingBlock:^(id attributeName, id value, BOOL *stop) {
                id existingValue = existingAttributes[attributeName];
                if (![value isEqual:existingValue]) {
                    LPContextualValues *contextualValues = [LPContextualValues new];
                    contextualValues.previousAttributeValue = existingValue;
                    contextualValues.attributeValue = value;
                    existingAttributes[attributeName] = value;
                    [Leanplum maybePerformActions:@[@"userAttribute"]
                                    withEventName:attributeName
                                       withFilter:kLeanplumActionFilterAll
                                    fromMessageId:nil
                             withContextualValues:contextualValues];
                    madeChanges = YES;
                }
            }];
        }
        [[LPInternalState sharedState].userAttributeChanges removeAllObjects];
        if (madeChanges) {
            [[LPVarCache sharedCache] saveUserAttributes];
        }
    }
}

+ (void)setTrafficSourceInfo:(NSDictionary *)info
{
    if ([LPUtils isNullOrEmpty:info]) {
        [self throwError:@"[Leanplum setTrafficSourceInfo:] Empty info parameter provided."];
        return;
    }
    RETURN_IF_NOOP;
    LP_TRY
    info = [self validateAttributes:info named:@"info" allowLists:NO];
    [self onStartIssued:^{
        [self setTrafficSourceInfoInternal:info];
    }];
    LP_END_TRY
}

+ (void)setTrafficSourceInfoInternal:(NSDictionary *)info
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory setTrafficSourceInfoWithParams:@{
        LP_PARAM_TRAFFIC_SOURCE: info
        }];
    [[LPRequestSender sharedInstance] send:request];
}

+ (void)advanceTo:(NSString *)state
{
    [self advanceTo:state withInfo:nil];
}

+ (void)advanceTo:(NSString *)state withInfo:(NSString *)info
{
    [self advanceTo:state withInfo:info andParameters:nil];
}

+ (void)advanceTo:(NSString *)state withParameters:(NSDictionary *)params
{
    [self advanceTo:state withInfo:nil andParameters:params];
}

+ (void)advanceTo:(NSString *)state withInfo:(NSString *)info andParameters:(NSDictionary *)params
{
    RETURN_IF_NOOP;
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"You cannot call advanceTo before calling start"];
        return;
    }
    LP_TRY
    if (state &&
        [[LPInternalState sharedState] stripViewControllerFromState] &&
        [state hasSuffix:@"ViewController"]) {
        state = [state substringToIndex:([state length] - [@"ViewController" length])];
    }
    NSMutableDictionary *args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 state ? state : @"", LP_PARAM_STATE, nil];
    if (info) {
        args[LP_PARAM_INFO] = info;
    }
    if (params) {
        params = [Leanplum validateAttributes:params named:@"params" allowLists:NO];
        args[LP_PARAM_PARAMS] = [LPJSON stringFromJSON:params];
    }

    [self onStartIssued:^{
        [self advanceToInternal:state withArgs:args andParameters:params];
    }];
    LP_END_TRY
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"advance_to"];
}

+ (void)advanceToInternal:(NSString *)state withArgs:(NSDictionary *)args
            andParameters:(NSDictionary *)params
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory advanceWithParams:args];
    [[LPRequestSender sharedInstance] send:request];
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];
    contextualValues.parameters = params;
    [self maybePerformActions:@[@"state"]
                withEventName:state
                   withFilter:kLeanplumActionFilterAll
                fromMessageId:nil
         withContextualValues:contextualValues];
}

+ (void)pauseState
{
    RETURN_IF_NOOP;
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"You cannot call pauseState before calling start"];
        return;
    }
    LP_TRY
    [self onStartIssued:^{
        [self pauseStateInternal];
    }];
    LP_END_TRY
}

+ (void)pauseStateInternal
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory pauseStateWithParams:@{}];
    [[LPRequestSender sharedInstance] send:request];
}

+ (void)resumeState
{
    RETURN_IF_NOOP;
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"You cannot call resumeState before calling start"];
        return;
    }
    LP_TRY
    [self onStartIssued:^{
        [self resumeStateInternal];
    }];
    LP_END_TRY
}

+ (void)resumeStateInternal
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory resumeStateWithParams:@{}];
    [[LPRequestSender sharedInstance] send:request];
}

+ (void)forceContentUpdate
{
    [self forceContentUpdate:nil];
}

+ (void)forceContentUpdate:(LeanplumVariablesChangedBlock)block
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"force_content_update"];
    
    if (IS_NOOP) {
        if (block) {
            block();
        }
        return;
    }
    LP_TRY
    NSMutableDictionary *params = [@{
        LP_PARAM_INCLUDE_DEFAULTS: @(NO),
        LP_PARAM_INBOX_MESSAGES: [[self inbox] messagesIds]
    } mutableCopy];
    
    if ([LPInternalState sharedState].isVariantDebugInfoEnabled) {
        params[LP_PARAM_INCLUDE_VARIANT_DEBUG_INFO] = @(YES);
    }

    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory getVarsWithParams:params];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
        LP_TRY
        NSDictionary *values = response[LP_KEY_VARS];
        NSDictionary *messages = response[LP_KEY_MESSAGES];
        NSArray *updateRules = response[LP_KEY_UPDATE_RULES];
        NSArray *eventRules = response[LP_KEY_EVENT_RULES];
        NSArray *variants = response[LP_KEY_VARIANTS];
        NSDictionary *regions = response[LP_KEY_REGIONS];
        NSDictionary *variantDebugInfo = [self parseVariantDebugInfoFromResponse:response];
        [[LPVarCache sharedCache] setVariantDebugInfo:variantDebugInfo];
        NSDictionary *filenameToURLs = [self parseFileURLsFromResponse:response];
        [LPFileTransferManager sharedInstance].filenameToURLs = filenameToURLs;

        if (![values isEqualToDictionary:[LPVarCache sharedCache].diffs] ||
            ![messages isEqualToDictionary:[LPVarCache sharedCache].messageDiffs] ||
            ![updateRules isEqualToArray:[LPVarCache sharedCache].updateRulesDiffs] ||
            ![eventRules isEqualToArray:[LPVarCache sharedCache].eventRulesDiffs] ||
            ![variants isEqualToArray:[LPVarCache sharedCache].variants] ||
            ![regions isEqualToDictionary:[LPVarCache sharedCache].regions]) {
            [[LPVarCache sharedCache] applyVariableDiffs:values
                                  messages:messages
                               updateRules:updateRules
                                eventRules:eventRules
                                  variants:variants
                                   regions:regions
                          variantDebugInfo:variantDebugInfo];

        }
        if ([response[LP_KEY_SYNC_INBOX] boolValue]) {
            [[self inbox] downloadMessages];
        } else {
            [[self inbox] triggerInboxSyncedWithStatus:YES];
        }
        LP_END_TRY
        if (block) {
            block();
        }
    }];
    [request onError:^(NSError *error) {
        if (block) {
            block();
        }
        [[self inbox] triggerInboxSyncedWithStatus:NO];
    }];
    [[LPRequestSender sharedInstance] sendIfConnected:request];
    LP_END_TRY
}

+ (void)enableTestMode
{
    LP_TRY
    [LPConstantsState sharedState].isTestMode = YES;
    LP_END_TRY
}

+ (void)setTestModeEnabled:(BOOL)isTestModeEnabled
{
    LP_TRY
    [LPConstantsState sharedState].isTestMode = isTestModeEnabled;
    LP_END_TRY
}

void leanplumExceptionHandler(NSException *exception)
{
    [Leanplum trackException:exception];
    if ([LPInternalState sharedState].customExceptionHandler) {
        [LPInternalState sharedState].customExceptionHandler(exception);
    }
}

+ (void)createDefaultExceptionHandler
{
    RETURN_IF_NOOP;
    [LPInternalState sharedState].customExceptionHandler = nil;
    NSSetUncaughtExceptionHandler(&leanplumExceptionHandler);
}

+ (void)createExceptionHandler:(NSUncaughtExceptionHandler *)customHandler
{
    RETURN_IF_NOOP;
    [LPInternalState sharedState].customExceptionHandler = customHandler;
    NSSetUncaughtExceptionHandler(&leanplumExceptionHandler);
}

+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)extension
{
    if ([LPUtils isNullOrEmpty:name]) {
        [self throwError:@"[Leanplum pathForResource:ofType:] Empty name parameter provided."];
        return nil;
    }
    if ([LPUtils isNullOrEmpty:extension]) {
        [self throwError:@"[Leanplum pathForResource:ofType:] Empty name extension provided."];
        return nil;
    }
    LP_TRY
    LPVar *resource = [LPVar define:name withFile:[name stringByAppendingFormat:@".%@", extension]];
    return [resource fileValue];
    LP_END_TRY
    return nil;
}

+ (id)objectForKeyPath:(id)firstComponent, ...
{
    LP_TRY
    NSMutableArray *components = [[NSMutableArray alloc] init];
    va_list args;
    va_start(args, firstComponent);
    for (id component = firstComponent;
         component != nil; component = va_arg(args, id)) {
        [components addObject:component];
    }
    va_end(args);
    return [[LPVarCache sharedCache] getMergedValueFromComponentArray:components];
    LP_END_TRY
    return nil;
}

+ (id)objectForKeyPathComponents:(NSArray *) pathComponents
{
    LP_TRY
    return [[LPVarCache sharedCache] getMergedValueFromComponentArray:pathComponents];
    LP_END_TRY
    return nil;
}

+ (NSArray *)variants
{
    LP_TRY
    NSArray *variants = [[LPVarCache sharedCache] variants];
    if (variants) {
        return variants;
    }
    LP_END_TRY
    return [NSArray array];
}

+ (NSDictionary *)variantDebugInfo
{
    LP_TRY
    NSDictionary *variantDebugInfo = [[LPVarCache sharedCache] variantDebugInfo];
    if (variantDebugInfo) {
        return variantDebugInfo;
    }
    LP_END_TRY
    return [NSDictionary dictionary];
}

+ (NSDictionary *)messageMetadata
{
    LP_TRY
    NSDictionary *messages = [[LPVarCache sharedCache] messages];
    if (messages) {
        return messages;
    }
    LP_END_TRY
    return [NSDictionary dictionary];
}

+ (void)setPushSetup:(LeanplumPushSetupBlock)block
{
    LP_TRY
    pushSetupBlock = block;
    LP_END_TRY
}

+ (LeanplumPushSetupBlock)pushSetupBlock
{
    LP_TRY
    return pushSetupBlock;
    LP_END_TRY
    return nil;
}

+ (BOOL)isPreLeanplumInstall
{
    LP_TRY
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"[Leanplum start] must be called before calling isPreLeanplumInstall"];
        return NO;
    }
    return [[NSUserDefaults standardUserDefaults]
            boolForKey:LEANPLUM_DEFAULTS_PRE_LEANPLUM_INSTALL_KEY];
    LP_END_TRY
    return NO;
}

+ (NSString *)deviceId
{
    LP_TRY
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"[Leanplum start] must be called before calling deviceId"];
        return nil;
    }
    return [LPAPIConfig sharedConfig].deviceId;
    LP_END_TRY
    return nil;
}

+ (NSString *)userId
{
    LP_TRY
    if (![LPInternalState sharedState].calledStart) {
        [self throwError:@"[Leanplum start] must be called before calling userId"];
        return nil;
    }
    return [LPAPIConfig sharedConfig].userId;
    LP_END_TRY
    return nil;
}

+ (LPInbox *)inbox
{
    LP_TRY
    return [LPInbox sharedState];
    LP_END_TRY
    return nil;
}

+ (LPNewsfeed *)newsfeed
{
    LP_TRY
    return [LPNewsfeed sharedState];
    LP_END_TRY
    return nil;
}

void LPLog(LPLogType type, NSString *format, ...) {
    va_list vargs;
    va_start(vargs, format);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:vargs];
    va_end(vargs);

    NSString *message;
    switch (type) {
        case LPDebug:
#ifdef DEBUG
            message = [NSString stringWithFormat:@"Leanplum DEBUG: %@", formattedMessage];
            printf("%s\n", [message UTF8String]);
#endif
            return;
        case LPVerbose:
            if ([LPConstantsState sharedState].isDevelopmentModeEnabled
                && [LPConstantsState sharedState].verboseLoggingInDevelopmentMode) {
                message = [NSString stringWithFormat:@"Leanplum VERBOSE: %@", formattedMessage];
                printf("%s\n", [message UTF8String]);
                [Leanplum maybeSendLog:message];
            }
            return;
        case LPError:
            message = [NSString stringWithFormat:@"Leanplum ERROR: %@", formattedMessage];
            printf("%s\n", [message UTF8String]);
            [Leanplum maybeSendLog:message];
            return;
        case LPWarning:
            message = [NSString stringWithFormat:@"Leanplum WARNING: %@", formattedMessage];
            printf("%s\n", [message UTF8String]);
            [Leanplum maybeSendLog:message];
            return;
        case LPInfo:
            message = [NSString stringWithFormat:@"Leanplum INFO: %@", formattedMessage];
            printf("%s\n", [message UTF8String]);
            [Leanplum maybeSendLog:message];
            return;
        case LPInternal:
            message = [NSString stringWithFormat:@"Leanplum INTERNAL: %@", formattedMessage];
            [Leanplum maybeSendLog:message];
            return;
        default:
            return;
    }
}

+ (void)maybeSendLog:(NSString *)message {
    if (![LPConstantsState sharedState].loggingEnabled) {
        return;
    }

    NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
    BOOL isLogging = [[[[NSThread currentThread] threadDictionary]
                       objectForKey:LP_IS_LOGGING] boolValue];

    if (isLogging) {
        return;
    }

    threadDict[LP_IS_LOGGING] = @YES;

    @try {
        LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                        initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
        id<LPRequesting> request = [reqFactory logWithParams:@{
                                                      LP_PARAM_TYPE: LP_VALUE_SDK_LOG,
                                                      LP_PARAM_MESSAGE: message
                                                      }];
                [[LPRequestSender sharedInstance] sendEventually:request sync:NO];
    } @catch (NSException *exception) {
        NSLog(@"Leanplum: Unable to send log: %@", exception);
    } @finally {
        [threadDict removeObjectForKey:LP_IS_LOGGING];
    }
}

/**
 * Returns the name of LPLocationAccuracyType.
 */
+ (NSString *)getLocationAccuracyTypeName:(LPLocationAccuracyType)locationAccuracyType
{
    switch(locationAccuracyType) {
        case LPLocationAccuracyIP:
            return @"ip";
        case LPLocationAccuracyCELL:
            return @"cell";
        case LPLocationAccuracyGPS:
            return @"gps";
        default:
            LPLog(LPError, @"Unexpected LPLocationType.");
            return nil;
    }
}

+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"setDeviceLocationWithLatitude_longitude"];
    [Leanplum setDeviceLocationWithLatitude:latitude
                                  longitude:longitude
                                       type:LPLocationAccuracyCELL];
}

+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
                                 type:(LPLocationAccuracyType)type
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"setDeviceLocationWithLatitude_longitude_type"];
    [Leanplum setDeviceLocationWithLatitude:latitude longitude:longitude
                                       city:nil region:nil country:nil
                                       type:type];
}

+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
                                 city:(NSString *)city
                               region:(NSString *)region
                              country:(NSString *)country
                                 type:(LPLocationAccuracyType)type
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"setDeviceLocationWithLatitude_longitude_city_region_country_type"];
    LP_TRY
    if ([LPConstantsState sharedState].isLocationCollectionEnabled &&
        NSClassFromString(@"LPLocationManager")) {
        LPLog(LPWarning, @"Leanplum is automatically collecting device location, "
              "so there is no need to call setDeviceLocation. If you prefer to "
              "always set location manually, then call disableLocationCollection:.");
    }

    [self setUserLocationAttributeWithLatitude:latitude longitude:longitude
                                          city:city region:region country:country
                                          type:type responseHandler:nil];
    LP_END_TRY
}

+ (void)setUserLocationAttributeWithLatitude:(double)latitude
                                   longitude:(double)longitude
                                        city:(NSString *)city
                                      region:(NSString *)region
                                     country:(NSString *)country
                                        type:(LPLocationAccuracyType)type
                             responseHandler:(LeanplumSetLocationBlock)response
{
    LP_TRY
    NSMutableDictionary *params = [@{
        LP_KEY_LOCATION: [NSString stringWithFormat:@"%.6f,%.6f", latitude, longitude],
        LP_KEY_LOCATION_ACCURACY_TYPE: [self getLocationAccuracyTypeName:type]
    } mutableCopy];
    if (city) {
        params[LP_KEY_CITY] = city;
    }
    if (region) {
        params[LP_KEY_REGION] = region;
    }
    if (country) {
        params[LP_KEY_COUNTRY] = country;
    }

    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory setUserAttributesWithParams:params];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (response) {
            response(YES);
        }
    }];
    [request onError:^(NSError *error) {
        LPLog(LPError, @"setUserAttributes failed with error: %@", error);
        if (response) {
            response(NO);
        }
    }];
    [[LPRequestSender sharedInstance] send:request];
    LP_END_TRY
}

+ (void)disableLocationCollection
{
    LP_TRY
    [LPConstantsState sharedState].isLocationCollectionEnabled = NO;
    LP_END_TRY
}

+ (NSDictionary *)parseVariantDebugInfoFromResponse:(NSDictionary *)response
{
    if ([response objectForKey:LP_KEY_VARIANT_DEBUG_INFO]) {
        return response[LP_KEY_VARIANT_DEBUG_INFO];
    }
    return nil;
}

+ (NSSet<NSString *> *)parseEnabledCountersFromResponse:(NSDictionary *)response
{
    if ([response objectForKey:LP_KEY_ENABLED_COUNTERS]) {
        return [NSSet setWithArray:response[LP_KEY_ENABLED_COUNTERS]];
    }
    return nil;
}

+ (NSSet<NSString *> *)parseEnabledFeatureFlagsFromResponse:(NSDictionary *)response
{
    if ([response objectForKey:LP_KEY_ENABLED_FEATURE_FLAGS]) {
        return [NSSet setWithArray:response[LP_KEY_ENABLED_FEATURE_FLAGS]];
    }
    return nil;
}

+ (NSDictionary *)parseFileURLsFromResponse:(NSDictionary *)response {
    if ([response objectForKey:LP_KEY_FILES]) {
        return [NSDictionary dictionaryWithDictionary:[response objectForKey:LP_KEY_FILES]];
    }
    return nil;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
