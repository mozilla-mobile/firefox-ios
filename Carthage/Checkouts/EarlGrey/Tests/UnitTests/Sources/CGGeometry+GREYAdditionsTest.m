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
#import "GREYBaseTest.h"

@interface CGGeometry_GREYAdditionsTest : GREYBaseTest
@end

@implementation CGGeometry_GREYAdditionsTest

// Always run in portrait mode.
- (void)testCGRectFixedToVariableCoordinates {
  CGRect expectedRect = CGRectMake(10, 20, 15, 30);
  CGRect actualRect = CGRectFixedToVariableScreenCoordinates(CGRectMake(10, 20, 15, 30));
  XCTAssertTrue(CGRectEqualToRect(expectedRect, actualRect));
}

// Always run in portrait mode.
- (void)testCGRectVariableToFixedCoordinates {
  CGRect expectedRect = CGRectMake(10, 20, 15, 30);
  CGRect actualRect = CGRectVariableToFixedScreenCoordinates(CGRectMake(10, 20, 15, 30));
  XCTAssertTrue(CGRectEqualToRect(expectedRect, actualRect));
}

- (void)testCGRectPointToPixel {
  CGFloat scale = [UIScreen mainScreen].scale;
  CGRect expectedRect = CGRectMake(10 * scale, 22 * scale, 12 * scale, 11.5f * scale);
  CGRect actualRect = CGRectPointToPixel(CGRectMake(10, 22, 12, 11.5f));
  XCTAssertTrue(CGRectEqualToRect(expectedRect, actualRect));
}

- (void)testCGRectPixelToPoint {
  CGFloat scale = [UIScreen mainScreen].scale;
  CGRect actualRect = CGRectPixelToPoint(CGRectMake(10, 22, 12, 11.5f));
  XCTAssertEqualWithAccuracy(10 / scale, actualRect.origin.x, 0.005);
  XCTAssertEqualWithAccuracy(22 / scale, actualRect.origin.y, 0.005);
  XCTAssertEqualWithAccuracy(12 / scale, actualRect.size.width, 0.005);
  XCTAssertEqualWithAccuracy(11.5f / scale, actualRect.size.height, 0.005);
}

- (void)testCGRectIntegralInside {
  CGRect expected[][2] = {
    /* input, expected result */

    // integer inputs
    {CGRectMake(10, 10, 20, 30), CGRectMake(10, 10, 20, 30)},
    {CGRectMake(0, 0, 20, 30), CGRectMake(0, 0, 20, 30)},
    {CGRectMake(0, 0, 0, 0), CGRectMake(0, 0, 0, 0)},
    {CGRectMake(10, 9, -10, -10), CGRectMake(0, -1, 10, 10)},

    // inputs w/ non-integer widths (and > 1)
    {CGRectMake(10, 11, (CGFloat)1.51, (CGFloat)1.51), CGRectMake(10, 11, 1, 1)},
    {CGRectMake(10.5, 11.5, (CGFloat)1.51, (CGFloat)1.51), CGRectMake(11, 12, 1, 1)},
    {CGRectMake((CGFloat)10.2, (CGFloat)11.2, (CGFloat)2.8, (CGFloat)2.8),
      CGRectMake(11, 12, 2, 2)},

    // inputs w/ shrinking widths
    {CGRectMake(10.5, 11.5, 20, 30), CGRectMake(11, 12, 19, 29)},
    {CGRectMake(10, 11, (CGFloat)19.5, (CGFloat)20.5), CGRectMake(10, 11, 19, 20)},
    {CGRectMake(10.5, 11.5, (CGFloat)20.4, (CGFloat)21.4), CGRectMake(11, 12, 19, 20)},

    // inputs w/ width < 1
    //// rounded up when it's > 0.5
    {CGRectMake((CGFloat)10.51, (CGFloat)11.51, 1, 1), CGRectMake(11, 12, 1, 1)},
    {CGRectMake(10, 11, (CGFloat)0.51, (CGFloat)0.51), CGRectMake(10, 11, 1, 1)},
    {CGRectMake((CGFloat)10.4, (CGFloat)11.4, (CGFloat).51, (CGFloat).51),
      CGRectMake(11, 12, 1, 1)},
    //// rounded down when it's <= 0.5
    {CGRectMake((CGFloat)10.25, (CGFloat)11.25, .5, .5), CGRectMake(11, 12, 0, 0)},
    {CGRectMake(10.5, 11.5, (CGFloat).99, (CGFloat).99), CGRectMake(11, 12, 1, 1)},
    {CGRectMake(5, 6, (CGFloat)0.5, (CGFloat)0.5), CGRectMake(5, 6, 0, 0)},
    {CGRectMake((CGFloat)5.99, (CGFloat)6.99, (CGFloat).49, (CGFloat).49), CGRectMake(6, 7, 0, 0)},

    // inputs w/ non-shrinking-greater-than-1 widths: the compromised width can compensate itself
    {CGRectMake((CGFloat)5.9, (CGFloat)5.9, (CGFloat)1.1, (CGFloat)1.1), CGRectMake(6, 6, 1, 1)},
    {CGRectMake((CGFloat).95, (CGFloat)0.95, (CGFloat)10.1, (CGFloat)10.1),
      CGRectMake(1, 1, 10, 10)},
    {CGRectMake(1.5, 1.5, 1.5, 1.5), CGRectMake(2, 2, 1, 1)},

    // inputs w/ negative origins and/or negative sizes
    {CGRectMake((CGFloat)-.05, (CGFloat)-.06, (CGFloat)10.1, (CGFloat)11.12),
      CGRectMake(0, 0, 10, 11)},
    {CGRectMake((CGFloat).05, (CGFloat).06, (CGFloat)-10.1, (CGFloat)-11.12),
      CGRectMake(-10, -11, 10, 11)},
    {CGRectMake(-1.5, -2.5, 5.5, 6.5), CGRectMake(-1, -2, 5, 6)},
    {CGRectMake(-1.5, -2.5, (CGFloat)5.49, (CGFloat)6.49), CGRectMake(-1, -2, 4, 5)},
    {CGRectMake((CGFloat)-.05, (CGFloat)-.05, (CGFloat)-10.1, (CGFloat)-11.1),
      CGRectMake(-10, -11, 9, 10)},
    {CGRectMake(2, 4, (CGFloat)-10.5, (CGFloat)-11.5), CGRectMake(-8, -7, 10, 11)},
  };

  int testSize = sizeof(expected) / sizeof(expected[0]);
  for (int i = 0; i < testSize; ++i) {
    XCTAssertTrue(CGRectEqualToRect(CGRectIntegralInside(expected[i][0]), expected[i][1]),
                  @"Test %d: IntegralInside of %@ is not equal to %@, but %@", i + 1,
                  NSStringFromCGRect(expected[i][0]),
                  NSStringFromCGRect(expected[i][1]),
                  NSStringFromCGRect(CGRectIntegralInside(expected[i][0])));
  }
}

