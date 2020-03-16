//
// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <XCTest/XCTest.h>

#import "Common/GREYObjectFormatter.h"
#import "GREYBaseTest.h"

@interface GREYObjectFormatterTest : GREYBaseTest
@end

@implementation GREYObjectFormatterTest

- (void)testFormatEmptyArray {
  NSArray *testArray = @[];
  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@""
                                                  indent:0
                                                keyOrder:nil];
  XCTAssertTrue([formatted isEqualToString:@"[\n\n]"],
                @"Error formatting empty array");
}

- (void)testFormatNumberArray {
  NSArray *testArray = @[ @(1), @(2), @(3) ];
  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@""
                                                  indent:0
                                                keyOrder:nil];
  XCTAssertTrue([formatted isEqualToString:@"[\n1,\n2,\n3\n]"],
                @"Error formatting number array");
}

- (void)testFormatStringArray {
  NSArray *testArray = @[ @"item1", @"item2", @"item3" ];
  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@""
                                                  indent:0
                                                keyOrder:nil];
  XCTAssertTrue([formatted isEqualToString:@"[\n\"item1\",\n\"item2\",\n\"item3\"\n]"],
                @"Error formatting string array");
}

- (void)testFormatArrayPrefix {
  NSArray *testArray = @[ @"item1", @"item2", @"item3" ];
  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@"  "
                                                  indent:0
                                                keyOrder:nil];
  XCTAssertTrue([formatted isEqualToString:@"  [\n  \"item1\",\n  \"item2\",\n  \"item3\"\n  ]"],
                @"Error formatting array with prefix");
  formatted = [GREYObjectFormatter formatArray:testArray
                                        prefix:@"\t"
                                        indent:0
                                      keyOrder:nil];
  XCTAssertTrue([formatted isEqualToString:@"\t[\n\t\"item1\",\n\t\"item2\",\n\t\"item3\"\n\t]"],
                @"Error formatting array with prefix");
}

- (void)testFormatArrayIndent {
  NSArray *testArray = @[ @"item1", @"item2", @"item3" ];
  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@""
                                                  indent:kGREYObjectFormatIndent
                                                keyOrder:nil];
  XCTAssertTrue([formatted isEqualToString:@"[\n  \"item1\",\n  \"item2\",\n  \"item3\"\n]"],
                @"Error formatting array with indent");
}

- (void)testFormatArrayPrefixAndIndent {
  NSArray *testArray = @[ @"item1", @"item2", @"item3" ];
  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@"  "
                                                  indent:kGREYObjectFormatIndent
                                                keyOrder:nil];
  NSString *expected = @"  [\n    \"item1\",\n    \"item2\",\n    \"item3\"\n  ]";
  XCTAssertTrue([formatted isEqualToString:expected],
                @"Error formatting array with prefix and indent");
}

- (void)testFormatArrayOfArray {
  NSArray *testArray = @[ @[ @"item11", @"item12"],
      @[ @[ @"item211", @"item212" ], @[ @"item221" ] ] ];
  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@"  "
                                                  indent:kGREYObjectFormatIndent
                                                keyOrder:nil];
  NSString *expected = @"  [\n    [\n      \"item11\",\n      \"item12\"\n    ],"
      "\n    [\n      [\n        \"item211\",\n        \"item212\"\n      ],"
      "\n      [\n        \"item221\"\n      ]\n    ]\n  ]";
  XCTAssertTrue([formatted isEqualToString:expected],
                @"Error formatting array of array");
}

- (void)testFormatArrayOfArrayWithEmpty {
  NSArray *testArray = @[ @[ @"item11", @"item12"],
                          @[ @[ @"item211", @"item212" ], @[ ] ] ];
  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@"  "
                                                  indent:kGREYObjectFormatIndent
                                                keyOrder:nil];
  NSString *expected = @"  [\n    [\n      \"item11\",\n      \"item12\"\n    ],"
      "\n    [\n      [\n        \"item211\",\n        \"item212\"\n      ],"
      "\n      [\n\n      ]\n    ]\n  ]";
  XCTAssertTrue([formatted isEqualToString:expected],
                @"Error formatting array of array with empty");
}

- (void)testFormatArrayUnsupportedError {
  NSArray *testArray = @[ @(1), @"key2", [[NSObject alloc] init] ];
  NSString *formatted = nil;
  @try {
    formatted = [GREYObjectFormatter formatArray:testArray
                                          prefix:@"  "
                                          indent:kGREYObjectFormatIndent
                                        keyOrder:nil];
  } @catch (NSException *exception) {
    XCTAssertEqualObjects(exception.reason, @"Unhandled output type: NSObject");
  }
  XCTAssertNil(formatted,
               @"Error getting unsupported error for dictionary formatting");
}

