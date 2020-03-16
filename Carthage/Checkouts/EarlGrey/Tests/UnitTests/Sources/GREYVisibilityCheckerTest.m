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

#import "Additions/CGGeometry+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Common/GREYVisibilityChecker.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

extern const NSUInteger kMinimumPointsVisibleForInteraction;

@interface GREYVisibilityCheckerTest : GREYBaseTest

@end

@implementation GREYVisibilityCheckerTest {
  CGFloat _screenWidth;
  CGFloat _screenHeight;
}

- (void)setUp {
  [super setUp];
  _screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
  _screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
}

- (void)testPercentVisibleAreaOfElementReturnsZeroForNilElements {
  XCTAssertEqual([GREYVisibilityChecker percentVisibleAreaOfElement:nil], 0,
                 @"Nil elements shouldn't be visible");
}

- (void)testPercentElementVisibleOnScreenReturnsZeroForNilElements {
  double percentVisible = [GREYVisibilityChecker percentVisibleAreaOfElement:nil];
  XCTAssertEqual(percentVisible, 0, @"Percent visible of nil elements should be 0");
}

- (void)testIsNotVisibleReturnsYesForNilElements {
  XCTAssertTrue([GREYVisibilityChecker isNotVisible:nil],
                @"Nil elements should not be visible");
}

- (void)testIsNotVisibleReturnsYesForElementWithZeroSize {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 0, 1)];
  XCTAssertTrue([GREYVisibilityChecker isNotVisible:view]);
  XCTAssertEqual([GREYVisibilityChecker percentVisibleAreaOfElement:view], 0);

  view.frame = CGRectMake(10, 10, 0, 1);
  XCTAssertTrue([GREYVisibilityChecker isNotVisible:view]);
  XCTAssertEqual([GREYVisibilityChecker percentVisibleAreaOfElement:view], 0);

  view.frame = CGRectMake(10, 10, 0, 0);
  XCTAssertTrue([GREYVisibilityChecker isNotVisible:view]);
  XCTAssertEqual([GREYVisibilityChecker percentVisibleAreaOfElement:view], 0);
}

- (void)testAccessibilityElementWithNoContainerViewIsNotVisible {
  id mockElementA = [OCMockObject mockForClass:[UIAccessibilityElement class]];
  [[[mockElementA stub] andReturn:nil] grey_viewContainingSelf];
  CGRect frame = CGRectMake(0, 0, 100, 100);
  [[[mockElementA stub] andReturnValue:OCMOCK_STRUCT(CGRect, frame)] accessibilityFrame];
  [[[mockElementA stub] andReturnValue:@NO] grey_isWebAccessibilityElement];
  XCTAssertTrue([GREYVisibilityChecker isNotVisible:mockElementA],
                @"Accessibility element with no container view should not be visible");

  double percentVisible = [GREYVisibilityChecker percentVisibleAreaOfElement:mockElementA];
  XCTAssertEqual(percentVisible,
                 0,
                 @"Percent visible of accessibility element with no container view should be 0");
}

- (void)testVisibilityOfViewWithBeforeAndShiftedAfterImage {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  CGSize size = CGSizeMake(10, 10);

  // Before Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor whiteColor]]];
  // After Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.hidden = NO;

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
  view.alpha = 1;
  view.hidden = NO;

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);

  XCTAssertEqual([GREYVisibilityChecker percentVisibleAreaOfElement:view], 1.0f,
                 @"Should be 1.0 because before and after image colors are shifted exactly by 128");
}

- (void)testVisibilityOfViewWithAlphaAndBeforeAndShiftedAfterImage {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  CGSize size = CGSizeMake(10, 10);
  // Before Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];
  // After Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor blackColor]]];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.hidden = NO;
  window.alpha = 0.7f;

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
  view.alpha = 0.6f;
  view.hidden = NO;

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);

  XCTAssertEqual([GREYVisibilityChecker percentVisibleAreaOfElement:view], 1.0f,
                 @"percent must be 1.0 because before and after image colors are shifted exactly"
                 @" by 128");
  XCTAssertEqual(0.6f,
                 (float)view.alpha,
                 @"Visibility checker must not change alpha values");
  XCTAssertEqual(0.7f,
                 (float)window.alpha,
                 @"Visibility checker must not change alpha values");
}

