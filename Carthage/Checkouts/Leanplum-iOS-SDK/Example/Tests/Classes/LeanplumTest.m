//
//  LeanplumTest.m
//  Leanplum-SDK
//
//  Created by Milos Jakovljevic on 10/13/16.
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
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "LeanplumReachability+Category.h"
#import "Leanplum+Extensions.h"
#import "LPActionManager.h"
#import "LPCountAggregator.h"
#import "LPFeatureFlagManager.h"
#import "LPFileTransferManager.h"
#import "LPConstants.h"
#import "LPRegisterDevice.h"
#import "Leanplum.h"
#import "LPOperationQueue.h"

/**
 * Tests leanplum public methods, we seed predefined response that comes from backend
 * and validate whether sdk properly parses the response and calls appropriate methods
 * the test all verifies whether request is properly packed with all necessary data.
 */
@interface Leanplum (Test)

+ (NSSet<NSString *> *)parseEnabledCountersFromResponse:(NSDictionary *)response;
+ (NSSet<NSString *> *)parseEnabledFeatureFlagsFromResponse:(NSDictionary *)response;
+ (NSDictionary *)parseFileURLsFromResponse:(NSDictionary *)response;
+ (void)triggerMessageDisplayed:(LPActionContext *)context;
+ (LPMessageArchiveData *)messageArchiveDataFromContext:(LPActionContext *)context;
+ (NSString *)messageBodyFromContext:(LPActionContext *)context;

+ (void)trackGeofence:(LPGeofenceEventType *)event withValue:(double)value andInfo:(NSString *)info andArgs:(NSDictionary *)args andParameters:(NSDictionary *)params;

@end

@interface LeanplumTest : XCTestCase

@end

@implementation LeanplumTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
    [Leanplum_Reachability online:YES];
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    // Clean up after every test.
    [LeanplumHelper clean_up];
    [OHHTTPStubs removeAllStubs];
}

/**
 * Tests a simple development start.
 */
- (void) test_simple_development_start
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // Validate request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        
        return YES;
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);
    XCTAssertTrue([[LPConstantsState sharedState] isDevelopmentModeEnabled]);
    XCTAssertTrue([Leanplum hasStarted]);
    XCTAssertNotNil([Leanplum deviceId]);
}

/**
 * Tests a simple development start with gzip response and validate success.
 */
- (void) test_simple_development_gzip_start
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json", @"Content-Encoding":@"gzip"}];
    }];
    
    // Validate request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"start");
        
        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        
        return YES;
    }];
    
    XCTAssertTrue([LeanplumHelper start_development_test]);
    XCTAssertTrue([[LPConstantsState sharedState] isDevelopmentModeEnabled]);
    XCTAssertTrue([Leanplum hasStarted]);
    XCTAssertNotNil([Leanplum deviceId]);
}

/**
 * Tests a simple production start.
 */
- (void) test_simple_production_start
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        if (![apiMethod isEqual:@"start"]) {
            return NO;
        }

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        
        dispatch_semaphore_signal(semaphor);
        return YES;
    }];

    XCTAssertTrue([LeanplumHelper start_production_test]);
    XCTAssertFalse([[LPConstantsState sharedState] isDevelopmentModeEnabled]);
    
    long timedOut = dispatch_semaphore_wait(semaphor, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);
}

/**
 * Test complex development start.
 */
- (void) test_complex_development_start
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"complex_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    NSDictionary *userAttributes = @{
                                     @"name": @"John Smith",
                                     @"age": @42,
                                     @"address": @"New York"
                                     };

    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        XCTAssertNotNil(params[@"userAttributes"]);
        return YES;
    }];

    [LeanplumHelper setup_development_test];

    // Test user attributes.
    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);
    [Leanplum startWithUserId:@"john.smith" userAttributes:userAttributes
              responseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        dispatch_semaphore_signal(semaphor);
    }];
    long timedOut = dispatch_semaphore_wait(semaphor, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);

    XCTAssertTrue([Leanplum hasStarted]);
}

/**
 * Tests a simple development start with variant debug info.
 */
- (void) testStartWithParamShouldIncludeVariantDebugInfo
{
    [Leanplum setVariantDebugInfoEnabled:YES];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    // Validate request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"start");
        
        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        XCTAssertTrue(params[@"includeVariantDebugInfo"]);
        return YES;
    }];
    
    XCTAssertTrue([LeanplumHelper start_development_test]);
    XCTAssertTrue([[LPConstantsState sharedState] isDevelopmentModeEnabled]);
    XCTAssertTrue([Leanplum hasStarted]);
    XCTAssertNotNil([Leanplum deviceId]);
}


/**
 * Test complex production start.
 */
- (void) test_complex_production_start
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"complex_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    NSDictionary *userAttributes = @{@"name": @"John Smith",
                                     @"age": @42,
                                     @"address": @"New York"
                                     };

    XCTestExpectation *request_expectation =
        [self expectationWithDescription:@"request_expectation"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        if (![apiMethod isEqual:@"start"]) {
            return NO;
        }
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        XCTAssertNotNil(params[@"userAttributes"]);
        
        [request_expectation fulfill];
        return YES;
    }];

    [LeanplumHelper setup_production_test];

    // Expectation for start handler.
    XCTestExpectation *expect = [self expectationWithDescription:@"start_expecatation"];

    [Leanplum startWithUserId:@"john.smith" userAttributes:userAttributes
              responseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [expect fulfill];
    }];
    // Wait and verify.
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([Leanplum hasStarted]);
}

/**
 * Test start method of the sdk without user id, attributes and callbacks.
 */
- (void) test_start
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        return YES;
    }];

    [LeanplumHelper setup_development_test];
    
    XCTestExpectation *start_expectation =
        [self expectationWithDescription:@"start_expectation"];
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [start_expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([Leanplum hasStarted]);
}

/**
 * Test start method with attributes
 */
- (void) test_start_with_attributes
{
    [LeanplumHelper clean_up];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    NSDictionary *userAttributes = @{
                                     @"name": @"John Smith",
                                     @"age": @42,
                                     @"address": @"New York"
                                     };

    XCTestExpectation *request_expectation =
        [self expectationWithDescription:@"request_expectation"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        if (![apiMethod isEqual:@"start"]) {
            return NO;
        }
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        XCTAssertNotNil(params[@"userAttributes"]);
        [request_expectation fulfill];
        return YES;
    }];

    [LeanplumHelper setup_development_test];
    XCTestExpectation *start_expectation =
        [self expectationWithDescription:@"start_expectation"];
    [Leanplum onStartResponse:^(BOOL success) {
        [start_expectation fulfill];
    }];
    [Leanplum startWithUserAttributes:userAttributes];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([Leanplum hasStarted]);
}

/**
 * Test start method with user id
 */