- (void)testFormatEmptyDictionary {
  NSDictionary *testDict = @{};
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:nil
                                                       indent:0
                                                    hideEmpty:NO
                                                     keyOrder:nil];
  XCTAssertTrue([formatted isEqualToString:@"{\n\n}"],
                @"Error formatting empty dictionary");
}

- (void)testFormatNumberDictionary {
  NSDictionary *testDict = @{ @"key1" : @(1), @"key2" : @(2), @"key3" : @(3) };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:nil
                                                       indent:0
                                                    hideEmpty:NO
                                                     keyOrder:nil];
  NSData *jsonData = [formatted dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
  XCTAssertTrue([parsed[@"key1"] compare:@(1)] == NSOrderedSame,
                @"Error formatting number dictionary");
  XCTAssertTrue([parsed[@"key2"] compare:@(2)] == NSOrderedSame,
                @"Error formatting number dictionary");
  XCTAssertTrue([parsed[@"key3"] compare:@(3)] == NSOrderedSame,
                @"Error formatting number dictionary");
}

- (void)testFormatDictionaryUnsupportedError {
  NSDictionary *testDict = @{ @"key1" : @(1), @"key2" : @(2), @"key3" : [[NSObject alloc] init] };
  NSString *formatted = nil;
  @try {
    formatted = [GREYObjectFormatter formatDictionary:testDict
                                               prefix:nil
                                               indent:0
                                            hideEmpty:NO
                                             keyOrder:nil];
  } @catch (NSException *exception) {
    XCTAssertEqualObjects(exception.reason, @"Unhandled output type: NSObject");
  }
  XCTAssertNil(formatted,
               @"Error getting unsupported error for dictionary formatting");
}

- (void)testFormatStringDictionary {
  NSDictionary *testDict = @{ @"key1" : @"value1", @"key2" : @"value2", @"key3" : @"value3" };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:nil
                                                       indent:0
                                                    hideEmpty:NO
                                                     keyOrder:nil];
  NSData *jsonData = [formatted dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
  XCTAssertTrue([parsed[@"key1"] isEqualToString:@"value1"],
                @"Error formatting string dictionary");
  XCTAssertTrue([parsed[@"key2"] isEqualToString:@"value2"],
                @"Error formatting string dictionary");
  XCTAssertTrue([parsed[@"key3"] isEqualToString:@"value3"],
                @"Error formatting string dictionary");
  XCTAssertNil(parsed[@"key4"],
               @"Error formatting string dictionary");
}

- (void)testFormatStringDictionaryWithOrder {
  NSDictionary *testDict = @{ @"key1" : @"value1", @"key2" : @"value2", @"key3" : @"value3" };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:nil
                                                       indent:0
                                                    hideEmpty:NO
                                                     keyOrder:@[ @"key1", @"key2", @"key3" ]];
  NSString *expected = @"{\n\"key1\":\"value1\",\n\"key2\":\"value2\",\n\"key3\":\"value3\"\n}";
  XCTAssertEqualObjects(formatted, expected, @"Error formatting dictionary with key order");
}

- (void)testFormatStringDictionaryWithEmptyHidden {
  NSDictionary *testDict = @{ @"key1" : @"value1", @"key3" : @"value3" };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:nil
                                                       indent:0
                                                    hideEmpty:YES
                                                     keyOrder:@[ @"key1", @"key2", @"key3" ]];
  NSString *expected = @"{\n\"key1\":\"value1\",\n\"key3\":\"value3\"\n}";
  XCTAssertEqualObjects(formatted, expected, @"Error formatting with empty key hidden");
}

- (void)testFormatStringDictionaryPrefix {
  NSDictionary *testDict = @{ @"key1" : @"value1", @"key2" : @"value2" };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:@"  "
                                                       indent:0
                                                    hideEmpty:YES
                                                     keyOrder:@[ @"key1", @"key2", @"key3" ]];
  NSString *expected = @"  {\n  \"key1\":\"value1\",\n  \"key2\":\"value2\"\n  }";
  XCTAssertEqualObjects(formatted, expected, @"Error formatting prefix dictionary");
}

- (void)testFormatStringDictionaryIndent {
  NSDictionary *testDict = @{ @"key1" : @"value1", @"key2" : @"value2" };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:nil
                                                       indent:kGREYObjectFormatIndent
                                                    hideEmpty:YES
                                                     keyOrder:@[ @"key1", @"key2", @"key3" ]];
  NSString *expected = @"{\n  \"key1\":  \"value1\",\n  \"key2\":  \"value2\"\n}";
  XCTAssertEqualObjects(formatted, expected, @"Error formatting indent dictionary");
}

