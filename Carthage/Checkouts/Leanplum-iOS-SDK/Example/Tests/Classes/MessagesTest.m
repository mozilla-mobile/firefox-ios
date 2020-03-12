//
//  LPInAppMessagePrioritizationTest.m
//  Leanplum
//
//  Created by Kyu Hyun Chang on 6/15/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
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
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "LeanplumHelper.h"
#import "LPConstants.h"
#import "LPJSON.h"
#import "LPActionManager.h"
#import "LPVarCache.h"
#import "Leanplum.h"
#import "LeanplumInternal.h"
#import "LeanplumRequest+Categories.h"
#import "LPNetworkEngine+Category.h"

@interface MessagesTest : XCTestCase
@property (nonatomic) LeanplumMessageMatchResult mockResult;
@property (nonatomic) id mockActionManager;
@property (nonatomic) id mockLPInternalState;
@property (nonatomic) NSArray *mockWhenCondtions;
@property (nonatomic) NSString *mockEventName;
@property (nonatomic) LeanplumActionFilter mockFilter;
@property (nonatomic) NSString *mockFromMessageId;
@property (nonatomic) LPContextualValues *mockContextualValues;
@end


@implementation MessagesTest

- (void)setUp
{
    [super setUp];
    // Automatically sets up AppId and AccessKey for development mode.
    [LeanplumHelper setup_development_test];
    [self setMockResult];
    [self setMockActionManager];
    [self setMockLPInternalState];
    [self setParametersForMaybePerformAction];
}

- (void)tearDown
{
    [super tearDown];
    [LeanplumHelper clean_up];
}

- (void)setMockResult
{
    self.mockResult = LeanplumMessageMatchResultMake(YES, NO, YES, YES);
    XCTAssertFalse(self.mockResult.matchedUnlessTrigger);
    XCTAssertTrue(self.mockResult.matchedTrigger);
    XCTAssertTrue(self.mockResult.matchedLimit);
    XCTAssertTrue(self.mockResult.matchedActivePeriod);
}

- (void)setMockResultActivePeriodFalse
{
    self.mockResult = LeanplumMessageMatchResultMake(YES, NO, YES, NO);
    XCTAssertFalse(self.mockResult.matchedUnlessTrigger);
    XCTAssertTrue(self.mockResult.matchedTrigger);
    XCTAssertTrue(self.mockResult.matchedLimit);
    XCTAssertFalse(self.mockResult.matchedActivePeriod);
}

- (void)setMockActionManager
{
    self.mockActionManager = OCMClassMock([LPActionManager class]);
    OCMStub([self.mockActionManager shouldShowMessage:[OCMArg any]
                                      withConfig:[OCMArg any]
                                            when:[OCMArg any]
                                   withEventName:[OCMArg any]
                                contextualValues:[OCMArg any]]).andReturn(self.mockResult);

    LeanplumMessageMatchResult testResult =
        [self.mockActionManager shouldShowMessage:@"test"
                                       withConfig:[NSDictionary dictionary]
                                             when:@"test"
                                    withEventName:@"test"
                                 contextualValues:[[LPContextualValues alloc]init]];

    XCTAssertTrue(testResult.matchedTrigger);
    XCTAssertTrue(testResult.matchedLimit);
}

- (void)setMockLPInternalState
{
    LPInternalState *lp = [[LPInternalState alloc] init];
    lp.actionManager = self.mockActionManager;
    self.mockLPInternalState = OCMClassMock([LPInternalState class]);
    OCMStub([self.mockLPInternalState sharedState]).andReturn(lp);
}

- (void)setParametersForMaybePerformAction
{
    self.mockWhenCondtions = @[@"Event"];
    self.mockEventName = @"TestActivity";
    self.mockFilter = kLeanplumActionFilterAll;
    self.mockFromMessageId = nil;
    self.mockContextualValues = [[LPContextualValues alloc] init];
}

