//
//  LeanplumSocket.m
//  Leanplum
//
//  Created by Andrew First on 5/5/12.
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

#import "LeanplumSocket.h"
#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "LPConstants.h"
#import "LPVarCache.h"
#import "LPActionManager.h"
#import "LPUIAlert.h"
#import "LPUIEditorWrapper.h"
#import "LPAPIConfig.h"
#import "LPCountAggregator.h"

id<LPNetworkEngineProtocol> engine_;

@interface LeanplumSocket()

@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end

@implementation LeanplumSocket

static LeanplumSocket *leanplum_sharedSocket = nil;
static dispatch_once_t leanplum_onceToken;

+ (LeanplumSocket *)sharedSocket
{
    dispatch_once(&leanplum_onceToken, ^{
        leanplum_sharedSocket = [[self alloc] init];
    });
    return leanplum_sharedSocket;
}

+ (id<LPNetworkEngineProtocol>)engine
{
    if (engine_ == nil) {
        NSString *userAgentString = [NSString stringWithFormat:@"%@/%@(%@; %@; %@)",
                                     NSBundle.mainBundle.infoDictionary[(NSString *)
                                                                        kCFBundleNameKey],
                                     NSBundle.mainBundle.infoDictionary[(NSString *)
                                                                        kCFBundleVersionKey],
                                     [LPAPIConfig sharedConfig].appId,
                                     LEANPLUM_CLIENT,
                                     LEANPLUM_SDK_VERSION];
        engine_ = [LPNetworkFactory
                   engineWithHostName:[LPConstantsState sharedState].socketHost
                   customHeaderFields:@{@"User-Agent": userAgentString}];
    }
    return engine_;
}

