//
//  NewsfeedTest.m
//  Leanplum-SDK
//
//  Created by Milos Jakovljevic on 10/26/16.
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
#import "LPNetworkEngine+Category.h"
#import "Leanplum+Extensions.h"
#import "LPFileManager.h"
#import "LPActionManager.h"
#import "LPConstants.h"

@interface NewsfeedTest : XCTestCase

@end

@implementation NewsfeedTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
}

- (void)tearDown
{
    [super tearDown];
    // Clean up after every test.
    [LeanplumHelper clean_up];
    [OHHTTPStubs removeAllStubs];
}

/**
 * Tests newsfeed class.
 */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)test_newsfeed
{
    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json",
                                                self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                                statusCode:200
                                    headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    // Stub to return newsfeed json.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
        NSString *response_file = OHPathForFile(@"newsfeed_response.json",
                                                self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                                statusCode:200
                         headers:@{@"Content-Type":@"application/json"}];
    }];

    // Vaidate request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString  *apiMethod,
                                        NSDictionary  *params) {
        XCTAssertEqualObjects(apiMethod, @"getNewsfeedMessages");
        return YES;
    }];

    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);
    [[Leanplum newsfeed] onChanged:^{
        // We need to have 2 unread messages.
        XCTAssertEqual(2, [[Leanplum newsfeed] unreadCount]);
        XCTAssertEqual(2, [[Leanplum newsfeed] count]);
        NSArray *messages = [[Leanplum newsfeed] unreadMessages];

        LPNewsfeedMessage *message1 = messages[0];
        LPNewsfeedMessage *message2 = messages[1];

        // Validate message data.
        XCTAssertEqualObjects(message1.messageId, @"5231495977893888##1");
        XCTAssertEqualObjects(message1.title, @"This is a test inbox message");
        XCTAssertEqualObjects(message1.subtitle, @"This is a subtitle");
        XCTAssertEqualObjects(message1.imageURL.absoluteString, @"https://test.png");
        XCTAssertTrue([message1.data[@"Group"][@"number"] intValue] == 7);
        XCTAssertTrue([message1.data[@"Group"][@"text"] isEqual:@"Sample text"]);
        XCTAssertTrue([message1.data[@"Group"][@"bool"] boolValue]);
        XCTAssertTrue([message1.data[@"test"] isEqual:@"test string"]);
        XCTAssertEqualObjects(message1.deliveryTimestamp.description,
                              @"2016-10-26 13:04:17 +0000");
        XCTAssertNil(message1.expirationTimestamp);
        XCTAssertFalse(message1.isRead);

        XCTAssertEqualObjects(message2.messageId, @"4682943996362752##2");
        XCTAssertEqualObjects(message2.title, @"This is a second test message");
        XCTAssertEqualObjects(message2.subtitle, @"This is a second test message subtitle");
        XCTAssertEqualObjects(message2.deliveryTimestamp.description,
                              @"2016-10-26 13:04:44 +0000");
        XCTAssertTrue(message2.data.count == 0);
        XCTAssertTrue(message2.imageURL.absoluteString.length == 0);
        XCTAssertNil(message2.expirationTimestamp);
        XCTAssertFalse(message2.isRead);

        dispatch_semaphore_signal(semaphor);
    }];
    [[Leanplum inbox] downloadMessages];

    long timedOut = dispatch_semaphore_wait(semaphor, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);

    // Remove since we don't want to get callback after message is read.
    [Leanplum inbox].inboxChangedBlocks = [NSMutableArray new];

    NSArray *messages = [[Leanplum newsfeed] unreadMessages];

    LPNewsfeedMessage *message1 = messages[0];
    LPNewsfeedMessage *message2 = messages[1];

    // Read message and validate.
    [message1 read];
    XCTAssertTrue([message1 isRead]);
    XCTAssertEqual(1, [[Leanplum newsfeed] unreadCount]);

    // Read message and validate.
    [message2 read];
    XCTAssertTrue([message2 isRead]);
    XCTAssertEqual(0, [[Leanplum newsfeed] unreadCount]);

    XCTAssertEqual(2, [[Leanplum newsfeed] count]);

    // Get message by id.
    LPNewsfeedMessage *messageById = [[Leanplum newsfeed] messageForId:message1.messageId];

    XCTAssertNotNil(messageById);
    XCTAssertEqualObjects(message1, messageById);
}
#pragma GCC diagnostic pop

