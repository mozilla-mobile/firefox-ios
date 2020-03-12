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

#import "Action/GREYPathGestureUtils.h"

#include <objc/message.h>

#import "Additions/CGGeometry+GREYAdditions.h"
#import "Additions/UIScrollView+GREYAdditions.h"
#import "Common/GREYConstants.h"
#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYThrowDefines.h"
#import "Common/GREYVisibilityChecker.h"
#import "Event/GREYSyntheticEvents.h"
#import "Event/GREYTouchInjector.h"

/**
 *  Refers to the minimum 10 points of scroll that is required for any scroll to be detected.
 *  It is non-static to make it accessible to unit tests.
 */
const NSInteger kGREYScrollDetectionLength = 10;

/**
 *  The minimum distance between any 2 adjacent points in the touch path.
 *  In practice, this value seems to yield the best results by triggering the gestures more
 *  accurately, even on slower machines.
 */
static const CGFloat kGREYDistanceBetweenTwoAdjacentPoints = 10.0f;

/**
 *  Cached screen edge pan detection length for the current device.
 */
static CGFloat kCachedScreenEdgePanDetectionLength = NAN;

@implementation GREYPathGestureUtils

+ (NSArray *)touchPathForGestureWithStartPoint:(CGPoint)startPointInWindowCoords
                                  andDirection:(GREYDirection)direction
                                   andDuration:(CFTimeInterval)duration
                                      inWindow:(UIWindow *)window {
  GREYDirection interfaceTransformedDirection =
      [self grey_relativeDirectionForCurrentOrientationWithDirection:direction];
  // Find an endpoint for gesture in window coordinates that gives us the longest path.
  CGPoint endPointInWindowCoords =
      [self grey_pointOnEdge:[GREYConstants edgeInDirectionFromCenter:interfaceTransformedDirection]
                      ofRect:[window convertRect:[UIScreen mainScreen].bounds fromWindow:nil]];
  // Align the end point and create a touch path.
  if ([self grey_isVerticalDirection:interfaceTransformedDirection]) {
    endPointInWindowCoords.x = startPointInWindowCoords.x;
  } else {
    endPointInWindowCoords.y = startPointInWindowCoords.y;
  }
  return [self grey_touchPathWithStartPoint:startPointInWindowCoords
                                   endPoint:endPointInWindowCoords
                                   duration:duration
                        shouldCancelInertia:NO];
}

+ (NSArray *)touchPathForDragGestureWithStartPoint:(CGPoint)startPoint
                                          endPoint:(CGPoint)endPoint
                                     cancelInertia:(BOOL)cancelInertia {
  return [self grey_touchPathWithStartPoint:startPoint
                                   endPoint:endPoint
                                   duration:NAN
                        shouldCancelInertia:cancelInertia];
}

