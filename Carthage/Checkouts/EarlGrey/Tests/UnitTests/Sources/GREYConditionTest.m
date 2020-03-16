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

#import <EarlGrey/GREYCondition.h>
#import "GREYBaseTest.h"

@interface GREYConditionTest : GREYBaseTest
@end

@implementation GREYConditionTest

- (void)testConditionMet {
  __block BOOL conditionCalled = NO;
  GREYCondition *condition = [GREYCondition conditionWithName:@"test" block:^BOOL() {
    conditionCalled = YES;
    return YES;
  }];
  [condition waitWithTimeout:0.1];

  XCTAssertTrue(conditionCalled, @"Condition should have been called.");
}

- (void)testConditionMetAfterMultipleAttempts {
  __block BOOL conditionCalled = NO;
  __block int numExec = 0;
  GREYCondition *condition = [GREYCondition conditionWithName:@"test" block:^BOOL() {
    conditionCalled = YES;
    if (++numExec >= 3) {
      return YES;
    } else {
      return NO;
    }
  }];
  [condition waitWithTimeout:0.1];

  XCTAssertTrue(conditionCalled, @"Condition should have been called.");
  XCTAssertEqual(numExec, 3, @"Condition should have met the third time and returned immediately. "
                             @"Current condition execution count: %d", numExec);
}

- (void)testConditionTimedOut {
  __block BOOL conditionCalled = NO;
  GREYCondition *condition = [GREYCondition conditionWithName:@"test" block:^BOOL() {
    conditionCalled = YES;
    return NO;
  }];

  CFTimeInterval beforeWaitWithTimeoutTime = CACurrentMediaTime();
  BOOL timedOut = ![condition waitWithTimeout:0.1];
  CFTimeInterval afterWaitWithTimeoutTime = CACurrentMediaTime();
  CFTimeInterval deltaBeforeAndAfterWaitWithTimeoutTime =
      beforeWaitWithTimeoutTime - afterWaitWithTimeoutTime;

  XCTAssertLessThanOrEqual(deltaBeforeAndAfterWaitWithTimeoutTime, 0.2);
  XCTAssertTrue(conditionCalled, @"Condition should have been called.");
  XCTAssertTrue(timedOut, @"Condition should have timed out.");
}

- (void)testConditionWithVerySmallTimeout {
  GREYCondition *condition = [GREYCondition conditionWithName:@"test" block:^ {
    return YES;
  }];
  BOOL timedOut = ![condition waitWithTimeout:0.000000001];
  XCTAssertFalse(timedOut, @"Condition should have not timed out.");
}

- (void)testDrainUntilIdleInsideCondition {
  __block BOOL called = NO;
  GREYCondition *condition = [GREYCondition conditionWithName:@"test" block:^ {
    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
    called = YES;
    return YES;
  }];
  XCTAssertNoThrow([condition waitWithTimeout:0.1]);
  XCTAssertTrue(called, @"Was the condition even executed?");
}

@end