- (void) test_start_with_user_id
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTestExpectation *request_expectation =
        [self expectationWithDescription:@"request_expectation"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        if (![apiMethod isEqual:@"start"]) {
            return NO;
        }
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        XCTAssertNotNil(params[@"userAttributes"]);
        
        [request_expectation fulfill];
        return YES;
    }];

    NSString *userId = @"test_user";

    [LeanplumHelper setup_development_test];
    [Leanplum startWithUserId:userId];
    XCTAssertEqual(userId, [Leanplum userId]);
    [self waitForExpectationsWithTimeout:2 handler:nil];

    // Test setting user id manually.
    [Leanplum setUserId:@"test_user_new"];
    XCTAssertEqual([Leanplum userId], @"test_user_new");

    // Check if started.
    XCTAssertTrue([Leanplum hasStarted]);
}

- (void) test_start_with_attributes_and_response
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    NSDictionary *userAttributes = @{@"name": @"John Smith",
                                     @"age": @42,
                                     @"address": @"New York"
                                     };

    XCTestExpectation *request_expectation =
        [self expectationWithDescription:@"request_expectation"];
    
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        if (![apiMethod isEqual:@"start"]) {
            return NO;
        }
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        XCTAssertNotNil(params[@"userAttributes"]);
        [request_expectation fulfill];
        return YES;
    }];

    [LeanplumHelper setup_development_test];

    XCTestExpectation *start_expectation =
        [self expectationWithDescription:@"start_expectation"];

    [Leanplum startWithUserId:@"userId" userAttributes:userAttributes
              responseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [start_expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([Leanplum hasStarted]);
}

- (void) test_start_with_id_and_attributes
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    NSDictionary *userAttributes = @{@"name": @"John Smith",
                                     @"age": @42,
                                     @"address": @"New York"
                                     };

    XCTestExpectation *request_expectation =
        [self expectationWithDescription:@"request_expectation"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        if (![apiMethod isEqual:@"start"]) {
            return NO;
        }
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        XCTAssertNotNil(params[@"userAttributes"]);
        [request_expectation fulfill];
        return YES;
    }];

    [LeanplumHelper setup_development_test];

    XCTestExpectation *start_expectation =
    [self expectationWithDescription:@"start_expectation"];
    [Leanplum startWithUserId:@"userid" userAttributes:userAttributes
              responseHandler:^(BOOL success) {
      XCTAssertTrue(success);
      [start_expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([Leanplum hasStarted]);
}

- (void) test_start_with_id_and_response
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTestExpectation *request_expectation =
        [self expectationWithDescription:@"request_expectation"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        if (![apiMethod isEqual:@"start"]) {
            return NO;
        }
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"]
                            isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        XCTAssertNotNil(params[@"userAttributes"]);
        
        [request_expectation fulfill];
        return YES;
    }];

    [LeanplumHelper setup_development_test];

    XCTestExpectation *start_expectation =
        [self expectationWithDescription:@"start_expectation"];

    [Leanplum startWithUserId:@"userId" responseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [start_expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([Leanplum hasStarted]);
}

/**
 * Tests whether start callback is properly executed when sdk starts.
 */
- (void) test_start_callbacks
{
    // Add start responder and verify if added, must be executed before start command to make sure
    // it is added to a internal state for later execution.
    [Leanplum addStartResponseResponder:self withSelector:@selector(on_start_response:)];
    XCTAssertTrue([LPInternalState sharedState].startResponders.count == 1);

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Expectation for for start response.
    XCTestExpectation *expect = [self expectationWithDescription:@"start_response"];

    [Leanplum onStartResponse:^(BOOL success) {
        XCTAssertTrue(success);
        [expect fulfill];
    }];
    // Wait until executed and verify.
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([Leanplum hasStarted]);

    // Remove responder and verify.
    [Leanplum removeStartResponseResponder:self withSelector:@selector(on_start_response:)];
    XCTAssertTrue([LPInternalState sharedState].startResponders.count == 0);
}

/**
 * Tests whether setting user attributes and id works correctly.
 */
- (void) test_user_attributes
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    NSString *userId = @"john.smith";
    NSDictionary *userAttributes = @{@"name": @"John Smith",
                                     @"age": @42,
                                     @"address": @"New York"
                                     };

    // Try to set user id and attributes.
    [Leanplum setUserId:userId withUserAttributes:userAttributes];

    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);
    [Leanplum onStartResponse:^(BOOL success) {
        XCTAssertTrue(success);
        dispatch_semaphore_signal(semaphor);
    }];
    long timedOut = dispatch_semaphore_wait(semaphor, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);
    XCTAssertTrue([Leanplum hasStarted]);
}

/**
 * Tests track with events of same type , priority and countdown.
 */
- (void) test_track_events_priority_countDown
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Sample track params.
    NSString *trackName = @"pushLocal";
    
    // Validate track request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertNotNil(params[@"event"]);
        return YES;
    }];
    NSString *messageIdOne = @"4982955628167168";
    NSString *messageIdSecond = @"5571264209354752";
    [LeanplumRequest validate_onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        NSDictionary *outputDict = json[@"messages"];
        XCTAssertNotNil(outputDict);
        XCTAssertEqual([[outputDict allKeys] count], 2, @"Wrong array size.");
        XCTAssertNotNil(outputDict[messageIdOne]);
        XCTAssertNotNil(outputDict[messageIdSecond]);
        XCTAssertEqual(outputDict[messageIdOne][@"priority"], outputDict[messageIdOne][@"priority"], @"Priority not Equal");
        XCTAssertEqual(outputDict[messageIdOne][@"countdown"], outputDict[messageIdOne][@"countdown"], @"Countdown not Equal");
    }];
    [Leanplum track:trackName];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    [Leanplum forceContentUpdate];
    XCTAssertTrue([Leanplum hasStarted]);
}

/**
 * Tests  track methods.
 */
