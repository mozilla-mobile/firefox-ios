//
//  LPNetworkEngine+Category.m
//  Leanplum-SDK
//
//  Created by Alexis Oyama on 12/5/16.
//  Copyright © 2016 Leanplum. All rights reserved.
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


#import "LPNetworkEngine+Category.h"
#import "LPSwizzle.h"

@implementation LPNetworkEngine (MethodSwizzling)

static BOOL (^operationCallback)(LPNetworkOperation *);
static BOOL swizzled = NO;

+ (void)setupValidateOperation
{
    if (swizzled) {
        return;
    }
    
    NSError *error;
    bool success = [LPSwizzle swizzleMethod:@selector(runSynchronously:)
                             withMethod:@selector(swizzle_runSynchronously:)
                                  error:&error
                                  class:[LPNetworkEngine class]];
    success &= [LPSwizzle swizzleMethod:@selector(enqueueOperation:)
                            withMethod:@selector(swizzle_enqueueOperation:)
                                 error:&error
                                 class:[LPNetworkEngine class]];
    if (!success || error) {
        NSLog(@"Failed swizzling methods for LPNetworkEngine: %@", error);
    }
    swizzled = success;
}

+ (void)enableForceSynchronous
{
    NSError *error;
    bool success = [LPSwizzle swizzleMethod:@selector(enqueueOperation:)
                                 withMethod:@selector(force_enqueue_operation_synchronous:)
                                      error:&error
                                      class:[LPNetworkEngine class]];
    if (!success || error) {
        NSLog(@"Failed swizzling methods for LPNetworkEngine: %@", error);
    }
}

+ (void)disableForceSynchronous
{
    NSError *error;
    bool success = [LPSwizzle swizzleMethod:@selector(enqueueOperation:)
                                 withMethod:@selector(original_enqueue_operation:)
                                      error:&error
                                      class:[LPNetworkEngine class]];

    if (!success || error) {
        NSLog(@"Failed swizzling methods for LPNetworkEngine: %@", error);
    }
}

- (void)original_enqueue_operation:(id<LPNetworkOperationProtocol>)operation
{
    if ([operation isKindOfClass:[LPNetworkOperation class]]) {
        [(LPNetworkOperation *)operation run];
    }
}

- (void)force_enqueue_operation_synchronous:(id<LPNetworkOperationProtocol>)_operation;
{
    [self runSynchronously:_operation];
}

- (void)swizzle_enqueueOperation:(id<LPNetworkOperationProtocol>)operation
{
    if (operationCallback) {
        BOOL success = operationCallback((LPNetworkOperation *)operation);
        if (success) {
            operationCallback = nil;
        }
    }
    
    [self swizzle_enqueueOperation:operation];
}

- (void)swizzle_runSynchronously:(id<LPNetworkOperationProtocol>)operation
{
    if (operationCallback) {
        BOOL success = operationCallback((LPNetworkOperation *)operation);
        if (success) {
            operationCallback = nil;
        }
    }
    
    [self swizzle_runSynchronously:operation];
}

+ (void)validate_operation:(BOOL (^)(LPNetworkOperation *))callback
{
    operationCallback = callback;
}

@end
