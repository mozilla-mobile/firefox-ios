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

#import "Additions/XCTestCase+GREYAdditions.h"
#import <EarlGrey/GREYFrameworkException.h>
#import "GREYBaseTest.h"

#pragma mark - Example tests

static NSString *const kGREYSampleExceptionName = @"GREYSampleException";

static NSString *gXCTestCaseInterruptionExceptionName;

@interface GREYSampleTests : XCTestCase

@property(nonatomic, assign) BOOL failInSetUp;
@property(nonatomic, assign) BOOL failInTearDown;

@end

@implementation GREYSampleTests

+ (void)initialize {
  if (self == [GREYSampleTests class]) {
#if defined(__IPHONE_11_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
    gXCTestCaseInterruptionExceptionName = @"NSInternalInconsistencyException";
#else
    gXCTestCaseInterruptionExceptionName = @"_XCTestCaseInterruptionException";
#endif
  }
}

- (void)setUp {
  [super setUp];
  [EarlGrey setFailureHandler:nil];
  if (self.failInSetUp) {
    GREYAssertTrue(NO, @"Induced failure in setUp.");
  }
}

- (void)tearDown {
  [super tearDown];
  if (self.failInTearDown) {
    GREYAssertTrue(NO, @"Induced failure in tearDown.");
  }
}

- (void)failUsingGREYAssert {
  GREYAssertTrue(NO, @"Failing test with GREYAssert.");
}

- (void)failUsingNSAssert {
  NSAssert(NO, @"Failing test with NSAssert.");
}

- (void)failUsingRecordFailureWithDescription {
  [self recordFailureWithDescription:@"Test Failure"
                              inFile:@"XCTestCase+GREYAdditionsTest.m"
                              atLine:0
                            expected:NO];
}

- (void)failByRaisingException {
  [[NSException exceptionWithName:kGREYSampleExceptionName
                           reason:@"Failure from exception test"
                         userInfo:nil] raise];
}

- (void)successfulTest {
  GREYAssertTrue(YES, @"Test should pass.");
}

@end

#pragma mark - Actual Tests

@interface XCTestCase_GREYAdditionsTest : GREYBaseTest
@end

@implementation XCTestCase_GREYAdditionsTest

- (void)tearDown {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super tearDown];
}

- (void)testGreyStatusIsFailedAfterGreyAssertFailure {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingGREYAssert)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               gXCTestCaseInterruptionExceptionName);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from GREYAssert failure");
}

- (void)testGreyStatusIsFailedAfterNSAssertFailure {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingNSAssert)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               NSInternalInconsistencyException);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from NSAssert failure");
}

- (void)testGreyStatusIsFailedAfterRecordFailureWithDescription {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingRecordFailureWithDescription)];
  XCTestRun *testRun = [XCTestRun testRunWithTest:failingTest];
  NSAssert(testRun, @"Test Run cannot be nil.");
  [[testRun test] performTest:testRun];
  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from RecordFailureWithDescription");
  XCTAssertTrue(YES);
}


- (void)testGreyStatusIsFailedAfterUncaughtException {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failByRaisingException)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               kGREYSampleExceptionName);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from uncaught exception");
}

- (void)testGreyStatusIsPassedAfterSuccessfulTest {
  GREYSampleTests *successfulTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  [successfulTest invokeTest];
  NSAssert(successfulTest.grey_status == kGREYXCTestCaseStatusPassed,
           @"Test should have passed");
}

- (void)testTestStatusIsFailedOnWillTeardownAfterGREYAssertFailure {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingGREYAssert)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               gXCTestCaseInterruptionExceptionName);

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testTestStatusIsFailedOnWillTeardownAfterNSAssertFailure {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingNSAssert)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               NSInternalInconsistencyException);

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testTestStatusIsFailedOnWillTeardownAfterRecordFailureWithDescription {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingRecordFailureWithDescription)];

  XCTestRun *testRun = [XCTestRun testRunWithTest:failingTest];
  NSAssert(testRun, @"Test Run cannot be nil.");
  [[testRun test] performTest:testRun];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testTestStatusIsFailedOnWillTeardownAfterUncaughtException {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failByRaisingException)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               kGREYSampleExceptionName);

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testTestStatusIsUnknownOnWillTeardownAfterSuccessfulTest {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsUnknownOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *successfulTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  [successfulTest invokeTest];

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testPassedSetUpSendsNotifications {
  GREYSampleTests *passingTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];

  __block BOOL willSetUpCalled = NO;
  void (^willSetUpBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
    willSetUpCalled = YES;
    XCTAssertEqual(note.object, passingTest);
  };

  __block BOOL didSetUpCalled = NO;
  void (^didSetUpBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
    didSetUpCalled = YES;
    XCTAssertEqual(note.object, passingTest);
  };
  id notificationID1 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceWillSetUp
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willSetUpBlock];
  id notificationID2 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidSetUp
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didSetUpBlock];

  [passingTest invokeTest];
  XCTAssertTrue(willSetUpCalled);
  XCTAssertTrue(didSetUpCalled);

  [[NSNotificationCenter defaultCenter] removeObserver:notificationID1];
  [[NSNotificationCenter defaultCenter] removeObserver:notificationID2];
}