- (void) test_track
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

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful.
    [OHHTTPStubs removeStub:startStub];

    // Create a stub for track event response.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"track_event_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // Sample track params.
    NSString *trackName = @"this is track event";
    NSString *trackInfo = @"this is track info";
    NSDictionary *trackParams = @{@"test_value": @25,
                                  @"test_string": @"string"
                                  };
    double trackValue = 25.0f;

    // Validate track request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertNotNil(params[@"event"]);
        return YES;
    }];
    [Leanplum track:trackName];
    [Leanplum forceContentUpdate];

    // Validate track with value request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertTrue([params[@"value"] doubleValue] == trackValue);
        return YES;
    }];
    [Leanplum track:trackName withValue:trackValue];
    [Leanplum forceContentUpdate];


    // Validate track with value and info request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertTrue([params[@"info"] isEqualToString:trackInfo]);
        XCTAssertTrue([params[@"value"] doubleValue] == trackValue);
        return YES;
    }];
    [Leanplum track:trackName withValue:trackValue andInfo:trackInfo];
    [Leanplum forceContentUpdate];

    /// Validate track with name, value and params request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertTrue([params[@"value"] doubleValue] == trackValue);
        XCTAssertNotNil(params[@"params"]);
        return YES;
    }];
    [Leanplum track:trackName withValue:trackValue andParameters:trackParams];
    [Leanplum forceContentUpdate];

    /// Validate track with name, value, info and params request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertTrue([params[@"info"] isEqualToString:trackInfo]);
        XCTAssertTrue([params[@"value"] doubleValue] == trackValue);
        XCTAssertNotNil(params[@"params"]);
        return YES;
    }];
    [Leanplum track:trackName withValue:trackValue andInfo:trackInfo andParameters:trackParams];
    [Leanplum forceContentUpdate];

    /// Validate track with name and info.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertTrue([params[@"info"] isEqualToString:trackInfo]);
        return YES;
    }];
    [Leanplum track:trackName withInfo:trackInfo];
    [Leanplum forceContentUpdate];

    /// Validate track with name and params.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertNotNil(params[@"params"]);
        return YES;
    }];
    [Leanplum track:trackName withParameters:trackParams];
    [Leanplum forceContentUpdate];

    /// Validate track with name, value, args and params.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertTrue([params[@"value"] doubleValue] == trackValue);
        XCTAssertNotNil(params[@"params"]);
        XCTAssertNotNil(params[@"test_value"]);
        XCTAssertNotNil(params[@"test_string"]);
        return YES;
    }];
    [Leanplum track:trackName withValue:trackValue andArgs:trackParams andParameters:trackParams];
    [Leanplum forceContentUpdate];
    
    /// Validate track for manual purchase
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"track");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:trackName]);
        XCTAssertTrue([params[@"value"] doubleValue] == 1.99);
        XCTAssertTrue([params[@"currencyCode"] isEqualToString:@"USD"]);
        XCTAssertNotNil(params[@"params"]);
        return YES;
    }];
    [Leanplum trackPurchase:trackName
                  withValue:1.99
            andCurrencyCode:@"USD"
              andParameters:trackParams];
    [Leanplum forceContentUpdate];
    
    // Validate track geofence with info request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"trackGeofence");
        // Check if request has all params.
        XCTAssertTrue([params[@"event"] isEqualToString:@"enter_region"]);
        XCTAssertTrue([params[@"info"] isEqualToString:trackInfo]);
        return YES;
    }];
    [Leanplum trackGeofence:LPEnterRegion withValue:0.0 andInfo:trackInfo andArgs:nil andParameters:nil];
    [Leanplum forceContentUpdate];

    XCTAssertTrue([Leanplum hasStarted]);
}

/**
 * Tests set location.
 */
- (void)test_set_location
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
    XCTAssertTrue([LeanplumHelper start_development_test]);
    // Remove stub after start is successful.
    [OHHTTPStubs removeStub:startStub];

    // Test disable location collection.
    XCTAssertTrue([LPConstantsState sharedState].isLocationCollectionEnabled);
    [Leanplum disableLocationCollection];
    XCTAssertFalse([LPConstantsState sharedState].isLocationCollectionEnabled);

    // Validate set location request shorthand.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"setUserAttributes");
        XCTAssertTrue([params[@"location"] isEqualToString:@"37.324708,-122.020799"]);
        XCTAssertTrue([params[@"locationAccuracyType"] isEqualToString:@"cell"]);
        return YES;
    }];
    [Leanplum setDeviceLocationWithLatitude:37.324708 longitude:-122.020799];

    // Validate gps.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"setUserAttributes");
        XCTAssertTrue([params[@"location"] isEqualToString:@"37.324708,-122.020799"]);
        XCTAssertTrue([params[@"locationAccuracyType"] isEqualToString:@"gps"]);
        return YES;
    }];
    [Leanplum setDeviceLocationWithLatitude:37.324708 longitude:-122.020799
                                       type:LPLocationAccuracyGPS];

    // Validate city and region info.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"setUserAttributes");
        XCTAssertTrue([params[@"location"] isEqualToString:@"37.324708,-122.020799"]);
        XCTAssertTrue([params[@"locationAccuracyType"] isEqualToString:@"gps"]);
        XCTAssertTrue([params[@"city"] isEqualToString:@"San Francisco"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"California"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"US"]);
        return YES;

    }];
    [Leanplum setDeviceLocationWithLatitude:37.324708 longitude:-122.020799
                                       city:@"San Francisco" region:@"California"
                                    country:@"US" type:LPLocationAccuracyGPS];
}

/**
 * Tests variables syncing, request validation and response.
 */
