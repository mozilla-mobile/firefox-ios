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

#import "Additions/CAAnimation+GREYAdditions.h"
#import "Common/GREYSwizzler.h"
#import "Delegate/GREYCAAnimationDelegate.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "GREYBaseTest.h"

static id gDelegate;

@implementation CAAnimation (Test)

#pragma mark - Swizzled Implementation

- (void)greyswizzled_test_setDelegate:(id)del {
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_test_setDelegate:), del);
  gDelegate = del;
}

@end

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@interface CAAnimation_GREYAdditionsTest : GREYBaseTest<CAAnimationDelegate>
#else
@interface CAAnimation_GREYAdditionsTest : GREYBaseTest
#endif
@end


/**
 *  CAAnimationDelegate that doesn't have the animation delegate methods implemented.
 */
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@interface CAAnimationDelegateWithoutMethodsImplemented : NSObject<CAAnimationDelegate>
#else
@interface CAAnimationDelegateWithoutMethodsImplemented : NSObject
#endif
@end

@implementation CAAnimationDelegateWithoutMethodsImplemented
@end

@implementation CAAnimation_GREYAdditionsTest {
  BOOL _animationDidStartCalled;
  BOOL _animationDidStopCalled;
  GREYSwizzler *_swizzler;
}

- (void)setUp {
  [super setUp];
  gDelegate = nil;
  _swizzler = [[GREYSwizzler alloc] init];

  // Swizzle setDelegate so we can tell if animation tracking logic was injected in init method.
  SEL swizzledSEL = @selector(greyswizzled_test_setDelegate:);
  GREY_UNUSED_VARIABLE BOOL swizzled = [_swizzler swizzleClass:[CAAnimation class]
                                         replaceInstanceMethod:@selector(setDelegate:)
                                                    withMethod:swizzledSEL];
  NSAssert(swizzled, @"Could not swizzle CAAnimation setDelegate");
}

- (void)tearDown {
  // Undo swizzling done in setup.
  NSAssert([_swizzler resetInstanceMethod:@selector(setDelegate:) class:[CAAnimation class]],
           @"Failed to reset");
  NSAssert([_swizzler resetInstanceMethod:@selector(greyswizzled_test_setDelegate:)
                                    class:[CAAnimation class]],
           @"Failed to reset");
  [super tearDown];
}

- (void)animationDidStart:(CAAnimation *)anim {
  _animationDidStartCalled = YES;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  _animationDidStopCalled = YES;
}

- (void)testSimpleAnimation {
  CAAnimation *animation = [CAAnimation animation];
  [[animation delegate] animationDidStart:animation];
  XCTAssertTrue(kGREYPendingCAAnimation & [[GREYAppStateTracker sharedInstance] currentState],
                @"Should track animation start.");
  [[animation delegate] animationDidStop:animation finished:YES];
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should be in idle state after stopping");
}

- (void)testAnimationWithDelegate {
  _animationDidStartCalled = NO;
  _animationDidStopCalled = NO;

  CAAnimation *animation = [CAAnimation animation];
  [animation setDelegate:self];
  [[animation delegate] animationDidStart:animation];
  XCTAssertTrue(_animationDidStartCalled,
                @"Original delegate not called.");
  [[animation delegate] animationDidStop:animation finished:YES];
  XCTAssertTrue(_animationDidStopCalled,
                @"Original delegate not called.");
}

- (void)testDelegateSetsStateToStarted {
  CAAnimation *animation = [[CAAnimation alloc] init];
  [animation.delegate animationDidStart:animation];

  XCTAssertTrue(kGREYPendingCAAnimation & [[GREYAppStateTracker sharedInstance] currentState],
                @"Should be in pending ca animation state");
}

- (void)testDelegateSetsStateToStopped {
  CAAnimation *animation = [[CAAnimation alloc] init];
  [animation.delegate animationDidStart:animation];
  [animation.delegate animationDidStop:animation finished:NO];

  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should be in idle state");
}

- (void)testAnimationPendingStart {
  CAAnimation *animation = [[CAAnimation alloc] init];
  [animation grey_setAnimationState:kGREYAnimationStarted];
  [animation grey_setAnimationState:kGREYAnimationPendingStart];
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should be in idle state");
}

- (void)testAnimationStarted {
  CAAnimation *animation = [[CAAnimation alloc] init];
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should be in idle state");
  [animation grey_setAnimationState:kGREYAnimationStarted];

  XCTAssertTrue(kGREYPendingCAAnimation & [[GREYAppStateTracker sharedInstance] currentState],
                @"Should be in pending ca animation state");
}