- (void)testVisibilityOfViewWithSameImageReturnedForBeforeAndAfter {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  UIImage *image = [self grey_imageOfSize:CGSizeMake(10, 10)   withColor:[UIColor whiteColor]];

  // For each invocation of isVisible, 2 screenshots are taken, one before and one after.
  // Since we have 3 invocations, we add 6 screenshots to return by GREYScreenshotUtil.
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = NO;

  [window addSubview:view];

  XCTAssertEqual([GREYVisibilityChecker percentVisibleAreaOfElement:view], 0,
                 @"Should be 0 because no pixels changed between screenshots");
  XCTAssertTrue([GREYVisibilityChecker isNotVisible:view],
                @"Should be YES because no pixels changed between screenshots");
}

- (void)testVisibilityOfElementWithSameImageReturnedForContainerViewBeforeAndAfter {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  UIImage *image = [self grey_imageOfSize:CGSizeMake(10, 10)   withColor:[UIColor whiteColor]];

  // For each invocation of isVisible, 2 screenshots are taken, one before and one after.
  // Since we have 3 invocations, we add 6 screenshots to return by GREYScreenshotUtil.
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = NO;

  [window addSubview:view];

  id mockElementA = [OCMockObject mockForClass:[UIAccessibilityElement class]];
  [[[mockElementA stub] andReturn:view] accessibilityContainer];
  [[[mockElementA stub] andReturn:view] grey_viewContainingSelf];
  [[[mockElementA stub] andReturnValue:@NO] grey_isWebAccessibilityElement];

  CGRect accessibilityFrame = CGRectMake(0, 0, 10, 10);
  [[[mockElementA stub] andReturnValue:OCMOCK_STRUCT(CGRect, accessibilityFrame)]
      accessibilityFrame];

  double percentVisible = [GREYVisibilityChecker percentVisibleAreaOfElement:mockElementA];

  XCTAssertEqual(percentVisible, 0, @"Should be 0 because no pixels changed between screenshots");
  XCTAssertTrue([GREYVisibilityChecker isNotVisible:view],
                @"Should be YES because no pixels changed between screenshots");
  XCTAssertFalse([grey_sufficientlyVisible() matches:view],
                 @"Should be NO because no pixels changed between screenshots");
}

- (void)testIsSufficientlyVisibleForInteractionReturnsNoForNilElements {
  XCTAssertFalse([GREYVisibilityChecker isVisibleForInteraction:nil],
                 @"Nil elements shouldn't be visible");
}

- (void)testVisibileForInteractionIsYesForOutOfBoundsActivationPointButVisiblePortion {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  // Image has to be bigger because of the minimum visible area constraints.
  CGSize size = CGSizeMake(100, 100);

  // Before and after images for first visibility check.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor whiteColor]]];
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];
  // Before and after images for interaction point query.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor whiteColor]]];
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  window.hidden = NO;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGPointMake(CGRectGetMaxX(view.accessibilityFrame) + 1,
                                                  CGRectGetMaxY(view.accessibilityFrame) + 1);

  XCTAssertTrue([GREYVisibilityChecker isVisibleForInteraction:view],
                 @"Should succeed because part of the view is inside the screen.");
  XCTAssertFalse(CGPointEqualToPoint([view accessibilityActivationPoint],
      [GREYVisibilityChecker visibleInteractionPointForElement:view]),
                 @"Interaction point should be different than activation point.");
}

- (void)testVisibileForInteractionIsYesForOutOfScreenBoundsActivationPoint {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  CGSize size = CGSizeMake(50, 50);

  // Before and after images for first visibility check.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor whiteColor]]];
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];

  // Before and after images for interaction point query.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor whiteColor]]];
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];

  UIWindow *window =
      [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 2 * size.width, 2 * size.height)];
  window.hidden = NO;
  // Make a frame rect whose mid point lies outside the screen bounds.
  CGRect frameRect = CGRectMake(-size.width / 2 - 1,
                                -size.height / 2 - 1,
                                size.width,
                                size.height);
  UIView *view = [[UIView alloc] initWithFrame:frameRect];
  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(frameRect);

  XCTAssertTrue([GREYVisibilityChecker isVisibleForInteraction:view],
                @"Should succeed because part of the view is inside the screen.");
  XCTAssertFalse(CGPointEqualToPoint([view accessibilityActivationPoint],
      [GREYVisibilityChecker visibleInteractionPointForElement:view]),
                 @"Interaction point should be different than activation point.");
}