+ (NSArray *)touchPathForGestureInView:(UIView *)view
                         withDirection:(GREYDirection)direction
                                length:(CGFloat)length
                    startPointPercents:(CGPoint)startPointPercents
                    outRemainingAmount:(CGFloat *)outRemainingAmountOrNull {
  GREYThrowOnFailedConditionWithMessage(isnan(startPointPercents.x) ||
                                        (startPointPercents.x > 0 && startPointPercents.x < 1),
                                        @"startPointPercents must be NAN or in the range (0, 1) "
                                        @"exclusive");
  GREYThrowOnFailedConditionWithMessage(isnan(startPointPercents.y) ||
                                        (startPointPercents.y > 0 && startPointPercents.y < 1),
                                        @"startPointPercents must be NAN or in the range (0, 1) "
                                        @"exclusive");
  GREYThrowOnFailedConditionWithMessage(length > 0,
                                        @"Scroll length must be positive and greater than zero.");

  GREYDirection interfaceTransformedDirection =
      [self grey_relativeDirectionForCurrentOrientationWithDirection:direction];

  // Pick a startPoint from the visible area of the given view.
  CGRect visibleArea = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
  visibleArea = [view.window convertRect:visibleArea fromWindow:nil];

  // Shave off the unsafe edges to ensure that we pick a valid starting point that is inside the
  // visible area.
  CGRect safeScreenBounds = [view.window convertRect:[UIScreen mainScreen].bounds fromWindow:nil];
  if (CGRectIsEmpty(safeScreenBounds)) {
    return nil;
  }
  UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0f,
                                            [self grey_edgePanDetectionLength],
                                            0.0f,
                                            [self grey_edgePanDetectionLength]);
  safeScreenBounds = [GREYPathGestureUtils grey_rectByAddingEdgeInsets:edgeInset
                                                                toRect:safeScreenBounds];
  // In addition choose a rect that lies completely inside the visible area not on the edges.
  CGRect safeStartPointRect =
      [GREYPathGestureUtils grey_rectByAddingEdgeInsets:UIEdgeInsetsMake(1, 1, 1, 1)
                                                 toRect:CGRectIntersection(visibleArea,
                                                                           safeScreenBounds)];
  if (CGRectIsEmpty(safeStartPointRect)) {
    return nil;
  }
  GREYDirection reverseDirection = [GREYConstants reverseOfDirection:interfaceTransformedDirection];
  GREYContentEdge edgeInReverseDirection =
      [GREYConstants edgeInDirectionFromCenter:reverseDirection];
  CGPoint startPoint = [self grey_pointOnEdge:edgeInReverseDirection ofRect:safeStartPointRect];
  // Update start point if startPointPercents are provided.
  if (!isnan(startPointPercents.x)) {
    startPoint.x =
        safeStartPointRect.origin.x + safeStartPointRect.size.width * startPointPercents.x;
  }
  if (!isnan(startPointPercents.y)) {
    startPoint.y =
        safeStartPointRect.origin.y + safeStartPointRect.size.height * startPointPercents.y;
  }

  // Pick an end point that gives us maximum path length and align as per the direction.
  GREYContentEdge edgeClosestToEndPoint =
      [GREYConstants edgeInDirectionFromCenter:interfaceTransformedDirection];
  CGPoint endPoint = [self grey_pointOnEdge:edgeClosestToEndPoint ofRect:safeScreenBounds];
  CGFloat scrollAmountPossible;
  if ([self grey_isVerticalDirection:interfaceTransformedDirection]) {
    scrollAmountPossible = (CGFloat)fabs(endPoint.y - startPoint.y);
  } else {
    scrollAmountPossible = (CGFloat)fabs(endPoint.x - startPoint.x);
  }
  scrollAmountPossible -= kGREYScrollDetectionLength;
  if (scrollAmountPossible <= 0) {
    // Scroll view is narrow and it is too close to the edge.
    return nil;
  }

  CGFloat amountWillScroll = 0;
  CGFloat remainingAmount = 0;
  CGVector delta = [GREYConstants normalizedVectorFromDirection:interfaceTransformedDirection];
  if (scrollAmountPossible > length) {
    // We have enough space to get the given amount of scroll by a single touch path.
    amountWillScroll = length;
    remainingAmount = 0;
  } else {
    // We will need multiple scrolls to get the required amount.
    amountWillScroll = scrollAmountPossible;
    remainingAmount = length - amountWillScroll;
  }

  if (outRemainingAmountOrNull) {
    *outRemainingAmountOrNull = remainingAmount;
  }
  endPoint = CGPointAddVector(startPoint,
                              CGVectorScale(delta, amountWillScroll + kGREYScrollDetectionLength));
  return [self grey_touchPathWithStartPoint:startPoint
                                   endPoint:endPoint
                                   duration:NAN
                        shouldCancelInertia:YES];
}

#pragma mark - Private

/**
 *  Gives the direction obtained from clockwise rotation of the given @c direction.
 *
 *  @param direction Direction of the rotation.
 *
 *  @return The direction after the rotation.
 */
+ (GREYDirection)grey_directionByClockwiseRotationOfDirection:(GREYDirection)direction {
  switch (direction) {
    case kGREYDirectionUp: return kGREYDirectionRight;
    case kGREYDirectionRight: return kGREYDirectionDown;
    case kGREYDirectionDown: return kGREYDirectionLeft;
    case kGREYDirectionLeft: return kGREYDirectionUp;
  }
}


/**
 *  The relative path direction required to achieve a touch path in the given direction for
 *  the current interface orientation. This method is a no-op on iOS 8.0 and above because
 *  the OS uses variable coordinate system and touch path direction need not be transformed.
 *
 *  @param direction The direction of the current orientation.
 *
 *  @return The relative direction required for the touch path.
 */
+ (GREYDirection)grey_relativeDirectionForCurrentOrientationWithDirection:(GREYDirection)direction {
  if (iOS8_0_OR_ABOVE()) {
    return direction;
  }

  // Transform the direction assuming it exists on portrait orientation and we would like to apply
  // it in the current interface orientation.
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  switch (orientation) {
    case UIInterfaceOrientationPortrait:
      return direction;
    case UIInterfaceOrientationPortraitUpsideDown:
      return [GREYConstants reverseOfDirection:direction];
    case UIInterfaceOrientationLandscapeRight:
      return [self grey_directionByClockwiseRotationOfDirection:direction];
    case UIInterfaceOrientationLandscapeLeft:
      return [GREYConstants reverseOfDirection:
        [self grey_directionByClockwiseRotationOfDirection:direction]];
    case UIInterfaceOrientationUnknown:
      GREYFatalAssertWithMessage(NO, @"Unknown orientation, cannot transform direction.");
      return 0;
  }
}