- (void)test_variables
{
    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString* response_file = OHPathForFile(@"start_variables_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    [LeanplumHelper setup_development_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [OHHTTPStubs removeStub:startStub];
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);

    // Remove stub after start is successful, so we don't capture requests from other methods
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString* response_file = OHPathForFile(@"variables_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // Validate that callback is called since there are no downloads pending
    XCTestExpectation *variables_changed_downloads_expectation =
        [self expectationWithDescription:@"variables_changed_downloads_expectation"];
    [Leanplum onceVariablesChangedAndNoDownloadsPending:^{
        [variables_changed_downloads_expectation fulfill];
    }];
//    [self waitForExpectationsWithTimeout:10 handler:nil];

    // Validate that callback is properly called
    __block XCTestExpectation *variables_changed_expectation =
        [self expectationWithDescription:@"variables_changed_expectation"];
    [Leanplum onVariablesChanged:^{
        if (variables_changed_expectation != nil)
        {
            [variables_changed_expectation fulfill];
            variables_changed_expectation = nil;
        }
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    [LPVar define:@"named"];
    [LPVar define:@"int" withInt:10];
    [LPVar define:@"float" withFloat:10.0f];
    [LPVar define:@"double" withDouble:10.0];
    [LPVar define:@"bool" withBool:YES];
    [LPVar define:@"long" withLong:10L];
    [LPVar define:@"number" withNumber:@10];
    [LPVar define:@"color" withColor:[UIColor blueColor]];
    LPVar *cgfloat_variable = [LPVar define:@"cgfloat" withCGFloat:5.0f];
    LPVar *char_variable = [LPVar define:@"char" withChar:'c'];
    LPVar *long_long_variable = [LPVar define:@"long_long" withLongLong:100LL];
    [LPVar define:@"short" withShort:0x1];
    [LPVar define:@"unsigned_char" withUnsignedChar:200];
    [LPVar define:@"unsigned_short" withUnsignedShort:0x1];
    [LPVar define:@"unsigned_int" withUnsignedInt:5];
    [LPVar define:@"unsigned_integer" withUnsignedInteger:NSUIntegerMax];
    [LPVar define:@"unsigned_long" withUnsignedLong:50L];
    [LPVar define:@"unsigned_long_long" withUnsignedLongLong:25LL];
    [LPVar define:@"unsigned_short" withUnsignedShort:0x1];
    [LPVar define:@"A" withInteger:1];
    [LPVar define:@"B.a.i" withInteger:1];
    [LPVar define:@"C.a" withInteger:1];
    [LPVar define:@"C" withDictionary:@{}];
    [LPVar define:@"D" withDictionary:@{}];
    [LPVar define:@"D.a" withInteger:1];
    [LPVar define:@"mario" withFile:@"Mario.png"];
    [LPVar define:@"params" withDictionary:@{
                                             @"jumpDuration": @1.0,
                                             @"jumpButton": @"Jump!",
                                             @"title": @"?.!sœ∑πøˆ˜¨&//.sd"}];
    [LPVar define:@"myArray" withArray:@[@1, @2, @3, @4, @5]];
    [LPVar define:@"welcomeMessage" withString:@"Welcome to Leanplum!"];

    [[LPVarCache sharedCache] applyVariableDiffs:
     @{
       @"B": @{
               @"a": @{
                       @"i": @2,
                       @"ii": @2
                       }
               },
       @"C": @{
               @"a": @2
               },
       @"D": @{
               @"b": @2
               },
       @"params": @{
               @"title": @"blah"
               },
       @"myArray": @{
               @"[2]": @33
               }
       } messages:nil updateRules:nil eventRules:nil variants:nil regions:nil variantDebugInfo:nil];

    
    XCTestExpectation *request_expectation =
        [self expectationWithDescription:@"request_expectation"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        if (![apiMethod isEqual:@"setVars"]) {
            return NO;
        }
        XCTAssertEqualObjects(apiMethod, @"setVars");

        NSDictionary *variablesData = [LPJSON JSONFromString:params[@"vars"]];

        XCTAssertEqualObjects(@1, variablesData[@"A"]);
        XCTAssertEqualObjects(@1, variablesData[@"B"][@"a"][@"i"]);
        XCTAssertEqualObjects(@{}, variablesData[@"C"]);
        XCTAssertEqualObjects(([NSMutableArray arrayWithObjects:@1, @2, @3, @4, @5, nil]),
                              variablesData[@"myArray"]);
        XCTAssertEqualObjects(@"Mario.png", variablesData[@"mario"]);
        XCTAssertEqualObjects(@"Welcome to Leanplum!", variablesData[@"welcomeMessage"]);
        XCTAssertEqualObjects((@{@"jumpButton": @"Jump!",
                                 @"jumpDuration": @1,
                                 @"title": @"?.!sœ∑πøˆ˜¨&//.sd"
                                 }),
                              variablesData[@"params"]);
        NSDictionary *testObject = @{@"A" : @"integer",
                                     @"B.a.i" : @"integer",
                                     @"C" : @"group",
                                     @"C.a" : @"integer",
                                     @"D" : @"group",
                                     @"D.a" : @"integer",
                                     @"bool" : @"bool",
                                     @"cgfloat" : @"float",
                                     @"char" : @"integer",
                                     @"color" : @"color",
                                     @"double" : @"float",
                                     @"float" : @"float",
                                     @"int" : @"integer",
                                     @"long" : @"integer",
                                     @"long_long" : @"integer",
                                     @"mario" : @"file",
                                     @"myArray" : @"list",
                                     @"number" : @"float",
                                     @"params" : @"group",
                                     @"short" : @"integer",
                                     @"unsigned_char" : @"integer",
                                     @"unsigned_int" : @"integer",
                                     @"unsigned_integer" : @"integer",
                                     @"unsigned_long" : @"integer",
                                     @"unsigned_long_long" : @"integer",
                                     @"unsigned_short" : @"integer",
                                     @"welcomeMessage" : @"string"
                                     };

        NSDictionary *json = [LPJSON JSONFromString:params[@"kinds"]];
        [testObject enumerateKeysAndObjectsUsingBlock:^(id key, id  obj, BOOL *stop) {
            XCTAssertTrue([json[key] isEqual:obj]);
        }];
        [request_expectation fulfill];
        return YES;
    }];

    XCTAssertTrue([[LPVarCache sharedCache] sendVariablesIfChanged]);
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Test object for key path.
    XCTAssertNotNil(([Leanplum objectForKeyPath:@"color", nil]));
    XCTAssertEqualObjects(@5.0f, ([Leanplum objectForKeyPath:@"cgfloat", nil]));
    XCTAssertEqualObjects(@'c', ([Leanplum objectForKeyPath:@"char", nil]));
    XCTAssertEqualObjects(@100LL, ([Leanplum objectForKeyPath:@"long_long", nil]));
    XCTAssertEqualObjects(@0x1, ([Leanplum objectForKeyPath:@"short", nil]));
    XCTAssertEqualObjects(@5, ([Leanplum objectForKeyPath:@"unsigned_int", nil]));
    XCTAssertEqualObjects(@NSUIntegerMax, ([Leanplum objectForKeyPath:@"unsigned_integer", nil]));
    XCTAssertEqualObjects(@50L, ([Leanplum objectForKeyPath:@"unsigned_long", nil]));
    XCTAssertEqualObjects(@25LL, ([Leanplum objectForKeyPath:@"unsigned_long_long", nil]));
    XCTAssertEqualObjects(@0x1, ([Leanplum objectForKeyPath:@"unsigned_short", nil]));
    XCTAssertEqualObjects(@1, ([Leanplum objectForKeyPath:@"A", nil]));
    XCTAssertEqualObjects(@2, ([Leanplum objectForKeyPath:@"B", @"a", @"ii", nil]));
    XCTAssertEqualObjects(@2, ([Leanplum objectForKeyPath:@"B", @"a", @"i", nil]));
    XCTAssertEqualObjects(@1, ([Leanplum objectForKeyPath:@"D", @"a", nil]));
    XCTAssertEqualObjects(nil, ([Leanplum objectForKeyPath:@"D", @"c", nil]));
    XCTAssertEqualObjects(@1.0, ([Leanplum objectForKeyPath:@"params", @"jumpDuration", nil]));
    XCTAssertEqualObjects(@"blah", ([Leanplum objectForKeyPath:@"params", @"title", nil]));
    XCTAssertEqualObjects(@33, ([Leanplum objectForKeyPath:@"myArray", @2, nil]));
    XCTAssertEqualObjects(@4, ([Leanplum objectForKeyPath:@"myArray", @3, nil]));
    XCTAssertEqualObjects(@2, ([Leanplum objectForKeyPathComponents:@[@"D", @"b"]]));

    // Test LPVarCache get variable.
    XCTAssertEqualObjects(@"Welcome to Leanplum!", [[[LPVarCache sharedCache] getVariable:@"welcomeMessage"]
                                                    defaultValue]);
    XCTAssertNotNil([[LPVarCache sharedCache] getVariable:@"named"]);
    XCTAssertEqual(10, [[[LPVarCache sharedCache] getVariable:@"int"] intValue]);
    XCTAssertEqual(10.0f, [[[LPVarCache sharedCache] getVariable:@"float"] floatValue]);
    XCTAssertEqual(10.0, [[[LPVarCache sharedCache] getVariable:@"double"] doubleValue]);
    XCTAssertEqual(YES, [[[LPVarCache sharedCache] getVariable:@"bool"] boolValue]);
    XCTAssertEqual(10L, [[[LPVarCache sharedCache] getVariable:@"long"] longValue]);
    XCTAssertEqual(@10, [[[LPVarCache sharedCache] getVariable:@"number"] numberValue]);
    XCTAssertEqual(5.0f, [[[LPVarCache sharedCache] getVariable:@"cgfloat"] cgFloatValue]);
    XCTAssertEqual('c', [[[LPVarCache sharedCache] getVariable:@"char"] charValue]);
    XCTAssertEqual(100LL, [[[LPVarCache sharedCache] getVariable:@"long_long"] longLongValue]);
    XCTAssertEqual(0x1, [[[LPVarCache sharedCache] getVariable:@"short"] shortValue]);
    XCTAssertEqual(5, [[[LPVarCache sharedCache] getVariable:@"unsigned_int"] unsignedIntValue]);
    XCTAssertEqual(NSUIntegerMax, [[[LPVarCache sharedCache] getVariable:@"unsigned_integer"]
                                   unsignedIntegerValue]);
    XCTAssertEqual(200, [[[LPVarCache sharedCache] getVariable:@"unsigned_char"] unsignedCharValue]);
    XCTAssertEqual(50L, [[[LPVarCache sharedCache] getVariable:@"unsigned_long"] unsignedLongValue]);
    XCTAssertEqual(25LL, [[[LPVarCache sharedCache] getVariable:@"unsigned_long_long"] unsignedLongLongValue]);
    XCTAssertEqual(0x1, [[[LPVarCache sharedCache] getVariable:@"unsigned_short"] unsignedShortValue]);
    XCTAssertEqual(1, [[[LPVarCache sharedCache] getVariable:@"A"] integerValue]);
    XCTAssertEqual(2, [[[[LPVarCache sharedCache] getVariable:@"C"] objectForKey:@"a"] integerValue]);

    // default variables.
    XCTAssertEqualObjects(@5.0, [cgfloat_variable defaultValue]);
    XCTAssertEqualObjects(@'c', [char_variable defaultValue]);
    XCTAssertEqualObjects(@100LL, [long_long_variable defaultValue]);
}

/**
 * Tests variant debug info.
 */
- (void)testStartResponseShouldParseVariantDebugInfo
{
    //Given: start request
    
    //When: VariantDebugInfoEnabled is YES
    [Leanplum setVariantDebugInfoEnabled:YES];
    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
                                               return [request.URL.host isEqualToString:API_HOST];
                                           } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
                                               NSString* response_file = OHPathForFile(@"start_with_variant_debug_info_response.json", self.class);
                                               return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                                                          headers:@{@"Content-Type":@"application/json"}];
                                           }];
    
    [LeanplumHelper setup_development_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [OHHTTPStubs removeStub:startStub];
        // Then: variantDebugInfo should be parsed
        XCTAssertNotNil([[LPVarCache sharedCache] variantDebugInfo]);
        NSDictionary *abTests = [[LPVarCache sharedCache] variantDebugInfo][@"abTests"];
        XCTAssertEqual(abTests.count, 2);
        
        // Then: variantDebugInfo should be persisted
        [[LPVarCache sharedCache] saveDiffs];
        [[LPVarCache sharedCache] setVariantDebugInfo:nil];
        XCTAssertNil([[LPVarCache sharedCache] variantDebugInfo]);
        [[LPVarCache sharedCache] loadDiffs];
        XCTAssertNotNil([[LPVarCache sharedCache] variantDebugInfo]);
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
}