- (id)init
{
    self = [super init];
    if (self) {
        if (![LPConstantsState sharedState].isTestMode) {
            if (_socketIO == nil) {
                _socketIO = [[Leanplum_SocketIO alloc] initWithDelegate:self];
            }
            _connected = NO;
        }
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

- (void)connectToAppId:(NSString *)appId deviceId:(NSString *)deviceId
{
    if (!_socketIO) {
        return;
    }
    _appId = appId;
    _deviceId = deviceId;
    [self connect];
    _reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self
                                                     selector:@selector(reconnect)
                                                     userInfo:nil repeats:YES];
    
    [self.countAggregator incrementCount:@"connect_to_app_id"];
}

- (void)connect
{
    int port = [LPConstantsState sharedState].socketPort;
    [_socketIO connectWithEngine:[LeanplumSocket engine]
                        withHost:[LPConstantsState sharedState].socketHost
                          onPort:port
                secureConnection:port == 443];
}

- (void)reconnect
{
    if (!_connected) {
        [self connect];
    }
}

- (void)socketIODidConnect:(Leanplum_SocketIO *)socket
{
    if (!_authSent) {
        NSLog(@"Leanplum: Connected to development server");
        NSDictionary *dict = @{
            LP_PARAM_APP_ID: _appId,
            LP_PARAM_DEVICE_ID: _deviceId
        };
        [_socketIO sendEvent:@"auth" withData:dict];
        _authSent = YES;
        _connected = YES;
    }
}

-(void)socketIODidDisconnect:(Leanplum_SocketIO *)socketIO
{
    NSLog(@"Leanplum: Disconnected from development server");
    _connected = NO;
    _authSent = NO;
}

- (void)socketIO:(Leanplum_SocketIO *)socketIO didReceiveEvent:(Leanplum_SocketIOPacket *)packet
{
    LP_TRY
    if ([packet.name isEqualToString:@"updateVars"]) {
        // Refresh variables.
        [Leanplum forceContentUpdate];
    } else if ([packet.name isEqualToString:@"trigger"]) {
        // Trigger a custom action.
        NSDictionary *payload = [packet dataAsJSON][@"args"][0];
        id action = payload[LP_PARAM_ACTION];
        if (action && [action isKindOfClass:[NSDictionary class]]) {
            NSString *messageId = [payload[LP_PARAM_MESSAGE_ID] description];
            BOOL isRooted = [payload[@"isRooted"] boolValue];
            NSString *actionType = action[LP_VALUE_ACTION_ARG];
            NSDictionary *defaultArgs = [LPVarCache sharedCache].actionDefinitions
                                          [action[LP_VALUE_ACTION_ARG]] [@"values"];
            action = [[LPVarCache sharedCache] mergeHelper:defaultArgs withDiffs:action];
            LPActionContext *context = [LPActionContext actionContextWithName:actionType
                                                                         args:action
                                                                    messageId:messageId];
            [context setIsPreview:YES];
            context.preventRealtimeUpdating = YES;
            [context setIsRooted:isRooted];
            [context maybeDownloadFiles];
            [Leanplum triggerAction:context];
            [[LPActionManager sharedManager] recordMessageImpression:messageId];
        }

    } else if ([packet.name isEqualToString:@"getVariables"]) {
        BOOL sentValues = [[LPVarCache sharedCache] sendVariablesIfChanged];
        [[LPVarCache sharedCache] maybeUploadNewFiles];
        [self sendEvent:@"getContentResponse" withData:@{@"updated": @(sentValues)}];

    } else if ([packet.name isEqualToString:@"getActions"]) {
        BOOL sentValues = [[LPVarCache sharedCache] sendActionsIfChanged];
        [[LPVarCache sharedCache] maybeUploadNewFiles];
        [self sendEvent:@"getContentResponse" withData:@{@"updated": @(sentValues)}];

    } else if ([packet.name isEqualToString:@"getViewHierarchy"]) {
        [LPUIEditorWrapper startUpdating];
        [LPUIEditorWrapper sendUpdate];
    } else if ([packet.name isEqualToString:@"previewUpdateRules"]) {
        NSDictionary *packetData = packet.dataAsJSON[@"args"][0];
        if ([packetData[@"closed"] boolValue]) {
            [LPUIEditorWrapper stopUpdating];
        } else {
            [LPUIEditorWrapper startUpdating];
        }
        if (packetData[@"mode"]) {
            NSInteger mode = [packetData[@"mode"] integerValue];
            if (mode != 0 && mode != 1) {
                NSLog(@"Leanplum: Invalid LPEditor mode in packet.");
            }
            [LPUIEditorWrapper setMode:mode];
        }
        BOOL wasEnabled = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        [[LPVarCache sharedCache] applyUpdateRuleDiffs:packetData[@"rules"]];
        
        dispatch_time_t changeTime = dispatch_time(DISPATCH_TIME_NOW, LP_EDITOR_REDRAW_DELAY
                                                   * NSEC_PER_SEC);
        dispatch_after(changeTime, dispatch_get_main_queue(), ^(void) {
            [UIView setAnimationsEnabled:wasEnabled];
        });
        [LPUIEditorWrapper sendUpdateDelayed];
    } else if ([packet.name isEqualToString:@"registerDevice"]) {
        NSDictionary *packetData = packet.dataAsJSON[@"args"][0];
        NSString *email = packetData[@"email"];
        [Leanplum onHasStartedAndRegisteredAsDeveloper];
        [LPUIAlert showWithTitle:@"Leanplum"
                         message:[NSString stringWithFormat:@"Your device is registered to %@.", email]
               cancelButtonTitle:NSLocalizedString(@"OK", nil)
               otherButtonTitles:nil
                           block:nil];
    } else if ([packet.name isEqualToString:@"applyVars"]) {
        NSDictionary *packetData = packet.dataAsJSON[@"args"][0];
        [[LPVarCache sharedCache] applyVariableDiffs:packetData messages:nil updateRules:nil eventRules:nil
                              variants:nil regions:nil variantDebugInfo:nil];
    }
    LP_END_TRY
}

- (void) sendEvent:(NSString *)eventName withData:(NSDictionary *)data
{
    [_socketIO sendEvent:eventName withData:data];
    
    [self.countAggregator incrementCount:@"send_event_socket"];
}

@end
