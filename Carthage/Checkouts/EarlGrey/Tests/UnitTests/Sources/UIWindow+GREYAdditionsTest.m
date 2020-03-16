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

#import "Additions/UIViewController+GREYAdditions.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "GREYBaseTest.h"

@interface GREYUIWindow_AdditionsTest : GREYBaseTest

@end

@implementation GREYUIWindow_AdditionsTest

- (void)testSetNilRootViewController {
  UIWindow *window = [[UIWindow alloc] init];
  [window setHidden:NO];

  [window setRootViewController:nil];
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] &
                 kGREYPendingRootViewControllerToAppear,
                 @"Setting nil shouldn't cause kGREYPendingRootViewControllerToAppear");
}

- (void)testSetRootViewController {
  UIViewController *viewController = [[UIViewController alloc] init];

  UIWindow *window = [[UIWindow alloc] init];
  [window setHidden:NO];
  [window setRootViewController:viewController];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] &
                kGREYPendingRootViewControllerToAppear,
                @"Setting root view controller should change state");
}

- (void)testSetRootViewControllerOnHiddenWindow {
  UIViewController *viewController = [[UIViewController alloc] init];

  UIWindow *window = [[UIWindow alloc] init];
  [window setHidden:YES];

  [window setRootViewController:viewController];
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] &
                 kGREYPendingRootViewControllerToAppear,
                 @"Setting root view controller on hidden window should not change state");


  [window setHidden:NO];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] &
                kGREYPendingRootViewControllerToAppear,
                @"Setting window to visible should track root view controller");

  [window setHidden:YES];
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] &
                 kGREYPendingRootViewControllerToAppear,
                 @"Setting window to hidden should untrack root view controller");
}

- (void)testSetSameRootViewControllerMoreThanOnce {
  UIViewController *viewController = [[UIViewController alloc] init];
  UIWindow *window = [[UIWindow alloc] init];
  [window setHidden:NO];

  [window setRootViewController:viewController];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] &
                 kGREYPendingRootViewControllerToAppear,
                @"Setting root view controller should change state");

  [viewController viewDidAppear:YES];
  // Set same view controller again.
  [window setRootViewController:viewController];
  // State should be unchanged.
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] &
                 kGREYPendingRootViewControllerToAppear,
                 @"Setting root view controller should change state");
}

- (void)testSetDifferentRootViewControllerMoreThanOnce {
  UIWindow *window = [[UIWindow alloc] init];
  UIViewController *viewController1 = [[UIViewController alloc] init];
  UIViewController *viewController2 = [[UIViewController alloc] init];

  [window setHidden:NO];

  [window setRootViewController:viewController1];
  [window setRootViewController:nil];
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] &
                 kGREYPendingRootViewControllerToAppear,
                 @"Setting nil shouldn't cause kGREYPendingRootViewControllerToAppear");

  [window setRootViewController:viewController2];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] &
                kGREYPendingRootViewControllerToAppear,
                @"Setting viewController2 should cause kGREYPendingRootViewControllerToAppear");

  [window setRootViewController:viewController1];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] &
                kGREYPendingRootViewControllerToAppear,
                @"Setting viewController1 should cause kGREYPendingRootViewControllerToAppear");
}

- (void)testHideAndUnhideRepeatedlyWithRootViewControllerSet {
  UIViewController *viewController = [[UIViewController alloc] init];

  UIWindow *window = [[UIWindow alloc] init];
  [window setRootViewController:viewController];

  [window setHidden:NO];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] &
                kGREYPendingRootViewControllerToAppear,
                @"Setting viewcontroller that hasn't appeared yet should change state to pending");

  [window setHidden:YES];
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] &
                 kGREYPendingRootViewControllerToAppear,
                 @"Hiding window of root view controller should clear any appearance states");

  [window setHidden:NO];
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] &
                kGREYPendingRootViewControllerToAppear,
                @"Setting viewcontroller that hasn't appeared yet should change state to pending");
}

@end
