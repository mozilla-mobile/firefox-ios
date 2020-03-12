//
//  RegisterDevice.m
//  Leanplum
//
//  Created by Andrew First on 5/13/12.
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

#import "LPRegisterDevice.h"
#import "LPRequestFactory.h"
#import "LPResponse.h"
#import "LPConstants.h"
#import "LPRequestSender.h"
#import "LPCountAggregator.h"

@interface LPRegisterDevice()

@property (nonatomic, copy) LeanplumStartBlock callback;
@property (strong, nonatomic) LPCountAggregator *countAggregator;

@end

@implementation LPRegisterDevice

- (id)initWithCallback:(LeanplumStartBlock)callback
{
    if (self = [super init]) {
        _callback = callback;
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    [self.countAggregator incrementCount:@"init_with_callback"];
    return self;
}

- (void)showError:(NSString *)message
{
    NSLog(@"Leanplum: Device registration error: %@", message);
    self.callback(NO);
}

- (void)registerDevice:(NSString *)email
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory registerDeviceWithParams:@{ LP_PARAM_EMAIL: email }];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
        LP_TRY
        BOOL isSuccess = [LPResponse isResponseSuccess:response];
        if (isSuccess) {
            self.callback(YES);
        } else {
            [self showError:[LPResponse getResponseError:response]];
        }
        LP_END_TRY
    }];
    [request onError:^(NSError *error) {
        [self showError:[error localizedDescription]];
    }];
    [[LPRequestSender sharedInstance] sendNow:request];
    
    [self.countAggregator incrementCount:@"register_device"];
}

@end
