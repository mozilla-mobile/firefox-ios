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

#import "Matcher/GREYStringDescription.h"
#import "GREYBaseTest.h"

/**
 *  A string constant that the tests use as a sample description.
 */
static NSString * const kSampleTestDescription = @"foo";

#pragma mark - Test Helpers

/**
 *  Test object that returns a custom description.
 */
@interface GREYStringDescriptionTestObject : NSObject
@end

@implementation GREYStringDescriptionTestObject

- (NSString *)description {
  return kSampleTestDescription;
}

@end

#pragma mark -

@interface GREYStringDescriptionTest : GREYBaseTest
@end

@implementation GREYStringDescriptionTest

- (void)testGREYStringDescriptionHasEmptyDescriptionInitially {
  GREYStringDescription *description = [[GREYStringDescription alloc] init];
  XCTAssertEqualObjects([description description], @"");
}

- (void)testAppendTextCanAppendText {
  GREYStringDescription *description = [[GREYStringDescription alloc] init];
  [description appendText:kSampleTestDescription];
  XCTAssertEqualObjects([description description], kSampleTestDescription);
}

- (void)testAppendDescriptionCanAppendText {
  GREYStringDescription *description = [[GREYStringDescription alloc] init];
  [description appendDescriptionOf:[[GREYStringDescriptionTestObject alloc] init]];
  XCTAssertEqualObjects([description description], kSampleTestDescription);
}

@end