/**
 * Tests inbox class. Mimics Newsfeed. Make sure both tests are identical.
 */
- (void)test_inbox
{
    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
       return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
       NSString *response_file = OHPathForFile(@"simple_start_response.json",
                                               self.class);
       return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                               statusCode:200
                                          headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    // Stub to return newsfeed json.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
        NSString *response_file = OHPathForFile(@"newsfeed_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                                statusCode:200
                                       headers:@{@"Content-Type":@"application/json"}];
    }];

    // Vaidate request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString  *apiMethod,
                                        NSDictionary  *params) {
        XCTAssertEqualObjects(apiMethod, @"getNewsfeedMessages");
        return YES;
    }];

    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);
    [[Leanplum inbox] onChanged:^{
        // We need to have 2 unread messages.
        XCTAssertEqual(2, [[Leanplum inbox] unreadCount]);
        XCTAssertEqual(2, [[Leanplum inbox] count]);
        NSArray *messages = [[Leanplum inbox] unreadMessages];

        LPInboxMessage *message1 = messages[0];
        LPInboxMessage *message2 = messages[1];

        // Validate message data.
        XCTAssertEqualObjects(message1.messageId, @"5231495977893888##1");
        XCTAssertEqualObjects(message1.title, @"This is a test inbox message");
        XCTAssertEqualObjects(message1.subtitle, @"This is a subtitle");
        XCTAssertEqualObjects(message1.imageURL.absoluteString, @"https://test.png");
        XCTAssertTrue([message1.data[@"Group"][@"number"] intValue] == 7);
        XCTAssertTrue([message1.data[@"Group"][@"text"] isEqual:@"Sample text"]);
        XCTAssertTrue([message1.data[@"Group"][@"bool"] boolValue]);
        XCTAssertTrue([message1.data[@"test"] isEqual:@"test string"]);
        XCTAssertEqualObjects(message1.deliveryTimestamp.description,
                              @"2016-10-26 13:04:17 +0000");
        XCTAssertNil(message1.expirationTimestamp);
        XCTAssertFalse(message1.isRead);

        XCTAssertEqualObjects(message2.messageId, @"4682943996362752##2");
        XCTAssertEqualObjects(message2.title, @"This is a second test message");
        XCTAssertEqualObjects(message2.subtitle, @"This is a second test message subtitle");
        XCTAssertEqualObjects(message2.deliveryTimestamp.description,
                              @"2016-10-26 13:04:44 +0000");
        XCTAssertTrue(message2.data.count == 0);
        XCTAssertTrue(message2.imageURL.absoluteString.length == 0);
        XCTAssertNil(message2.expirationTimestamp);
        XCTAssertFalse(message2.isRead);

        dispatch_semaphore_signal(semaphor);
    }];
    [[Leanplum inbox] downloadMessages];

    long timedOut = dispatch_semaphore_wait(semaphor, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);

    // Remove since we don't want to get callback after message is read.
    [Leanplum inbox].inboxChangedBlocks = [NSMutableArray new];

    NSArray *messages = [[Leanplum inbox] unreadMessages];

    LPInboxMessage *message1 = messages[0];
    LPInboxMessage *message2 = messages[1];

    // Read message and validate.
    [message1 read];
    XCTAssertTrue([message1 isRead]);
    XCTAssertEqual(1, [[Leanplum inbox] unreadCount]);

    // Read message and validate.
    [message2 read];
    XCTAssertTrue([message2 isRead]);
    XCTAssertEqual(0, [[Leanplum inbox] unreadCount]);

    XCTAssertEqual(2, [[Leanplum inbox] count]);

    // Get message by id.
    LPInboxMessage *messageById = [[Leanplum inbox] messageForId:message1.messageId];

    XCTAssertNotNil(messageById);
    XCTAssertEqualObjects(message1, messageById);
}