- (void)testFailedSetUpSendsNotifications {
  GREYSampleTests *failingSetUpTest =
  [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  failingSetUpTest.failInSetUp = YES;

  __block BOOL willSetUpCalled = NO;
  void (^willSetUpBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
    willSetUpCalled = YES;
    XCTAssertEqual(note.object, failingSetUpTest);
  };

  __block BOOL didSetUpCalled = NO;
  void (^didSetUpBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
    didSetUpCalled = YES;
    XCTAssertEqual(note.object, failingSetUpTest);
  };
  id notificationID1 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceWillSetUp
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willSetUpBlock];
  id notificationID2 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidSetUp
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didSetUpBlock];

  XCTAssertThrowsSpecificNamed([failingSetUpTest invokeTest],
                               NSException,
                               gXCTestCaseInterruptionExceptionName);
  XCTAssertTrue(willSetUpCalled);
  XCTAssertFalse(didSetUpCalled);

  [[NSNotificationCenter defaultCenter] removeObserver:notificationID1];
  [[NSNotificationCenter defaultCenter] removeObserver:notificationID2];
}

- (void)testPassedTearDownSendsNotifications {
  GREYSampleTests *passingTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];

  __block BOOL willTearDownCalled = NO;
  void (^willTearDownBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
    willTearDownCalled = YES;
    XCTAssertEqual(note.object, passingTest);
  };

  __block BOOL didTearDownCalled = NO;
  void (^didTearDownBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
    didTearDownCalled = YES;
    XCTAssertEqual(note.object, passingTest);
  };
  id notificationID1 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceWillTearDown
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willTearDownBlock];
  id notificationID2 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidTearDown
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didTearDownBlock];

  [passingTest invokeTest];
  XCTAssertTrue(willTearDownCalled);
  XCTAssertTrue(didTearDownCalled);

  [[NSNotificationCenter defaultCenter] removeObserver:notificationID1];
  [[NSNotificationCenter defaultCenter] removeObserver:notificationID2];
}

- (void)testFailedTearDownSendsNotifications {
  GREYSampleTests *failingTearDownTest =
  [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  failingTearDownTest.failInTearDown = YES;

  __block BOOL willTearDownCalled = NO;
  void (^willTearDownBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
    willTearDownCalled = YES;
    XCTAssertEqual(note.object, failingTearDownTest);
  };

  __block BOOL didTearDownCalled = NO;
  void (^didTearDownBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
    didTearDownCalled = YES;
    XCTAssertEqual(note.object, failingTearDownTest);
  };
  id notificationID1 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceWillTearDown
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willTearDownBlock];
  id notificationID2 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidTearDown
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didTearDownBlock];

  XCTAssertThrowsSpecificNamed([failingTearDownTest invokeTest],
                               NSException,
                               gXCTestCaseInterruptionExceptionName);
  XCTAssertTrue(willTearDownCalled);
  XCTAssertFalse(didTearDownCalled);

  [[NSNotificationCenter defaultCenter] removeObserver:notificationID1];
  [[NSNotificationCenter defaultCenter] removeObserver:notificationID2];
}

#pragma mark - Helper methods

- (void)verifyTestStatusIsFailedOnWillTearDown:(NSNotification *)notification {
  XCTestCase *testCase = (XCTestCase *)[notification object];
  NSAssert(testCase.grey_status == kGREYXCTestCaseStatusFailed,
           @"TestCase status should be failed on WillTearDown notification.");
}

- (void)verifyTestStatusIsUnknownOnWillTearDown:(NSNotification *)notification {
  XCTestCase *testCase = (XCTestCase *)[notification object];
  NSAssert(testCase.grey_status == kGREYXCTestCaseStatusUnknown,
           @"TestCase status should be unknown on WillTearDown notification.");
}

@end