/**
 * Tests variant debug info persistence.
 */
- (void)testShouldPersistVariantDebugInfo
{
    //Given: a variantDebugInfo set in VarCache
    NSDictionary *mockVariantDebugInfo = @{@"abTests":@[]};
    [[LPVarCache sharedCache] setVariantDebugInfo:mockVariantDebugInfo];
    XCTAssertEqual([Leanplum variantDebugInfo].allKeys.count, 1);
    
    //When: the varcache is persisted
    [[LPVarCache sharedCache] saveDiffs];
    XCTAssertEqual([Leanplum variantDebugInfo].allKeys.count, 1);
    
    
    [[LPVarCache sharedCache] setVariantDebugInfo:nil];
    XCTAssertEqual([Leanplum variantDebugInfo].allKeys.count, 0);
    
    //Then: the variantDebugInfo can be loaded from disk
    [[LPVarCache sharedCache] loadDiffs];
    XCTAssertEqual([Leanplum variantDebugInfo].allKeys.count, 1);
}

/**
 * Tests advance methods
 */
- (void)test_advance
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

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    NSString *advanceName = @"advance to test";
    NSString *advanceInfo = @"advance info";
    NSDictionary *advanceParams = @{@"advance_value": @25,
                                    @"advance_string": @"string"
                                    };

    // Validate advance with value and info request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"advance");
        // Check if request has all params.
        XCTAssertTrue([params[@"state"] isEqualToString:advanceName]);
        return YES;
    }];
    [Leanplum advanceTo:advanceName];

    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"advance");
        // Check if request has all params.
        XCTAssertTrue([params[@"state"] isEqualToString:advanceName]);
        XCTAssertTrue([params[@"info"] isEqualToString:advanceInfo]);
        return YES;
    }];
    [Leanplum advanceTo:advanceName withInfo:advanceInfo];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"advance");
        // Check if request has all params.
        XCTAssertTrue([params[@"state"] isEqualToString:advanceName]);
        XCTAssertEqualObjects([LPJSON JSONFromString:params[@"params"]], advanceParams);
        return YES;
    }];
    [Leanplum advanceTo:advanceName withParameters:advanceParams];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"advance");
        // Check if request has all params.
        XCTAssertTrue([params[@"state"] isEqualToString:advanceName]);
        XCTAssertTrue([params[@"info"] isEqualToString:advanceInfo]);
        XCTAssertEqualObjects([LPJSON JSONFromString:params[@"params"]], advanceParams);
        return YES;
    }];
    [Leanplum advanceTo:advanceName withInfo:advanceInfo andParameters:advanceParams];
}

