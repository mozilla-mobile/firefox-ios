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

#import <objc/runtime.h>

#import "Additions/CALayer+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import <EarlGrey/GREYConfiguration.h>
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

static const CFTimeInterval kMaxAnimationInterval = 5.0;

// Class that performs swizzled operations in dealloc to ensure they don't track
@interface CALayerDealloc : CALayer
@end

@implementation CALayerDealloc

- (void)dealloc {
  [self setNeedsDisplayInRect:CGRectNull];
  [self setNeedsDisplay];
  [self setNeedsLayout];
}

@end

@interface CALayer_GREYAdditionsTest : GREYBaseTest
@end

@implementation CALayer_GREYAdditionsTest {
  NSTimer *timer;
}

- (void)setUp {
  [super setUp];
  [[GREYConfiguration sharedInstance] setValue:@(kMaxAnimationInterval)
                                  forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
}

- (void)testDrawRequestChangesPendingUIEventState {
  [[GREYAppStateTracker sharedInstance] grey_clearState];
  // NS_VALID_UNTIL_END_OF_SCOPE required so layer is valid until end of the current scope.
  NS_VALID_UNTIL_END_OF_SCOPE CALayer *layer = [[CALayer alloc] init];
  [layer setNeedsLayout];
  XCTAssertEqual(kGREYPendingDrawLayoutPass,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");

  [[GREYAppStateTracker sharedInstance] grey_clearState];

  layer = [[CALayer alloc] init];
  [layer setNeedsDisplay];
  XCTAssertEqual(kGREYPendingDrawLayoutPass,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");

  [[GREYAppStateTracker sharedInstance] grey_clearState];
  layer = [[CALayer alloc] init];
  [layer setNeedsDisplayInRect:CGRectMake(0, 0, 0, 0)];
  XCTAssertEqual(kGREYPendingDrawLayoutPass,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");
}

- (void)testAddAnimationWithLongDuration {
  CALayer *layer = [[CALayer alloc] init];

  CAAnimation *animationLongDuration = [CAAnimation animation];
  animationLongDuration.duration = 10.0 + kMaxAnimationInterval;

  [layer addAnimation:animationLongDuration forKey:@"animationLongDuration"];
  CAAnimation *animation = [layer animationForKey:@"animationLongDuration"];
  XCTAssertEqual(kMaxAnimationInterval,
                 animation.duration,
                 @"Duration must be less than %f", kMaxAnimationInterval);
}

- (void)testAddAnimationWithLongRepeatCount {
  CALayer *layer = [[CALayer alloc] init];

  CAAnimation *animationLongRepeatCount = [CAAnimation animation];
  animationLongRepeatCount.duration = kMaxAnimationInterval / 2.0;
  animationLongRepeatCount.repeatCount = kMaxAnimationInterval + 10;

  [layer addAnimation:animationLongRepeatCount forKey:@"animationLongRepeatCount"];
  CAAnimation *animation = [layer animationForKey:@"animationLongRepeatCount"];
  XCTAssertEqualWithAccuracy(animation.repeatCount,
                             1,
                             0.1,
                             @"Should have reduced repeat count to fit in maxAnimationDuration");

  CAAnimation *animationShortRepeatCount = [CAAnimation animation];
  animationShortRepeatCount.duration = kMaxAnimationInterval / 5.0;
  animationShortRepeatCount.repeatCount = 0;

  [layer addAnimation:animationShortRepeatCount forKey:@"animationShortRepeatCount"];
  animation = [layer animationForKey:@"animationShortRepeatCount"];
  XCTAssertEqualWithAccuracy(animation.repeatCount,
                             0,
                             0.0001,
                             @"Should not change repeat count");
}

- (void)testAddAnimationWithLongRepeatDuration {
  CALayer *layer = [[CALayer alloc] init];

  CAAnimation *animationLongRepeatDuration = [CAAnimation animation];
  animationLongRepeatDuration.duration = kMaxAnimationInterval / 2.0;
  animationLongRepeatDuration.repeatDuration = kMaxAnimationInterval + 10.0;

  [layer addAnimation:animationLongRepeatDuration forKey:@"animationLongRepeatDuration"];
  CAAnimation *animation = [layer animationForKey:@"animationLongRepeatDuration"];
  XCTAssertEqualWithAccuracy(animation.repeatDuration,
                             kMaxAnimationInterval / 2.0,
                             0.0001,
                             @"Should have reduced repeat duration to fit in maxAnimationDuration");
}

// Tests that animations are not limited if the appropriate GREYConfiguration flag is disabled.
- (void)testLimitAnimationsFlag {
  [[GREYConfiguration sharedInstance] setValue:@NO
                                  forConfigKey:kGREYConfigKeyCALayerModifyAnimations];

  CALayer *layer = [[CALayer alloc] init];

  CAAnimation *animationLongRepeatCount = [CAAnimation animation];
  animationLongRepeatCount.duration = 5;
  animationLongRepeatCount.repeatCount = 10;

  [layer addAnimation:animationLongRepeatCount forKey:@"animationLongRepeatCount"];
  CAAnimation *animation = [layer animationForKey:@"animationLongRepeatCount"];
  XCTAssertEqualWithAccuracy(animation.duration,
                             5,
                             0.0001,
                             @"Should not change duration");
  XCTAssertEqualWithAccuracy(animation.repeatCount,
                             10,
                             0.0001,
                             @"Should not change repeat count");
}

- (void)testNotTrackedDuringDealloc {
  {
    // NS_VALID_UNTIL_END_OF_SCOPE required so layer is valid until end of the current scope.
    NS_VALID_UNTIL_END_OF_SCOPE CALayerDealloc *layer = [[CALayerDealloc alloc] init];

    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState],
                   kGREYIdle,
                   @"State tracker must be idle so tracking during dealloc can be detected");
  }

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState],
                 kGREYIdle,
                 @"State should be idle after object is deallocated.");
}

