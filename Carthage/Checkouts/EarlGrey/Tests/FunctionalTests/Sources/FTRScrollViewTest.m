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
#import "Common/GREYVisibilityChecker.h"
#import <EarlGrey/EarlGrey.h>

@interface FTRScrollViewTest : FTRBaseIntegrationTest
@end

@implementation FTRScrollViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Scroll Views"];
}

- (void)testScrollToTopEdge {
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"),
                                       grey_interactable(),
                                       grey_sufficientlyVisible(),
                                       nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToBottomEdge {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeBottom)]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeBottom)];
}

- (void)testScrollToRightEdge {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeRight)]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeRight)];
}

- (void)testScrollToLeftEdge {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeRight)];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeLeft)]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeLeft)];
}

- (void)testScrollToLeftEdgeWithCustomStartPoint {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      performAction:grey_scrollToContentEdgeWithStartPoint(kGREYContentEdgeLeft, 0.5, 0.5)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeLeft)];
}

- (void)testScrollToRightEdgeWithCustomStartPoint {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      performAction:grey_scrollToContentEdgeWithStartPoint(kGREYContentEdgeRight, 0.5, 0.5)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeRight)];
}

- (void)testScrollToTopEdgeWithCustomStartPoint {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      performAction:grey_scrollToContentEdgeWithStartPoint(kGREYContentEdgeTop, 0.5, 0.5)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToBottomEdgeWithCustomStartPoint {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      performAction:grey_scrollToContentEdgeWithStartPoint(kGREYContentEdgeBottom, 0.5, 0.5)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeBottom)];
}

- (void)testScrollToTopWorksWithPositiveInsets {
  // Scroll down.
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"),
                                       grey_interactable(),
                                       grey_sufficientlyVisible(),
                                       nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_sufficientlyVisible()];

  // Add positive insets using this format {top,left,bottom,right}
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      performAction:grey_typeText(@"{100,0,0,0}\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets toggle")]
      performAction:grey_turnSwitchOn(YES)];

  // Scroll to top and verify.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWorksWithNegativeInsets {
  // Scroll down.
  id<GREYMatcher> matcher =
      grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_sufficientlyVisible()];

  // Add positive insets using this format {top,left,bottom,right}
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      performAction:grey_typeText(@"{-100,0,0,0}\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets toggle")]
      performAction:grey_turnSwitchOn(YES)];

  // Scroll to top and verify.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testSearchActionReturnsNilWhenElementIsNotFound {
  id<GREYMatcher> matcher =
      grey_allOf(grey_accessibilityLabel(@"Unobtainium"), grey_interactable(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionUp, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_nil()];
}

- (void)testScrollToTopWhenAlreadyAtTheTopWithoutBounce {
  GREYActionBlock *bounceOff =
      [[GREYActionBlock alloc] initWithName:@"toggleBounces"
                                constraints:grey_kindOfClass([UIScrollView class])
                               performBlock:^BOOL(UIScrollView *scrollView,
                                                  NSError *__strong *error) {
    GREYAssertTrue(scrollView.bounces, @"Bounce must be set or this test is same as"
                                       @" testScrollToTopWhenAlreadyAtTheTopWithBounce");
    scrollView.bounces = !scrollView.bounces;
    return YES;
  }];
  // Verify this test with and without bounce enabled by toggling it.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:bounceOff];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWhenAlreadyAtTheTopWithBounce {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testVisibilityOnPartiallyObscuredScrollView {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Bottom Scroll View")]
      assert:[GREYAssertionBlock assertionWithName:@"TestVisibleRectangle"
                           assertionBlockWithError:^BOOL(id element,
                                                         NSError *__strong *errorOrNil) {
        GREYAssertNotNil(element, @"element must not be nil");
        GREYAssertTrue([element isKindOfClass:[UIScrollView class]], @"should be UIScrollView");
        UIView *view = element;
        CGRect visibleRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
        visibleRect = [view.window convertRect:visibleRect fromWindow:nil];
        visibleRect = [view convertRect:visibleRect fromView:nil];
        CGRect expectedVisibleRect = CGRectMake(0, 0, view.superview.bounds.size.width, 82);
        GREYAssertTrue(CGRectEqualToRect(visibleRect, expectedVisibleRect),
                      @"rects must be equal");
        return YES;
      }
  ]];
}

