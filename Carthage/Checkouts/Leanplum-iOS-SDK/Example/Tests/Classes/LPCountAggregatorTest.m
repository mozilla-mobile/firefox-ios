//
//  AppIconManagerTest.m
//  Leanplum-SDK
//
//  Created by Grace Gu on 9/11/18.
//  Copyright © 2017 Leanplum. All rights reserved.
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
#import <OCMock/OCMock.h>
#import "LPCountAggregator.h"
#import "LPConstants.h"
#import "LeanplumRequest.h"

/**
 * Expose private class methods
 */
@interface LPCountAggregator(UnitTest)

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *counts;

- (NSDictionary<NSString *, NSNumber *> *)getAndClearCounts;
- (NSMutableDictionary<NSString *, id> *)makeParams:(nonnull NSString *)name withCount:(int) count;

@end

@interface LPCountAggregatorTest : XCTestCase

@end

@implementation LPCountAggregatorTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_incrementDisabledCount {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";

    [countAggregator incrementCount:testString];
    XCTAssert([countAggregator.counts[testString] intValue] == 0);
    
    [countAggregator incrementCount:testString];
    XCTAssert([countAggregator.counts[testString] intValue] == 0);
}

- (void)test_incrementCount {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    countAggregator.enabledCounters = [NSSet setWithObjects:testString, nil];
    
    [countAggregator incrementCount:testString];
    XCTAssert([countAggregator.counts[testString] intValue] == 1);
    
    [countAggregator incrementCount:testString];
    XCTAssert([countAggregator.counts[testString] intValue] == 2);
}

- (void)test_incrementDisabledCountMultiple {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    
    [countAggregator incrementCount:testString by:2];
    XCTAssert([countAggregator.counts[testString] intValue] == 0);
    
    [countAggregator incrementCount:testString by:15];
    XCTAssert([countAggregator.counts[testString] intValue] == 0);
}

- (void)test_incrementCountMultiple {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    countAggregator.enabledCounters = [NSSet setWithObjects:testString, nil];
    
    [countAggregator incrementCount:testString by:2];
    XCTAssert([countAggregator.counts[testString] intValue] == 2);
    
    [countAggregator incrementCount:testString by:15];
    XCTAssert([countAggregator.counts[testString] intValue] == 17);
}

- (void)test_getAndClearCounts {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    NSString *testString2 = @"test2";
    countAggregator.enabledCounters = [NSSet setWithObjects:testString, testString2, nil];
    
    [countAggregator incrementCount:testString by:2];
    [countAggregator incrementCount:testString2 by:15];
    
    NSDictionary<NSString *, NSNumber *> *previousCounts = [countAggregator getAndClearCounts];
    
    //test counts is empty after clearing
    XCTAssert([countAggregator.counts count] == 0);
    //test counts transferred to previousCounts
    XCTAssert([previousCounts[testString] intValue] == 2);
    XCTAssert([previousCounts[testString2] intValue] == 15);
}

- (void)test_makeParams {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    NSMutableDictionary<NSString *, id> *params = [countAggregator makeParams:testString withCount:2];

    XCTAssert([params[LP_PARAM_TYPE] isEqualToString:LP_VALUE_SDK_COUNT]);
    XCTAssert([params[LP_PARAM_NAME] isEqualToString:testString]);
    XCTAssert([params[LP_PARAM_COUNT] intValue] == 2);
}

- (void)test_sendAllCounts {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    countAggregator.enabledCounters = [NSSet setWithObjects:testString, nil];
    [countAggregator incrementCount:testString];
    
    id leanplumRequestMock = OCMClassMock([LeanplumRequest class]);
    
    OCMStub([leanplumRequestMock post:LP_METHOD_LOG params:[OCMArg any]]).andReturn(leanplumRequestMock);
    
    [countAggregator sendAllCounts];

    [[[leanplumRequestMock verify] ignoringNonObjectArgs] sendEventually:[OCMArg any]];
}

@end
