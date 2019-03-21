//
//  LPEventCallbackManager.h
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

#import <Foundation/Foundation.h>
#import "LPNetworkProtocol.h"

@interface LPEventCallbackManager : NSObject

/**
 * Returns dictionary that maps event index to event callback object.
 * Since requests are batched there can be a case where other LeanplumRequest
 * can take future LeanplumRequest events. We need to ensure all callbacks are
 * called from any instance.
 */
+ (NSMutableDictionary *)eventCallbackMap;

+ (void)addEventCallbackAt:(NSInteger)index
           onSuccess:(LPNetworkResponseBlock)responseBlock
             onError:(LPNetworkErrorBlock)errorBlock;

/** 
 * Invoke success callbacks that within the range.
 * Note we need to do this because Request can steal future sendNow callbacks.
 * Callback map will either have to be updated or removed.
 */
+ (void)invokeSuccessCallbacksOnResponses:(id)responses
                                 requests:(NSArray *)requests
                                operation:(id<LPNetworkOperationProtocol>)operation;

/**
 * Invoke error callbacks if responses does not contain 'success'.
 * Called internally from invokeSuccessCallbacksOnResponses:.
 */
+ (void)invokeErrorCallbacksOnResponses:(id)responses;

/**
 * Invoke all success callbacks. Loop through all the possible callbacks.
 * Note we need to do this because Request can steal future sendNow callbacks.
 * Callback map will either have to be updated or removed.
 */
+ (void)invokeErrorCallbacksWithError:(NSError *)error;

@end