- (void)testInfiniteScroll {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionDown, 100)];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetInPortraitMode {
  [self ftr_assertScrollInDirectionCausesExactChangesToContentOffset];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetInPortraitUpsideDownMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown errorOrNil:nil];
  [self ftr_assertScrollInDirectionCausesExactChangesToContentOffset];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
  [self ftr_assertScrollInDirectionCausesExactChangesToContentOffset];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];
  [self ftr_assertScrollInDirectionCausesExactChangesToContentOffset];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetWithTinyScrollAmounts {
  // Scroll by a fixed amount and verify that the scroll offset has changed by that amount.
  // Go down to (0, 7)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionDown, 7)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(0, 7)))];
  // Go right to (6, 7)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionRight, 6)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(6, 7)))];
  // Go up to (6, 4)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionUp, 3)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(6, 4)))];
  // Go left to (3, 4)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionLeft, 3)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(3, 4)))];
}

- (void)testScrollToTopWithZeroXOffset {
  // Scroll down.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionDown, 500)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(0, 500)))];
  // Scroll up using grey_scrollToTop(...) and verify scroll offset is back at 0.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(0, 0)))];
}

- (void)testScrollToTopWithNonZeroXOffset {
  // Scroll to (50, 400)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionDown, 400)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionRight, 50)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(50, 400)))];
  // Scroll up using grey_scrollToContentEdge(...) and verify scroll offset is back at 0.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(50, 0)))];
}

- (void)testScrollingBeyondTheContentViewCausesScrollErrors {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionDown, 100)];
  NSError *scrollError;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionUp, 200) error:&scrollError];
  GREYAssertEqualObjects(scrollError.domain, kGREYScrollErrorDomain, @"should be equal");
  GREYAssertEqual(scrollError.code, kGREYScrollReachedContentEdge, @"should be equal");
}

- (void)testSetContentOffsetAnimatedYesWaitsForAnimation {
  [self ftr_setContentOffSet:CGPointMake(0, 100) animated:YES];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSetContentOffsetAnimatedNoDoesNotWaitForAnimation {
  [self ftr_setContentOffSet:CGPointMake(0, 100) animated:NO];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSetContentOffsetToSameCGPointDoesNotWait{
  [self ftr_setContentOffSet:CGPointZero animated:YES];
}

#pragma mark - Private

// Asserts that the scroll actions work accurately in all four directions by verifying the content
// offset changes caused by them.
- (void)ftr_assertScrollInDirectionCausesExactChangesToContentOffset {
  // Scroll by a fixed amount and verify that the scroll offset has changed by that amount.
  // Go down to (0, 99)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionDown, 99)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(0, 99)))];
  // Go right to (77, 99)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionRight, 77)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(77, 99)))];
  // Go up to (77, 44)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionUp, 55)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(77, 44)))];
  // Go left to (33, 44)
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Infinite Scroll View")]
      performAction:grey_scrollInDirection(kGREYDirectionLeft, 44)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:grey_text(NSStringFromCGPoint(CGPointMake(33, 44)))];
}

// Makes a setContentOffset:animated: call on an element of type UIScrollView.
- (void)ftr_setContentOffSet:(CGPoint)offset animated:(BOOL)animated {
  BOOL (^actionBlock)(UIScrollView *, __strong NSError **) =
      ^BOOL (UIScrollView *view, __strong NSError **errorOrNil) {
          [view setContentOffset:offset animated:animated];
          return YES;
        };

  id<GREYAction> action = [GREYActionBlock actionWithName:@"ftr_setContentOffSet"
                                              constraints:grey_kindOfClass([UIScrollView class])
                                             performBlock:actionBlock];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      performAction:action];
}

@end
