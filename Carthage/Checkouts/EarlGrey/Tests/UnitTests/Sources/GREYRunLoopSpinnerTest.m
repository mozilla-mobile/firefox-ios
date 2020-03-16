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

#import "Synchronization/GREYRunLoopSpinner.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYRunLoopSpinnerTest : GREYBaseTest
@end

// This string uniquely identifies a run loop mode that should be empty except for the sources,
// timers, and blocks added to it in these tests.
NSString *const kSpinnerTestMode = @"SpinnerTestMode";

// A version 0 source that may be added to the spinner test mode. This source will always signal
// itself so that it is handled every run loop drain in the spinner test mode. This source
// will increment a drain counter every time it is handled.
static CFRunLoopSourceRef counterSource;

// The number of times that the counter source has been invoked.
static NSUInteger gDrainCountForSpinnerTest;

@implementation GREYRunLoopSpinnerTest

- (void)setUp {
  [super setUp];
  gDrainCountForSpinnerTest = 0;
}

- (void)tearDown {
  [self tearDownDrainCounter];
  [super tearDown];
}

- (void)testConditionMetCallbackWhenConditionTrue {
  GREYRunLoopSpinner *spinner = [[GREYRunLoopSpinner alloc] init];

  __block BOOL conditionMetHandlerCalled = NO;
  __block NSString *conditionMetHandlerMode;

  spinner.conditionMetHandler = ^{
    conditionMetHandlerCalled = YES;
    conditionMetHandlerMode = [[NSRunLoop currentRunLoop] currentMode];
  };

  spinner.maxSleepInterval = 0;
  spinner.minRunLoopDrains = 2;
  spinner.timeout = DBL_MAX;

  [self changeActiveModeToSpinnerTestMode];

  BOOL result = [spinner spinWithStopConditionBlock:^BOOL {
    return YES;
  }];

  XCTAssertTrue(result,
                @"Spin result should be YES. The condition was met.");
  XCTAssertTrue(conditionMetHandlerCalled,
                @"Should call condition met handler if condition was met.");
  XCTAssertEqualObjects(conditionMetHandlerMode, kSpinnerTestMode,
                        @"Condition met handler should have been invoked on the active mode.");
}

- (void)testConditionMetCallbackWhenConditionEventuallyTrue {
  GREYRunLoopSpinner *spinner = [[GREYRunLoopSpinner alloc] init];

  __block BOOL conditionMetHandlerCalled = NO;
  __block NSString *conditionMetHandlerMode;

  spinner.conditionMetHandler = ^{
    XCTAssertFalse(conditionMetHandlerCalled,
                   @"The condition met handler should only be called at most once.");
    conditionMetHandlerCalled = YES;
    conditionMetHandlerMode = [[NSRunLoop currentRunLoop] currentMode];
  };

  spinner.maxSleepInterval = 0;
  spinner.minRunLoopDrains = 2;
  spinner.timeout = DBL_MAX;

  __block int conditionCheckCountLimit = 20;
  __block int currentConditionCheckCount = 0;

  [self changeActiveModeToSpinnerTestMode];

  BOOL result = [spinner spinWithStopConditionBlock:^BOOL {
    currentConditionCheckCount++;
    return currentConditionCheckCount > conditionCheckCountLimit;
  }];

  XCTAssertTrue(result,
                @"Spin result should be YES. The condition was met eventually.");
  XCTAssertTrue(conditionMetHandlerCalled,
                @"Should call condition met handler if condition was met.");
  XCTAssertEqualObjects(conditionMetHandlerMode, kSpinnerTestMode,
                        @"Condition met handler should have been invoked on the active mode.");
}

- (void)testConditionMetCallbackWhenConditionFalse {
  GREYRunLoopSpinner *spinner = [[GREYRunLoopSpinner alloc] init];

  __block BOOL conditionMetHandlerCalled = NO;

  spinner.conditionMetHandler = ^{
    XCTAssertFalse(conditionMetHandlerCalled,
                   @"The condition met handler should only be called at most once.");
    conditionMetHandlerCalled = YES;
  };

  spinner.maxSleepInterval = 0;
  spinner.minRunLoopDrains = 2;
  spinner.timeout = 0.1;

  BOOL result = [spinner spinWithStopConditionBlock:^BOOL {
    return NO;
  }];

  XCTAssertFalse(result, @"Spin result should be NO. The condition was never met.");
  XCTAssertFalse(conditionMetHandlerCalled,
                 @"Should not call condition met handler if condition was never met.");
}

- (void)testMinDrains {
  GREYRunLoopSpinner *spinner = [[GREYRunLoopSpinner alloc] init];

  __block NSUInteger minDrains = 5;
  spinner.minRunLoopDrains = minDrains;

  spinner.conditionMetHandler = ^{
    XCTAssertEqual(minDrains, gDrainCountForSpinnerTest,
                   @"This spinner's completion handler should be invoked after exactly the minimum"
                   @"number of drains.");
  };

  [self setupDrainCounter];
  [self changeActiveModeToSpinnerTestMode];

  BOOL result = [spinner spinWithStopConditionBlock:^BOOL {
    XCTAssertEqual(minDrains, gDrainCountForSpinnerTest,
                   @"The stop condition should be checked after exactly the minimum number of"
                   @"drains.");
    return YES;
  }];

  XCTAssertLessThanOrEqual(minDrains + 1, gDrainCountForSpinnerTest,
                           @"The run loop spinner guarantees that it will not iniate any new"
                           @"drains after the condition is met. However, the counter source may"
                           @"have been handled once after the condition was met.");
  XCTAssertTrue(result, @"Spin result should be YES. The condition was met.");
}