- (void)testAccessibilityElementWithNoContainerViewIsNotVisibleForInteraction {
  id mockElementA = [OCMockObject mockForClass:[UIAccessibilityElement class]];
  [[[mockElementA stub] andReturn:nil] grey_viewContainingSelf];
  CGRect frame = CGRectMake(0, 0, 100, 100);
  CGPoint point = CGRectCenter(frame);
  [[[mockElementA stub] andReturnValue:OCMOCK_STRUCT(CGRect, frame)] accessibilityFrame];
  [[[mockElementA stub] andReturnValue:OCMOCK_STRUCT(CGPoint, point)] accessibilityActivationPoint];
  [[[mockElementA stub] andReturnValue:@NO] grey_isWebAccessibilityElement];
  XCTAssertFalse([GREYVisibilityChecker isVisibleForInteraction:mockElementA],
                 @"Accessibility element with no container view should not be visible");
}

- (void)testVisibleForInteractionWithBeforeAndChangedAfterImage {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  CGSize size = CGSizeMake(10, 10);
  // Before Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor whiteColor]]];
  // After Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.hidden = NO;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  XCTAssertTrue([GREYVisibilityChecker isVisibleForInteraction:view],
                @"Should pass because before and after image colors are different.");
}

- (void)testVisibleForInteractionForTinyElements {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  CGSize size = CGSizeMake(10, 10);
  // Before Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor whiteColor]]];
  // After Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  const NSUInteger minimumPixelsVisibleForInteraction =
      (NSUInteger)(kMinimumPointsVisibleForInteraction * [[UIScreen mainScreen] scale]);
  // Create a view that has fewer points than minimumPixelsVisibleForInteraction.
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  [window addSubview:view];

  // Verify that the view has fewer points than kMinimumPointsVisibleForInteraction.
  NSUInteger pixelCount = (NSUInteger)(view.bounds.size.width * [[UIScreen mainScreen] scale] *
      view.bounds.size.width * [[UIScreen mainScreen] scale]);
  XCTAssertTrue(pixelCount < minimumPixelsVisibleForInteraction,
                @"This test requires a view with pixels less than"
                " minimumPixelsVisibleForInteraction");

  // Verify that the view is not visible for interaction.
  XCTAssertFalse([GREYVisibilityChecker isVisibleForInteraction:view],
                 @"Should pass because all of the pixels in the view are visible.");
}

- (void)testVisibleForInteractionOfViewWithAlphaAndBeforeAndShiftedAfterImage {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  CGSize size = CGSizeMake(10, 10);
  // Before Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor grayColor]]];
  // After Image.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:size
                                                                 withColor:[UIColor blackColor]]];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.alpha = 0.7f;
  window.hidden = NO;

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
  view.alpha = 0.6f;
  view.hidden = NO;

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  XCTAssertTrue([GREYVisibilityChecker isVisibleForInteraction:view],
                @"Should pass because before and after image colors have changed.");
  XCTAssertEqual(0.6f,
                 (float)view.alpha,
                 @"Visibility checker must not change alpha values");
  XCTAssertEqual(0.7f,
                 (float)window.alpha,
                 @"Visibility checker must not change alpha values");
}

- (void)testVisibleForInteractionForViewWithSameImageReturnedForBeforeAndAfter {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  UIImage *image = [self grey_imageOfSize:CGSizeMake(10, 10)
                                withColor:[UIColor whiteColor]];

  // For each invocation of isVisibleForInteraction, 2 screenshots are needed, for before and after.
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = NO;

  [window addSubview:view];

  XCTAssertFalse([GREYVisibilityChecker isVisibleForInteraction:view],
                 @"Should be NO because no pixels changed between screenshots");
}

- (void)testVisibileForInteractionOfElementWithSameImageReturnedForContainerViewBeforeAndAfter {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  UIImage *image = [self grey_imageOfSize:CGSizeMake(10, 10)   withColor:[UIColor whiteColor]];

  // For each invocation of isVisibleForInteraction, 2 screenshots are needed, for before and after.
  [self addToScreenshotListReturnedByScreenshotUtil:image];
  [self addToScreenshotListReturnedByScreenshotUtil:image];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = NO;

  [window addSubview:view];

  id mockElementA = [OCMockObject mockForClass:[UIAccessibilityElement class]];
  [[[mockElementA stub] andReturn:view] accessibilityContainer];
  [[[mockElementA stub] andReturn:view] grey_viewContainingSelf];
  [[[mockElementA stub] andReturnValue:@NO] grey_isWebAccessibilityElement];

  CGRect accessibilityFrame = CGRectMake(0, 0, 10, 10);
  CGPoint activationPoint = CGRectCenter(accessibilityFrame);
  [[[mockElementA stub] andReturnValue:OCMOCK_STRUCT(CGRect, accessibilityFrame)]
      accessibilityFrame];
  [[[mockElementA stub] andReturnValue:OCMOCK_STRUCT(CGPoint, activationPoint)]
      accessibilityActivationPoint];

  XCTAssertFalse([GREYVisibilityChecker isVisibleForInteraction:view],
                 @"Should be NO because no pixels changed between screenshots");
}