/**
 *  Returns whether the current direction is vertical or not.
 *
 *  @param direction Current direction to be checked for verticalness.
 *
 *  @return @c YES if the current direction is vertical, else @c NO.
 */
+ (BOOL)grey_isVerticalDirection:(GREYDirection)direction {
  return direction == kGREYDirectionUp || direction == kGREYDirectionDown;
}

/**
 *  Returns a point on the @c edge of the given @c rect.
 *
 *  @param edge The edge of the given @c rect to get the point for.
 *  @param rect The @c rect from which the point is being returned.
 *
 *  @return A CGPoint on the chosen edge of the given @c rect.
 */
+ (CGPoint)grey_pointOnEdge:(GREYContentEdge)edge ofRect:(CGRect)rect {
  CGVector vector =
      [GREYConstants normalizedVectorFromDirection:[GREYConstants directionFromCenterForEdge:edge]];
  return CGPointMake(CGRectCenter(rect).x + vector.dx * (rect.size.width / 2),
                     CGRectCenter(rect).y + vector.dy * (rect.size.height / 2));
}

/**
 *  Standardizes the given @c rect and shrinks (or expands if inset is negative) the given @c rect
 *  by the given @c insets. Note that if width/height is less than the required insets they are
 *  set to zero.
 *
 *  @param insets The insets to standardize the given @c rect.
 *  @param rect   The rect to be standardized.
 *
 *  @return The rect after being standardized.
 */
+ (CGRect)grey_rectByAddingEdgeInsets:(UIEdgeInsets)insets toRect:(CGRect)rect {
  rect = CGRectStandardize(rect);
  rect.origin.x += insets.left;
  rect.origin.y += insets.top;
  // Note that right edge and bottom edge must be adjusted for the change in origin along with
  // applying the given insets.
  if (rect.size.width > insets.right + insets.left) {
    rect.size.width -= insets.right + insets.left;
  } else {
    rect.size.width = 0;
  }
  if (rect.size.height > insets.bottom + insets.top) {
    rect.size.height -= insets.bottom + insets.top;
  } else {
    rect.size.height = 0;
  }
  return rect;
}

/**
 *  Touch path between the given points with the option to cancel the inertia.
 *
 *  @param startPoint    The start point of the touch path.
 *  @param endPoint      The end point of the touch path.
 *  @param duration      How long the gesture should last.
 *                       Can be NAN to indicate that path lengths of fixed magnitude should be used.
 *  @param cancelInertia A check to nullify the inertia in the touch path.
 *
 *  @return A touch path between the two points.
 */