- (void)testSpinningEmptyMode {
  GREYRunLoopSpinner *spinner = [[GREYRunLoopSpinner alloc] init];

  spinner.maxSleepInterval = 0;
  spinner.minRunLoopDrains = 2;
  spinner.timeout = DBL_MAX;

  __block int conditionCheckCountLimit = 20;
  __block int currentConditionCheckCount = 0;

  [self changeActiveModeToSpinnerTestMode];

  BOOL result = [spinner spinWithStopConditionBlock:^BOOL {
    currentConditionCheckCount++;
    return currentConditionCheckCount > conditionCheckCountLimit;
  }];

  XCTAssertTrue(result,
                @"Spin result should be YES. The condition was eventually met.");
}

- (void)testChecksConditionAtLeastOncePerDrain {
  GREYRunLoopSpinner *spinner = [[GREYRunLoopSpinner alloc] init];

  spinner.maxSleepInterval = 0;
  spinner.minRunLoopDrains = 0;
  spinner.timeout = DBL_MAX;

  __block int conditionCheckCountLimit = 20;
  __block int currentConditionCheckCount = 0;
  __block NSUInteger lastConditionCheckDrainCount = gDrainCountForSpinnerTest;

  [self changeActiveModeToSpinnerTestMode];
  [self setupDrainCounter];

  BOOL result = [spinner spinWithStopConditionBlock:^BOOL {
    XCTAssertLessThanOrEqual(gDrainCountForSpinnerTest, lastConditionCheckDrainCount + 1,
                             @"The drain count should not increase by more than 1 per stop"
                             @"condition check. The spinner should check this condition at least"
                             @"once every drain.");
    lastConditionCheckDrainCount = gDrainCountForSpinnerTest;
    currentConditionCheckCount++;
    return currentConditionCheckCount > conditionCheckCountLimit;
  }];

  XCTAssertTrue(result,
                @"Spin result should be YES. The condition was eventually met.");
  XCTAssertLessThanOrEqual(gDrainCountForSpinnerTest, lastConditionCheckDrainCount + 1,
                           @"Spinner should not iniate any new drains after the condition "
                           @"was met.");
}

// Note, though it was shown to be robust when it was added, this test is very likely to become
// flaky. If it does, remove it.
- (void)testTimeout {
  GREYRunLoopSpinner *spinner = [[GREYRunLoopSpinner alloc] init];

  CFTimeInterval timeout = 0.2;
  CFTimeInterval timeoutTime = CACurrentMediaTime() + timeout;

  spinner.maxSleepInterval = 0;
  spinner.minRunLoopDrains = 0;
  spinner.timeout = timeout;


  [self changeActiveModeToSpinnerTestMode];

  BOOL result = [spinner spinWithStopConditionBlock:^BOOL {
    return NO;
  }];

  XCTAssertFalse(result,
                 @"Spin result should be NO. The condition was never met.");
  XCTAssertEqualWithAccuracy(timeoutTime, CACurrentMediaTime(), 0.1,
                             @"Since the testing run loop mode drains very quickly, the spinner"
                             @"should return very shortly after its timeout has elapsed.");
}

// Note, though it was shown to be robust when it was added, this test is very likely to become
// flaky. If it does, remove it.
- (void)testMaxSleepIntervalZero {
  GREYRunLoopSpinner *spinner = [[GREYRunLoopSpinner alloc] init];

  spinner.maxSleepInterval = 0;
  spinner.minRunLoopDrains = 0;
  spinner.timeout = 0.1;

  [self changeActiveModeToSpinnerTestMode];

  __block CFTimeInterval lastConditionCheck = CACurrentMediaTime();

  BOOL result = [spinner spinWithStopConditionBlock:^BOOL {
    // Since we are guaranteed that this condition block is checked once per drain, we can leverage
    // that to verify that the run loop is never sleeping. (Or if it is, not for long.)
    XCTAssertLessThan(CACurrentMediaTime(), lastConditionCheck + 0.1,
                      @"Since the testing run loop mode drains very quickly, the last condition"
                      @"check should have been very recent.");
    lastConditionCheck = CACurrentMediaTime();
    return NO;
  }];

  XCTAssertFalse(result,
                 @"Spin result should be NO. The condition was never met.");
}

#pragma mark - Helpers

- (void)changeActiveModeToSpinnerTestMode {
  self.activeRunLoopMode = kSpinnerTestMode;
}

// Sets up a version 0 source that will be fired on every drain in the spinner test mode.
// Be wary about using this counter as version 0 sources affect the way the run loop drains and
// nested runs of in this mode will affect the count.
- (void)setupDrainCounter {
  CFStringRef spinnerTestMode = CFBridgingRetain(kSpinnerTestMode);

  CFRunLoopSourceContext context;
  memset(&context, 0, sizeof(context));
  context.info = NULL;
  context.perform = grey_testIncrementDrainCount;
  counterSource = CFRunLoopSourceCreate(NULL, 0, &context);
  CFRunLoopAddSource(CFRunLoopGetMain(), counterSource, spinnerTestMode);

  CFRunLoopSourceSignal(counterSource);

  CFRelease(spinnerTestMode);
}

- (void)tearDownDrainCounter {
  if (counterSource) {
    CFStringRef spinnerTestMode = CFBridgingRetain(kSpinnerTestMode);

    CFRunLoopRemoveSource(CFRunLoopGetMain(), counterSource, spinnerTestMode);
    CFRelease(counterSource);
    counterSource = nil;

    CFRelease(spinnerTestMode);
  }
}

void grey_testIncrementDrainCount(void *info);
void grey_testIncrementDrainCount(void *info) {
  gDrainCountForSpinnerTest++;
  CFRunLoopSourceSignal(counterSource);
}

@end

