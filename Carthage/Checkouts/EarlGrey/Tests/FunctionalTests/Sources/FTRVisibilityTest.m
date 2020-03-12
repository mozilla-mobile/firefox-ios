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
#import "Additions/CGGeometry+GREYAdditions.h"
#import "Common/GREYVisibilityChecker.h"
#import <EarlGrey/EarlGrey.h>

@interface FTRVisibilityTest : FTRBaseIntegrationTest
@end

@implementation FTRVisibilityTest {
  UIView *_outerview;
}

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Visibility Tests"];
}

- (void)tearDown {
  [_outerview removeFromSuperview];
  [super tearDown];
}

- (void)testOverlappingViews {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"bottomScrollView")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];

  BOOL (^assertionBlock)(id element, NSError *__strong *errorOrNil) =
      ^BOOL(id element, NSError *__strong *errorOrNil) {
         CGPoint offset = ((UIScrollView*) element).contentOffset;
         CGPoint expectedOffset = CGPointMake(100, 100);
         if (CGPointEqualToPoint(offset, expectedOffset)) {
           return YES;
         } else {
           NSError* error = [[NSError alloc]
                             initWithDomain:kGREYInteractionErrorDomain
                             code:
                             kGREYInteractionAssertionFailedErrorCode
                             userInfo:@{
                                        NSLocalizedDescriptionKey:
                                          @"Cover view moved."}];
           *errorOrNil = error;
           return NO;
         }
      };
  id<GREYAssertion> assertion = [GREYAssertionBlock assertionWithName:@"coverContentOffsetUnchanged"
                                              assertionBlockWithError:assertionBlock];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"coverScrollView")] assert:assertion];
}

- (void)testTranslucentViews {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"translucentLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"translucentOverlappingView")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"translucentOverlappingView")]
      assert:[GREYAssertionBlock assertionWithName:@"translucentOverlappingViewVisibleArea"
                           assertionBlockWithError:^BOOL(id element,
                                                         NSError *__strong *errorOrNil) {
        CGRect visibleRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:element];
        CGRect expectedRect = CGRectMake(0, 0, 50, 50);
        GREYAssertTrue(CGSizeEqualToSize(visibleRect.size, expectedRect.size),
                     @"rects must be equal");
        return YES;
      }
  ]];
}

- (void)testNonPixelBoundaryAlignedLabel {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixel1")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixel2")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixel3")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixel4")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixelWithOnePixelSize")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixelWithHalfPixelSize")]
      assertWithMatcher:grey_notVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixelWithFractionPixelSize")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testButtonIsVisible {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRVisibilityButton")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testObscuredButtonIsNotVisible {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRVisibilityButton")]
      performAction:grey_tap()] assertWithMatcher:grey_notVisible()];
}

- (void)testRasterization {
  UIWindow *currentWindow = [[[UIApplication sharedApplication] delegate] window];
  _outerview = [[UIView alloc] initWithFrame:currentWindow.frame];
  _outerview.isAccessibilityElement = YES;
  _outerview.layer.shouldRasterize = YES;
  _outerview.layer.rasterizationScale = 0.001f;
  _outerview.accessibilityLabel = @"RasterizedLayer";
  _outerview.backgroundColor = [UIColor blueColor];
  [currentWindow.rootViewController.view addSubview:_outerview];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"RasterizedLayer")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testVisibleRectOfPartiallyObscuredView {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"FTRRedSquare")]
      assert:[GREYAssertionBlock assertionWithName:@"TestVisibleRectangle"
                           assertionBlockWithError:^BOOL(id element,
                                                         NSError *__strong *errorOrNil) {
        CGRect visibleRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:element];
        GREYAssertTrue(CGSizeEqualToSize(visibleRect.size, CGSizeMake(50, 50)),
                     @"Visible rect must be 50X50. It is currently %@",
                     NSStringFromCGSize(visibleRect.size));
        return YES;
      }
  ]];
}

- (void)testVisibleEnclosingRectangleOfVisibleViewIsEntireView {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRVisibilityButton")]
      assert:[GREYAssertionBlock assertionWithName:@"TestVisibleRectangle"
                           assertionBlockWithError:^BOOL(id element,
                                                         NSError *__strong *errorOrNil) {
        GREYAssertNotNil(element, @"element must not be nil");
        GREYAssertTrue([element isKindOfClass:[UIView class]], @"element must be UIView");
        UIView *view = element;
        CGRect expectedRect = view.accessibilityFrame;
        // Visiblity checker should first convert to pixel, then get integral inside,
        // then back to points.
        expectedRect = CGRectPointToPixel(expectedRect);
        expectedRect = CGRectIntegralInside(expectedRect);
        expectedRect = CGRectPixelToPoint(expectedRect);
        CGRect actualRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
        GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect),
                     @"expected: %@, actual: %@",
                     NSStringFromCGRect(expectedRect),
                     NSStringFromCGRect(actualRect));
        return YES;
      }
  ]];
}

