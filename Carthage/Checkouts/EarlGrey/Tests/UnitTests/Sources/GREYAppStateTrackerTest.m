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

#import "Synchronization/GREYAppStateTracker.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYAppStateTrackerTest : GREYBaseTest
@end

@implementation GREYAppStateTrackerTest

- (void)tearDown {
  [super tearDown];
  [[GREYAppStateTracker sharedInstance] clearIgnoredStates];
}

- (void)testLastKnownStateChangedAfterOnStateChange {
  // NS_VALID_UNTIL_END_OF_SCOPE required so obj1 and obj2 are valid until end of the current scope.
  NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj1 = [[NSObject alloc] init];

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYIdle,
                 @"By default current state should always be in kGREYIdle");

  GREYAppStateTrackerObject *elementID1 = TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj1);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYPendingCAAnimation,
                 @"State should be kGREYPendingCAAnimation");

  NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj2 = [[NSObject alloc] init];
  GREYAppStateTrackerObject *elementID2 = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, obj2);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYPendingCAAnimation,
                 @"State should be kGREYPendingCAAnimation");
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj2],
                 kGREYPendingDrawLayoutPass,
                 @"State should be kGREYPendingDrawCycle");

  UNTRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, elementID1);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYIdle,
                 @"State should be kGREYIdle");
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj2],
                 kGREYPendingDrawLayoutPass,
                 @"State should be kGREYPendingDrawCycle");

  UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, elementID2);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYIdle,
                 @"State should be kGREYIdle");
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj2],
                 kGREYIdle,
                 @"State should be kGREYIdle");

}

- (void)testCurrentStateAfterOnStateChange {
  NSObject *obj1 = [[NSObject alloc] init];
  NSObject *obj2 = [[NSObject alloc] init];

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle,
                 @"By default current state should always be in kGREYIdle");

  GREYAppStateTrackerObject *elementID1 = TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj1);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYPendingCAAnimation,
                 @"State should be kGREYPendingCAAnimation");

  GREYAppStateTrackerObject *elementID2 = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, obj2);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState],
                 kGREYPendingCAAnimation | kGREYPendingDrawLayoutPass,
                 @"State should be kGREYPendingCAAnimation and kGREYPendingDrawCycle");

  UNTRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, elementID1);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYPendingDrawLayoutPass,
                 @"State should be kGREYPendingDrawCycle");

  UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, elementID2);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle,
                 @"State should be kGREYIdle");
}

- (void)testDescriptionInVerboseMode {
  NSObject *obj1 = [[NSObject alloc] init];

  NSString *desc = [[GREYAppStateTracker sharedInstance] description];
  XCTAssertTrue([desc rangeOfString:@"Idle"].location != NSNotFound,
                 @"No state transition, should report Idle state in description");

  TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj1);

  desc = [[GREYAppStateTracker sharedInstance] description];
  XCTAssertTrue([desc rangeOfString:@"Waiting for CAAnimations to finish"].location != NSNotFound,
                @"Should report that it is waiting on CAAnimation to finish");

  NSString *obj1ClassAndMemory =
      [NSString stringWithFormat:@"<%@:%p>", [obj1 class], obj1];
  NSString *obj1FullStateDesc = [NSString stringWithFormat:@"%@ => %@",
                                                           obj1ClassAndMemory,
                                                           @"Waiting for CAAnimations to finish"];
  XCTAssertTrue([desc rangeOfString:obj1FullStateDesc].location != NSNotFound,
                @"Should report exactly what object is in what state.");
}

- (void)testDeallocatedObjectClearsState {
  @autoreleasepool {
    __autoreleasing NSObject *obj = [[NSObject alloc] init];
    TRACK_STATE_FOR_OBJECT(kGREYPendingUIWebViewAsyncRequest, obj);
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj],
                   kGREYPendingUIWebViewAsyncRequest);
  }
  // obj should dealloc and clear all associations, causing state tracker to untrack all states
  // associated to it.
  XCTAssertEqual(kGREYIdle, [[GREYAppStateTracker sharedInstance] currentState]);
}

- (void)testAppStateEfficiency {
  CFTimeInterval testStartTime = CACurrentMediaTime();

  // Make a really big UIView hierarchy.
  UIView *view = [[UIView alloc] init];
  for (int i = 0; i < 15000; i++) {
    [view addSubview:[[UIView alloc] init]];
  }

  // With efficient state tracking, this test should complete in under .5 seconds. To avoid test
  // flakiness, just make sure that it is under 10 seconds.
  XCTAssertLessThan(CACurrentMediaTime() - testStartTime, 10,
                    @"This test should complete in less than than 10 seconds.");
}

- (void)testTrackingIgnoredState {
  GREYAppState testIgnoreState = kGREYPendingViewsToAppear;
  [[GREYAppStateTracker sharedInstance] ignoreChangesToState:testIgnoreState];
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    XCTAssertNil([self grey_trackStateForTesting:testIgnoreState onObject:obj]);
    XCTAssertNotEqual([[GREYAppStateTracker sharedInstance] currentState], testIgnoreState);
    XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] & testIgnoreState);
  }
}

