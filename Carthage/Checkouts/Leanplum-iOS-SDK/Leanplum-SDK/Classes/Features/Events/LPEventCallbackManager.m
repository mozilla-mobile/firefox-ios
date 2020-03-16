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

#import "LPEventCallbackManager.h"
#import "LeanplumRequest.h"
#import "LPEventCallback.h"
#import "LPResponse.h"
#import "LPCountAggregator.h"

@implementation LPEventCallbackManager

+ (NSMutableDictionary *)eventCallbackMap
{
    static NSMutableDictionary *_eventCallbackMap;
    static dispatch_once_t eventCallbackMapToken;
    dispatch_once(&eventCallbackMapToken, ^{
        _eventCallbackMap = [NSMutableDictionary new];
    });
    return _eventCallbackMap;
}

+ (void)addEventCallbackAt:(NSInteger)index
                 onSuccess:(LPNetworkResponseBlock)responseBlock
                   onError:(LPNetworkErrorBlock)errorBlock
{
    @synchronized ([LPEventCallbackManager eventCallbackMap])
    {
        if (!responseBlock && !errorBlock) {
            return;
        }

        NSMutableDictionary *callbackMap = [LPEventCallbackManager eventCallbackMap];
        LPEventCallback *callback = [[LPEventCallback alloc] initWithResponseBlock:responseBlock
                                                                        errorBlock:errorBlock];

        NSNumber *atIndex = @(index);

        if (callbackMap && callback && atIndex) {
            callbackMap[atIndex] = callback;
        }
        [[LPCountAggregator sharedAggregator] incrementCount:@"add_event_callback_at"];
    }
}

+ (void)invokeSuccessCallbacksOnResponses:(id)responses
                                 requests:(NSArray *)requests
                                operation:(id<LPNetworkOperationProtocol>)operation
{
    @synchronized ([LPEventCallbackManager eventCallbackMap])
    {
        // Invoke and remove the callbacks that have errors.
        [LPEventCallbackManager invokeErrorCallbacksOnResponses:responses];

        NSMutableDictionary *callbackMap = [LPEventCallbackManager eventCallbackMap];
        NSMutableDictionary *updatedCallbackMap = [NSMutableDictionary new];
        NSMutableDictionary *activeResponseMap = [NSMutableDictionary new];

        for (NSNumber *indexObject in callbackMap.allKeys) {
            NSInteger index = [indexObject integerValue];
            LPEventCallback *eventCallback = callbackMap[indexObject];

            // If index is in range, execute and remove it.
            // If not, requests are in the future. Update the index.
            [callbackMap removeObjectForKey:indexObject];
            if (index >= requests.count) {
                index -= requests.count;
                updatedCallbackMap[@(index)] = eventCallback;
            } else if (eventCallback.responseBlock) {
                activeResponseMap[indexObject] = [eventCallback.responseBlock copy];
            }
        }
        [callbackMap addEntriesFromDictionary:updatedCallbackMap];

        // Execute responses afterwards to prevent index collision.
        [activeResponseMap enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObject, LPNetworkResponseBlock responseBlock, BOOL *stop) {
            NSInteger index = [indexObject integerValue];
            id response = [LPResponse getResponseAt:index fromDictionary:responses];
            responseBlock(operation, response);
        }];
        [[LPCountAggregator sharedAggregator] incrementCount:@"invoke_success_callbacks_on_responses"];
    }
}

+ (void)invokeErrorCallbacksOnResponses:(id)responses
{
    @synchronized ([LPEventCallbackManager eventCallbackMap])
    {
        // Handle errors that don't return an HTTP error code.
        NSMutableDictionary *callbackMap = [LPEventCallbackManager eventCallbackMap];
        for (NSUInteger i = 0; i < [LPResponse numResponsesInDictionary:responses]; i++) {
            NSDictionary *response = [LPResponse getResponseAt:i fromDictionary:responses];
            if ([LPResponse isResponseSuccess:response]) {
                continue;
            }

            NSString *errorMessage = @"API error";
            NSString *responseError = [LPResponse getResponseError:response];
            if (responseError) {
                errorMessage = [NSString stringWithFormat:@"API error: %@", errorMessage];
            }
            NSLog(@"Leanplum: %@", errorMessage);

            LPEventCallback *callback = callbackMap[@(i)];
            if (callback) {
                [callbackMap removeObjectForKey:@(i)];
                NSError *error = [NSError errorWithDomain:@"Leanplum" code:2
                                                 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                [callback invokeError:error];
            }
        }
        [[LPCountAggregator sharedAggregator] incrementCount:@"invoke_error_callbacks_on_responses"];
    }
}

+ (void)invokeErrorCallbacksWithError:(NSError *)error
{
    @synchronized ([LPEventCallbackManager eventCallbackMap])
    {
        NSMutableDictionary *callbackMap = [LPEventCallbackManager eventCallbackMap];
        for (LPEventCallback *callback in callbackMap.allValues) {
            [callback invokeError:error];
        }
        [callbackMap removeAllObjects];
    }
}

@end