- (void)runInAppMessagePrioritizationTest:(NSDictionary *)messageConfigs
                   withExpectedMessageIds:(NSSet *)expectedMessageIds
{
    id mockLPVarCache = OCMPartialMock([LPVarCache sharedCache]);
    OCMStub([mockLPVarCache messages]).andReturn(messageConfigs);
    XCTAssertEqual([[LPVarCache sharedCache] messages], messageConfigs);

    __block NSMutableSet *calledMessageIds = [NSMutableSet set];
    id mockLeanplum = OCMClassMock([Leanplum class]);
    OCMStub([mockLeanplum triggerAction:[OCMArg any]
                           handledBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation){
        // __unsafe_unretained prevents double-release.
        __unsafe_unretained LPActionContext *actionContext;
        [invocation getArgument:&actionContext atIndex:2];
        [calledMessageIds addObject:[actionContext messageId]];
    });

    [Leanplum maybePerformActions:self.mockWhenCondtions
                    withEventName:self.mockEventName
                       withFilter:self.mockFilter
                    fromMessageId:self.mockFromMessageId
             withContextualValues:self.mockContextualValues];

    XCTAssertTrue([calledMessageIds isEqualToSet:expectedMessageIds]);
}

- (void) test_single_message
{
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"SingleMessage"
                                                              ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects: @"1", nil]];

    // Test creating action context for message id.
    LPActionContext *context = [Leanplum createActionContextForMessageId:@"1"];
    XCTAssertEqualObjects(@"Alert", context.actionName);
}

- (void) test_no_priorities
{
    // Testing three messages with no priority values.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"NoPriorities"
                                                              ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void) test_different_priorities_small
{
    // Testing three messages with priorities of 1, 2, and 3.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"DifferentPriorities1"
                                                              ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void) test_different_priorities_large
{
    // Testing three messages with priorities of 10, 1000, and 5.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"DifferentPriorities2"
                                                    ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"3", nil]];
}

- (void) test_tied_priorities_no_value
{
    // Testing three messages with priorities of 5, no value, and 5.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"TiedPriorities1"
                                                              ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void) test_tied_priorities_identical
{
    // Testing three messages with the same priority.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"TiedPriorities2"
                                                    ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void) test_tied_priorities_identical_different_time
{
    // Testing three messages with the same priority.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"TiedPrioritiesDifferentDelay"
                                                              ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", @"2", @"3", nil]];
}

- (void) test_different_priorities_with_missing_values
{
    // Testing  three messages with priorities of 10, 30, and no value.
    NSString *jsonString = [LeanplumHelper
                            retrieve_string_from_file:@"DifferentPrioritiesWithMissingValues"
                                               ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void)test_chained_messages
{
    NSString *jsonString = [LeanplumHelper
                            retrieve_string_from_file:@"ChainedMessage"
                            ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];

    // Mock LPVarCache messages.
    id mockLPVarCache = OCMPartialMock([LPVarCache sharedCache]);
    OCMStub([mockLPVarCache messages]).andReturn(messageConfigs);
    XCTAssertEqual([[LPVarCache sharedCache] messages], messageConfigs);

    LPActionContext *context1 = [Leanplum createActionContextForMessageId:@"1"];
    LPActionContext *context2 = [Leanplum createActionContextForMessageId:@"2"];

    // Capture Creating New Action.
    NSString __block *chainedMessageId = nil;
    id mockLeanplum = OCMClassMock([Leanplum class]);
    OCMStub([mockLeanplum createActionContextForMessageId:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        // __unsafe_unretained prevents double-release.
        __unsafe_unretained NSString *messageId;
        [invocation getArgument:&messageId atIndex:2];

        chainedMessageId = messageId;
    }).andReturn(context1);

    // Run Dismiss Action on 2 that will chain to 1.
    [context2 runActionNamed:@"Dismiss action"];
    XCTAssertTrue([chainedMessageId isEqual:@"1"]);
}

- (void) test_active_period_true
{
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"SingleMessage"
                                                              ofType:@"json"];
    
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects: @"1", nil]];
    
    // Test creating action context for message id.
    LPActionContext *context = [Leanplum createActionContextForMessageId:@"1"];
    XCTAssertEqualObjects(@"Alert", context.actionName);
}

- (void) test_active_period_false
{
    [self setMockResultActivePeriodFalse];
    [self setMockActionManager];
    [self setMockLPInternalState];
    
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"SingleMessage"
                                                              ofType:@"json"];
    
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet set]];
    
}

@end