/**
 * Tests sdk states.
 */
- (void)test_states
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

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"state_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"pauseState");
        return YES;
    }];
    [Leanplum pauseState];

    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"resumeState");
        return YES;
    }];
    [Leanplum resumeState];
    [Leanplum forceContentUpdate];
}

/**
 * Tests metadata.
 */
- (void)test_metadata
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

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    NSDictionary *messages = @{@"123":@{@"action":@"",
                                        @"vars":@{},
                                        @"whenLimits":@{},
                                        @"whenTriggers":@{},
                                        }};
    NSArray *variants = @[@{@"id":@"1"}, @{@"id":@"2"}];
    [[LPVarCache sharedCache] applyVariableDiffs:nil messages:messages updateRules:nil
                        eventRules:nil variants:variants regions:nil variantDebugInfo:nil];

    XCTAssertEqualObjects(variants, [Leanplum variants]);
    XCTAssertEqualObjects(messages, [Leanplum messageMetadata]);
}

/**
 * Tests whether file syncs correctly.
 */
- (void)test_file_syncing
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

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"state_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];


    // Vaidate request.
    [Leanplum syncResourcePaths:@[@"\\.file$"] excluding:@[] async:NO];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"setVars");

        NSDictionary *files = [LPJSON JSONFromString:params[@"fileAttributes"]];

        NSDictionary *plist = files[@"PlugIns/Leanplum-SDK_Tests.xctest/test.file"][@""];

        XCTAssertTrue([plist[@"hash"] length] > 0);
        XCTAssertTrue([plist[@"size"] intValue] > 0);

        XCTAssertTrue([[[LPVarCache sharedCache] defaultKinds][@"__Resources"] isEqual:@"group"]);
        XCTAssertTrue([[[LPVarCache sharedCache] defaultKinds]
                       [@"__Resources.PlugIns.Leanplum-SDK_Tests\\.xctest.test\\.file"]
                       isEqual:@"file"]);
        return YES;
    }];
    [[LPVarCache sharedCache] sendVariablesIfChanged];

    NSDictionary *fileAttributes = [[LPVarCache sharedCache] fileAttributes];
    XCTAssertEqual(2, fileAttributes.count);
}

/**
 * Tests defining of actions and arguments, validating request sent to server.
 */
- (void)test_define_actions
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

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    NSString *action_name = @"test_action";

    NSString *number_argument_name = @"number_argument";
    NSString *string_argument_name = @"string_argument";
    NSString *bool_argument_name = @"bool_argument";
    NSString *file_argument_name = @"file_argument";
    NSString *dict_argument_name = @"dictionary_argument";
    NSString *array_argument_name = @"array_argument";
    NSString *action_argument_name = @"action_argument";
    NSString *color_argument_name = @"color_argument";

    LPActionArg *number_argument = [LPActionArg argNamed:number_argument_name withNumber:@5];
    LPActionArg *string_argument = [LPActionArg argNamed:string_argument_name
                                              withString:@"test_string"];
    LPActionArg *bool_argument = [LPActionArg argNamed:bool_argument_name withBool:YES];
    LPActionArg *file_argument = [LPActionArg argNamed:file_argument_name withFile:@"Mario.png"];
    LPActionArg *dict_argument = [LPActionArg argNamed:dict_argument_name
                                              withDict:@{@"test_value":@"test"}];
    LPActionArg *array_argument = [LPActionArg argNamed:array_argument_name
                                              withArray:@[@1, @2, @3, @4]];
    LPActionArg *action_argument = [LPActionArg argNamed:action_argument_name
                                              withAction:@"action_test"];
    LPActionArg *color_argument = [LPActionArg argNamed:color_argument_name
                                              withColor:[UIColor blueColor]];

    NSArray *arguments = @[number_argument,
                           string_argument,
                           bool_argument,
                           file_argument,
                           dict_argument,
                           array_argument,
                           action_argument,
                           color_argument
                           ];

    // Validate request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"setVars");

        NSDictionary *action_definitions = [LPJSON JSONFromString:params[@"actionDefinitions"]];
        NSDictionary *defined_actions = action_definitions[action_name];


        XCTAssertEqual([defined_actions[@"kind"] intValue], kLeanplumActionKindAction);
        XCTAssertEqualObjects(defined_actions[@"kinds"],
                              (@{@"action_argument" : @"action",
                                 @"array_argument" : @"list",
                                 @"bool_argument" : @"bool",
                                 @"color_argument" : @"color",
                                 @"dictionary_argument" : @"group",
                                 @"file_argument" : @"file",
                                 @"number_argument" : @"float",
                                 @"string_argument" : @"string"}));
        XCTAssertNotNil(defined_actions[@"values"]);

        NSDictionary *values = defined_actions[@"values"];

        XCTAssertEqualObjects(values[action_argument_name], [action_argument defaultValue]);
        XCTAssertEqualObjects(values[array_argument_name], [array_argument defaultValue]);
        XCTAssertEqualObjects(values[bool_argument_name], [bool_argument defaultValue]);
        XCTAssertEqualObjects(values[color_argument_name], [color_argument defaultValue]);
        XCTAssertEqualObjects(values[dict_argument_name], [dict_argument defaultValue]);
        XCTAssertEqualObjects(values[file_argument_name], [file_argument defaultValue]);
        XCTAssertEqualObjects(values[number_argument_name], [number_argument defaultValue]);
        XCTAssertEqualObjects(values[string_argument_name], [string_argument defaultValue]);
        
        return YES;
    }];

    // Handle action response.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"action_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // Define action and send it.
    [Leanplum defineAction:action_name ofKind:kLeanplumActionKindAction withArguments:arguments];
    [[LPVarCache sharedCache] sendActionsIfChanged];

    // Test whether notification parsing is working correctly.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"sample_action_notification"
                                                              ofType:@"json"];
    NSDictionary *userInfo = [LPJSON JSONFromString:jsonString];

    // Expectation for onAction block.
    XCTestExpectation *expects = [self expectationWithDescription:@"waiting_for_action"];

    // Add responder.
    [Leanplum addResponder:self withSelector:@selector(on_action_named:)
            forActionNamed:action_name];
    // Verify that responder is added.
    NSMutableSet *responders = [LPInternalState sharedState].actionResponders[action_name];
    XCTAssertTrue(responders.count == 1);

    // Test action received via notification.
    [Leanplum onAction:action_name invoke:^BOOL(LPActionContext *context) {
        XCTAssertEqualObjects(action_name, [context actionName]);
        XCTAssertEqualObjects([context stringNamed:string_argument_name], @"test_string_2");
        XCTAssertEqualObjects([context numberNamed:number_argument_name], @15);
        XCTAssertEqual([context boolNamed:bool_argument_name], YES);
        XCTAssertEqualObjects([context dictionaryNamed:dict_argument_name],
                                @{@"test_value": @"test_value_2"});
        XCTAssertEqualObjects([context arrayNamed:array_argument_name], (@[@9, @8, @7, @6]));
        XCTAssertNotNil([context colorNamed:color_argument_name]);

        [expects fulfill];
        return YES;
    }];
    // Perform action with notification.
    [[LPActionManager sharedManager] maybePerformNotificationActions:userInfo
                                                              action:nil active:NO];

    // Wait for action to be received before finishing.
    [self waitForExpectationsWithTimeout:10 handler:nil];

    // Remove responder.
    [Leanplum removeResponder:self withSelector:@selector(on_action_named:)
               forActionNamed:action_name];
    // Verify that responder is removed.
    XCTAssertTrue(responders.count == 0);
}