- (void)testFormatStringDictionaryPrefixAndIndent {
  NSDictionary *testDict = @{ @"key1" : @"value1", @"key2" : @"value2" };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:@"  "
                                                       indent:kGREYObjectFormatIndent
                                                    hideEmpty:YES
                                                     keyOrder:@[ @"key1", @"key2", @"key3" ]];
  NSString *expected = @"  {\n    \"key1\":  \"value1\",\n    \"key2\":  \"value2\"\n  }";
  XCTAssertEqualObjects(formatted, expected, @"Error formatting prefix and indent dictionary");
}

- (void)testFormatStringDictionaryOfDictionary {
  NSDictionary *testDict = @{ @"key1" : @"value1",
                              @"key2" : @{ @"key21" : @"value21", @"key22" : @"value22" },
                              @"key3" : @{ @"key31" : @{ @"key311" : @"value311",
                                                         @"key312" : @"value312" } } };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:@"  "
                                                       indent:kGREYObjectFormatIndent
                                                    hideEmpty:YES
                                                     keyOrder:@[ @"key1", @"key2", @"key3" ]];
  NSData *jsonData = [formatted dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
  XCTAssertTrue([parsed[@"key1"] isEqualToString:@"value1"],
                @"Error formatting dictionary of dictionary");
  XCTAssertTrue([parsed[@"key2"][@"key21"] isEqualToString:@"value21"],
                @"Error formatting dictionary of dictionary");
  XCTAssertTrue([parsed[@"key2"][@"key22"] isEqualToString:@"value22"],
                @"Error formatting dictionary of dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key31"][@"key311"] isEqualToString:@"value311"],
                @"Error formatting dictionary of dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key31"][@"key312"] isEqualToString:@"value312"],
                @"Error formatting dictionary of dictionary");
}

- (void)testFormatMixedArray {
  NSArray *testArray = @[ @"item1", @(2), @"item3", @{ @"key1" : @(1), @"key2" : @"value2" } ];

  NSString *formatted = [GREYObjectFormatter formatArray:testArray
                                                  prefix:@""
                                                  indent:0
                                                keyOrder:@[ @"key1", @"key2" ]];
  NSString *expected = @"[\n\"item1\",\n2,\n\"item3\",\n"
                       @"{\n\"key1\":1,\n\"key2\":\"value2\"\n}\n]";
  XCTAssertTrue([formatted isEqualToString:expected],
                @"Error formatting number/string/object mixed array");
}

- (void)testFormatMixedDictionary {
  NSDictionary *testDict = @{ @"key1" : @"value1",
                              @"key2" : @{ @"key21" : @"value21",
                                           @"key22" : @"value22",
                                           @"key23" : @[ @[], @[ @"value2321", @(2322) ] ] },
                              @"key3" : @{ @"key31" : @{ @"key311" : @"value311",
                                                         @"key312" : @"value312" },
                                           @"key32" : @[ @"value321", @(322), @"value323" ],
                                           @"key33" : @"value33",
                                           @"key34" : @(34) },
                              @"key4" : @(4),
                              @"key5" : @[ @{ @"key511" : @"value511" }, @"value52", @(53) ],
                              @"key7" : @{} };
  NSString *formatted = [GREYObjectFormatter formatDictionary:testDict
                                                       prefix:@"  "
                                                       indent:kGREYObjectFormatIndent
                                                    hideEmpty:YES
                                                     keyOrder:@[ @"key1", @"key2", @"key3" ]];
  NSData *jsonData = [formatted dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
  XCTAssertTrue([parsed[@"key1"] isEqualToString:@"value1"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key2"][@"key21"] isEqualToString:@"value21"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key2"][@"key23"][0] count] == 0,
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key2"][@"key23"][1][0] isEqualToString:@"value2321"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key2"][@"key23"][1][1] compare:@(2322)] == NSOrderedSame,
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key31"][@"key311"] isEqualToString:@"value311"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key31"][@"key312"] isEqualToString:@"value312"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key32"][0] isEqualToString:@"value321"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key32"][1] compare:@(322)] == NSOrderedSame,
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key32"][2] isEqualToString:@"value323"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key33"] isEqualToString:@"value33"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key3"][@"key34"] compare:@(34)] == NSOrderedSame,
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key4"] compare:@(4)] == NSOrderedSame,
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key5"][0][@"key511"] isEqualToString:@"value511"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key5"][1] isEqualToString:@"value52"],
                @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key5"][2] compare:@(53)] == NSOrderedSame,
                @"Error formatting mixed dictionary");
  XCTAssertNil(parsed[@"key6"],
               @"Error formatting mixed dictionary");
  XCTAssertTrue([parsed[@"key7"] count] == 0,
               @"Error formatting mixed dictionary");
}

@end