- (void)testVisibleEnclosingRectangleOfObscuredViewIsCGRectNull {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRVisibilityButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRVisibilityButton")]
      assert:[GREYAssertionBlock assertionWithName:@"TestVisibleRectangle"
                           assertionBlockWithError:^BOOL(id element,
                                                         NSError *__strong *errorOrNil) {
        GREYAssertNotNil(element, @"element must not be nil");
        GREYAssertTrue([element isKindOfClass:[UIView class]], @"element must be UIView");
        UIView *view = element;
        CGRect visibleRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
        GREYAssertTrue(CGRectIsEmpty(visibleRect), @"rect must be CGRectIsZero");
        return YES;
      }
  ]];
}

- (void)testVisibilityFailsWhenViewIsObscured {
  // Verify FTRRedBar cannot be interacted with when overlapped by another view.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRedBar")]
      assertWithMatcher:grey_not(grey_interactable())];

  // Unhide the activation point.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRUnObscureRedBar")]
      performAction:[GREYActions actionForTurnSwitchOn:YES]];

  // Verify FTRRedBar can now be interacted with.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRedBar")]
      assertWithMatcher:grey_interactable()];
}

- (void)testVisibilityOfViewsWithSameAccessibilityLabelAndAtIndex {
  NSError *error;

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")]
      assertWithMatcher:grey_sufficientlyVisible() error:&error];
  GREYAssertEqual(error.code, kGREYInteractionMultipleElementsMatchedErrorCode, @"should be equal");

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")]
      performAction:grey_tap() error:&error];
  GREYAssertEqual(error.code, kGREYInteractionMultipleElementsMatchedErrorCode, @"should be equal");

  NSMutableSet *idSet = [NSMutableSet set];

  // Match against the first view present.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] atIndex:0]
      assert:[self ftr_assertOnIDSet:idSet]];

  // Match against the second view present.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] atIndex:1]
      assert:[self ftr_assertOnIDSet:idSet]];

  // Match against the third and last view present.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] atIndex:2]
      assert:[self ftr_assertOnIDSet:idSet]];

  // Use the element at index matcher with an incorrect matcher.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"InvalidView")] atIndex:0]
      assertWithMatcher:grey_sufficientlyVisible() error:&error];
  GREYAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode, @"should be equal");

  // Use the element at index matcher with an incorrect matcher on an action.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"InvalidView")] atIndex:0]
      performAction:grey_tap() error:&error];
  GREYAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode, @"should be equal");

  // Use the element at index matcher with an incorrect matcher and also an invalid bounds.
  // This should throw an error with the code as kGREYInteractionElementNotFoundErrorCode
  // since we first check if the number of matched elements is greater than zero.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"InvalidView")] atIndex:99]
      assertWithMatcher:grey_sufficientlyVisible() error:&error];
  GREYAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode, @"should be equal");

  // Use the element at index matcher with an index greater than the number of
  // matched elements.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] atIndex:999]
      assertWithMatcher:grey_sufficientlyVisible() error:&error];
  GREYAssertEqual(error.code,
                  kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode,
                  @"should be equal");

  GREYAssertEqual(idSet.count, 3, @"should be equal");
}

- (void)testElementsInHierarchyDump {
  NSString *hierarchyDump = [GREYElementHierarchy hierarchyStringForAllUIWindows];
  NSArray *stringTargetHierarchy_iOS10Later =
      @[ @"========== Window 1 ==========",
         @"<UIWindow:",
         @"  |--<UILayoutContainerView:",
         @"  |  |--<UINavigationTransitionView:",
         @"  |  |  |--<UIViewControllerWrapperView:",
         @"  |  |  |  |--<UIView",
         @"  |  |  |  |  |--<UIView:"];
  NSArray *stringTargetHierarchy_iOS9Earlier =
      @[ @"========== Window 1 ==========",
         @"========== Window 2 ==========",
         @"<UITextEffectsWindow",
         @"  |--<UIInputSetContainerView:",
         @"  |  |--<UIInputSetHostView:",
         @"<UIWindow:",
         @"  |--<UILayoutContainerView:",
         @"  |  |--<UINavigationTransitionView:",
         @"  |  |  |--<UIViewControllerWrapperView:",
         @"  |  |  |  |--<UIView",
         @"  |  |  |  |  |--<UIView:"];
  if (iOS10_OR_ABOVE()) {
    for (NSString *targetString in stringTargetHierarchy_iOS10Later) {
      XCTAssertNotEqual([hierarchyDump rangeOfString:targetString].location,
                        (NSUInteger)NSNotFound);
    }
  } else {
    for (NSString *targetString in stringTargetHierarchy_iOS9Earlier) {
      XCTAssertNotEqual([hierarchyDump rangeOfString:targetString].location,
                        (NSUInteger)NSNotFound);
    }
  }
}

#pragma mark - Private

- (GREYAssertionBlock *)ftr_assertOnIDSet:(NSMutableSet *)idSet {
  GREYAssertionBlock *assertAxId =
      [GREYAssertionBlock assertionWithName:@"Check Accessibility Id"
                    assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
                      XCTAssertNotNil(element);

                      [grey_sufficientlyVisible() matches:element];
                      UIView *view = element;
                      [idSet addObject:view.accessibilityIdentifier];
                      return YES;
                    }];
  return assertAxId;
}

@end