+ (NSArray *)grey_touchPathWithStartPoint:(CGPoint)startPoint
                                 endPoint:(CGPoint)endPoint
                                 duration:(CFTimeInterval)duration
                      shouldCancelInertia:(BOOL)cancelInertia {
  const CGVector deltaVector = CGVectorFromEndPoints(startPoint, endPoint, NO);
  const CGFloat pathLength = CGVectorLength(deltaVector);
  if (pathLength <= kGREYScrollDetectionLength) {
    return nil;
  }

  NSMutableArray *touchPath = [[NSMutableArray alloc] init];
  if (isnan(duration)) {
    // After the start point, rest of the path is divided into equal segments and a touch point is
    // created for each segment.
    NSUInteger totalPoints = (NSUInteger)(pathLength / kGREYDistanceBetweenTwoAdjacentPoints);
    // Compute delta for each point and create a path with it.
    CGFloat deltaX = (endPoint.x - startPoint.x) / totalPoints;
    CGFloat deltaY = (endPoint.y - startPoint.y) / totalPoints;
    for (NSUInteger i = 0; i < totalPoints; i++) {
      CGPoint touchPoint = CGPointMake(startPoint.x + (deltaX * i), startPoint.y + (deltaY * i));
      [touchPath addObject:[NSValue valueWithCGPoint:touchPoint]];
    }
  } else {
    [touchPath addObject:[NSValue valueWithCGPoint:startPoint]];

    // Uses the kinematics equation for distance: d = a*t*t/2 + v*t
    const double initialVelocity = 0;
    const double initialDisplacement = (initialVelocity * duration);
    const double acceleration = (2 * (pathLength - initialDisplacement)) / (duration * duration);

    // Determine the angle which will be used for calculating individual x and y components of the
    // displacement.
    double angleFromXAxis;
    CGPoint deltaPoint = CGPointMake(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
    if (deltaPoint.x == 0) {
      angleFromXAxis = deltaPoint.y > 0 ? M_PI_2 : -M_PI_2;
    } else if (deltaPoint.y == 0) {
      angleFromXAxis = deltaPoint.x > 0 ? 0 : -M_PI;
    } else {
      angleFromXAxis = atan2(deltaPoint.y, deltaPoint.x);
    }

    const double cosAngle = cos(angleFromXAxis);
    const double sinAngle = sin(angleFromXAxis);

    // Duration is divided into fixed intervals which depends on the frequency at which touches are
    // delivered. The first and last interval are always going to be the start and end touch points.
    // Through experiments, it was discovered that not all gestures trigger until there is a
    // minimum of kGREYDistanceBetweenTwoAdjacentPoints movement. For that reason, we find the
    // interval (after first touch point) at which displacement is at least
    // kGREYDistanceBetweenTwoAdjacentPoints and continue the gesture from there.
    // With this approach, touch points after first touch point is at least
    // kGREYDistanceBetweenTwoAdjacentPoints apart and gesture recognizers can detect them
    // correctly.
    const double interval = (1 / kGREYTouchInjectionFrequency);
    // The last interval is always the last touch point so use 2nd to last as the end of loop below.
    const double interval_penultimate = (duration - interval);
    double interval_shift =
        sqrt(((2 * (kGREYDistanceBetweenTwoAdjacentPoints - initialDisplacement)) / acceleration));
    // Negative interval can't be shifted.
    if (interval_shift < 0) {
      interval_shift = 0;
    }
    // Boundary-align interval_shift to interval.
    interval_shift = ceil(interval_shift / interval) * interval;
    // interval_shift past 2nd last interval means only 2 touches will be injected.
    // Adjust it to the last interval.
    if (interval_shift > interval_penultimate) {
      interval_shift = interval_penultimate;
    }

    for (double time = interval_shift; time < interval_penultimate; time += interval) {
      double displacement = ((acceleration * time * time) / 2);
      displacement = displacement + (initialVelocity * time);

      double deltaX = displacement * cosAngle;
      double deltaY = displacement * sinAngle;
      CGPoint touchPoint = CGPointMake((CGFloat)(startPoint.x + deltaX),
                                       (CGFloat)(startPoint.y + deltaY));
      [touchPath addObject:[NSValue valueWithCGPoint:touchPoint]];
    }
  }

  NSValue *endPointValue = [NSValue valueWithCGPoint:endPoint];
  if (cancelInertia) {
    // To cancel inertia, slow down as approaching the end point. This is done by inserting a series
    // of points between the 2nd last and the last point.
    static const NSUInteger kNumSlowTouchesBetweenSecondLastAndLastTouch = 20;

    NSValue *secondLastValue = [touchPath lastObject];
    CGPoint secondLastPoint = [secondLastValue CGPointValue];
    CGVector secondLastToLastVector = CGVectorFromEndPoints(secondLastPoint, endPoint, NO);

    CGFloat slowTouchesVectorScale = (CGFloat)(1.0 / kNumSlowTouchesBetweenSecondLastAndLastTouch);
    CGVector slowTouchesVector = CGVectorScale(secondLastToLastVector, slowTouchesVectorScale);

    CGPoint slowTouchPoint = secondLastPoint;
    for (NSUInteger i = 0; i < (kNumSlowTouchesBetweenSecondLastAndLastTouch - 1); i++) {
      slowTouchPoint = CGPointAddVector(slowTouchPoint, slowTouchesVector);
      [touchPath addObject:[NSValue valueWithCGPoint:slowTouchPoint]];
    }
  }
  [touchPath addObject:endPointValue];

  return touchPath;
}

/**
 *  @return The maximum distance in points from the left edge of the screen that can trigger
 *          "screen edge pan" gesture.
 */
+ (CGFloat)grey_edgePanDetectionLength {
  if (isnan(kCachedScreenEdgePanDetectionLength)) {
    // Use _edgeRegionSize property of UIScreenEdgePanGestureRecognizer on the default
    // UINavigationController object to determine edge pan detection length.
    UIViewController *viewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:viewController];
    UIGestureRecognizer *popGestureRecognizer =
        navigationController.interactivePopGestureRecognizer;
    if ([popGestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
      SEL edgeRegionSizeSelector = NSSelectorFromString(@"_edgeRegionSize");
      float (*edgeRegionSizeIMP)(id, SEL) =
          (void *)[popGestureRecognizer methodForSelector:edgeRegionSizeSelector];
      kCachedScreenEdgePanDetectionLength = edgeRegionSizeIMP(popGestureRecognizer,
                                                              edgeRegionSizeSelector);
    }
  }
  return kCachedScreenEdgePanDetectionLength;
}

@end
