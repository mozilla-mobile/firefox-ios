//
//  AppIconManagerTest.m
//  Leanplum-SDK
//
//  Created by Alexis Oyama on 3/2/17.
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
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LPAppIconManager.h"
#import "LeanplumHelper.h"
#import "LPVarCache.h"
#import "LPConstants.h"
#import "LeanplumRequest+Categories.h"
#import "LPJSON.h"

/**
 * Expose private class methods
 */
@interface LPAppIconManager(UnitTest)

+ (BOOL)supportsAlternateIcons;
+ (NSDictionary *)primaryIconBundle;
+ (NSDictionary *)alternativeIconsBundle;
+ (void)prepareUploadRequestParam:(NSMutableArray *)requestParam
              iconDataWithFileKey:(NSMutableDictionary *)requestDatas
                   withIconBundle:(NSDictionary *)bundle
                         iconName:(NSString *)iconName;

@end

@interface LPAppIconManagerTest : XCTestCase

@end

@implementation LPAppIconManagerTest

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

- (void)test_supportsAlternateIcons {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.3")) {
        XCTAssertTrue([LPAppIconManager supportsAlternateIcons]);
    }
}

- (void)test_primaryIconBundle {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.3")) {
        NSDictionary *bundle = [LPAppIconManager primaryIconBundle];
        XCTAssertTrue(bundle.count > 0);
        XCTAssertTrue([bundle[@"CFBundleIconFiles"][0] isEqual:@"MainAppIcon"]);
    }
}

- (void)test_alternativeIconsBundle {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.3")) {
        NSDictionary *bundle = [LPAppIconManager alternativeIconsBundle];
        XCTAssertTrue(bundle.count > 0);
        XCTAssertNotNil(bundle[@"Gold"]);
        XCTAssertTrue([bundle[@"Gold"][@"CFBundleIconFiles"][0] isEqual:@"GoldIcon"]);
    }
}

- (void)test_prepareUploadRequestParam {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.3")) {
        NSMutableArray *param = [NSMutableArray new];
        NSMutableDictionary *datas = [NSMutableDictionary new];
        [LPAppIconManager prepareUploadRequestParam:param
                                iconDataWithFileKey:datas
                                     withIconBundle:[LPAppIconManager primaryIconBundle]
                                           iconName:@"Test"];
        XCTAssertTrue(param.count == 1);
        XCTAssertNotNil(param[0][@"hash"]);
        XCTAssertNotNil(param[0][@"filename"]);
        XCTAssertNotNil(param[0][@"size"]);
        XCTAssertTrue(datas.count == 1);
        XCTAssertNotNil(datas[@"file0"]);
    }
}

- (void)test_uploadAppIconsOnDevMode {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.3")) {
        [LeanplumHelper start_development_test];
        [LeanplumRequest validate_request:^(NSString *method, NSString *apiMethod,
                                            NSDictionary *params){
            XCTAssertEqualObjects(apiMethod, @"uploadFile");
            NSString *data = params[@"data"];
            NSDictionary* json = [LPJSON JSONFromString:data];

            XCTAssertTrue(json.count == 2);
            for (NSDictionary* value in json) {
                XCTAssertNotNil(value[@"hash"]);
                XCTAssertNotNil(value[@"filename"]);
                XCTAssertNotNil(value[@"size"]);
            }
            return YES;

        }];
        [LPAppIconManager uploadAppIconsOnDevMode];
    }
}

- (void)test_uploadAppIconsOnDevMode_prod {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.3")) {
        [LeanplumHelper start_production_test];
        [LeanplumRequest validate_request:^(NSString *method, NSString *apiMethod,
                                            NSDictionary *params){
            XCTAssertTrue(NO);
            return YES;
        }];
        [LPAppIconManager uploadAppIconsOnDevMode];
    }
}

@end
