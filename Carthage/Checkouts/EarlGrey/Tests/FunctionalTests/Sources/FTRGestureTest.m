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

#import "FTRBaseIntegrationTest.h"

#import <EarlGrey/EarlGrey.h>

@interface FTRGestureTest : FTRBaseIntegrationTest
@end

@implementation FTRGestureTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Gesture Tests"];
}

- (void)testSingleTap {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"single tap")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSingleTapAtPoint {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_tapAtPoint(CGPointMake(12.0, 50.0))];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"single tap")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"x:12.0 - y:50.0")]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_tapAtPoint(CGPointZero)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"single tap")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"x:0.0 - y:0.0")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testDoubleTap {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_doubleTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"double tap")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testDoubleTapAtPoint {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_doubleTapAtPoint(CGPointMake(50, 50))];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"double tap")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"x:50.0 - y:50.0")]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_doubleTapAtPoint(CGPointMake(125, 10))];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"double tap")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"x:125.0 - y:10.0")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testLongPress {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_longPress()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"single long press")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testLongPressWithDuration {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_longPressWithDuration(1.0)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"single long press")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testLongPressWithDurationAtPoint {
  // Find the bounds of the element.
  __block CGRect targetBounds;
  GREYActionBlock *boundsFinder =
      [[GREYActionBlock alloc] initWithName:@"Frame finder"
                                constraints:nil
                               performBlock:^BOOL(UIView *view, NSError *__strong *error) {
    targetBounds = view.bounds;
    return YES;
  }];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:boundsFinder];

  // Verify tapping outside the bounds does not cause long press.
  CGFloat midX = CGRectGetMidX(targetBounds);
  CGFloat midY = CGRectGetMidY(targetBounds);
  CGPoint outsidePoints[4] = {
    CGPointMake(CGRectGetMinX(targetBounds) - 1, midY),
    CGPointMake(CGRectGetMaxX(targetBounds) + 1, midY),
    CGPointMake(midX, CGRectGetMinY(targetBounds) - 1),
    CGPointMake(midX, CGRectGetMaxY(targetBounds) + 1)
  };
  for (NSInteger i = 0; i < 4; i++) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
        performAction:grey_longPressAtPointWithDuration(outsidePoints[i], 1.0)];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"single long press")]
        assertWithMatcher:grey_nil()];
  }

  // Verify that tapping inside the bounds causes the long press.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_longPressAtPointWithDuration(CGPointMake(midX, midX), 1.0)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"single long press")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSwipeWorksInAllDirectionsInPortraitMode {
  [self ftr_assertSwipeWorksInAllDirections];
}

- (void)testSwipeWorksInAllDirectionsInUpsideDownMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown errorOrNil:nil];
  [self ftr_assertSwipeWorksInAllDirections];
}

- (void)testSwipeWorksInAllDirectionsInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
  [self ftr_assertSwipeWorksInAllDirections];
}

- (void)testSwipeWorksInAllDirectionsInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];
  [self ftr_assertSwipeWorksInAllDirections];
}

- (void)testSwipeOnWindow {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Window swipes start here")]
      performAction:grey_swipeFastInDirection(kGREYDirectionUp)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"swipe up on window")]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Window swipes start here")]
      performAction:grey_swipeFastInDirection(kGREYDirectionDown)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"swipe down on window")]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Window swipes start here")]
      performAction:grey_swipeFastInDirection(kGREYDirectionLeft)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"swipe left on window")]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Window swipes start here")]
      performAction:grey_swipeFastInDirection(kGREYDirectionRight)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"swipe right on window")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSwipeWithLocationForAllDirections {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_swipeFastInDirectionWithStartPoint(kGREYDirectionUp, 0.25, 0.25)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"swipe up")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"x:54.0 - y:49.0")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_swipeFastInDirectionWithStartPoint(kGREYDirectionDown, 0.75, 0.75)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"swipe down")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"x:162.0 - y:147.0")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_swipeFastInDirectionWithStartPoint(kGREYDirectionLeft, 0.875, 0.5)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"swipe left")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"x:189.0 - y:98.0")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_swipeFastInDirectionWithStartPoint(kGREYDirectionRight, 0.125, 0.75)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"swipe right")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"x:27.0 - y:147.0")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testPinchWorksInAllDirectionsInPortraitMode {
  [self ftr_assertPinchWorksInAllDirections];
}

- (void)testPinchWorksInAllDirectionsInUpsideDownMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown errorOrNil:nil];
  [self ftr_assertPinchWorksInAllDirections];
}

- (void)testPinchWorksInAllDirectionsInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
  [self ftr_assertPinchWorksInAllDirections];
}

- (void)testPinchWorksInAllDirectionsInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];
  [self ftr_assertPinchWorksInAllDirections];
}

#pragma mark - Private

// Asserts that swipe works in all directions by verifying if the swipe gestures are correctly
// recognized.
- (void)ftr_assertSwipeWorksInAllDirections {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_swipeFastInDirection(kGREYDirectionUp)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:grey_text(@"swipe up")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_swipeSlowInDirection(kGREYDirectionDown)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:grey_text(@"swipe down")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_swipeFastInDirection(kGREYDirectionLeft)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:grey_text(@"swipe left")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_swipeSlowInDirection(kGREYDirectionRight)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:grey_text(@"swipe right")];
}

// Asserts that Pinch works in all directions by verifying if the pinch gestures are correctly
// recognized.
- (void)ftr_assertPinchWorksInAllDirections {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_pinchFastInDirectionAndAngle(kGREYPinchDirectionOutward,
                                                      kGREYPinchAngleDefault)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:grey_text(@"pinch out")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
      performAction:grey_pinchSlowInDirectionAndAngle(kGREYPinchDirectionInward,
                                                      kGREYPinchAngleDefault)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:grey_text(@"pinch in")];
}

@end
