//
//  LPEventCallbackManager.m
//  Leanplum
//
//  Created by Alexis Oyama on 7/11/17.
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

#import "LPEventCallback.h"
#import "LeanplumRequest.h"
#import "LPResponse.h"
#import "LPCountAggregator.h"

@interface LPEventCallback()

@property (strong, nonatomic) LPCountAggregator *countAggregator;

@end

@implementation LPEventCallback

- (id)initWithResponseBlock:(LPNetworkResponseBlock)responseBlock
                 errorBlock:(LPNetworkErrorBlock)errorBlock
{
    if (self = [super init]) {
        self.responseBlock = [responseBlock copy];
        self.errorBlock = [errorBlock copy];
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

- (void)invokeResponseWithOperation:(id<LPNetworkOperationProtocol>)operation
                           response:(id)response
{
    if (!self.responseBlock) {
        return;
    }
    
    [self.countAggregator incrementCount:@"invoke_response_with_operation"];
    
    // Ensure all callbacks are on main thread.
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.responseBlock(operation, response);
        });
        return;
    }

    self.responseBlock(operation, response);
}

- (void)invokeError:(NSError *)error
{
    if (!self.errorBlock) {
        return;
    }
    
    // Ensure all callbacks are on main thread.
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.errorBlock(error);
        });
        return;
    }
    
    self.errorBlock(error);
}

@end
