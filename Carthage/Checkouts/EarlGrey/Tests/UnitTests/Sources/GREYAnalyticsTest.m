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

#import <OCMock/OCMock.h>

#import "Additions/NSString+GREYAdditions.h"
#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYAnalytics.h"
#import "Common/GREYAnalyticsDelegate.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYAnalyticsTestDelegate : NSObject<GREYAnalyticsDelegate>

@property(nonatomic, assign) NSInteger count;
@property(nonatomic, strong) NSString *clientID;
@property(nonatomic, strong) NSString *bundleID;
@property(nonatomic, strong) NSString *subCategory;

@end

@implementation GREYAnalyticsTestDelegate

- (void)trackEventWithTrackingID:(NSString *)trackingID
                        clientID:(NSString *)clientID
                        category:(NSString *)category
                          action:(NSString *)subCategory
                           value:(NSString *)value {
  _clientID = clientID;
  _bundleID = category;
  _subCategory = subCategory;
  _count += 1;
}

@end

@interface GREYAnalyticsTest : GREYBaseTest
@end

@implementation GREYAnalyticsTest {
  // Reference to the previous analytics delegate that this test overrides (used to restore later).
  id<GREYAnalyticsDelegate> _previousDelegate;
  // The test delegate that saves data passed in for verification.
  GREYAnalyticsTestDelegate *_testDelegate;
}

- (void)setUp {
  [super setUp];

  _previousDelegate = [[GREYAnalytics sharedInstance] delegate];
  _testDelegate = [[GREYAnalyticsTestDelegate alloc] init];
  [[GREYAnalytics sharedInstance] setDelegate:_testDelegate];
}

- (void)tearDown {
  [[GREYAnalytics sharedInstance] setDelegate:_previousDelegate];

  [super tearDown];
}

- (void)testAnalyticsDelegateGetsAnonymizedBundleID {
  // Verify bundle ID is a non-empty string.
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
  XCTAssertGreaterThan([bundleID length], 0u);

  [self greytest_simulateTestExecution];
  XCTAssertEqualObjects([bundleID grey_md5String], _testDelegate.bundleID);
  XCTAssertEqual(_testDelegate.count, 1);
}

- (void)testAnalyticsDelegateGetsTestCaseMD5 {
  [self greytest_simulateTestExecution];

  // Verify the testcase name passed to the delegate is md5ed.
  NSString *testCase = [NSString stringWithFormat:@"%@::%@",
                                                  [self grey_testClassName],
                                                  [self grey_testMethodName]];
  NSString *testCaseId = [NSString stringWithFormat:@"TestCase_%@", [testCase grey_md5String]];
  NSString *expectedTestCaseId = @"TestCase_5f844eaf0aeace73b955acc9f896800f";
  XCTAssertEqualObjects(testCaseId, expectedTestCaseId);
  XCTAssertEqualObjects(_testDelegate.subCategory, expectedTestCaseId);
  XCTAssertEqual(_testDelegate.count, 1);
}

- (void)testAnalyticsDelegateGetsAnonymousClientId {
  NSString *fakeUUID = @"1234-1234-1234-1234";
  id uuidMock = [OCMockObject mockForClass:[NSUUID class]];
  [[[uuidMock stub] andReturn:fakeUUID] UUIDString];
  id uuidClassMock = [OCMockObject mockForClass:[NSUUID class]];
  [[[uuidClassMock stub] andReturn:uuidMock] UUID];

  [self greytest_simulateTestExecution];

  // Verify the client ID passed to the delegate contains anonymous data.
  // Note that this string must be modified if the test class name, test case name or the test app's
  // bundle ID changes.
  NSString *expectedClientId = fakeUUID;
  XCTAssertEqualObjects(_testDelegate.clientID, expectedClientId,
                        @"Either the user ID is not being anonymized or the test class, test "
                        @"method or test app's bundle ID has changed.");
  XCTAssertEqual(_testDelegate.count, 1);
}

#pragma mark - Private

/**
 *  Simulates the test execution to trigger analytics.
 */
- (void)greytest_simulateTestExecution {
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  [[GREYAnalytics sharedInstance] grey_testCaseInstanceDidTearDown];
}

/**
 *  @return The testcase count present in the given Analytics Event sub-category value.
 */
- (NSInteger)greytest_getTestCaseCountFromSubCategory:(NSString *)subCategoryValue {
  // Subcategory is in the following format: TestCase_<count>, we must extract <count>.
  NSString *testCaseCountString =
      [[subCategoryValue lowercaseString] componentsSeparatedByString:@"testcase_"][1];
  return [testCaseCountString integerValue];
}

@end
