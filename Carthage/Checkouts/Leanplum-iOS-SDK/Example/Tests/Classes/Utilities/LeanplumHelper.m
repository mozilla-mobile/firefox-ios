//
//  LeanplumHelper.m
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



#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "LPVarCache+Extensions.h"
#import "Leanplum+Extensions.h"
#import "LPActionManager.h"
#import "LeanplumReachability+Category.h"
#import "LPNetworkEngine+Category.h"
#import "LPNetworkOperation+Category.h"
#import "LPAPIConfig.h"
#import "LPOperationQueue.h"

NSString *APPLICATION_ID = @"app_nLiaLr3lXvCjXhsztS1Gw8j281cPLO6sZetTDxYnaSk";
NSString *DEVELOPMENT_KEY = @"dev_2bbeWLmVJyNrqI8F21Kn9nqyUPRkVCUoLddBkHEyzmk";
NSString *PRODUCTION_KEY = @"prod_XYpURdwPAaxJyYLclXNfACe9Y8hs084dBx2pB8wOnqU";

NSString *API_HOST = @"api.leanplum.com";

NSInteger DISPATCH_WAIT_TIME = 4;

@implementation LeanplumHelper

static BOOL swizzled = NO;

+ (void)setup_method_swizzling {
    if (!swizzled) {
        [LeanplumRequest swizzle_methods];
        [Leanplum_Reachability swizzle_methods];
        [LPNetworkOperation swizzle_methods];
        swizzled = YES;
    }
}

+ (void)setup_development_test {
    [Leanplum setVerboseLoggingInDevelopmentMode:YES];
    [Leanplum setAppId:APPLICATION_ID withDevelopmentKey:DEVELOPMENT_KEY];
}

+ (void)setup_production_test {
    [Leanplum setAppId:APPLICATION_ID withProductionKey:PRODUCTION_KEY];
}

+ (BOOL)start_development_test {
    [LeanplumHelper setup_development_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    id startStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [OHHTTPStubs removeStub:startStub];
        if (success) {
            dispatch_semaphore_signal(semaphore);
        } else {
            NSLog(@"Start Development Test failed.");
        }
    }];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    return timedOut == 0;
}

+ (BOOL)start_production_test {
    [LeanplumHelper setup_production_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    id startStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [OHHTTPStubs removeStub:startStub];
        if (success) {
            dispatch_semaphore_signal(semaphore);
        }
    }];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    return timedOut == 0;
}

+ (void)clean_up {
    [Leanplum reset];
    [[LPVarCache sharedCache] reset];
    [[LPVarCache sharedCache] initialize];
    [LPActionManager reset];
    [[LPAPIConfig sharedConfig] setDeviceId:nil];
    [[LPAPIConfig sharedConfig] setUserId:nil];
    [[LPAPIConfig sharedConfig] setToken:nil];
    [LeanplumRequest reset];
    [LeanplumHelper reset_user_defaults];
    [[LPOperationQueue serialQueue] cancelAllOperations];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
}

+ (dispatch_time_t)default_dispatch_time {
    return dispatch_time(DISPATCH_TIME_NOW, DISPATCH_WAIT_TIME *NSEC_PER_SEC);
}

+ (NSString *)retrieve_string_from_file:(NSString *)file ofType:(NSString *)type {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:file ofType:type];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];

    return content;
}

+ (NSData *)retrieve_data_from_file:(NSString *)file ofType:(NSString *)type {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:file ofType:type];

    return [[NSFileManager defaultManager] contentsAtPath:path];
}

/// resets all user defaults
+ (void)reset_user_defaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults dictionaryRepresentation];

    for (id key in dictionary) {
        [defaults removeObjectForKey:key];
    }
}

@end
