//
//  LPActionManagerTest.m
//  Leanplum
//
//  Created by Alexis Oyama on 11/3/16.
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


#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LPActionManager.h"
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "LPNetworkEngine+Category.h"
#import "Leanplum+Extensions.h"
#import "LPUIAlert.h"
#import "LPOperationQueue.h"

@interface LPActionManager (Test)
- (void)requireMessageContent:(NSString *)messageId
          withCompletionBlock:(LeanplumVariablesChangedBlock)onCompleted;
+ (NSString *)messageIdFromUserInfo:(NSDictionary *)userInfo;
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
                          withAction:(NSString *)action
              fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler;
- (void)leanplum_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (NSString *)hexadecimalStringFromData:(NSData *)data;
@end

@interface LPActionManagerTest : XCTestCase

@end

@implementation LPActionManagerTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
}

- (void)setUp
{
    [super setUp];
    // Automatically sets up AppId and AccessKey for development mode.
    [LeanplumHelper setup_development_test];
}

- (void)tearDown
{
    [super tearDown];
    [LeanplumHelper clean_up];
}

- (void)test_matched_trigger
{
    LPActionManager *manager = [LPActionManager sharedManager];

    // Message Object
    NSDictionary *config = @{@"whenLimits":@{@"children":@[],
                                             @"objects":@[],
                                             @"subjects":[NSNull null]
                                             },
                             @"whenTriggers":@{@"children":@[@{@"noun":@"Sick",
                                                               @"objects":@[@"symptom", @"cough"],
                                                               @"subject":@"event",
                                                               @"verb":@"triggersWithParameter"
                                                               }],
                                               @"verb":@"OR"
                                               }
                             };

    // track parameters
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];

    // [Leanplum track:@"Sick"]
    contextualValues.parameters = @{};
    LeanplumMessageMatchResult result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"Sick"
                                                  contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);

    // [Leanplum track:@"Sick" withParameters:@{@"symptom":@""}]
    contextualValues.parameters = @{@"symptom":@""};
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"Sick"
                       contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);

    // [Leanplum track:@"Sick" withParameters:@{@"test":@"test"}]
    contextualValues.parameters = @{@"test":@"test"};
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"Sick"
                       contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);

    // [Leanplum track:@"Sick" withParameters:@{@"symptom":@"cough"}]
    contextualValues.parameters = @{@"symptom":@"cough"};
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"Sick"
                       contextualValues:contextualValues];
    XCTAssertTrue(result.matchedTrigger);
    
    // [Leanplum track:@"Sick" withParameters:nil
    contextualValues.parameters = nil;
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"Sick"
                       contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);
    
    // [Leanplum track:@"NotSick" withParameters:@{@"symptom":@"cough"}]
    contextualValues.parameters = @{@"symptom":@"cough"};
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"NotSick"
                       contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);
}

- (void)test_require_message_content
{
    // Vaidate request.
    [LeanplumRequest validate_request:^(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"getVars");
        XCTAssertEqual(params[@"includeMessageId"], @"messageId");
        return YES;
    }];
    [[LPActionManager sharedManager] requireMessageContent:@"messageId" withCompletionBlock:nil];
}

- (void)test_notification_action
{
    id classMock = OCMClassMock([LPUIAlert class]);
    
    NSDictionary* userInfo = @{
                               @"_lpm": @"messageId",
                               @"_lpx": @"test_action",
                               @"aps" : @{@"alert": @"test"}};
    [[LPActionManager sharedManager] maybePerformNotificationActions:userInfo
                                                              action:nil
                                                              active:YES];
    
    OCMVerify([classMock showWithTitle:OCMOCK_ANY
                               message:OCMOCK_ANY
                     cancelButtonTitle:OCMOCK_ANY
                     otherButtonTitles:OCMOCK_ANY
                                 block:OCMOCK_ANY]);
}

