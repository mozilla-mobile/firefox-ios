//
//  LeanplumRequest+Extensions.m
//  Leanplum-SDK
//
//  Created by Milos Jakovljevic on 10/17/16.
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


#import "LeanplumRequest+Categories.h"
#import "LPSwizzle.h"

@implementation LeanplumRequest(MethodSwizzling)

static BOOL (^requestCallback)(NSString *method, NSString *apiMethod, NSDictionary *params);
static LPNetworkResponseBlock responseCallback;

+ (void)swizzle_methods
{
    NSError *error;
    bool success = [LPSwizzle swizzleMethod:@selector(sendNow)
                                 withMethod:@selector(swizzle_sendNow)
                                      error:&error
                                      class:[LeanplumRequest class]];
    success &= [LPSwizzle swizzleMethod:@selector(sendEventually:)
                             withMethod:@selector(swizzle_sendEventually:)
                                  error:&error
                                  class:[LeanplumRequest class]];
    success &= [LPSwizzle swizzleClassMethod:@selector(get:params:)
                             withClassMethod:@selector(swizzle_get:params:)
                                       error:&error
                                       class:[LeanplumRequest class]];
    success &= [LPSwizzle swizzleClassMethod:@selector(post:params:)
                             withClassMethod:@selector(swizzle_post:params:)
                                       error:&error
                                       class:[LeanplumRequest class]];
    success &= [LPSwizzle swizzleMethod:@selector(onResponse:)
                             withMethod:@selector(swizzle_onResponse:)
                                  error:&error
                                  class:[LeanplumRequest class]];
    if (!success || error) {
        NSLog(@"Failed swizzling methods for LeanplumRequest: %@", error);
    }
}

- (void)swizzle_sendNow
{
    SEL selector = NSSelectorFromString(@"sendNowSync");
    IMP imp = [self methodForSelector:selector];
    void (*func) (id, SEL) = (void*)imp;
    func(self, selector);
}

- (void)swizzle_sendEventually:(BOOL) sync
{
    [self swizzle_sendEventually:YES];
}

- (void)swizzle_download
{

}

- (void)swizzle_onResponse:(LPNetworkResponseBlock) response_
{
    [self swizzle_onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (responseCallback) {
            responseCallback(operation, json);
            responseCallback = nil;
        }
        response_(operation, json);
    }];
}

+ (LeanplumRequest *)swizzle_get:(NSString *) apiMethod_ params:(NSDictionary *) params_
{
    if (requestCallback != nil)
    {
        BOOL success = requestCallback(@"get", apiMethod_, params_);
        if (success) {
            requestCallback = nil;
        }
    }
    return [self swizzle_get:apiMethod_ params:params_];
}

+ (LeanplumRequest *)swizzle_post:(NSString *) apiMethod_ params:(NSDictionary *) params_
{
    if (requestCallback != nil)
    {
        BOOL success = requestCallback(@"post", apiMethod_, params_);
        if (success) {
            requestCallback = nil;
        }
    }
    return [self swizzle_post:apiMethod_ params:params_];
}

+ (void)validate_request:(BOOL (^)(NSString *, NSString *, NSDictionary *)) callback
{
    requestCallback = callback;
}

+ (void)validate_onResponse:(LPNetworkResponseBlock)callback
{
    responseCallback = callback;
}

+ (void)reset {
    requestCallback = nil;
    responseCallback = nil;
}

@end
