//
//  LPJSONTest.m
//  Leanplum-SDK
//
//  Created by Alexis Oyama on 2/1/17.
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
#import "LPJSON.h"

@interface LPJSONTest : XCTestCase

@end

@implementation LPJSONTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_LPJSON {
    // Test json to string.
    NSDictionary *json = @{@"key":@"string", @"number":@23, @"array":@[@"item"]};
    NSString *string = @"{\"key\":\"string\", \"number\":23, \"array\":[\"item\"]}";
    XCTAssertTrue([[LPJSON stringFromJSON:json] containsString:@"string"]);

    // Test JSONFromString.
    XCTAssertTrue([[LPJSON JSONFromString:string] isKindOfClass:[NSDictionary class]]);
    json = [LPJSON JSONFromString:string];
    XCTAssertNotNil(json);
    XCTAssertTrue([json[@"key"] isEqual:@"string"]);
    XCTAssertTrue([json[@"number"] isEqual:@23]);
    XCTAssertTrue([json[@"array"] isKindOfClass:[NSArray class]]);
    XCTAssertTrue([json[@"array"] count] == 1);

    // Test JSONFromData.
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    json = [LPJSON JSONFromData:data];
    XCTAssertNotNil(json);
    XCTAssertTrue([json[@"key"] isEqual:@"string"]);
    XCTAssertTrue([json[@"number"] isEqual:@23]);
    XCTAssertTrue([json[@"array"] isKindOfClass:[NSArray class]]);
    XCTAssertTrue([json[@"array"] count] == 1);

    // Test Array.
    string = @"[\"item\"]";
    XCTAssertTrue([[LPJSON JSONFromString:string] isKindOfClass:[NSArray class]]);
}

@end
