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
#include <objc/runtime.h>

#import "Additions/UIViewController+GREYAdditions.h"
#import "Common/GREYAppleInternals.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "GREYBaseTest.h"

// A custom view controller that lets you set various hidden properties for testing purposes.
// Use this instead of creating spy objects using ocmock.
@interface GREYUTCustomUIViewController : UIViewController
@property(nonatomic, strong) id<UIViewControllerTransitionCoordinator> transitionCoordinator;
@end

@implementation GREYUTCustomUIViewController
@end

@interface UIViewController_GREYAdditionsTest : GREYBaseTest
@end

@implementation UIViewController_GREYAdditionsTest

- (void)testViewTransitionChangesPendingUIEventState {
  UIViewController *viewController = [[UIViewController alloc] init];
  [viewController viewWillAppear:NO];
  XCTAssertEqual(kGREYPendingViewsToAppear,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");

  [viewController viewDidAppear:NO];
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should idle.");

  [viewController viewWillDisappear:NO];
  XCTAssertEqual(kGREYPendingViewsToDisappear,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");
  [viewController viewDidDisappear:NO];
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should idle.");
}

- (void)testViewWillMoveToWindow {
  UIViewController *viewController = [[UIViewController alloc] init];
  [viewController viewWillMoveToWindow:nil];
  [viewController viewWillDisappear:NO];
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should idle.");

  id window = [OCMockObject niceMockForClass:[UIWindow class]];
  [viewController viewWillMoveToWindow:window];
  [viewController viewDidAppear:NO];
  [viewController viewWillDisappear:NO];
  XCTAssertTrue(kGREYPendingViewsToDisappear & [[GREYAppStateTracker sharedInstance] currentState],
                @"State should include kGREYPendingViewsToDisappear");
}

- (void)testViewDidMoveToWindow {
  UIViewController *viewController = [[UIViewController alloc] init];
  [viewController viewWillDisappear:NO];
  [viewController viewDidMoveToWindow:nil shouldAppearOrDisappear:NO];
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should idle.");

  [viewController viewWillDisappear:NO];
  id window = [OCMockObject niceMockForClass:[UIWindow class]];
  [viewController viewDidMoveToWindow:window shouldAppearOrDisappear:NO];
  XCTAssertTrue(kGREYPendingViewsToDisappear & [[GREYAppStateTracker sharedInstance] currentState],
                @"State should include kGREYPendingViewsToDisappear");
}

- (void)testViewViewWillAppearAndViewDidMoveToNilWindow {
  UIViewController *viewController = [[UIViewController alloc] init];
  [viewController viewWillAppear:YES];
  XCTAssertEqual(kGREYPendingViewsToAppear,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should change state.");

  [viewController viewDidMoveToWindow:nil shouldAppearOrDisappear:YES];
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should idle.");
}

- (void)testRootViewControllerAppearance {
  UIViewController *viewController = [[UIViewController alloc] init];

  UIWindow *window = [[UIWindow alloc] init];
  [window setHidden:NO];

  [window setRootViewController:viewController];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState]
                & kGREYPendingRootViewControllerToAppear,
                @"Should be pending root view appearance");

  [viewController viewWillAppear:YES];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState]
                & kGREYPendingRootViewControllerToAppear,
                @"Should be pending root view appearance");

  [viewController viewDidAppear:YES];
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState]
                 & kGREYPendingRootViewControllerToAppear,
                 @"Should not be pending root view appearance");
}

- (void)testTransitionCoordinatorNotCalledWhenParentIsMovingToNilWindow {
  UIViewController *viewController = [[UIViewController alloc] init];
  UIViewController *childViewController = [[UIViewController alloc] init];
  [viewController addChildViewController:childViewController];

  [viewController viewWillMoveToWindow:nil];
  [childViewController viewWillDisappear:NO];

  XCTAssertFalse(kGREYPendingViewsToDisappear & [[GREYAppStateTracker sharedInstance] currentState],
                 @"viewWillDisappear should not change state because childViewController's parent "
                 "is moving to nil window");
}

- (void)testTransitionCoordinatorNotCalledWhenChildIsMovingToNilWindow {
  UIViewController *viewController = [[UIViewController alloc] init];
  UIViewController *childViewController = [[UIViewController alloc] init];
  [viewController addChildViewController:childViewController];

  [childViewController viewWillMoveToWindow:nil];
  [childViewController viewWillDisappear:NO];

  XCTAssertFalse(kGREYPendingViewsToDisappear & [[GREYAppStateTracker sharedInstance] currentState],
                 @"viewWillDisappear should not change state because childViewController's parent "
                 "is moving to nil window");
}

- (void)testViewWillAppearInteractiveTransitionCancelled {
  GREYUTCustomUIViewController *viewController = [[GREYUTCustomUIViewController alloc] init];
  id transitionCoordinator = [OCMockObject
                                 mockForProtocol:@protocol(UIViewControllerTransitionCoordinator)];

  [viewController setTransitionCoordinator:transitionCoordinator];
  __block void (^captureBlock)(id<UIViewControllerTransitionCoordinatorContext> context);
  [[transitionCoordinator expect]
      notifyWhenInteractionEndsUsingBlock:[OCMArg checkWithBlock:^(id value) {
        captureBlock = value;
        return YES;
  }]];

  [[[transitionCoordinator expect] andReturnValue:@YES] initiallyInteractive];

  [viewController viewWillAppear:NO];

  [transitionCoordinator verify];
  XCTAssertEqual(kGREYPendingViewsToAppear,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should be waiting for view to appear");
  id context = [OCMockObject
                   mockForProtocol:@protocol(UIViewControllerTransitionCoordinatorContext)];
  [[[context expect] andReturnValue:@YES] isCancelled];
  // Cancel the interaction.
  captureBlock(context);
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Interaction is cancelled and viewDidAppear won't be called.");
}

- (void)testViewWillDisappearInteractiveTransitionCancelled {
  GREYUTCustomUIViewController *viewController = [[GREYUTCustomUIViewController alloc] init];
  id transitionCoordinator = [OCMockObject
                                 mockForProtocol:@protocol(UIViewControllerTransitionCoordinator)];

  [viewController setTransitionCoordinator:transitionCoordinator];
  __block void (^captureBlock)(id<UIViewControllerTransitionCoordinatorContext> context);
  [[transitionCoordinator expect]
      notifyWhenInteractionEndsUsingBlock:[OCMArg checkWithBlock:^(id value) {
        captureBlock = value;
        return YES;
  }]];

  [[[transitionCoordinator expect] andReturnValue:@YES] initiallyInteractive];

  [viewController viewWillDisappear:NO];

  [transitionCoordinator verify];
  XCTAssertEqual(kGREYPendingViewsToDisappear,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Should be waiting for view to appear");
  id context = [OCMockObject
                   mockForProtocol:@protocol(UIViewControllerTransitionCoordinatorContext)];
  [[[context expect] andReturnValue:@YES] isCancelled];
  // Cancel the interaction.
  captureBlock(context);
  XCTAssertEqual(kGREYIdle,
                 [[GREYAppStateTracker sharedInstance] currentState],
                 @"Interaction is cancelled and viewDidAppear won't be called.");
}

@end
