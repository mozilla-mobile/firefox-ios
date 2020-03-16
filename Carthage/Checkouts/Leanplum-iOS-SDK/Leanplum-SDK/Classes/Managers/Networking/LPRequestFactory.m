//
//  LPRequestFactory.h
//  Leanplum
//
//  Created by Mayank Sanganeria on 6/30/18.
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
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

#import "LPRequestFactory.h"
#import "LPRequest.h"
#import "LeanplumRequest.h"
#import "LPCountAggregator.h"

NSString *LP_API_METHOD_START = @"start";
NSString *LP_API_METHOD_GET_VARS = @"getVars";
NSString *LP_API_METHOD_SET_VARS = @"setVars";
NSString *LP_API_METHOD_STOP = @"stop";
NSString *LP_API_METHOD_RESTART = @"restart";
NSString *LP_API_METHOD_TRACK = @"track";
NSString *LP_API_METHOD_TRACK_GEOFENCE = @"trackGeofence";
NSString *LP_API_METHOD_ADVANCE = @"advance";
NSString *LP_API_METHOD_PAUSE_SESSION = @"pauseSession";
NSString *LP_API_METHOD_PAUSE_STATE = @"pauseState";
NSString *LP_API_METHOD_RESUME_SESSION = @"resumeSession";
NSString *LP_API_METHOD_RESUME_STATE = @"resumeState";
NSString *LP_API_METHOD_MULTI = @"multi";
NSString *LP_API_METHOD_REGISTER_FOR_DEVELOPMENT = @"registerDevice";
NSString *LP_API_METHOD_SET_USER_ATTRIBUTES = @"setUserAttributes";
NSString *LP_API_METHOD_SET_DEVICE_ATTRIBUTES = @"setDeviceAttributes";
NSString *LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO = @"setTrafficSourceInfo";
NSString *LP_API_METHOD_UPLOAD_FILE = @"uploadFile";
NSString *LP_API_METHOD_DOWNLOAD_FILE = @"downloadFile";
NSString *LP_API_METHOD_HEARTBEAT = @"heartbeat";
NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION = @"saveInterface";
NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE = @"saveInterfaceImage";
NSString *LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST = @"getViewControllerVersionsList";
NSString *LP_API_METHOD_LOG = @"log";
NSString *LP_API_METHOD_GET_INBOX_MESSAGES = @"getNewsfeedMessages";
NSString *LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ = @"markNewsfeedMessageAsRead";
NSString *LP_API_METHOD_DELETE_INBOX_MESSAGE = @"deleteNewsfeedMessage";

@interface LPRequestFactory()

@property (nonatomic, strong) LPFeatureFlagManager *featureFlagManager;
@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end

@implementation LPRequestFactory

-(instancetype)initWithFeatureFlagManager:(LPFeatureFlagManager *)featureFlagManager {
    self = [super init];
    if (self) {
        _featureFlagManager = featureFlagManager;
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

#pragma mark Public methods

- (id<LPRequesting>)startWithParams:(NSDictionary *)params
{
    [self.countAggregator incrementCount:@"start_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_START params:params];
}
- (id<LPRequesting>)getVarsWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"get_vars_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_GET_VARS params:params];
}
- (id<LPRequesting>)setVarsWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"set_vars_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_SET_VARS params:params];
}
- (id<LPRequesting>)stopWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"stop_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_STOP params:params];
}
- (id<LPRequesting>)restartWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"restart_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_RESTART params:params];
}
- (id<LPRequesting>)trackWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"track_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_TRACK params:params];
}

- (id<LPRequesting>)trackGeofenceWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"track_geofence_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_TRACK_GEOFENCE params:params];
}
- (id<LPRequesting>)advanceWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"advance_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_ADVANCE params:params];
}
- (id<LPRequesting>)pauseSessionWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"pause_session_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_PAUSE_SESSION params:params];
}
- (id<LPRequesting>)pauseStateWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"pause_state_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_PAUSE_STATE params:params];
}
- (id<LPRequesting>)resumeSessionWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"resume_session_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_RESUME_SESSION params:params];
}
- (id<LPRequesting>)resumeStateWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"resume_state_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_RESUME_STATE params:params];
}
- (id<LPRequesting>)multiWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"multi_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_MULTI params:params];
}
- (id<LPRequesting>)registerDeviceWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"register_device_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_REGISTER_FOR_DEVELOPMENT params:params];
}
- (id<LPRequesting>)setUserAttributesWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"set_user_attributes_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_SET_USER_ATTRIBUTES params:params];
}
- (id<LPRequesting>)setDeviceAttributesWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"set_device_attributes_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_SET_DEVICE_ATTRIBUTES params:params];
}
- (id<LPRequesting>)setTrafficSourceInfoWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"set_traffic_source_info_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO params:params];
}
- (id<LPRequesting>)uploadFileWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"upload_file_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_UPLOAD_FILE params:params];
}
- (id<LPRequesting>)downloadFileWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"download_file_with_params"];
    return [self createGetForApiMethod:LP_API_METHOD_DOWNLOAD_FILE params:params];
}
- (id<LPRequesting>)heartbeatWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"heartbeat_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_HEARTBEAT params:params];
}
- (id<LPRequesting>)saveInterfaceWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"save_interface_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION params:params];
}
- (id<LPRequesting>)saveInterfaceImageWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"save_interface_image_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE params:params];
}
- (id<LPRequesting>)getViewControllerVersionsListWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"get_view_controller_versions_list_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST params:params];
}
- (id<LPRequesting>)logWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"log_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_LOG params:params];
}
- (id<LPRequesting>)getNewsfeedMessagesWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"get_newsfeed_messages_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_GET_INBOX_MESSAGES params:params];
}
- (id<LPRequesting>)markNewsfeedMessageAsReadWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"mark_newsfeed_messages_as_read_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ params:params];
}
- (id<LPRequesting>)deleteNewsfeedMessageWithParams:(NSDictionary *)params;
{
    [self.countAggregator incrementCount:@"delete_newsfeed_message_with_params"];
    return [self createPostForApiMethod:LP_API_METHOD_DELETE_INBOX_MESSAGE params:params];
}

#pragma mark Private methods

- (id<LPRequesting>)createGetForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params {
    [self.countAggregator incrementCount:@"create_get_for_api_method"];
    
    if ([self shouldReturnLPRequestClass]) {
        return [LPRequest get:apiMethod params:params];
    }
    return [LeanplumRequest get:apiMethod params:params];
}

- (id<LPRequesting>)createPostForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params {
    [self.countAggregator incrementCount:@"create_post_for_api_method"];
    
    if ([self shouldReturnLPRequestClass]) {
        return [LPRequest post:apiMethod params:params];
    }
    return [LeanplumRequest post:apiMethod params:params];
}

-(BOOL)shouldReturnLPRequestClass {
    [self.countAggregator incrementCount:@"should_return_lprequest_class"];
    return [self.featureFlagManager isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR];
}

@end