- (void)test_device_registration
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

    XCTAssertTrue([LeanplumHelper start_development_test]);


    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"registration_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    NSString *test_email = @"example@example.com";

    // Vaidate request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"registerDevice");
        XCTAssertEqual(params[@"email"], test_email);
        return YES;
    }];

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    XCTestExpectation *expectation = [self expectationWithDescription:@"registration"];

    LPRegisterDevice *registration = [[LPRegisterDevice alloc] initWithCallback:
                                      ^(BOOL success) {
        XCTAssertTrue(success);
        [expectation fulfill];
    }];

    [registration registerDevice:test_email];

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_configuration
{
    NSString* host = @"test_host";
    NSString* servlet = @"servlet";
    
    XCTAssertEqualObjects([LPConstantsState sharedState].apiHostName, @"api.leanplum.com");
    XCTAssertEqualObjects([LPConstantsState sharedState].apiServlet, @"api");
    
    [Leanplum setApiHostName:host withServletName:servlet usingSsl:true];

    XCTAssertEqual([LPConstantsState sharedState].apiHostName, host);
    XCTAssertEqual([LPConstantsState sharedState].apiServlet, servlet);
    
    [Leanplum setApiHostName:nil withServletName:nil usingSsl:true];
    
    XCTAssertEqual([LPConstantsState sharedState].apiHostName, host);
    XCTAssertEqual([LPConstantsState sharedState].apiServlet, servlet);
    
    [Leanplum setApiHostName:host withServletName:nil usingSsl:true];
    
    XCTAssertEqual([LPConstantsState sharedState].apiHostName, host);
    XCTAssertEqual([LPConstantsState sharedState].apiServlet, servlet);
    
    int timeout = 10;
    
    [Leanplum setNetworkTimeoutSeconds:timeout];
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSeconds, timeout);
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSecondsForDownloads, timeout);
    
    [Leanplum setNetworkTimeoutSeconds: -1];
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSeconds, timeout);
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSecondsForDownloads, timeout);
    
    [Leanplum setNetworkTimeoutSeconds:timeout forDownloads:timeout];
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSeconds, timeout);
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSecondsForDownloads, timeout);
    
    [Leanplum setNetworkTimeoutSeconds:20 forDownloads:-1];
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSeconds, timeout);
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSecondsForDownloads, timeout);
    
    [Leanplum setNetworkTimeoutSeconds:-1 forDownloads:20];
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSeconds, timeout);
    XCTAssertEqual([LPConstantsState sharedState].networkTimeoutSecondsForDownloads, timeout);
}

- (void)testStartResponseShouldParseCounters
{
    //Given: start request
    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString* response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                                            headers:@{@"Content-Type":@"application/json"}];
    }];

   [LeanplumHelper setup_development_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [OHHTTPStubs removeStub:startStub];
        // Then: enabledCounters should be parsed
        XCTAssertNotNil([[LPCountAggregator sharedAggregator] enabledCounters]);
        NSSet *enabledCounters = [[LPCountAggregator sharedAggregator] enabledCounters];
        NSSet *expected = [NSSet setWithArray:@[@"testCounter1", @"testCounter2"]];
        XCTAssertEqualObjects(expected, enabledCounters);

        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
}

- (void)testStartResponseShouldParseFeatureFlags
{
    //Given: start request
    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
                                               return [request.URL.host isEqualToString:API_HOST];
                                           } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
                                               NSString* response_file = OHPathForFile(@"simple_start_response.json", self.class);
                                               return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                                                          headers:@{@"Content-Type":@"application/json"}];
                                           }];
    
    [LeanplumHelper setup_development_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [OHHTTPStubs removeStub:startStub];
        // Then: enabledFeatureFlags should be parsed
        XCTAssertNotNil([[LPFeatureFlagManager sharedManager] enabledFeatureFlags]);
        NSSet<NSString *> *enabledFeatureFlags = [[LPFeatureFlagManager sharedManager] enabledFeatureFlags];
        NSSet<NSString *> *expected = [NSSet setWithArray:@[@"testFeatureFlag1", @"testFeatureFlag2"]];
        XCTAssertEqualObjects(expected, enabledFeatureFlags);
        
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
}

- (void)testStartResponseShouldParseFilenameToURLs
{
    //Given: start request
    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
                                               return [request.URL.host isEqualToString:API_HOST];
                                           } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
                                               NSString* response_file = OHPathForFile(@"simple_start_response.json", self.class);
                                               return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                                                          headers:@{@"Content-Type":@"application/json"}];
                                           }];

    [LeanplumHelper setup_development_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [OHHTTPStubs removeStub:startStub];
        // Then: FilenameToURLs should be parsed
        XCTAssertNotNil([LPFileTransferManager sharedInstance].filenameToURLs);
        NSDictionary *filenameToURLs = [LPFileTransferManager sharedInstance].filenameToURLs;
        NSDictionary *expected = @{
                                   @"file1.jpg" : @"http://www.domain.com/file1.jpg",
                                   @"file2.jpg" : @"http://www.domain.com/file2.jpg"
                                   };
        XCTAssertEqualObjects(expected, filenameToURLs);
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
}

- (void)test_parseFilenameToURLs
{
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    NSDictionary *filenameToURLs = [Leanplum parseFileURLsFromResponse:response];
    XCTAssertNil(filenameToURLs);

    NSDictionary *testFilenameToURLs = @{@"filename.jpg" : @"http://www.domain.com/filename.jpg"};
    [response setObject:testFilenameToURLs forKey:LP_KEY_FILES];
    filenameToURLs = [Leanplum parseFileURLsFromResponse:response];
    XCTAssertEqualObjects(filenameToURLs, testFilenameToURLs);
}