- (void)testPausingAndResumingAnimationsFromParentLayer {
  UIView *view = [[UIView alloc] init];
  CALayer *sublayer = [[CALayer alloc] init];

  [view.layer addSublayer:sublayer];

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation setDuration:2];
  [animation setFromValue:[NSNumber numberWithFloat:0.0f]];
  [animation setToValue:[NSNumber numberWithFloat:6.18f]];
  [sublayer addAnimation:animation forKey:@"TestAnim1"];
  GREYAppState state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertTrue(state & kGREYPendingCAAnimation,
                @"Right after adding an animation, state should change to pending animation");

  // Pause top-most view layer.
  view.layer.speed = 0;

  NSMutableSet *pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 1u,
                 @"Number of paused animations should be exactly 1!");
  XCTAssertTrue([pausedAnimationKeys containsObject:@"TestAnim1"],
                @"Animation was not paused!");

  // Drain so that state changes in addAnimation are untracked.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertEqual(state, kGREYIdle, @"State tracker is not idle after pausing animations!");

  // Resume top-most view layer.
  view.layer.speed = 1;

  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 0u, @"Animation did not resume!");
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYPendingCAAnimation,
                 @"State tracker not pending after resuming animation!");
}

- (void)testPausingAndResumingAnimationsFromSublayer {
  UIView *view = [[UIView alloc] init];
  CALayer *sublayer = [[CALayer alloc] init];

  [view.layer addSublayer:sublayer];

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation setDuration:2];
  [animation setFromValue:[NSNumber numberWithFloat:0.0f]];
  [animation setToValue:[NSNumber numberWithFloat:6.18f]];
  [sublayer addAnimation:animation forKey:@"TestAnim1"];
  GREYAppState state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertTrue(state & kGREYPendingCAAnimation,
                @"Right after adding an animation, state should change to pending animation");

  // Pause top-most view layer.
  sublayer.speed = 0;

  NSMutableSet *pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 1u,
                 @"Number of paused animations should be exactly 1!");
  XCTAssertTrue([pausedAnimationKeys containsObject:@"TestAnim1"],
                @"Animation was not paused!");
  // Drain so that state changes in addAnimation are untracked.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertEqual(state, kGREYIdle, @"State tracker is not idle after pausing animations!");

  // Resume top-most view layer.
  sublayer.speed = 1;

  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 0u, @"Animation did not resume!");
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYPendingCAAnimation,
                 @"State tracker not pending after resuming animation!");
}

- (void)testResumingParentDoesNotResumeSublayer {
  UIView *view = [[UIView alloc] init];
  CALayer *sublayer = [[CALayer alloc] init];

  [view.layer addSublayer:sublayer];

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation setDuration:2];
  [animation setFromValue:[NSNumber numberWithFloat:0.0f]];
  [animation setToValue:[NSNumber numberWithFloat:6.18f]];
  [sublayer addAnimation:animation forKey:@"TestAnim1"];
  GREYAppState state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertTrue(state & kGREYPendingCAAnimation,
                @"Right after adding an animation, state should change to pending animation");

  // Pause top-most view layer.
  sublayer.speed = 0;

  NSMutableSet *pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 1u,
                 @"Number of paused animations should be exactly 1!");
  XCTAssertTrue([pausedAnimationKeys containsObject:@"TestAnim1"],
                @"Animation was not paused!");
  // Drain so that state changes in addAnimation are untracked.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertEqual(state, kGREYIdle, @"State tracker is not idle after pausing animations!");

  // Resume top-most view layer.
  sublayer.speed = 1;

  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 0u, @"Animation did not resume!");
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYPendingCAAnimation,
                 @"State tracker not pending after resuming animation!");
}

