//
//  ExceptionsTest.m
//  Leanplum-SDK
//
//  Created by Milos Jakovljevic on 11/3/16.
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
#import <UIKit/UIKit.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "LPNetworkEngine+Category.h"
#import "Leanplum+Extensions.h"
#import "LeanplumReachability+Category.h"
#import "LPActionManager.h"
#import "LPConstants.h"
#import "LPRegisterDevice.h"

@interface ExceptionsTest : XCTestCase

@end

@implementation ExceptionsTest

+ (void)setUp
{
    [super setUp];

    [LeanplumHelper setup_method_swizzling];
}

- (void)tearDown
{
    [super tearDown];
    // Clean up after every test.
    [LeanplumHelper clean_up];
    [OHHTTPStubs removeAllStubs];
    
}

- (void) test_start_offline
{
    [Leanplum_Reachability online:NO];
    [LeanplumHelper setup_development_test];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString* response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        XCTAssertFalse(success);
        if (!success){
            dispatch_semaphore_signal(semaphore);
        }
    }];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);
    XCTAssertFalse([Leanplum hasStarted] == NO);
    [Leanplum_Reachability online:YES];
}

- (void) test_start_malformed_response
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString* response_file = OHPathForFile(@"malformed_simple_start_response.json",
                                                self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);
}

- (void) test_start_http_error_400
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:400
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);
}

- (void) test_start_http_error_401
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:401
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);
}

- (void) test_start_http_error_404
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:404
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);
}

- (void) test_failed_track
{
    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    if (![Leanplum hasStarted]) {
        [LeanplumHelper start_development_test];
    }

    // Remove stub after start is successful.
    [OHHTTPStubs removeStub:startStub];

    // Create a stub for track event response.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"malformed_track_event_response.json",
                                                self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:404
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // Sample track params.
    NSString *trackName = @"this is track event";

    [Leanplum track:trackName];
    [Leanplum forceContentUpdate];
}
@end
