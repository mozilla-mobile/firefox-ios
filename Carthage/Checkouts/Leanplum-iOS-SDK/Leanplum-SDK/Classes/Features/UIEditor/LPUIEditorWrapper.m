//
//  LPUIEditorWrapper.m
//  Leanplum
//
//  Created by Milos Jakovljevic on 3/27/17.
//  Copyright (c) 2017 Leanplum, Inc. All rights reserved.
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

#import "LPUIEditorWrapper.h"
#import "LPCountAggregator.h"

@implementation LPUIEditorWrapper

NSString *LP_EDITOR_EVENT_NAME = @"__leanplum_editor_NAME";

NSString *LP_EDITOR_KEY_ACTION = @"action";
NSString *LP_EDITOR_KEY_MODE = @"mode";

NSString *LP_EDITOR_PARAM_START_UPDATING = @"editorStartUpdating";
NSString *LP_EDITOR_PARAM_STOP_UPDATING = @"editorStopUpdate";
NSString *LP_EDITOR_PARAM_SEND_UPDATE = @"editorSendUpdate";
NSString *LP_EDITOR_PARAM_SEND_UPDATE_DELAYED = @"editorSendUpdateDelayed";
NSString *LP_EDITOR_PARAM_SET_MODE = @"editorSetMode";
NSString *LP_EDITOR_PARAM_AUTOMATIC_SCREEN_TRACKING = @"editorAutomaticScreenTracking";

+ (void)startUpdating
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_START_UPDATING
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"start_updating_ui"];
}

+ (void)stopUpdating
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_STOP_UPDATING
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}

+ (void)sendUpdate
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_SEND_UPDATE
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_update_ui"];
}

+ (void)sendUpdateDelayed
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_SEND_UPDATE_DELAYED
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}

+ (void)setMode:(NSInteger)mode
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_SET_MODE,
                           LP_EDITOR_KEY_MODE: @(mode)
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}

+ (void)enableAutomaticScreenTracking
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_AUTOMATIC_SCREEN_TRACKING
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}
@end
