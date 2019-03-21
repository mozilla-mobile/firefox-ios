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

#import <Foundation/Foundation.h>
#import "LPRequesting.h"
#import "LPFeatureFlagManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRequestFactory : NSObject

-(instancetype)initWithFeatureFlagManager:(LPFeatureFlagManager *)featureFlagManager;

- (id<LPRequesting>)startWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)getVarsWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)setVarsWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)stopWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)restartWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)trackWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)trackGeofenceWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)advanceWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)pauseSessionWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)pauseStateWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)resumeSessionWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)resumeStateWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)multiWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)registerDeviceWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)setUserAttributesWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)setDeviceAttributesWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)setTrafficSourceInfoWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)uploadFileWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)downloadFileWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)heartbeatWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)saveInterfaceWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)saveInterfaceImageWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)getViewControllerVersionsListWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)logWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)getNewsfeedMessagesWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)markNewsfeedMessageAsReadWithParams:(nullable NSDictionary *)params;
- (id<LPRequesting>)deleteNewsfeedMessageWithParams:(nullable NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