- (void)testVisibleForInteractionIsNoForHiddenActivationPointAndCenterOfVisibleArea {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  CGSize size = CGSizeMake(10, 10);
  UIImage *before = [self grey_imageOfSize:size   withColor:[UIColor whiteColor]];
  // Indicate that the activation point is hidden by setting color at the view's center same as
  // before image.
  UIImage *after = [self grey_imageOfSize:size
                      withBackgroundColor:[UIColor whiteColor]
                          withVisibleArea:CGRectMake(5, 5, 1, 1)];

  // For each invocation of isVisibleForInteraction, 2 screenshots are needed, for before and after.
  [self addToScreenshotListReturnedByScreenshotUtil:before];
  [self addToScreenshotListReturnedByScreenshotUtil:after];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = NO;
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  [window addSubview:view];

  XCTAssertFalse([GREYVisibilityChecker isVisibleForInteraction:view],
                 @"Should be NO because no pixels changed between screenshots");
}

- (void)testVisibleForInteractionIsYesForHiddenActivationPointButVisibleCenterOfVisibleArea {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  // Image has to be bigger because of the minimum visible area constraints.
  CGSize size = CGSizeMake(100, 100);
  UIImage *before = [self grey_imageOfSize:size   withColor:[UIColor whiteColor]];

  // Indicate that the activation point is hidden by leaving the color at the center of the image
  // the same as in the before image. The checker should then pick the center of the visible area.
  CGRect visibleArea = CGRectMake(0, 0, 30, 30);
  UIImage *after = [self grey_imageOfSize:size
                      withBackgroundColor:[UIColor whiteColor]
                          withVisibleArea:visibleArea];

  // For each invocation of isVisibleForInteraction, 2 screenshots are needed, for before and after.
  [self addToScreenshotListReturnedByScreenshotUtil:before];
  [self addToScreenshotListReturnedByScreenshotUtil:after];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  window.hidden = NO;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  view.alpha = 1;
  view.hidden = NO;

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  XCTAssertTrue([GREYVisibilityChecker isVisibleForInteraction:view],
                 @"Should be YES because the center of the visible area is visible.");
}

