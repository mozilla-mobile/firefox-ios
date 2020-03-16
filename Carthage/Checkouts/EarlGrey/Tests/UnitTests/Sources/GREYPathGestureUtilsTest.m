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

#import "Action/GREYPathGestureUtils.h"
#import "Additions/CGGeometry+GREYAdditions.h"
#import "Common/GREYVisibilityChecker.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYPathGestureUtilsTest : GREYBaseTest
@end

@implementation GREYPathGestureUtilsTest

- (void)setUp {
  [super setUp];
  [[[self.mockSharedApplication stub]
      andReturnValue:@(UIDeviceOrientationPortrait)] statusBarOrientation];
}

// Executes the given block once for each direction (up, down, left and right).
- (void)forEachDirectionPerformBlock:(void(^)(GREYDirection direction))block {
  GREYDirection allDirections[4] = {
    kGREYDirectionUp,
    kGREYDirectionDown,
    kGREYDirectionLeft,
    kGREYDirectionRight
  };
  const NSInteger maxDirections = (NSInteger)(sizeof(allDirections)/sizeof(allDirections[0]));
  for (NSInteger i = 0; i < maxDirections; i++) {
    block(allDirections[i]);
  }
}

// Returns a mock UIView that covers the entire screen.
- (id)mockFullScreenUIView {
  CGRect bounds = [UIScreen mainScreen].bounds;
  id mockUIView = [OCMockObject partialMockForObject:[[UIView alloc] initWithFrame:bounds]];
  id mockWindow = [OCMockObject partialMockForObject:[[UIWindow alloc] initWithFrame:bounds]];
  [[[mockWindow stub] andReturnValue:OCMOCK_VALUE(bounds)] convertRect:CGRectZero
                                                            fromWindow:OCMOCK_ANY];
  [[[mockUIView stub] andReturn:mockWindow] window];
  [[[mockUIView stub] andReturnValue:OCMOCK_VALUE(bounds)] accessibilityFrame];
  return mockUIView;
}

- (void)testSwipeTouchPathBeginsWithGivenStartPoint {
  [self forEachDirectionPerformBlock:^(GREYDirection direction) {
    CGPoint startPoint = CGPointMake(100, 200);
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    NSArray *path = [GREYPathGestureUtils touchPathForGestureWithStartPoint:startPoint
                                                               andDirection:direction
                                                                andDuration:1.0
                                                                   inWindow:window];
    CGPoint pathStartPoint = [path[0] CGPointValue];
    XCTAssertEqual(pathStartPoint.x, startPoint.x);
    XCTAssertEqual(pathStartPoint.y, startPoint.y);
  }];
}

- (void)testDragTouchPath_noCancelInertia {
  CGPoint startPoint = CGPointMake(100, 200);
  CGPoint endPoint = CGPointMake(200, 300);
  NSArray *path = [GREYPathGestureUtils touchPathForDragGestureWithStartPoint:startPoint
                                                                     endPoint:endPoint
                                                                cancelInertia:NO];
  CGPoint pathStartPoint = [[path firstObject] CGPointValue];
  XCTAssertEqual(pathStartPoint.x, startPoint.x);
  XCTAssertEqual(pathStartPoint.y, startPoint.y);

  CGPoint pathEndPoint = [[path lastObject] CGPointValue];
  XCTAssertEqual(pathEndPoint.x, endPoint.x);
  XCTAssertEqual(pathEndPoint.y, endPoint.y);

  NSUInteger pathLength = [path count];
  CGPoint path2ndLastPoint = [[path objectAtIndex:(pathLength - 2)] CGPointValue];
  XCTAssertLessThan(path2ndLastPoint.x, endPoint.x);
  XCTAssertLessThan(path2ndLastPoint.y, endPoint.y);

  CGPoint path3rdLastPoint = [[path objectAtIndex:(pathLength - 3)] CGPointValue];
  XCTAssertLessThan(path3rdLastPoint.x, path2ndLastPoint.x);
  XCTAssertLessThan(path3rdLastPoint.y, path2ndLastPoint.y);
}