- (void)test_parseEnabledCounters
{
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    NSSet<NSString *> *enabledCounters = [Leanplum parseEnabledCountersFromResponse:response];
    XCTAssertNil(enabledCounters);
    
    [response setObject:@[@"test"] forKey:LP_KEY_ENABLED_COUNTERS];
    enabledCounters = [Leanplum parseEnabledCountersFromResponse:response];
    XCTAssertEqualObjects([NSSet setWithArray:@[@"test"]], enabledCounters);
}

- (void)test_parseEnabledFeatureFlags
{
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    NSSet<NSString *> *enabledFeatureFlags = [Leanplum parseEnabledFeatureFlagsFromResponse:response];
    XCTAssertNil(enabledFeatureFlags);
    
    [response setObject:@[@"test"] forKey:LP_KEY_ENABLED_FEATURE_FLAGS];
    enabledFeatureFlags = [Leanplum parseEnabledFeatureFlagsFromResponse:response];
    XCTAssertEqualObjects([NSSet setWithArray:@[@"test"]], enabledFeatureFlags);
}

#pragma mark - Selectors

/**
 * Called when action is executed.
 */
- (BOOL)on_action_named:(LPActionContext *)context
{
    XCTAssertNotNil(context);
    return YES;
}

/**
 * Called on start responder.
 */
- (void)on_start_response:(BOOL) success
{
    XCTAssertTrue(success);
}

/**
 * Test that method triggerMessageDisplayed calls user defined callback
 */
-(void)test_triggerMessageDisplayedCallsCallback
{
    __block BOOL blockCalled = NO;

    NSString *messageID = @"testMessageID";
    NSString *messageBody = @"testMessageBody";
    NSString *recipientUserID = @"recipientUserID";

    LPActionContext *actionContext = [[LPActionContext alloc] init];
    id actionContextMock = OCMPartialMock(actionContext);

    OCMStub([actionContextMock messageId]).andReturn(messageID);
    OCMStub([actionContextMock args]).andReturn(@{@"Message":messageBody});

    id leanplumMock = OCMClassMock([Leanplum class]);
    OCMStub([leanplumMock userId]).andReturn(recipientUserID);

    LeanplumMessageDisplayedCallbackBlock block =
    ^void(LPMessageArchiveData *messageArchiveData) {
        blockCalled = YES;
        XCTAssertEqual(messageArchiveData.messageID, messageID);
        XCTAssertEqual(messageArchiveData.messageBody, messageBody);
        XCTAssertEqual(messageArchiveData.recipientUserID, recipientUserID);
        NSDate *now = [NSDate date];
        NSTimeInterval interval = [now timeIntervalSinceDate:messageArchiveData.deliveryDateTime];
        XCTAssertTrue(interval < 1000);
    };
    [Leanplum onMessageDisplayed:block];
    [Leanplum triggerMessageDisplayed:actionContext];

    XCTAssertTrue(blockCalled);
}

/**
 * Test that method messageBodyFromContext gets the correct message body for string.
 */
-(void)test_messageBodyFromContextGetsCorrectBodyForString
{
    NSString *messageID = @"testMessageID";
    NSString *messageBody = @"testMessageBody";
    NSString *recipientUserID = @"recipientUserID";

    LPActionContext *actionContext = [[LPActionContext alloc] init];
    id actionContextMock = OCMPartialMock(actionContext);

    OCMStub([actionContextMock messageId]).andReturn(messageID);
    OCMStub([actionContextMock args]).andReturn(@{@"Message":messageBody});

    XCTAssertTrue([[Leanplum messageBodyFromContext:actionContext] isEqualToString:messageBody]);
}

/**
 * Test that method messageBodyFromContext gets the correct message body for
 * dictionary with key "Text".
 */
-(void)test_messageBodyFromContextGetsCorrectBodyForDictionaryKeyText
{
    NSString *messageID = @"testMessageID";
    NSString *messageBody = @"testMessageBody";
    NSString *recipientUserID = @"recipientUserID";

    LPActionContext *actionContext = [[LPActionContext alloc] init];
    id actionContextMock = OCMPartialMock(actionContext);

    OCMStub([actionContextMock messageId]).andReturn(messageID);
    OCMStub([actionContextMock args]).andReturn(@{@"Message":@{@"Text":messageBody}});

    XCTAssertTrue([[Leanplum messageBodyFromContext:actionContext] isEqualToString:messageBody]);
}

/**
 * Test that method messageBodyFromContext gets the correct message body for
 * dictionary with key "Text value".
 */
-(void)test_messageBodyFromContextGetsCorrectBodyForDictionaryKeyTextValue
{
    NSString *messageID = @"testMessageID";
    NSString *messageBody = @"testMessageBody";
    NSString *recipientUserID = @"recipientUserID";

    LPActionContext *actionContext = [[LPActionContext alloc] init];
    id actionContextMock = OCMPartialMock(actionContext);

    OCMStub([actionContextMock messageId]).andReturn(messageID);
    OCMStub([actionContextMock args]).andReturn(@{@"Message":@{@"Text value":messageBody}});

    XCTAssertTrue([[Leanplum messageBodyFromContext:actionContext] isEqualToString:messageBody]);
}

- (void) test_forceContentUpdateVariants
{
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"start");

        // Check if request has all params.
        XCTAssertTrue([params[@"city"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"country"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"location"] isEqualToString:@"(detect)"]);
        XCTAssertTrue([params[@"region"] isEqualToString:@"(detect)"]);
        NSString* deviceModel = params[@"deviceModel"];
        XCTAssertTrue([deviceModel isEqualToString:@"iPhone"] ||
                      [deviceModel isEqualToString:@"iPhone Simulator"]);
        XCTAssertTrue([params[@"deviceName"] isEqualToString:[[UIDevice currentDevice] name]]);
        XCTAssertEqualObjects(@0, params[@"includeDefaults"]);
        XCTAssertNotNil(params[@"locale"]);
        XCTAssertNotNil(params[@"timezone"]);
        XCTAssertNotNil(params[@"timezoneOffsetSeconds"]);
        return YES;
    }];

    [LeanplumHelper setup_development_test];

    XCTestExpectation *start_expectation =
    [self expectationWithDescription:@"start_expectation"];
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [start_expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([Leanplum hasStarted]);

    // Remove stub after start is successful.
    [OHHTTPStubs removeStub:startStub];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"variants_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([[LPVarCache sharedCache] variants].count == 0);

    [LeanplumRequest validate_onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary* json) {
        // Check if response contains variants.
        XCTAssertNotNil(json[@"variants"]);
    }];

    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"getVars");
        return YES;
    }];

    XCTestExpectation *getVars_expectation =
    [self expectationWithDescription:@"getVars_expectation"];
    [Leanplum forceContentUpdate:^{
        [getVars_expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTAssertTrue([[LPVarCache sharedCache] variants].count == 4);
}

@end
