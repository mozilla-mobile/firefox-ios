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

#import <XCTest/XCTest.h>

/**
 *  A constant used for asserting mismatched analytics hits, this is set to be a global to allow for
 *  the assertions themselves be tested.
 */
extern NSString *const gFTRAnalyticsHitsMisMatchedPrefix;

/**
 *  Base class for Analytics tests. Extending from this class causes the analytics config settings
 *  to be saved in the test class's setUp and restored in the tearDown so that the derived classes
 *  can modify it without effecting other tests. In addition, this class provides APIs to assert on
 *  the total number of hits sent out during the test.
 */
@interface FTRBaseAnalyticsTest : XCTestCase

/**
 *  Sets the expected analytics requests by the end of current test *class*, this value is asserted
 *  for in test class's tearDown.
 *
 *  @param count The count of expected analytics requests that must be sent out by EarlGrey.
 */
+ (void)setExpectedAnalyticsRequestsCount:(NSInteger)count;

/**
 *  Performs this class specific teardown without invoking super teardown.
 */
+ (void)classSpecificTearDown;

@end