- (void)test_prefetching
{
    [LPConstantsState sharedState].isInboxImagePrefetchingEnabled = YES;

    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
       return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
       NSString *response_file = OHPathForFile(@"simple_start_response.json",
                                               self.class);
       return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                               statusCode:200
                                                  headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    // Stub to return newsfeed json.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
        NSString *response_file = OHPathForFile(@"newsfeed_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                                statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // Check image has been downloaded after getNewsfeedMessages.
    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);
    [LeanplumRequest validate_onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        [LeanplumRequest validate_request:^BOOL(NSString *method, NSString  *apiMethod,
                                            NSDictionary  *params) {
            if (![apiMethod isEqual:@"downloadFile"]) {
                return NO;
            }
            dispatch_semaphore_signal(semaphor);
            return YES;
        }];
    }];
    [[Leanplum inbox] downloadMessages];

    long timedOut = dispatch_semaphore_wait(semaphor, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);
}

- (void)test_disableFetching
{
    [[Leanplum inbox] disableImagePrefetching];

    // This stub have to be removed when start command is successfully executed.
    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
       return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
       NSString *response_file = OHPathForFile(@"simple_start_response.json",
                                               self.class);
       return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                               statusCode:200
                                                  headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful, so we don't capture requests from other methods.
    [OHHTTPStubs removeStub:startStub];

    // Stub to return newsfeed json.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
        NSString *response_file = OHPathForFile(@"newsfeed_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                                statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // Check disableImagePrefetching by utilizing the fact that
    // downloadFile will be called before onChanged.
    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);
    [LeanplumRequest validate_onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        [LeanplumRequest validate_request:^BOOL(NSString *method, NSString  *apiMethod,
                                            NSDictionary  *params) {
            if (![apiMethod isEqual:@"DidNotDownload"]) {
                return NO;
            }
            dispatch_semaphore_signal(semaphor);
            return YES;
        }];
    }];
    [[Leanplum inbox] downloadMessages];
    [[Leanplum inbox] onChanged:^{
        [LeanplumRequest get:@"DidNotDownload" params:nil];
    }];
    long timedOut = dispatch_semaphore_wait(semaphor, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);
}

- (void)test_onForceContentUpdate {
    XCTAssertTrue([LeanplumHelper start_development_test]);
    
    // FCU without sync
    id<OHHTTPStubsDescriptor> stub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
        NSString *response_file = OHPathForFile(@"variables_response.json",
                                               self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                               statusCode:200
                                                  headers:@{@"Content-Type":@"application/json"}];
    }];
    
    XCTestExpectation *responseExpectation1 = [self expectationWithDescription:@"response1"];
    [[Leanplum inbox] onForceContentUpdate:^void(BOOL success){
        XCTAssertTrue(success);
        [responseExpectation1 fulfill];
    }];
    
    [Leanplum forceContentUpdate:nil];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    [OHHTTPStubs removeStub:stub];
    [[Leanplum inbox] reset];
    
    // FCU with sync
    stub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
                return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest *request) {
        NSString *response_file = OHPathForFile(@"variables_with_newsfeed_response.json",
                                                self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file
                                                statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    XCTestExpectation *responseExpectation2 = [self expectationWithDescription:@"response2"];
    [[Leanplum inbox] onForceContentUpdate:^void(BOOL success){
        XCTAssertTrue(success);
        [responseExpectation2 fulfill];
    }];
    
    [Leanplum forceContentUpdate:nil];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    [OHHTTPStubs removeStub:stub];
    [[Leanplum inbox] reset];
    
    // FCU without internet connection
    stub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:API_HOST];;
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorBadServerResponse userInfo:nil];
        return [OHHTTPStubsResponse responseWithError:error];
    }];
    
    XCTestExpectation *responseExpectation3 = [self expectationWithDescription:@"response3"];
    [[Leanplum inbox] onForceContentUpdate:^void(BOOL success){
        XCTAssertFalse(success);
        [responseExpectation3 fulfill];
    }];
    
    [Leanplum forceContentUpdate:nil];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    [OHHTTPStubs removeStub:stub];
    [[Leanplum inbox] reset];
}

@end