- (void)testAnimationCompleted {
  CAAnimation *animation = [[CAAnimation alloc] init];
  [animation grey_setAnimationState:kGREYAnimationStarted];
  [animation grey_setAnimationState:kGREYAnimationStopped];
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingCAAnimation,
                 @"State shouldn't contain pending animation after animation is stopped.");
}

- (void)testAnimationStartedWithDurationWithoutStopCalled {
  CFTimeInterval duration = 0.2;
  CAAnimation *animation = [[CAAnimation alloc] init];
  animation.duration = duration;

  [animation grey_setAnimationState:kGREYAnimationStarted];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingCAAnimation,
                @"Should be in pending ca animation state");

  // Drain for 1.0 second because a tiny buffer time is added to the actual duration to make sure
  // animation really completes before we decide to forcefully untrack it.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle, @"Should be idle");
}

- (void)testAnimationWithRepetitionWithoutStopCalled {
  CFTimeInterval duration = 0.2;
  float repeatCount = 0.2f;

  CAAnimation *animation = [[CAAnimation alloc] init];
  animation.repeatCount = repeatCount;
  animation.duration = duration;

  [animation grey_setAnimationState:kGREYAnimationStarted];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingCAAnimation,
                @"Should be in pending ca animation state");

  // Drain for 1.0 second because a tiny buffer time is added to the actual duration to make sure
  // animation really completes before we decide to forcefully untrack it.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState],
                 kGREYIdle,
                 @"Should be idle");
}

- (void)testAnimationWithRepeatDurationWithoutStopCalled {
  CFTimeInterval duration = 0.2;
  CFTimeInterval repeatDuration = 0.2;

  CAAnimation *animation = [[CAAnimation alloc] init];
  animation.repeatDuration = repeatDuration;
  animation.duration = duration;

  [animation grey_setAnimationState:kGREYAnimationStarted];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingCAAnimation,
                @"Should be in pending ca animation state");

  // Drain for 1.0 second because a tiny buffer time is added to the actual duration to make sure
  // animation really completes before we decide to forcefully untrack it.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState],
                 kGREYIdle,
                 @"Should be idle");
}


/**
 *  Test for checking if re-setting the delegate of a CAAnimation with the same delegate does not
 *  re-swizzle the delegate methods. This is checked by comparing the implementations of the
 *  swizzled methods before / after re-setting the delegate.
 */
- (void)testAnimationImplementationsWithDelegate {
  CAAnimation *animation = [CAAnimation animation];
  [animation setDelegate:self];
  IMP didStartMethod = [self methodForSelector:@selector(animationDidStart:)];
  IMP didStopMethod = [self methodForSelector:@selector(animationDidStop:finished:)];
  [animation setDelegate:self];
  XCTAssertEqual([self methodForSelector:@selector(animationDidStart:)], didStartMethod);
  XCTAssertEqual([self methodForSelector:@selector(animationDidStop:finished:)], didStopMethod);
}

/**
 *  Test for checking that setting the delegate on a CAAnimation with a delegate that does not
 *  implement the CAAnimationDelegate methods has them added to itself by EarlGrey's
 *  GREYCAAnimationDelegate. Also checks that re-setting the delegate on the animation with the
 *  same delegate does not cause re-swizzle the methods.
 */
- (void)testAnimationImplementationWithDelegateWithoutMethodsImplemented {
  // Ensure the animation delegate methods are not implemented.
  CAAnimationDelegateWithoutMethodsImplemented *delegate =
      [[CAAnimationDelegateWithoutMethodsImplemented alloc] init];
  XCTAssertFalse([delegate respondsToSelector:@selector(animationDidStart:)]);
  XCTAssertFalse([delegate respondsToSelector:@selector(animationDidStop:finished:)]);
  CAAnimation *animation = [CAAnimation animation];
  // Add the animation methods to the delegate.
  [animation setDelegate:delegate];
  IMP didStartMethod = [delegate methodForSelector:@selector(animationDidStart:)];
  IMP didStopMethod = [delegate methodForSelector:@selector(animationDidStop:finished:)];
  XCTAssertTrue([delegate respondsToSelector:@selector(animationDidStart:)]);
  XCTAssertTrue([delegate respondsToSelector:@selector(animationDidStop:finished:)]);
  // Reset the delegate and make sure the method implementations do not change.
  [animation setDelegate:delegate];
  XCTAssertEqual([delegate methodForSelector:@selector(animationDidStart:)], didStartMethod);
  XCTAssertEqual([delegate methodForSelector:@selector(animationDidStop:finished:)],
                 didStopMethod);
}

@end
