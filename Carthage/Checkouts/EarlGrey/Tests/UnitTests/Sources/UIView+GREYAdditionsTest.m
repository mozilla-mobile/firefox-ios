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

#include <objc/runtime.h>

#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/UIView+GREYAdditions.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

// Class that performs swizzled operations in dealloc to ensure they don't track
@interface UIViewDealloc : UIView
@end

@implementation UIViewDealloc

- (void)dealloc {
  [self setNeedsDisplayInRect:CGRectNull];
  [self setNeedsDisplay];
  [self setNeedsLayout];
  [self setNeedsUpdateConstraints];
}

@end

@interface UIView_GREYAdditionsTest : GREYBaseTest
@end

@implementation UIView_GREYAdditionsTest

- (void)setUp {
  [super setUp];

  [UIView setAnimationsEnabled:YES];
}

- (void)testKeepSubviewOnTopWithAddSubview {
  UIView *view = [[UIView alloc] init];
  CGRect topRect = CGRectMake(6, 2, 14, 18);
  CGPoint centerPoint = CGPointMake(CGRectGetMidX(topRect), CGRectGetMidY(topRect));
  UIView *subviewToKeepOnTop = [[UIView alloc] init];
  subviewToKeepOnTop.frame = topRect;

  UIView *nonTopSubview1 = [[UIView alloc] init];
  UIView *nonTopSubview2 = [[UIView alloc] init];

  [view addSubview:subviewToKeepOnTop];
  XCTAssertEqual(subviewToKeepOnTop, [view.subviews lastObject], @"added subview should be on top");
  [view addSubview:nonTopSubview1];
  XCTAssertEqual(nonTopSubview1, [view.subviews lastObject], "added subview should be on top");
  [view grey_keepSubviewOnTopAndFrameFixed:subviewToKeepOnTop];
  XCTAssertEqual(subviewToKeepOnTop,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop should be on top");

  subviewToKeepOnTop.frame = CGRectMake(0, 0, 11, 12);
  XCTAssertTrue(CGRectEqualToRect(topRect, subviewToKeepOnTop.frame),
                @"subviewToKeepOnTop's frame should not change");

  subviewToKeepOnTop.center = CGPointMake(9, 7);
  XCTAssertTrue(CGPointEqualToPoint(centerPoint, subviewToKeepOnTop.center),
                @"subviewToKeepOnTop's center should not change");
  XCTAssertTrue(CGRectEqualToRect(topRect, subviewToKeepOnTop.frame),
                @"subviewToKeepOnTop's frame should not change");

  [view addSubview:nonTopSubview2];
  XCTAssertEqual(subviewToKeepOnTop,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop should be on top");

  [subviewToKeepOnTop removeFromSuperview];
  XCTAssertEqual(nonTopSubview2,
                 [view.subviews lastObject],
                 @"last non-keep-on-top subview should be on top");
}

- (void)testKeepSubviewOnTopWithInsertAbove {
  UIView *view = [[UIView alloc] init];
  UIView *subviewToKeepOnTop = [[UIView alloc] init];
  UIView *nonTopSubview = [[UIView alloc] init];

  [view addSubview:subviewToKeepOnTop];
  XCTAssertEqual(subviewToKeepOnTop, [view.subviews lastObject], @"added subview should be on top");
  [view grey_keepSubviewOnTopAndFrameFixed:subviewToKeepOnTop];

  [view insertSubview:nonTopSubview aboveSubview:subviewToKeepOnTop];
  XCTAssertEqual(subviewToKeepOnTop,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop should be on top");
}

- (void)testKeepSubviewOnTopWithInsertBelow {
  UIView *view = [[UIView alloc] init];
  UIView *subviewToKeepOnTop = [[UIView alloc] init];
  UIView *nonTopSubview = [[UIView alloc] init];

  [view addSubview:subviewToKeepOnTop];
  XCTAssertEqual(subviewToKeepOnTop, [view.subviews lastObject], @"added subview should be on top");
  [view grey_keepSubviewOnTopAndFrameFixed:subviewToKeepOnTop];

  [view insertSubview:nonTopSubview belowSubview:subviewToKeepOnTop];
  XCTAssertEqual(subviewToKeepOnTop,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop should be on top");
}

- (void)testKeepSubviewOnTopWithInsertAtIndex {
  UIView *view = [[UIView alloc] init];
  UIView *subviewToKeepOnTop = [[UIView alloc] init];
  UIView *nonTopSubview = [[UIView alloc] init];

  [view addSubview:subviewToKeepOnTop];
  XCTAssertEqual(subviewToKeepOnTop, [view.subviews lastObject], @"added subview should be on top");
  [view grey_keepSubviewOnTopAndFrameFixed:subviewToKeepOnTop];

  [view insertSubview:nonTopSubview atIndex:1];
  XCTAssertEqual(subviewToKeepOnTop,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop should be on top");

  [view insertSubview:nonTopSubview atIndex:0];
  XCTAssertEqual(subviewToKeepOnTop,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop should be on top");
}

- (void)testKeepSubviewOnTopWithExchangeIndex {
  UIView *view = [[UIView alloc] init];
  UIView *subviewToKeepOnTop = [[UIView alloc] init];
  UIView *nonTopSubview = [[UIView alloc] init];

  [view addSubview:subviewToKeepOnTop];
  XCTAssertEqual(subviewToKeepOnTop, [view.subviews lastObject], @"added subview should be on top");
  [view grey_keepSubviewOnTopAndFrameFixed:subviewToKeepOnTop];

  [view addSubview:nonTopSubview];
  [view exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
  XCTAssertEqual(subviewToKeepOnTop,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop should be on top");
}

- (void)testMultipleKeepSubviewOnTopWithAddSubview {
  UIView *view = [[UIView alloc] init];
  UIView *subviewToKeepOnTop1 = [[UIView alloc] init];
  UIView *subviewToKeepOnTop2 = [[UIView alloc] init];

  [view addSubview:subviewToKeepOnTop1];
  XCTAssertEqual(subviewToKeepOnTop1,
                 [view.subviews lastObject],
                 @"added subview should be on top");
  [view addSubview:subviewToKeepOnTop2];
  XCTAssertEqual(subviewToKeepOnTop2,
                 [view.subviews lastObject],
                 @"added subview should be on top");
  [view grey_keepSubviewOnTopAndFrameFixed:subviewToKeepOnTop1];
  XCTAssertEqual(subviewToKeepOnTop1,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop1 should be on top");
  [view grey_keepSubviewOnTopAndFrameFixed:subviewToKeepOnTop2];
  XCTAssertEqual(subviewToKeepOnTop2,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop2 should be on top");
  [subviewToKeepOnTop2 removeFromSuperview];
  XCTAssertEqual(subviewToKeepOnTop1,
                 [view.subviews lastObject],
                 @"subviewToKeepOnTop1 should be on top");
}

- (void)testDrawRequestChangesPendingUIEventState {
  // NS_VALID_UNTIL_END_OF_SCOPE required so view is valid until end of the current scope.
  NS_VALID_UNTIL_END_OF_SCOPE UIView *view = [[UIView alloc] init];
  [view setNeedsDisplay];
  XCTAssertEqual(kGREYPendingDrawLayoutPass,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");

  [[GREYAppStateTracker sharedInstance] grey_clearState];
  [view setNeedsDisplayInRect:CGRectMake(0, 0, 0, 0)];
  XCTAssertEqual(kGREYPendingDrawLayoutPass,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");

  [[GREYAppStateTracker sharedInstance] grey_clearState];
  [view setNeedsLayout];
  XCTAssertEqual(kGREYPendingDrawLayoutPass,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");

  [[GREYAppStateTracker sharedInstance] grey_clearState];
  [view setNeedsUpdateConstraints];
  XCTAssertEqual(kGREYPendingDrawLayoutPass,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");
}

- (void)testKeyboardChangesPendingUIEventState {
  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillShowNotification
                                                      object:nil];
  XCTAssertTrue(kGREYPendingKeyboardTransition &
                [[GREYAppStateTracker sharedInstance] currentState],
                @"Pending Keyboard appearance should be tracked");

  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidShowNotification
                                                      object:nil];
  XCTAssertFalse(kGREYPendingKeyboardTransition &
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"After keyboard appears its state should be cleared");

  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillHideNotification
                                                      object:nil];
  XCTAssertTrue(kGREYPendingKeyboardTransition &
                [[GREYAppStateTracker sharedInstance] currentState],
                @"Pending Keyboard disappearance should be tracked");

  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidHideNotification
                                                      object:nil];
  XCTAssertFalse(kGREYPendingKeyboardTransition &
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"After keyboard disappears its state should be cleared");
}

- (void)testSubviewsAssignableFromClass {
  UIView *root = [[UIView alloc] init];
  UILabel *child1 = [[UILabel alloc] init];
  UISlider *child2 = [[UISlider alloc] init];
  UILabel *child1A = [[UILabel alloc] init];
  [root addSubview:child1];
  [root addSubview:child2];
  [child1 addSubview:child1A];

  NSArray *subviews = [root grey_childrenAssignableFromClass:[UIView class]];
  NSArray *expected = @[ child1, child1A, child2 ];
  XCTAssertEqualObjects(expected, subviews, @"Should return all subviews");

  subviews = [root grey_childrenAssignableFromClass:[UILabel class]];
  expected = @[ child1, child1A ];
  XCTAssertEqualObjects(expected, subviews, @"Should return all UILabel views");

  subviews = [root grey_childrenAssignableFromClass:[UISlider class]];
  expected = @[ child2 ];
  XCTAssertEqualObjects(expected, subviews, @"Should return just one UISlider view");

  subviews = [root grey_childrenAssignableFromClass:[UIWindow class]];
  XCTAssertEqual(0u, [subviews count], @"Should return no view");
}

- (void)testSuperviewsAssignableFromClass {
  UIView *root = [[UIView alloc] init];
  UILabel *child1 = [[UILabel alloc] init];
  UISlider *child2 = [[UISlider alloc] init];
  UILabel *child1A = [[UILabel alloc] init];
  [root addSubview:child1];
  [root addSubview:child2];
  [child1 addSubview:child1A];

  NSArray *superviews = [root grey_containersAssignableFromClass:[UIView class]];
  NSArray *expected = @[ ];
  XCTAssertEqualObjects(expected, superviews, @"Should return empty");

  superviews = [child1A grey_containersAssignableFromClass:[UIView class]];
  expected = @[ child1, root ];
  XCTAssertEqualObjects(expected, superviews, @"Should return all UIView superviews");

  superviews = [child1A grey_containersAssignableFromClass:[UILabel class]];
  expected = @[ child1 ];
  XCTAssertEqualObjects(expected, superviews, @"Should return just one UILabel view");
}

- (void)testBlockBasedAnimationsWithDuration {
  __block BOOL animationCalled = NO;
  void (^animationBlock)(void) = ^ {
    animationCalled =  YES;
  };

  [UIView animateWithDuration:0.2 animations:animationBlock];

  XCTAssertTrue(animationCalled, @"did we forget to invoke the animation block?");

  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  // This will invoke the completion block that will change the UI state to idle after
  // animation is completed.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testSkipTrackingInteractableAnimations {
  void (^animationBlock)(void) = ^ {};

  UIView *view1 = [[UIView alloc] init];
  UIView *view2 = [[UIView alloc] init];

  // Drain the run loop after initializing the UIViews. Initializing these views kicks off some
  // Earl Grey tracking that we do not want to affect the test.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  [UIView animateKeyframesWithDuration:1.0
                                 delay:0.1
                               options:UIViewKeyframeAnimationOptionAllowUserInteraction
                            animations:animationBlock
                            completion:nil];
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  [UIView animateWithDuration:1.0
                        delay:1.0
                      options:(UIViewAnimationOptionLayoutSubviews |
                               UIViewAnimationOptionAllowUserInteraction)
                   animations:animationBlock
                   completion:nil];
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  [UIView animateWithDuration:1.0
                        delay:1.0
       usingSpringWithDamping:1.0
        initialSpringVelocity:1.0
                      options:(UIViewAnimationOptionLayoutSubviews |
                               UIViewAnimationOptionAllowUserInteraction)
                   animations:animationBlock
                   completion:nil];
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  [UIView transitionFromView:view1
                      toView:view2
                    duration:1
                     options:(UIViewAnimationOptionLayoutSubviews |
                              UIViewAnimationOptionAllowUserInteraction)
                  completion:nil];
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  [UIView transitionWithView:view1
                    duration:1
                     options:(UIViewAnimationOptionLayoutSubviews |
                              UIViewAnimationOptionAllowUserInteraction)
                  animations:animationBlock
                  completion:nil];
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testBlockBasedAnimationsWithDurationAndCompletion {
  __block BOOL animationCalled = NO;
  void (^animationBlock)(void) = ^ {
    animationCalled =  YES;
  };
  __block BOOL completionCalled = NO;
  void (^completionBlock)(BOOL) = ^(BOOL completed) {
    completionCalled =  YES;
    XCTAssertTrue(completed, @"no reason for it not to complete");
  };

  [UIView animateWithDuration:0.1 animations:animationBlock completion:completionBlock];
  XCTAssertTrue(animationCalled, @"did we forget to invoke the animation block?");

  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  // This will invoke the completion block that will change the UI state to idle after
  // animation is completed.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testBlockBasedAnimationsWithDurationAndDelayAndCompletion {
  __block BOOL animationCalled = NO;
  void (^animationBlock)(void) = ^ {
    animationCalled =  YES;
  };
  __block BOOL completionCalled = NO;
  void (^completionBlock)(BOOL) = ^(BOOL completed) {
    completionCalled =  YES;
    XCTAssertTrue(completed, @"no reason for it not to complete");
  };

  [UIView animateWithDuration:1.0
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:animationBlock
                   completion:completionBlock];
  XCTAssertTrue(animationCalled, @"did we forget to invoke the animation block?");
  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  // This will invoke the completion block that will change the UI state to idle after
  // animation is completed.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  XCTAssertTrue(completionCalled, @"did we forget to invoke the real completion block?");
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testBlockBasedAnimationsWithDurationAndDelayAndSpringDampingAndCompletion {
  __block BOOL animationCalled = NO;
  void (^animationBlock)(void) = ^ {
    animationCalled =  YES;
  };
  __block BOOL completionCalled = NO;
  void (^completionBlock)(BOOL) = ^(BOOL completed) {
    completionCalled =  YES;
    XCTAssertTrue(completed, @"no reason for it not to complete");
  };

  [UIView animateWithDuration:1.0
                        delay:0.0
       usingSpringWithDamping:0.0f
        initialSpringVelocity:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:animationBlock
                   completion:completionBlock];
  XCTAssertTrue(animationCalled, @"did we forget to invoke the animation block?");
  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  // This will invoke the completion block that will change the UI state to idle after
  // animation is completed.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  XCTAssertTrue(completionCalled, @"did we forget to invoke the real completion block?");
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testBlockBasedAnimationsWithKeyframesAndCompletion {
  __block BOOL animationCalled = NO;
  void (^animationBlock)(void) = ^ {
    animationCalled =  YES;
  };
  __block BOOL completionCalled = NO;
  void (^completionBlock)(BOOL) = ^(BOOL completed) {
    completionCalled =  YES;
    XCTAssertTrue(completed, @"no reason for it not to complete");
  };

  [UIView animateKeyframesWithDuration:0.0
                                 delay:0.2
                               options:UIViewKeyframeAnimationOptionCalculationModeLinear
                            animations:animationBlock
                            completion:completionBlock];
  XCTAssertTrue(animationCalled, @"did we forget to invoke the animation block?");
  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  // This will invoke the completion block that will change the UI state to idle after
  // animation is completed.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  XCTAssertTrue(completionCalled, @"did we forget to invoke the real completion block?");
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testTransitionWithView {
  __block BOOL animationCalled = NO;
  void (^animationBlock)(void) = ^ {
    animationCalled =  YES;
  };
  __block BOOL completionCalled = NO;
  void (^completionBlock)(BOOL) = ^(BOOL completed) {
    completionCalled =  YES;
    XCTAssertTrue(completed, @"no reason for it not to complete");
  };

  UIView *uiview = [[UIView alloc] init];
  [UIView transitionWithView:uiview
                    duration:0.2
                     options:UIViewAnimationOptionCurveEaseInOut
                  animations:animationBlock
                  completion:completionBlock];
  XCTAssertTrue(animationCalled, @"did we forget to invoke the animation block?");
  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  // This will invoke the completion block that will change the UI state to idle after
  // animation is completed.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  XCTAssertTrue(completionCalled, @"did we forget to invoke the real completion block?");
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testTransitionFromView {
  __block BOOL completionCalled = NO;
  void (^completionBlock)(BOOL) = ^(BOOL completed) {
    completionCalled =  YES;
    XCTAssertTrue(completed, @"no reason for it not to complete");
  };

  UIView *fromUIView = [[UIView alloc] init];
  UIView *toUIView = [[UIView alloc] init];
  [UIView transitionFromView:fromUIView
                      toView:toUIView
                    duration:0.2
                     options:UIViewAnimationOptionCurveEaseInOut
                  completion:completionBlock];
  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  // This will invoke the completion block that will change the UI state to idle after
  // animation is completed.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  XCTAssertTrue(completionCalled, @"did we forget to invoke the real completion block?");
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testPerformSystemAnimation {
  __block BOOL animationCalled = NO;
  void (^animationBlock)(void) = ^ {
    animationCalled =  YES;
  };
  __block BOOL completionCalled = NO;
  void (^completionBlock)(BOOL) = ^(BOOL completed) {
    completionCalled =  YES;
  };

  [UIView performSystemAnimation:UISystemAnimationDelete
                         onViews:@[ [[UIView alloc] init] ]
                         options:UIViewAnimationOptionCurveEaseOut
                      animations:animationBlock
                      completion:completionBlock];
  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);

  // This will invoke the completion block that will change the UI state to idle after
  // animation is completed.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(completionCalled, @"did we forget to invoke the real completion block?");
  XCTAssertTrue([[GREYUIThreadExecutor sharedInstance] grey_areAllResourcesIdle]);
}

- (void)testNotTrackedDuringDealloc {
  {
    NS_VALID_UNTIL_END_OF_SCOPE UIViewDealloc *view = [[UIViewDealloc alloc] init];

    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle,
             @"State must be idle so tracking during dealloc can be detected");
  }

  // Drain to clear out UIKit references to the UIView's CALayer.
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle,
           @"State should be idle after deallocation");
}


- (void)testViewIsValidForScreenshotForNilView {
  UIView *view = nil;
  XCTAssertFalse([view grey_isVisible]);
}

- (void)testViewIsValidForScreenshotForEmptyAXFrame {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testView = [[testWindow subviews] firstObject];
  testView.accessibilityFrame = CGRectZero;
  XCTAssertFalse([testView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfViewHidden {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testView = [[[[testWindow subviews] firstObject] subviews] firstObject];
  testView.hidden = YES;
  XCTAssertFalse([testView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfViewNotHidden {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testView = [[[[testWindow subviews] firstObject] subviews] firstObject];
  testView.hidden = NO;
  XCTAssertTrue([testView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfViewTranslucent {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = [[testWindow subviews] firstObject];
  UIView *leafView = [[testSuperView subviews] firstObject];
  leafView.alpha = 0;
  XCTAssertFalse([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfViewNotTranslucent {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = testWindow.rootViewController.view;
  UIView *leafView = [[testSuperView subviews] firstObject];
  XCTAssertTrue([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfViewAlphaLessThanEqualToOrGreaterThanThreshold {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = testWindow.rootViewController.view;
  UIView *leafView = [[testSuperView subviews] firstObject];
  leafView.alpha = kGREYMinimumVisibleAlpha - 1;
  XCTAssertFalse([leafView grey_isVisible]);
  leafView.alpha = kGREYMinimumVisibleAlpha;
  XCTAssertTrue([leafView grey_isVisible]);
  leafView.alpha = kGREYMinimumVisibleAlpha + 1;
  XCTAssertTrue([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfMainWindowHidden {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  testWindow.hidden = YES;
  UIView *testView = [[[[testWindow subviews] firstObject] subviews] firstObject];
  [testWindow addSubview:testView];
  XCTAssertFalse([testView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfMainWindowNotHidden {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  testWindow.hidden = NO;
  UIView *testView = [[[[testWindow subviews] firstObject] subviews] firstObject];

  XCTAssertTrue([testView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfMainWindowTranslucent {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  testWindow.alpha = 0;
  UIView *testSuperView = [[testWindow subviews] firstObject];
  UIView *leafView = [[testSuperView subviews] firstObject];
  XCTAssertFalse([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfMainWindowNotTranslucent {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = testWindow.rootViewController.view;
  UIView *leafView = [[testSuperView subviews] firstObject];
  XCTAssertTrue([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfMainWindowAlphaLessThanEqualToOrGreaterThanThreshold {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = testWindow.rootViewController.view;
  UIView *leafView = [[testSuperView subviews] firstObject];
  testWindow.alpha = kGREYMinimumVisibleAlpha - 1;
  XCTAssertFalse([leafView grey_isVisible]);
  testWindow.alpha = kGREYMinimumVisibleAlpha;
  XCTAssertTrue([leafView grey_isVisible]);
  testWindow.alpha = kGREYMinimumVisibleAlpha + 1;
  XCTAssertTrue([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfSuperViewHidden {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = [[testWindow subviews] firstObject];
  testSuperView.hidden = YES;
  UIView *leafView = [[testSuperView subviews] firstObject];
  XCTAssertFalse([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfSuperViewNotHidden {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = [[testWindow subviews] firstObject];
  testSuperView.hidden = NO;
  UIView *leafView = [[testSuperView subviews] firstObject];
  XCTAssertTrue([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfSuperViewTranslucent {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = [[testWindow subviews] firstObject];
  testSuperView.alpha = 0;
  UIView *leafView = [[testSuperView subviews] firstObject];
  XCTAssertFalse([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfSuperViewNotTranslucent {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = [[testWindow subviews] firstObject];
  testSuperView.alpha = 1;
  UIView *leafView = [[testSuperView subviews] firstObject];
  XCTAssertTrue([leafView grey_isVisible]);
}

- (void)testViewIsValidForScreenshotIfSuperViewAlphaLessThanEqualToOrGreaterThanThreshold {
  UIWindow *testWindow = [self grey_windowWithSetupTestViewHierarchy];
  UIView *testSuperView = testWindow.rootViewController.view;
  UIView *leafView = [[testSuperView subviews] firstObject];
  testSuperView.alpha = kGREYMinimumVisibleAlpha - 1;
  XCTAssertFalse([leafView grey_isVisible]);
  testSuperView.alpha = kGREYMinimumVisibleAlpha;
  XCTAssertTrue([leafView grey_isVisible]);
  testSuperView.alpha = kGREYMinimumVisibleAlpha + 1;
  XCTAssertTrue([leafView grey_isVisible]);
}

#pragma mark - Private

/**
 * A test window that has one subview that acts as a branch to two leaf views.
 * None of the elements have an empty frame.
 * The window is being set as keyAndVisible since without it, none of the views have their
 * window set to the created window.
 */
- (UIWindow *)grey_windowWithSetupTestViewHierarchy {
  CGRect testRect = CGRectMake(0, 0, 10, 10);
  UIWindow *window = [[UIWindow alloc] initWithFrame:testRect];
  UIView *branchView = [[UIView alloc] initWithFrame:testRect];
  UIView *firstLeafView = [[UIView alloc] initWithFrame:testRect];
  UIViewController *viewController = [[UIViewController alloc] init];
  viewController.view = branchView;
  window.rootViewController = viewController;
  [branchView addSubview:firstLeafView];
  [window makeKeyAndVisible];
  return window;
}

@end