- (void)testIgnoreStateValueDoesNotAffectTrackedState {
  GREYAppState testIgnoreState = kGREYPendingViewsToAppear;
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    GREYAppStateTrackerObject *objId =
        [self grey_trackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], testIgnoreState);
    objId = [self grey_ignoreAndTrackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], testIgnoreState);
  }
}

- (void)testIgnoringInvalidState {
  GREYAppState testIgnoreState = kGREYIdle;
  XCTAssertThrows([[GREYAppStateTracker sharedInstance] ignoreChangesToState:testIgnoreState]);
}

- (void)testIgnoringMultipleStates {
  GREYAppState testIgnoreStates = kGREYPendingViewsToAppear | kGREYPendingViewsToDisappear;
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    GREYAppStateTrackerObject *objId =
        [self grey_ignoreAndTrackStateForTesting:testIgnoreStates onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
    objId = [self grey_trackStateForTesting:kGREYPendingViewsToAppear onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
    objId = [self grey_trackStateForTesting:kGREYPendingViewsToAppear onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
  }
}

- (void)testIgnoringOneOfTrackedTests {
  GREYAppState testIgnoreState = kGREYPendingViewsToAppear;
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    GREYAppState trackedState = kGREYPendingViewsToAppear | kGREYPendingCAAnimation;
    [[GREYAppStateTracker sharedInstance] ignoreChangesToState:testIgnoreState];
    [self grey_trackStateForTesting:trackedState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYPendingCAAnimation);
    XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] & testIgnoreState);
  }
}

- (void)testAdditionOfIgnoreStates {
  GREYAppState testIgnoreState = kGREYPendingViewsToAppear;
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    GREYAppStateTrackerObject *objId =
        [self grey_ignoreAndTrackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
    testIgnoreState = testIgnoreState | kGREYPendingViewsToDisappear;
    [[GREYAppStateTracker sharedInstance] ignoreChangesToState:testIgnoreState];
    objId = [self grey_trackStateForTesting:kGREYPendingViewsToAppear onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
    XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] & testIgnoreState);
    objId = [self grey_trackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
    XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] & testIgnoreState);
    objId = [self grey_trackStateForTesting:kGREYPendingDrawLayoutPass onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYPendingDrawLayoutPass);
    XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] & testIgnoreState);
  }
}

- (void)testIgnoringOneStateAndTrackingAnotherState {
  GREYAppState testIgnoreState = kGREYPendingViewsToAppear;
  GREYAppState testTrackedState = kGREYPendingViewsToDisappear;
  [[GREYAppStateTracker sharedInstance] ignoreChangesToState:testIgnoreState];
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    [self grey_ignoreAndTrackStateForTesting:testIgnoreState onObject:obj];
    [self grey_trackStateForTesting:testTrackedState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], testTrackedState);
  }
}

- (void)testIgnoringTrackingAndUntrackingState {
  GREYAppState testIgnoreState = kGREYPendingViewsToAppear;
  // Track a particular state.
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    GREYAppStateTrackerObject *objID =
        [self grey_trackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], testIgnoreState);
    // Ignore the particular state. The untracking should work.
    [[GREYAppStateTracker sharedInstance] ignoreChangesToState:testIgnoreState];
    UNTRACK_STATE_FOR_OBJECT(testIgnoreState, objID);
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
  }
}

- (void)testBehaviorAfterUnIgnoring {
  GREYAppState testIgnoreState = kGREYPendingViewsToAppear;
  // Track a particular state.
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    GREYAppStateTrackerObject *objId =
        [self grey_trackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], testIgnoreState);
    // Ignore the particular state. The untracking should work.
    [[GREYAppStateTracker sharedInstance] ignoreChangesToState:testIgnoreState];
    UNTRACK_STATE_FOR_OBJECT(testIgnoreState, objId);
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);

    // Re-track the particular state. This won't work since we're ignoring the state.
    objId = [self grey_trackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
    // Stop ignoring the particular state. The untracking shouldn't affect anything since
    // nothing was tracked.
    [[GREYAppStateTracker sharedInstance] clearIgnoredStates];
    UNTRACK_STATE_FOR_OBJECT(testIgnoreState, objId);
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
  }
}

- (void)testClearingIgnoredStates {
  GREYAppState testIgnoreState = kGREYPendingViewsToAppear;
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    GREYAppStateTrackerObject *objId =
        [self grey_ignoreAndTrackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle);
    // Clear the ignored states.
    [[GREYAppStateTracker sharedInstance] clearIgnoredStates];
    // Track the state and check that it is not ignored.
    objId = [self grey_trackStateForTesting:testIgnoreState onObject:obj];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], testIgnoreState);
  }
}

#pragma mark - Private

- (GREYAppStateTrackerObject *)grey_ignoreAndTrackStateForTesting:(GREYAppState)state
                                                         onObject:(id)object {
  [[GREYAppStateTracker sharedInstance] ignoreChangesToState:state];
  return [self grey_trackStateForTesting:state onObject:object];
}

- (GREYAppStateTrackerObject *)grey_trackStateForTesting:(GREYAppState)state onObject:(id)object {
  XCTAssert(object != nil, @"The object for tracking cannot be nil.");
  GREYAppStateTrackerObject *objId = TRACK_STATE_FOR_OBJECT(state, object);
  return objId;
}

@end
