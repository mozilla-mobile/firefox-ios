//
//  UtilitiesTest.m
//  Leanplum-SDK
//
//  Created by Milos Jakovljevic on 11/4/16.
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
#import "NSString+MD5Addition.h"
#import "LPUtils.h"

@interface LPUtilsTest : XCTestCase

@end

@implementation LPUtilsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_md5 {
    NSString *test_string = @"test_string";
    NSString *expected_string = @"3474851a3410906697ec77337df7aae4";
    NSString *md5 = [test_string leanplum_stringFromMD5];

    XCTAssertEqualObjects(md5, expected_string);
}

- (void)test_isNullOrEmpty {
    XCTAssertTrue([LPUtils isNullOrEmpty:nil]);
    XCTAssertTrue([LPUtils isNullOrEmpty:@""]);
    XCTAssertTrue([LPUtils isNullOrEmpty:@[]]);
    XCTAssertTrue([LPUtils isNullOrEmpty:@{}]);
    XCTAssertFalse([LPUtils isNullOrEmpty:@"test"]);
    XCTAssertFalse([LPUtils isNullOrEmpty:@[@"test"]]);
    XCTAssertFalse([LPUtils isNullOrEmpty:@{@"test":@""}]);
}

- (void)test_isBlank {
    XCTAssertTrue([LPUtils isBlank:@""]);
    XCTAssertTrue([LPUtils isBlank:@"  "]);
    XCTAssertTrue([LPUtils isBlank:@"     "]);
    XCTAssertFalse([LPUtils isBlank:@"   test  "]);
}

- (void)test_md5OfData {
    NSData *data = [@"test_string" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *expectedSring = @"3474851a3410906697ec77337df7aae4";
    XCTAssertEqualObjects([LPUtils md5OfData:data], expectedSring);
}

- (void)test_base64EncodedStringFromData {
    NSData *data = [@"test_string" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *expectedSring = @"dGVzdF9zdHJpbmc=";
    NSString *base64String = [LPUtils base64EncodedStringFromData:data];
    XCTAssertEqualObjects(base64String, expectedSring);
}

@end
