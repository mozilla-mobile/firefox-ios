//
// Copyright 2016 Google Inc.
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

#import <EarlGrey/GREYDataEnumerator.h>
#import "GREYBaseTest.h"

@interface GREYDataEnumeratorTest : GREYBaseTest

@end

@implementation GREYDataEnumeratorTest {
  NSArray *expected;
  id userInfo;
  NSEnumerator *expectedArrayEnumerator;
  GREYDataEnumerator *enumerator;
}

- (void)setUp {
  [super setUp];

  expected = @[ @"foo", @"bar", @"foobaz" ];
  userInfo = [[NSObject alloc] init];
  expectedArrayEnumerator = [expected objectEnumerator];
  enumerator = [[GREYDataEnumerator alloc] initWithUserInfo:userInfo
                                                      block:^id(id info) {
    XCTAssertEqual(userInfo, info, @"passed userinfo should always be same");
    return [expectedArrayEnumerator nextObject];
  }];
}

- (void)testNextObject {
  NSMutableArray *actual = [[NSMutableArray alloc] init];
  id object;
  while ((object = [enumerator nextObject])) {
    [actual addObject:object];
  }
  XCTAssertEqualObjects(expected, actual, @"Enumerator should return all objects");
}

- (void)testAllObjects {
  NSArray *actual = [enumerator allObjects];
  XCTAssertEqualObjects(expected, actual, @"Enumerator should return all objects");
}

- (void)testAllObjectsAfterSkippingOneEnumeration {
  // Skip once.
  [enumerator nextObject];
  NSArray *newExpected = @[ @"bar", @"foobaz" ];
  NSArray *actual = [enumerator allObjects];
  XCTAssertEqualObjects(newExpected, actual, @"Enumerator should return all objects");
}

@end