- (void)testCGRectIntersectionError {
  CGRect rectBound = CGRectMake(-500, -500, 1000, 1000);

  // this articulated float number will fail when calling CGRectIntersection on 32-bit cpu where
  // the single precision will produce an errorous result.
  CGRect rect1 = CGRectMake(110.666672f, 420, 98.6666641f, 72);
  CGRect rect2 = CGRectMake(420, 110.666672f, 72, 98.6666641f);

#if !CGFLOAT_IS_DOUBLE
  // the built-in function would fail on 32 bit cpu
  XCTAssertFalse(CGRectEqualToRect(CGRectIntersection(rect1, rectBound), rect1));
  XCTAssertFalse(CGRectEqualToRect(CGRectIntersection(rect2, rectBound), rect2));
#else
  // the built-in function would work for 64 bit
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersection(rect1, rectBound), rect1));
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersection(rect2, rectBound), rect2));
#endif

  // the workaround function would always work
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersectionStrict(rect1, rectBound), rect1));
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersectionStrict(rect2, rectBound), rect2));

  // the regular numbers should work
  CGRect rect3 = CGRectMake(420, 110, 72, 98);
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersection(rect3, rectBound), rect3));
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersectionStrict(rect3, rectBound), rect3));

  // the non-normalized rect with floating errors
  CGRect rect4 = CGRectMake(420, 110.666672f, -70, 98.6666641f);
  CGRect rect4_result = CGRectMake(350, 110.666672f, 70, 98.6666641f);
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersectionStrict(rect4, rectBound), rect4_result));
#if !CGFLOAT_IS_DOUBLE
  XCTAssertFalse(CGRectEqualToRect(CGRectIntersection(rect4, rectBound), rect4_result));
#else
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersection(rect4, rectBound), rect4_result));
#endif

  // the non-normalized rect with regular numbers
  CGRect rect5 = CGRectMake(-10, -10, -70, -20);
  CGRect rect5_result = CGRectMake(-80, -30, 70, 20);
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersectionStrict(rect5, rectBound), rect5_result));
  XCTAssertTrue(CGRectEqualToRect(CGRectIntersection(rect5, rectBound), rect5_result));
}

- (void)testCGPointAfterRemovingFractionalPixelsRoundedDown {
  CGFloat scale = [UIScreen mainScreen].scale;
  CGPoint expected = CGPointMake(1.0f / scale, 1.0f / scale);
  CGPoint actual = CGPointAfterRemovingFractionalPixels(CGPointMake(1.1f / scale, 1.5f / scale));
  XCTAssertTrue(CGPointEqualToPoint(expected, actual));
}

- (void)testCGPointAfterRemovingFractionalPixelsRoundedUp {
  CGFloat scale = [UIScreen mainScreen].scale;
  CGPoint expected = CGPointMake(-1.0f / scale, 1.0f / scale);
  CGPoint actual = CGPointAfterRemovingFractionalPixels(CGPointMake(-1.4f / scale, 0.51f / scale));
  XCTAssertTrue(CGPointEqualToPoint(expected, actual));
}