- (void)testSuccessiveAnimationPauses {
  UIView *view = [[UIView alloc] init];
  CALayer *sublayer = [[CALayer alloc] init];

  [view.layer addSublayer:sublayer];

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation setDuration:2];
  [animation setFromValue:[NSNumber numberWithFloat:0.0f]];
  [animation setToValue:[NSNumber numberWithFloat:6.18f]];
  [view.layer addAnimation:animation forKey:@"TestAnim1"];

  CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation2 setDuration:2];
  [animation2 setFromValue:[NSNumber numberWithFloat:0.0f]];
  [animation2 setToValue:[NSNumber numberWithFloat:6.18f]];
  [sublayer addAnimation:animation forKey:@"TestAnim2"];

  // Pause view layer.
  view.layer.speed = 0;
  // Pause sublayer.
  sublayer.speed = 0;

  // Check view layer animations are paused.
  NSMutableSet *pausedAnimationKeys = [view.layer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 1u,
                 @"Number of paused animations should be exactly 1!");
  XCTAssertTrue([pausedAnimationKeys containsObject:@"TestAnim1"],
                @"Animation was not paused!");
  // Check sublayer animations are paused.
  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 1u,
                 @"Number of paused animations should be exactly 1!");
  XCTAssertTrue([pausedAnimationKeys containsObject:@"TestAnim2"],
                @"Animation was not paused!");
  GREYAppState state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYIdle, @"State tracker is not idle after animations paused!");

  // Resume view layer, but not sublayer.
  view.layer.speed = 1;

  // Check that view layer animation resumed.
  pausedAnimationKeys = [view.layer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 0u, @"Animation was not resumed!");
  // Check that sublayer animation did not resume.
  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 1u, @"Animation was not resumed!");
  XCTAssertTrue([pausedAnimationKeys containsObject:@"TestAnim2"],
                @"Animation was not paused!");
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYIdle, @"State tracker is not idle after animations paused!");
}

- (void)testSuccessiveAnimationResumes {
  UIView *view = [[UIView alloc] init];
  CALayer *sublayer = [[CALayer alloc] init];

  [view.layer addSublayer:sublayer];

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation setDuration:2];
  [animation setFromValue:[NSNumber numberWithFloat:0.0f]];
  [animation setToValue:[NSNumber numberWithFloat:6.18f]];
  [sublayer addAnimation:animation forKey:@"TestAnim1"];
  GREYAppState state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertTrue(state & kGREYPendingCAAnimation,
                @"Right after adding an animation, state should change to pending animation");

  // Pause layer.
  view.layer.speed = 0;

  NSMutableSet *pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 1u,
                 @"Number of paused animations should be exactly 1!");
  XCTAssertTrue([pausedAnimationKeys containsObject:@"TestAnim1"],
                @"Animation was not paused!");
  // Drain so that state changes in addAnimation are untracked.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertEqual(state, kGREYIdle, @"State tracker is not idle after pausing animations!");

  // Resume layer.
  view.layer.speed = 1;

  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 0u, @"Animation did not resume!");
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYPendingCAAnimation,
                 @"State tracker not pending after resuming animation!");

  // Resume layer again.
  view.layer.speed = 1;

  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 0u, @"Animation did not resume!");
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYPendingCAAnimation,
                 @"State tracker not pending after resuming animation!");
}

- (void)testPausingAndResumingFromNegativeSpeed {
  UIView *view = [[UIView alloc] init];
  CALayer *sublayer = [[CALayer alloc] init];
  [view.layer addSublayer:sublayer];

  // Set layer to negative speed.
  view.layer.speed = -1;

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation setDuration:10];
  [animation setFromValue:[NSNumber numberWithFloat:0.0f]];
  [animation setToValue:[NSNumber numberWithFloat:6.18f]];

  [sublayer addAnimation:animation forKey:@"TestAnim1"];
  GREYAppState state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertTrue(state & kGREYPendingCAAnimation,
                @"State should change after starting an animation.");

  // Clear the state change that happened after adding animation.
  [[GREYAppStateTracker sharedInstance] grey_clearState];

  // iOS creates immutable animation objects from added animations.
  CAAnimation *morphedFrameworkAnimation = [sublayer animationForKey:@"TestAnim1"];
  // Track the animation as if it was running.
  [morphedFrameworkAnimation grey_trackForDurationOfAnimation];

  NSMutableSet *pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 0u, @"Animation did not resume!");

  // Pause animation.
  view.layer.speed = 0;

  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 1u,
      @"Number of paused animations should be exactly 1!");
  XCTAssertTrue([pausedAnimationKeys containsObject:@"TestAnim1"],
      @"Animation was not paused!");
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYPendingCAAnimation,
                 @"State tracker should not be waiting for any animation!");

  // Resume negative speed.
  view.layer.speed = -1;

  pausedAnimationKeys = [sublayer grey_pausedAnimationKeys];
  XCTAssertEqual(pausedAnimationKeys.count, 0u, @"Animation did not resume!");
  state = [[GREYAppStateTracker sharedInstance] currentState];
  XCTAssertFalse(state & kGREYPendingCAAnimation,
                 @"State tracker not pending after resuming animation!");
}

@end