- (void)testDragTouchPath_cancelInertia {
  CGPoint startPoint = CGPointMake(100, 200);
  CGPoint endPoint = CGPointMake(0, 0);
  NSArray *path = [GREYPathGestureUtils touchPathForDragGestureWithStartPoint:startPoint
                                                                     endPoint:endPoint
                                                                cancelInertia:YES];
  CGPoint pathStartPoint = [[path firstObject] CGPointValue];
  XCTAssertEqual(pathStartPoint.x, startPoint.x);
  XCTAssertEqual(pathStartPoint.y, startPoint.y);

  CGPoint pathEndPoint = [[path lastObject] CGPointValue];
  XCTAssertEqual(pathEndPoint.x, endPoint.x);
  XCTAssertEqual(pathEndPoint.y, endPoint.y);

  NSUInteger pathLength = [path count];
  CGPoint path2ndPoint = [[path objectAtIndex:1] CGPointValue];
  CGPoint diffStartAndNextPoint =
      CGPointMake(path2ndPoint.x - startPoint.x, path2ndPoint.y - startPoint.y);
  XCTAssertLessThan(diffStartAndNextPoint.x, 0);
  XCTAssertLessThan(diffStartAndNextPoint.y, 0);

  CGPoint path2ndLastPoint = [[path objectAtIndex:(pathLength - 2)] CGPointValue];
  CGPoint diff2ndLastAndLastPoint =
      CGPointMake(path2ndLastPoint.x - endPoint.x, path2ndLastPoint.y - endPoint.y);
  XCTAssertLessThan(fabsf((float)diff2ndLastAndLastPoint.x),
                    fabsf((float)diffStartAndNextPoint.x));
  XCTAssertLessThan(fabsf((float)diff2ndLastAndLastPoint.y),
                    fabsf((float)diffStartAndNextPoint.y));

  CGPoint path3rdLastPoint = [[path objectAtIndex:(pathLength - 3)] CGPointValue];
  CGPoint diff3rdLastAnd2ndLastPoint = CGPointMake(path3rdLastPoint.x - path2ndLastPoint.x,
                                                   path3rdLastPoint.y - path2ndLastPoint.y);
  XCTAssertEqualWithAccuracy(diff3rdLastAnd2ndLastPoint.x, diff2ndLastAndLastPoint.x, 0.001);
  XCTAssertEqualWithAccuracy(diff3rdLastAnd2ndLastPoint.y, diff2ndLastAndLastPoint.y, 0.001);
}

- (void)testTouchPathWithLengthAndLeftDirection_cancelInertia {
  id mockUIView = [self mockFullScreenUIView];
  NSArray *path = [GREYPathGestureUtils touchPathForGestureInView:mockUIView
                                                    withDirection:kGREYDirectionLeft
                                                           length:100
                                               startPointPercents:CGPointMake(0.1f, 0.1f)
                                               outRemainingAmount:NULL];

  CGPoint pathStartPoint = [[path firstObject] CGPointValue];
  CGPoint pathEndPoint = [[path lastObject] CGPointValue];
  XCTAssertGreaterThan(pathStartPoint.x, pathEndPoint.x);
  XCTAssertEqual(pathStartPoint.y, pathEndPoint.y);

  NSUInteger pathLength = [path count];
  CGPoint path2ndPoint = [[path objectAtIndex:1] CGPointValue];
  CGPoint diffStartAndNextPoint =
      CGPointMake(path2ndPoint.x - pathStartPoint.x, path2ndPoint.y - pathStartPoint.y);
  XCTAssertLessThan(diffStartAndNextPoint.x, 0);
  XCTAssertEqual(diffStartAndNextPoint.y, 0);

  CGPoint path2ndLastPoint = [[path objectAtIndex:(pathLength - 2)] CGPointValue];
  CGPoint diff2ndLastAndLastPoint =
      CGPointMake(path2ndLastPoint.x - pathEndPoint.x, path2ndLastPoint.y - pathEndPoint.y);
  XCTAssertLessThan(fabsf((float)diff2ndLastAndLastPoint.x), fabsf((float)diffStartAndNextPoint.x));
  XCTAssertEqual(diff2ndLastAndLastPoint.y, diffStartAndNextPoint.y);

  CGPoint path3rdLastPoint = [[path objectAtIndex:(pathLength - 3)] CGPointValue];
  CGPoint diff3rdLastAnd2ndLastPoint = CGPointMake(path3rdLastPoint.x - path2ndLastPoint.x,
                                                   path3rdLastPoint.y - path2ndLastPoint.y);
  XCTAssertEqualWithAccuracy(diff3rdLastAnd2ndLastPoint.x, diff2ndLastAndLastPoint.x, 0.001);
  XCTAssertEqualWithAccuracy(diff3rdLastAnd2ndLastPoint.y, diff2ndLastAndLastPoint.y, 0.001);
}

