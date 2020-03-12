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

#import "Additions/CGGeometry+GREYAdditions.h"

#include <tgmath.h>

#import "Common/GREYDefines.h"

#pragma mark - Constants

// Extern constants.
const CGPoint GREYCGPointNull = {NAN, NAN};

#pragma mark - CGVector

CGFloat CGVectorLength(CGVector vector) {
  return (CGFloat)sqrt(pow(vector.dx, 2) + pow(vector.dy, 2));
}

CGPoint CGPointAddVector(CGPoint point, CGVector vector) {
  return CGPointMake(point.x + vector.dx, point.y + vector.dy);
}

CGVector CGVectorScale(CGVector vector, CGFloat scale) {
  return CGVectorMake(vector.dx * scale, vector.dy * scale);
}

CGVector CGVectorFromEndPoints(CGPoint startPoint, CGPoint endPoint, BOOL normalize) {
  CGVector vector = CGVectorMake(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
  if (normalize) {
    CGFloat length = CGVectorLength(vector);
    if (length > 0) {
      vector = CGVectorScale(vector, 1.0f / length);
    }
  }
  return vector;
}

#pragma mark - CGPoint

CGPoint CGPointMultiply(CGPoint inPoint, double amount) {
  return CGPointMake((CGFloat)(inPoint.x * amount), (CGFloat)(inPoint.y * amount));
}

CGPoint CGPointToPixel(CGPoint positionInPixels) {
  return CGPointMultiply(positionInPixels, [UIScreen mainScreen].scale);
}

CGPoint CGPixelToPoint(CGPoint positionInPoints) {
  return CGPointMultiply(positionInPoints, 1.0 / [UIScreen mainScreen].scale);
}

CGPoint CGPointAfterRemovingFractionalPixels(CGPoint cgpointInPoints) {
  return CGPointMake(CGFloatAfterRemovingFractionalPixels(cgpointInPoints.x),
                     CGFloatAfterRemovingFractionalPixels(cgpointInPoints.y));
}

CGPoint CGPointFixedToVariable(CGPoint pointInFixed) {
  CGAffineTransform transformToVariable =
      CGAffineTransformForFixedToVariable([UIApplication sharedApplication].statusBarOrientation);
  return CGPointApplyAffineTransform(pointInFixed, transformToVariable);
}

CGPoint CGPointVariableToFixed(CGPoint pointInVariable) {
  CGAffineTransform transformToVariable =
      CGAffineTransformForFixedToVariable([UIApplication sharedApplication].statusBarOrientation);
  CGAffineTransform transformToFixed = CGAffineTransformInvert(transformToVariable);
  return CGPointApplyAffineTransform(pointInVariable, transformToFixed);
}

BOOL CGPointIsNull(CGPoint point) {
  return isnan(point.x) || isnan(point.y);
}

#pragma mark - CGFloat

/**
 *  @todo Update this for touch events on iPhone 6 Plus where it does not produce the intended
 *        result because the touch grid is the same as the native screen resolution of 1080x1920,
 *        while UI rendering is done at 1242x2208, and downsampled to 1080x1920.
 */
CGFloat CGFloatAfterRemovingFractionalPixels(CGFloat floatInPoints) {
  double pointToPixelScale = [[UIScreen mainScreen] scale];

  // Fractional pixel values aren't useful and often arise due to floating point calculation
  // overflow (i.e. mantissa can only hold so many digits).
  double wholePixel = 0;
  double fractionPixel = modf(floatInPoints * pointToPixelScale, &wholePixel);
  if (islessgreater(fractionPixel, 0)) {
    if (signbit(fractionPixel)) {
      fractionPixel = fractionPixel < -0.5 ? -1.0 : 0;
    } else {
      fractionPixel = fractionPixel > 0.5 ? 1 : 0;
    }
  }
  wholePixel = (wholePixel + fractionPixel) / pointToPixelScale;
  return (CGFloat)wholePixel;
}

#pragma mark - CGRect

CGPoint CGRectCenter(CGRect rect) {
  return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

double CGRectArea(CGRect rect) {
  return (double)CGRectGetHeight(rect) * (double)CGRectGetWidth(rect);
}

CGRect CGRectScaleAndTranslate(CGRect inRect, double amount) {
  return CGRectMake((CGFloat)(inRect.origin.x * amount),
                    (CGFloat)(inRect.origin.y * amount),
                    (CGFloat)(inRect.size.width * amount),
                    (CGFloat)(inRect.size.height * amount));
}

CGRect CGRectPointToPixel(CGRect rectInPoints) {
  return CGRectScaleAndTranslate(rectInPoints, [UIScreen mainScreen].scale);
}

CGRect CGRectPixelToPoint(CGRect rectInPixel) {
  return CGRectScaleAndTranslate(rectInPixel, 1.0 / [UIScreen mainScreen].scale);
}

CGRect CGRectFixedToVariableScreenCoordinates(CGRect rectInFixedCoordinates) {
  UIScreen *screen = [UIScreen mainScreen];
  CGRect rectInVariableCoordinates = CGRectNull;
  if ([screen respondsToSelector:@selector(coordinateSpace)] &&
      [screen respondsToSelector:@selector(fixedCoordinateSpace)]) {
    rectInVariableCoordinates = [screen.fixedCoordinateSpace convertRect:rectInFixedCoordinates
                                                       toCoordinateSpace:screen.coordinateSpace];
  } else { // Pre-iOS 8.
    CGAffineTransform transform =
        CGAffineTransformForFixedToVariable([UIApplication sharedApplication].statusBarOrientation);
    rectInVariableCoordinates = CGRectApplyAffineTransform(rectInFixedCoordinates, transform);
  }
  return rectInVariableCoordinates;
}

CGRect CGRectVariableToFixedScreenCoordinates(CGRect rectInVariableCoordinates) {
  UIScreen *screen = [UIScreen mainScreen];
  CGRect rectInFixedCoordinates = CGRectNull;
  if ([screen respondsToSelector:@selector(coordinateSpace)] &&
      [screen respondsToSelector:@selector(fixedCoordinateSpace)]) {
    rectInFixedCoordinates =
        [screen.fixedCoordinateSpace convertRect:rectInVariableCoordinates
                             fromCoordinateSpace:screen.coordinateSpace];
  } else { // Pre-iOS 8.
    CGAffineTransform transform =
        CGAffineTransformForFixedToVariable([UIApplication sharedApplication].statusBarOrientation);
    // Invert so these transformation to go from fixed->variable to variable->fixed.
    transform = CGAffineTransformInvert(transform);
    rectInFixedCoordinates = CGRectApplyAffineTransform(rectInVariableCoordinates, transform);
  }
  return rectInFixedCoordinates;
}

CGRect CGRectIntersectionStrict(CGRect rect1, CGRect rect2) {
  CGRect rect = CGRectIntersection(rect1, rect2);
#if !CGFLOAT_IS_DOUBLE
  // CGRectGetWidth and CGRectGetHeight will return normalized results, this will ensure the
  // resulting rect is no greater than the given sources
  rect.size.width = MIN(CGRectGetWidth(rect),
                        MIN(CGRectGetWidth(rect1), CGRectGetWidth(rect2)));
  rect.size.height = MIN(CGRectGetHeight(rect),
                         MIN(CGRectGetHeight(rect1), CGRectGetHeight(rect2)));
#endif
  return rect;
}

CGRect CGRectIntegralInside(CGRect rectInPixels) {
  CGFloat newIntegralX = grey_ceil(CGRectGetMinX(rectInPixels));
  // Adjust horizontal pixel boundary alignment.
  CGFloat newIntegralWidth = CGRectGetMaxX(rectInPixels) - newIntegralX;
  rectInPixels.size.width = newIntegralWidth > 1.0
      ? grey_floor(newIntegralWidth)
      : grey_ceil(rectInPixels.size.width - 0.5);   // rounded up when it's <1 and >0.5 per iOS
  rectInPixels.origin.x = newIntegralX;

  // Adjust vertical pixel boundary alignment.
  CGFloat newIntegralY = grey_ceil(CGRectGetMinY(rectInPixels));
  CGFloat newIntegralHeight = CGRectGetMaxY(rectInPixels) - newIntegralY;
  rectInPixels.size.height = newIntegralHeight > 1.0
      ? grey_floor(newIntegralHeight)
      : grey_ceil(rectInPixels.size.height - 0.5);  // rounded up when it's <1 and >=0.5 per iOS
  rectInPixels.origin.y = newIntegralY;

  return rectInPixels;
}

#pragma mark - CGAffineTransform

CGAffineTransform CGAffineTransformForFixedToVariable(UIInterfaceOrientation orientation) {
  UIScreen *screen = [UIScreen mainScreen];
  CGAffineTransform transform = CGAffineTransformIdentity;
  if (orientation == UIInterfaceOrientationLandscapeLeft) {
    // Rotate pi/2
    transform = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
    transform = CGAffineTransformConcat(transform,
                                        CGAffineTransformTranslate(CGAffineTransformIdentity,
                                                                   CGRectGetHeight(screen.bounds),
                                                                   0));
  } else if (orientation == UIInterfaceOrientationLandscapeRight) {
    // Rotate -pi/2
    transform = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
    transform = CGAffineTransformConcat(transform,
                                        CGAffineTransformTranslate(CGAffineTransformIdentity,
                                                                   0,
                                                                   CGRectGetWidth(screen.bounds)));
  } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
    transform = CGAffineTransformMakeTranslation(-CGRectGetWidth(screen.bounds),
                                                 -CGRectGetHeight(screen.bounds));
    transform =
        CGAffineTransformConcat(transform,
                                CGAffineTransformScale(CGAffineTransformIdentity, -1.0, -1.0));
  }
  return transform;
}