- (void)testCGFloatAfterRemovingFractionalPixels {
  CGFloat scale = [UIScreen mainScreen].scale;

  XCTAssertEqual(1.0f / scale, CGFloatAfterRemovingFractionalPixels(1.0f / scale));
  XCTAssertEqual(1.0f / scale, CGFloatAfterRemovingFractionalPixels(1.1f / scale));
  XCTAssertEqual(2.0f / scale, CGFloatAfterRemovingFractionalPixels(1.8f / scale));
  XCTAssertEqual(2.0f / scale, CGFloatAfterRemovingFractionalPixels(1.51f / scale));
  XCTAssertEqual(-1.0f / scale, CGFloatAfterRemovingFractionalPixels(-1.5f / scale));
  XCTAssertEqual(-2.0f / scale, CGFloatAfterRemovingFractionalPixels(-1.51f / scale));
  XCTAssertEqual(.0f, CGFloatAfterRemovingFractionalPixels(0.4f / scale));
  XCTAssertEqual(.0f, CGFloatAfterRemovingFractionalPixels(-0.4f / scale));
  XCTAssertEqual(1.0f / scale, CGFloatAfterRemovingFractionalPixels(0.51f / scale));
  XCTAssertEqual(-1.0f / scale, CGFloatAfterRemovingFractionalPixels(-0.51f / scale));
}

- (void)expectCGVectorFromEndPointsToReturn:(CGVector)expected
                             withStartPoint:(CGPoint)startPoint
                                   endPoint:(CGPoint)endPoint
                               isNormalized:(BOOL)isNormalized {
  CGVector actual = CGVectorFromEndPoints(startPoint, endPoint, isNormalized);
  XCTAssertEqualWithAccuracy(actual.dx, expected.dx, 0.0001f);
  XCTAssertEqualWithAccuracy(actual.dy, expected.dy, 0.0001f);
}

- (void)testCGVectorFromEndPointsWorksForOrigin {
  const CGVector cgVectorZero = CGVectorMake(0, 0);
  [self expectCGVectorFromEndPointsToReturn:cgVectorZero
                             withStartPoint:CGPointZero
                                   endPoint:CGPointZero
                               isNormalized:YES];
  [self expectCGVectorFromEndPointsToReturn:cgVectorZero
                             withStartPoint:CGPointZero
                                   endPoint:CGPointZero
                               isNormalized:NO];
}

- (void)testCGVectorFromEndPointsWorksForNegativeCoordinates {
  CGPoint start = CGPointMake(-10, -20);
  CGPoint end = CGPointMake(-12, -18);
  // Expected normalized vector is (-√2/2, √2/2).
  [self expectCGVectorFromEndPointsToReturn:CGVectorMake((CGFloat)(-sqrt(2.0) / 2.0),
                                                         (CGFloat)(sqrt(2.0) / 2.0))
                             withStartPoint:start
                                   endPoint:end
                               isNormalized:YES];

}

- (void)testCGVectorFromEndPointsWorksForZeroLength {
  const CGVector cgVectorZero = CGVectorMake(0, 0);
  CGPoint aPoint = CGPointMake(10, 20);
  [self expectCGVectorFromEndPointsToReturn:cgVectorZero
                             withStartPoint:aPoint
                                   endPoint:aPoint
                               isNormalized:YES];
  [self expectCGVectorFromEndPointsToReturn:cgVectorZero
                             withStartPoint:aPoint
                                   endPoint:aPoint
                               isNormalized:NO];
}

- (void)testCGVectorFromEndPointsWorksForNonZeroLength {
  CGPoint aPoint = CGPointMake(10, 20);
  CGPoint anotherPoint = CGPointMake(12, 18);
  // Expected vector is (2, -2).
  [self expectCGVectorFromEndPointsToReturn:CGVectorMake(2, -2)
                             withStartPoint:aPoint
                                   endPoint:anotherPoint
                               isNormalized:NO];
  // Expected normalized vector is (√2/2, -√2/2).
  [self expectCGVectorFromEndPointsToReturn:CGVectorMake((CGFloat)(sqrt(2.0) / 2.0),
                                                         (CGFloat)(-sqrt(2.0) / 2.0))
                             withStartPoint:aPoint
                                   endPoint:anotherPoint
                               isNormalized:YES];
}

- (void)testCGPointIsNull {
  XCTAssertFalse(CGPointIsNull(CGPointMake(0, 0)), @"Point at {0,0} is not null.");
  XCTAssertTrue(CGPointIsNull(CGPointMake(0, NAN)), @"Point at {0,NAN} is null.");
  XCTAssertTrue(CGPointIsNull(CGPointMake(NAN, 0)), @"Point at {NAN,0} is null.");
  XCTAssertTrue(CGPointIsNull(CGPointMake(NAN, NAN)), @"Point at {NAN,NAN} is null.");
}

@end