- (void)testTouchPathIsNilForZeroSizedViews {
  [self forEachDirectionPerformBlock:^(GREYDirection direction) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.accessibilityFrame = CGRectZero;
    XCTAssertNil([GREYPathGestureUtils touchPathForGestureInView:view
                                                   withDirection:direction
                                                          length:100
                                              startPointPercents:GREYCGPointNull
                                              outRemainingAmount:NULL]);
  }];
}

- (void)testTouchPathIsNilForOnePixelViews {
  // One pixel views must also have no touch path as EarlGrey ignores one pixel on all sides to
  // ensure gesture starts inside the view.
  CGRect onePixelRect = CGRectMake(0, 0, 1, 1);
  id mockVisibilityChecker = OCMClassMock([GREYVisibilityChecker class]);
  OCMStub([mockVisibilityChecker
           rectEnclosingVisibleAreaOfElement:OCMOCK_ANY]).andReturn(onePixelRect);

  [self forEachDirectionPerformBlock:^(GREYDirection direction) {
    UIView *view = [[UIView alloc] initWithFrame:onePixelRect];
    view.accessibilityFrame = onePixelRect;
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    id mockView = OCMPartialMock(view);
    OCMStub([mockView window]).andReturn(window);
    XCTAssertNil([GREYPathGestureUtils touchPathForGestureInView:mockView
                                                   withDirection:direction
                                                          length:100
                                              startPointPercents:GREYCGPointNull
                                              outRemainingAmount:NULL]);
  }];
}

- (void)testTouchPathCannotBeGeneratedForZeroAmounts {
  [self forEachDirectionPerformBlock:^(GREYDirection direction) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    XCTAssertThrowsSpecificNamed([GREYPathGestureUtils touchPathForGestureInView:view
                                                                   withDirection:direction
                                                                          length:0
                                                              startPointPercents:GREYCGPointNull
                                                              outRemainingAmount:NULL],
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Must throw exception because amount is 0.");
  }];
}

- (void)testTouchPathCannotBeGeneratedForNegativeAmounts {
  [self forEachDirectionPerformBlock:^(GREYDirection direction) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    XCTAssertThrowsSpecificNamed([GREYPathGestureUtils touchPathForGestureInView:view
                                                                   withDirection:direction
                                                                          length:-1
                                                              startPointPercents:GREYCGPointNull
                                                              outRemainingAmount:NULL],
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Must throw exception because amount is negative.");
  }];
}

- (void)testTouchPathBreaksPathsAccurately {
  // Create a mock visibility checker that presents entire screen to be visible.
  id mockVisibilityChecker = OCMClassMock([GREYVisibilityChecker class]);
  OCMStub([mockVisibilityChecker
      rectEnclosingVisibleAreaOfElement:OCMOCK_ANY]).andReturn([UIScreen mainScreen].bounds);

  [self forEachDirectionPerformBlock:^(GREYDirection direction) {
    id mockUIView = [self mockFullScreenUIView];
    // Attempt to create paths with any length greater than the width and height of the screen.
    const CGFloat totalExpectedPathAmount = 10000;
    CGFloat totalActualPathAmount = 0;
    CGFloat remainingAmount = totalExpectedPathAmount;
    NSUInteger pathSegmentsCount = 0;
    while (remainingAmount > 0) {
      NSArray *path = [GREYPathGestureUtils touchPathForGestureInView:mockUIView
                                                        withDirection:kGREYDirectionDown
                                                               length:remainingAmount
                                                   startPointPercents:GREYCGPointNull
                                                   outRemainingAmount:&remainingAmount];
      CGFloat pathLength = CGVectorLength(CGVectorFromEndPoints([[path firstObject] CGPointValue],
                                                                [[path lastObject] CGPointValue],
                                                                NO));
      pathSegmentsCount += 1;
      XCTAssertGreaterThan(pathLength, kGREYScrollDetectionLength,
                           @"Touch path length must be greater than the scroll detection length.");
      // NOTE: Touch path contains kGREYScrollDetectionLength length in addition to what is
      // required, we subtract that here to compute the effective touch path length.
      totalActualPathAmount += pathLength - kGREYScrollDetectionLength;
    }
    XCTAssertGreaterThanOrEqual(pathSegmentsCount, 2u,
                                @"Path must be broken into at least 2 segments.");
    XCTAssertEqualWithAccuracy(totalActualPathAmount, totalExpectedPathAmount, 0.000001f);
  }];
}

@end