- (void) test_receive_notification
{
    NSDictionary* userInfo = @{
                               @"_lpm": @"messageId",
                               @"_lpx": @"test_action",
                               @"aps" : @{@"alert": @"test"}};
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"notification"];
    
    [[LPActionManager sharedManager] didReceiveRemoteNotification:userInfo
                                                       withAction:@"test_action"
                                           fetchCompletionHandler:
     ^(LeanplumUIBackgroundFetchResult result) {
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_messageId_from_userinfo
{
    NSDictionary *userInfo = nil;
    NSString* messageId = nil;
    
    userInfo = @{@"_lpm": @"messageId"};
    messageId = [LPActionManager messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
    
    userInfo = @{@"_lpu": @"messageId"};
    messageId = [LPActionManager messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
    
    userInfo = @{@"_lpn": @"messageId"};
    messageId = [LPActionManager messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
    
    userInfo = @{@"_lpv": @"messageId"};
    messageId = [LPActionManager messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
}

- (void)test_push_token
{
    XCTAssertTrue([LeanplumHelper start_production_test]);
    
    // Partial mock Action Manager.
    LPActionManager *manager = [LPActionManager sharedManager];
    id actionManagerMock = OCMPartialMock(manager);
    OCMStub([actionManagerMock sharedManager]).andReturn(actionManagerMock);
    OCMStub([actionManagerMock respondsToSelector:
             @selector(leanplum_application:didRegisterForRemoteNotificationsWithDeviceToken:)]).andReturn(NO);
    
    // Remove Push Token.
    NSString *pushTokenKey = [Leanplum pushTokenKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:pushTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Test push token is sent on clean start.
    UIApplication *app = [UIApplication sharedApplication];
    XCTestExpectation *expectNewToken = [self expectationWithDescription:@"expectNewToken"];
    NSData *token = [@"sample" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *formattedToken = [token description];
    formattedToken = [[[formattedToken stringByReplacingOccurrencesOfString:@"<" withString:@""]
                       stringByReplacingOccurrencesOfString:@">" withString:@""]
                      stringByReplacingOccurrencesOfString:@" " withString:@""];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[@"iosPushToken"] isEqual:formattedToken]);
        [expectNewToken fulfill];
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    
    // Test push token will not be sent with the same token.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue(NO);
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];

    // Test push token is sent if the token changes.
    token = [@"sample2" dataUsingEncoding:NSUTF8StringEncoding];
    formattedToken = [token description];
    formattedToken = [[[formattedToken stringByReplacingOccurrencesOfString:@"<" withString:@""]
                       stringByReplacingOccurrencesOfString:@">" withString:@""]
                      stringByReplacingOccurrencesOfString:@" " withString:@""];
    XCTestExpectation *expectUpdatedToken = [self expectationWithDescription:@"expectUpdatedToken"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[@"iosPushToken"] isEqual:formattedToken]);
        [expectUpdatedToken fulfill];
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_active_period_false
{
    LPActionManager *manager = [LPActionManager sharedManager];
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];
    
    NSDictionary *config = [self messageConfigInActivePeriod:NO];

    LeanplumMessageMatchResult result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"ActivePeriodTest"
                                                  contextualValues:contextualValues];
    XCTAssertFalse(result.matchedActivePeriod);
}

- (void)test_active_period_true
{
    LPActionManager *manager = [LPActionManager sharedManager];
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];

    NSDictionary *config = [self messageConfigInActivePeriod:YES];
    
    LeanplumMessageMatchResult result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"ActivePeriodTest"
                                                  contextualValues:contextualValues];
    XCTAssertTrue(result.matchedActivePeriod);

}

-(void)testHexadecimalStringFromData {
    LPActionManager *manager = [[LPActionManager alloc] init];
    NSString *testString = @"74657374537472696e67";
    NSData *data = [self hexDataFromString:testString];
    NSString *parsedString = [manager hexadecimalStringFromData:data];
    XCTAssertEqualObjects(testString, parsedString);
}

#pragma mark Helpers

-(NSDictionary *)messageConfigInActivePeriod:(BOOL)inActivePeriod
{
    NSDictionary *config = @{@"whenLimits":@{@"children":@[]},
                             @"whenTriggers":@{@"children":@[@{@"noun":@"ActivePeriodTest",
                                                               @"subject":@"event",
                                                               }],
                                               @"verb":@"OR"
                                               },
                             @"startTime": inActivePeriod ? @1524507600000 : @956557100000,
                             @"endTime": inActivePeriod ? @7836202020000 : @956557200000
                             };
    return config;
}

-(NSMutableData*)hexDataFromString:(NSString*)string {

    NSMutableData *hexData= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [string length]/2; i++) {
        byte_chars[0] = [string characterAtIndex:i*2];
        byte_chars[1] = [string characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [hexData appendBytes:&whole_byte length:1];
    }
    return hexData;
}



@end
