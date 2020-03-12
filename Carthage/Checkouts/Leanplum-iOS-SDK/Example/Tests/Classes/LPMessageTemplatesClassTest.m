//
//  MessageTemplatesTest.m
//  Leanplum-SDK-Tests
//
//  Created by Milos Jakovljevic on 6/16/17.
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
#import <UIKit/UIKit.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "Leanplum+Extensions.h"
#import "LPActionManager.h"
#import "LPConstants.h"
#import "LPRegisterDevice.h"
#import "LPMessageTemplates.h"

@interface LPMessageTemplatesClass (Test)
+ (UIImage *)imageFromColor:(UIColor *)color;
+ (UIImage *)dismissImage:(UIColor *)color withSize:(int)size;
+ (NSString *)urlEncodedStringFromString:(NSString *)urlString;

- (void)setupPopupLayout:(BOOL)isFullscreen isPushAskToAsk:(BOOL)isPushAskToAsk;
- (void)updatePopupLayout;
- (void)showPopup;
- (void)enableSystemPush;

@end

@interface LPMessageTemplatesClassTest : XCTestCase

@end

@implementation LPMessageTemplatesClassTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
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

- (void)test_image_from_color
{
    UIImage* image = [LPMessageTemplatesClass imageFromColor:[UIColor blueColor]];
    XCTAssertNotNil(image);
}

- (void)test_dismiss_image
{
    UIImage* image = [LPMessageTemplatesClass dismissImage:[UIColor blueColor] withSize:128];
    XCTAssertNotNil(image);
}

-(void)test_shared_templates_creation
{
    // Previously, this was causing a deadlock.
    [LPMessageTemplatesClass sharedTemplates];
}

- (void)test_popup_setup
{
    // This stub have to be removed when start command is successfully executed.
    [OHHTTPStubs stubRequestsPassingTest:
     ^BOOL(NSURLRequest * _Nonnull request) {
         return [request.URL.host isEqualToString:API_HOST];
     } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
         NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
         return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}];
     }];
    
    XCTAssertTrue([LeanplumHelper start_development_test]);
    
    [[LPMessageTemplatesClass sharedTemplates] setupPopupLayout:YES isPushAskToAsk:NO];
    [[LPMessageTemplatesClass sharedTemplates] updatePopupLayout];
    [[LPMessageTemplatesClass sharedTemplates] showPopup];
    id acceptButton = [[LPMessageTemplatesClass sharedTemplates] valueForKey:@"_acceptButton"];
    XCTAssertNotNil(acceptButton);
}

- (void)test_push_popup_setup
{
    // This stub have to be removed when start command is successfully executed.
    [OHHTTPStubs stubRequestsPassingTest:
     ^BOOL(NSURLRequest * _Nonnull request) {
         return [request.URL.host isEqualToString:API_HOST];
     } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
         NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
         return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}];
     }];
    
    XCTAssertTrue([LeanplumHelper start_development_test]);
    
    [[LPMessageTemplatesClass sharedTemplates] setupPopupLayout:YES isPushAskToAsk:YES];
    [[LPMessageTemplatesClass sharedTemplates] updatePopupLayout];
    [[LPMessageTemplatesClass sharedTemplates] showPopup];
    id acceptButton = [[LPMessageTemplatesClass sharedTemplates] valueForKey:@"_acceptButton"];
    XCTAssertNotNil(acceptButton);
    id cancelButton = [[LPMessageTemplatesClass sharedTemplates] valueForKey:@"_cancelButton"];
    XCTAssertNotNil(cancelButton);
}

- (void)test_urlEncodedStringFromString {
    XCTAssertEqualObjects([LPMessageTemplatesClass urlEncodedStringFromString:@"http://www.leanplum.com"], @"http://www.leanplum.com");
    XCTAssertEqualObjects([LPMessageTemplatesClass urlEncodedStringFromString:@"http://www.leanplum.com?q=simple_english1&test=2"], @"http://www.leanplum.com?q=simple_english1&test=2");
    XCTAssertEqualObjects([LPMessageTemplatesClass urlEncodedStringFromString:@"https://ramsey.tfaforms.net/356302?id={}"], @"https://ramsey.tfaforms.net/356302?id=%7B%7D");
    XCTAssertEqualObjects([LPMessageTemplatesClass urlEncodedStringFromString:@"lomotif://music/月亮"], @"lomotif://music/%E6%9C%88%E4%BA%AE");
}

- (void)test_pushEnableOnce
{
    [[LPMessageTemplatesClass sharedTemplates] enableSystemPush];
    XCTAssertTrue([[NSUserDefaults standardUserDefaults] boolForKey:@"__Leanplum_asked_to_push"]);
}

@end
