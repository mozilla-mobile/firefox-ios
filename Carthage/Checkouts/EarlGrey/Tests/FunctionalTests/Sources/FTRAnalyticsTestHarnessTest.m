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

#import "FTRBaseAnalyticsTest.h"

#import "FTRAssertionHandler.h"
#import <EarlGrey/EarlGrey.h>

@interface FTRAnalyticsTestHarnessTest : FTRBaseAnalyticsTest
@end

@implementation FTRAnalyticsTestHarnessTest

- (void)testHarnessCanAssertAnalyticsFailures {
  // All analytics tests use +setExpectedAnalyticsRequestsCount: to assert analytics failures and
  // this method triggers failures after the fact in +tearDown. This means that there is a risk that
  // all tests will pass if this mechanism is broken, this test ensures that it works as intended.
  // Save existing NSAssertion handler handler.
  NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
  NSAssertionHandler *previousHandler = [threadDictionary valueForKey:NSAssertionHandlerKey];

  // Setup a test NSAssertion handler.
  FTRAssertionHandler *testHandler = [[FTRAssertionHandler alloc] init];
  [threadDictionary setValue:testHandler forKey:NSAssertionHandlerKey];

  // Perform a *failing* analytics test: setting expected to be zero but a hit is actually sent out.
  [FTRBaseAnalyticsTest setExpectedAnalyticsRequestsCount:0];
  // Invoke trivial EarlGrey statement to trigger analytics.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];

  // Perform testcase and testclass teardown which must trigger a failing NSAsserts.
  [self tearDown];
  [FTRBaseAnalyticsTest classSpecificTearDown];

  // Restore the NSAssertion handler.
  [threadDictionary setValue:previousHandler forKey:NSAssertionHandlerKey];

  // Call +setUp and -setUp to even out setUp/tearDown calls.
  [[self class] setUp];
  [self setUp];

  // Assert that the analytics failure was caught by the test handler.
  XCTAssertEqual(testHandler.failuresCount, 1);
  NSString *failureDescription = testHandler.failureDescriptions[0];
  XCTAssertTrue([failureDescription containsString:gFTRAnalyticsHitsMisMatchedPrefix]);
}

@end