- (void)testVisibleForInteractionIsNoForLowVisiblePixelCount {
  [[[self.mockSharedApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
      statusBarOrientation];

  CGSize size = CGSizeMake(10, 10);
  UIImage *before = [self grey_imageOfSize:size withColor:[UIColor whiteColor]];

  // Indicate that the activation point is visible by changing color at the view's center.
  CGRect visibleArea = CGRectMake((size.width / 2) - 1, (size.height / 2) - 1, 1, 1);
  UIImage *after = [self grey_imageOfSize:size
                      withBackgroundColor:[UIColor whiteColor]
                          withVisibleArea:visibleArea];

  // For each invocation of isVisibleForInteraction, 2 screenshots are needed, for before and after.
  [self addToScreenshotListReturnedByScreenshotUtil:before];
  [self addToScreenshotListReturnedByScreenshotUtil:after];

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = NO;
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  [window addSubview:view];

  // Verify that visible pixel count is less than the minimum required.
  CGSize imageSizeInPixels = CGSizeMake(before.size.width * before.scale,
                                        before.size.height * before.scale);

  GREYVisibilityDiffBuffer diffBuffer =
      GREYVisibilityDiffBufferCreate((size_t)imageSizeInPixels.width,
                                     (size_t)imageSizeInPixels.height);
  GREYVisiblePixelData visiblePixels =
      [GREYVisibilityChecker grey_countPixelsInImage:before.CGImage
                         thatAreShiftedPixelsOfImage:after.CGImage
                         storeVisiblePixelRectInRect:NULL
                    andStoreComparisonResultInBuffer:&diffBuffer];
  free(diffBuffer.data);

  XCTAssertTrue(visiblePixels.visiblePixelCount <
                kMinimumPointsVisibleForInteraction * [[UIScreen mainScreen] scale],
                @"Too many visible pixels.");

  // Verify that the element not visible-for-interaction even though part of it is visible
  // because the visible pixel count is less than kMinimumPointsVisibleForInteraction.
  XCTAssertFalse([GREYVisibilityChecker isVisibleForInteraction:view],
                 @"Should be NO because number of visible pixels is below the minimum.");

}

#pragma mark - Private

- (UIImage *)grey_imageOfSize:(CGSize)size   withColor:(UIColor *)color {
  return [self grey_imageOfSize:size withBackgroundColor:color withVisibleArea:CGRectZero];
}

- (UIImage *)grey_imageOfSize:(CGSize)size
          withBackgroundColor:(UIColor *)backgroundColor
              withVisibleArea:(CGRect)paintedArea {
  UIGraphicsBeginImageContextWithOptions(size, YES, 0);

  [backgroundColor setFill];
  UIRectFill(CGRectMake(0, 0, size.width, size.height));

  [[UIColor grayColor] setFill];
  UIRectFill(paintedArea);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

- (void)testIsNotVisibleIsUsingCache {
  CGSize imageSize = CGSizeMake(10, 10);
  // Before screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor whiteColor]]];
  // After screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor blackColor]]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.hidden = YES;
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  BOOL isNotVisible = [GREYVisibilityChecker isNotVisible:view];
  XCTAssertTrue(isNotVisible);

  // If cache was not used, this would trigger visibility check.
  view.hidden = NO;
  // Calling it again. This time it should use cached value.
  isNotVisible = [GREYVisibilityChecker isNotVisible:view];
  XCTAssertTrue(isNotVisible, @"Cached value should also be YES. Are we using cache?");
}

- (void)testPercentVisibleAreaOfElementIsUsingCache {
  CGSize imageSize = CGSizeMake(10, 10);
  // Before screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor whiteColor]]];
  // After screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor blackColor]]];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = NO;

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.hidden = NO;

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  XCTAssertGreaterThan([GREYVisibilityChecker percentVisibleAreaOfElement:view], 0);

  view.hidden = YES;
  // Calling it again. This time it should use cached value.
  XCTAssertGreaterThan([GREYVisibilityChecker percentVisibleAreaOfElement:view], 0,
                       @"Cached value should also be non-zero. Are we using cache?");
}

- (void)testIsVisibleForInteractionIsUsingCache {
  CGSize imageSize = CGSizeMake(10, 10);
  // Before screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor whiteColor]]];
  // After screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor blackColor]]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.hidden = NO;

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.hidden = NO;

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  BOOL isVisibleForInteraction = [GREYVisibilityChecker isVisibleForInteraction:view];
  XCTAssertTrue(isVisibleForInteraction);

  view.hidden = YES;
  // Calling it again. This time it should use cached value.
  isVisibleForInteraction = [GREYVisibilityChecker isVisibleForInteraction:view];
  XCTAssertTrue(isVisibleForInteraction, @"Cached value should also be YES. Are we using cache?");
}

/**
 *  Helper for checking corner cases that calculates the visible rect for an imaginary view of a
 *  given size @c size with area @c targetArea hidden if @c hidden is YES or with only are
 *  @c targetArea showing if @c hidden is NO.
 *
 *  @param size       The size of the view image to build (for checking performance).
 *  @param targetArea The area to make visible/not visible depending on @c hidden
 *  @param hidden     If YES, make @c targetArea hidden. Otherwise, make @c targetArea
 *                    visible and everywhere else hidden.
 *
 *  @return The visible rect computed from the given parameters.
 */
- (CGRect)grey_visibleRectForSize:(CGSize)size
                             area:(CGRect)targetArea
                       areaHidden:(BOOL)hidden {
  CGRect visibleRect = CGRectMake(0, 0, size.width, size.height);
  // Generate some test images.
  UIImage *before = [self grey_imageOfSize:visibleRect.size withColor:[UIColor whiteColor]];
  UIImage *after;
  if (hidden) {
    after = [self grey_imageOfSize:visibleRect.size
               withBackgroundColor:[UIColor whiteColor]
                   withVisibleArea:visibleRect
andOptionalHiddenAreaFromVisibleArea:targetArea];
  } else {
    after = [self grey_imageOfSize:visibleRect.size
               withBackgroundColor:[UIColor whiteColor]
                    withVisibleArea:targetArea];
  }
  CGRect enclosing_px;
  [GREYVisibilityChecker grey_countPixelsInImage:before.CGImage
                     thatAreShiftedPixelsOfImage:after.CGImage
                     storeVisiblePixelRectInRect:&enclosing_px
                andStoreComparisonResultInBuffer:NULL];
  return CGRectPixelToPoint(enclosing_px);
}

- (void)testVisibleAreaCorrectTopLeftVisible {
  // Test (starred region visible):
  // ****---
  // ****   |
  // ****   |
  // |      |
  // |      |
  // |      |
  // |      |
  // |      |
  //  ------
  CGRect correct = CGRectMake(0, 0, 20, 20);
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(100, 10000)
                                    area:correct
                              areaHidden:NO];
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectCenterVisible {
  // Test (starred region visible):
  //  --------
  // |        |
  // | *****  |
  // | *****  |
  // |        |
  //  --------
  CGRect correct = CGRectMake(2, 3, 4, 4);
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:correct
                              areaHidden:NO];
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectBottomRightTallHidden {
  // Test (starred region visible):
  //  --------
  // |        |
  // |     ****
  // |     ****
  // |     ****
  //  -----****
  CGRect correct = CGRectMake(6, 3, 4, 7);
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:correct
                              areaHidden:NO];
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectTopLeftHidden {
  // Test (starred region occluded):
  // ****----------
  // ****          |
  // ****          |
  // |             |
  // |             |
  //  -------------
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(100, 10000)
                                    area:CGRectMake(0, 0, 20, 20)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 20, 100, 9980);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectTopRightHidden {
  // Test (starred region occluded):
  //  ----------****
  // |          ****
  // |          ****
  // |             |
  // |             |
  //  -------------
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10000, 10)
                                    area:CGRectMake(9996, 0, 4, 4)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 0, 9996, 10);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectCenterHidden {
  // Test (starred region occluded):
  //  --------
  // |        |
  // | *****  |
  // | *****  |
  // |        |
  //  --------
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(2, 3, 4, 4)
                              areaHidden:YES];
  CGRect correct = CGRectMake(6, 0, 4, 10);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectLeftHidden {
  // Test (starred region occluded):
  //  --------
  // |        |
  // ****     |
  // ****     |
  // |        |
  //  --------
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(0, 3, 4, 4)
                              areaHidden:YES];
  CGRect correct = CGRectMake(4, 0, 6, 10);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectRightHidden {
  // Test (starred region occluded):
  //  --------
  // |        |
  // |     ****
  // |     ****
  // |        |
  //  --------
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(6, 3, 4, 4)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 0, 6, 10);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectBottomHidden {
  // Test (starred region occluded):
  //  --------
  // |        |
  // |        |
  // |  ****  |
  // |  ****  |
  //  --****--
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(3, 6, 4, 4)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 0, 10, 6);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectBottomRightTallVisible {
  // Test (starred region occluded):
  //  --------
  // |        |
  // |     ****
  // |     ****
  // |     ****
  //  -----****
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(6, 3, 4, 7)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 0, 6, 10);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectBottomRightWideHidden {
  // Test (starred region occluded):
  //  --------
  // |        |
  // |        |
  // |        |
  // |   ******
  //  ---******
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(6, 7, 3, 3)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 0, 10, 7);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectBottomLeftSinglePixelHidden {
  // Test (starred region occluded):
  //  --------
  // |        |
  // |        |
  // |        |
  // |        |
  // **-------
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(0, 9, 2, 1)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 0, 10, 9);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectBottomRightSinglePixelHidden {
  // Test (starred region occluded):
  //  --------
  // |        |
  // |        |
  // |        |
  // |        |
  //  --------*
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(9, 9, 1, 1)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 0, 10, 9);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectTopRightSinglePixelHidden {
  // Test (starred region occluded):
  //  -------**
  // |        |
  // |        |
  // |        |
  // |        |
  //  --------
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(8, 0, 2, 1)
                              areaHidden:YES];
  CGRect correct = CGRectMake(0, 1, 10, 9);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testVisibleAreaCorrectTopLeftSinglePixelHidden {
  // Test (starred region occluded):
  // *--------
  // *        |
  // |        |
  // |        |
  // |        |
  //  --------
  CGRect rect = [self grey_visibleRectForSize:CGSizeMake(10, 10)
                                    area:CGRectMake(0, 0, 1, 2)
                              areaHidden:YES];
  CGRect correct = CGRectMake(1, 0, 9, 10);
  XCTAssertTrue(CGRectEqualToRect(rect, correct),
                @"Visible rect returned incorrect (expected %@ got %@).",
                NSStringFromCGRect(correct),
                NSStringFromCGRect(rect));
}

- (void)testRectEnclosingVisibleAreaOfElementIsUsingCache {
  CGSize imageSize = CGSizeMake(10, 10);
  // Before screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor whiteColor]]];
  // After screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor blackColor]]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.hidden = NO;

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.hidden = NO;

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  CGRect visibleAreaRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
  XCTAssertEqual(visibleAreaRect.origin.x, 0);
  XCTAssertEqual(visibleAreaRect.origin.y, 0);
  XCTAssertEqual(visibleAreaRect.size.width, view.bounds.size.width);
  XCTAssertEqual(visibleAreaRect.size.height, view.bounds.size.height);

  view.hidden = YES;
  // Calling it again. This time it should use cached value.
  visibleAreaRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
  XCTAssertEqual(visibleAreaRect.origin.x, 0,
                 @"Cached value should also be YES. Are we using cache?");
  XCTAssertEqual(visibleAreaRect.origin.y, 0,
                 @"Cached value should also be YES. Are we using cache?");
  XCTAssertEqual(visibleAreaRect.size.width, view.bounds.size.width,
                 @"Cached value should also be YES. Are we using cache?");
  XCTAssertEqual(visibleAreaRect.size.height, view.bounds.size.height,
                 @"Cached value should also be YES. Are we using cache?");
}

- (void)testDrainInvalidatesCache {
  CGSize imageSize = CGSizeMake(10, 10);
  // Before screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor whiteColor]]];
  // After screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor blackColor]]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.hidden = YES;

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.hidden = NO;

  [window addSubview:view];
  view.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(view.bounds, view);
  view.accessibilityActivationPoint = CGRectCenter(view.accessibilityFrame);

  BOOL isNotVisible = [GREYVisibilityChecker isNotVisible:view];
  XCTAssertTrue(isNotVisible);

  // If cache was not used, this would trigger visibility check.
  view.hidden = NO;

  // Do a drain.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];

  // Calling it again. This time it should be visible.
  isNotVisible = [GREYVisibilityChecker isNotVisible:view];
  XCTAssertFalse(isNotVisible, @"Cached value should have been invalidated after a drain.");
}

- (void)testRectEnclosingExistingElementIsNotEmpty {
  CGSize imageSize = CGSizeMake(10, 10);
  // Before screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor whiteColor]]];
  // After screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor blackColor]]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.hidden = NO;

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  window.hidden = NO;
  [window addSubview:view];

  // Do a drain.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];

  CGRect enclosingRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
  XCTAssertEqualObjects([NSValue valueWithCGRect:enclosingRect],
                        [NSValue valueWithCGRect:CGRectMake(0, 0, 10, 10)],
                        @"Rect for view is CGRectZero.");
}

- (void)testRectEnclosingNonExistingElementIsEmpty {
  CGSize imageSize = CGSizeMake(10, 10);
  // Before screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor whiteColor]]];
  // After screenshot.
  [self addToScreenshotListReturnedByScreenshotUtil:[self grey_imageOfSize:imageSize
                                                                 withColor:[UIColor whiteColor]]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.hidden = NO;

  // Do a drain.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];

  CGRect enclosingRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
  XCTAssertEqualObjects([NSValue valueWithCGRect:enclosingRect],
                        [NSValue valueWithCGRect:CGRectZero],
                        @"Rect for View is not CGRectZero.");
}

#pragma mark - Private

- (UIImage *)grey_imageOfSize:(CGSize)size
                     withBackgroundColor:(UIColor *)backgroundColor
                         withVisibleArea:(CGRect)paintedArea
    andOptionalHiddenAreaFromVisibleArea:(CGRect)hiddenArea {
  UIGraphicsBeginImageContextWithOptions(size, YES, 0);

  [backgroundColor setFill];
  UIRectFill(CGRectMake(0, 0, size.width, size.height));

  [[UIColor grayColor] setFill];
  UIRectFill(paintedArea);

  if (!CGRectIsNull(hiddenArea)) {
    [backgroundColor setFill];
    UIRectFill(hiddenArea);
  }
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

@end
