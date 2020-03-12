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

#import "Common/GREYAppleInternals.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "GREYBaseTest.h"


@interface GREYUIScrollViewTest : GREYBaseTest
@end

@implementation GREYUIScrollViewTest

- (void)testScrollViewTrackingWithoutDeceleration {
  UIScrollView *scrollView = [[UIScrollView alloc] init];
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssert([[GREYAppStateTracker sharedInstance] currentState] == kGREYIdle, @"should be idle");

  [scrollView _scrollViewWillBeginDragging];
  XCTAssert([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingUIScrollViewScrolling,
            @"Calling _scrollViewWillBeginDragging should change state");

  [scrollView _scrollViewDidEndDraggingWithDeceleration:NO];
  XCTAssert([[GREYAppStateTracker sharedInstance] currentState] == kGREYIdle,
            @"should now be idle");
}

- (void)testScrollViewTrackingWithDeceleration {
  UIScrollView *scrollView = [[UIScrollView alloc] init];
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssert([[GREYAppStateTracker sharedInstance] currentState] == kGREYIdle, @"should be idle");

  [scrollView _scrollViewWillBeginDragging];
  XCTAssert([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingUIScrollViewScrolling,
            @"Calling _scrollViewWillBeginDragging should change state");

  [scrollView _scrollViewDidEndDraggingWithDeceleration:YES];
  XCTAssert([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingUIScrollViewScrolling,
            @"Should still be tracking state");

  [scrollView _stopScrollDecelerationNotify:NO];
  XCTAssert([[GREYAppStateTracker sharedInstance] currentState] == kGREYIdle,
            @"should now be idle");
}

@end
