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
#import <EarlGrey/EarlGrey.h>

@interface FTRGeometryTest : FTRBaseIntegrationTest
@end

@implementation FTRGeometryTest

#pragma mark - CGRectFixedToVariableScreenCoordinates

- (void)testCGRectFixedToVariableScreenCoordinates_portrait {
  CGRect actualRect = CGRectFixedToVariableScreenCoordinates(CGRectMake(40, 50, 100, 120));
  GREYAssertTrue(CGRectEqualToRect(actualRect, CGRectMake(40, 50, 100, 120)), @"should be true");
}

- (void)testCGRectFixedToVariableScreenCoordinates_portraitUpsideDown {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown errorOrNil:nil];

  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat width = CGRectGetWidth(screenBounds);
  CGFloat height = CGRectGetHeight(screenBounds);
  CGRect actualRect = CGRectFixedToVariableScreenCoordinates(CGRectMake(40, 50, 100, 120));
  CGRect expectedRect = CGRectMake(width - 40 - 100, height - 50 - 120, 100, 120);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");
}

- (void)testCGRectFixedToVariableScreenCoordinates_landscapeRight {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];

  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat width = CGRectGetWidth(screenBounds);
  CGFloat height = CGRectGetHeight(screenBounds);

  // Bottom left => Top left
  CGRect rectInFixed = CGRectMake(0, (iOS8_0_OR_ABOVE() ? width : height) - 20, 10, 20);
  CGRect actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
  CGRect expectedRect = CGRectMake(0, 0, 20, 10);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");

  // Bottom right => Bottom left
  rectInFixed = CGRectMake((iOS8_0_OR_ABOVE() ? height : width) - 10,
                           (iOS8_0_OR_ABOVE() ? width : height) - 20,
                           10, 20);
  actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
  expectedRect = CGRectMake(0, (iOS8_0_OR_ABOVE() ? height : width) - 10, 20, 10);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");

  // Top left => Top right
  actualRect = CGRectFixedToVariableScreenCoordinates(CGRectMake(0, 0, 10, 20));
  expectedRect = CGRectMake((iOS8_0_OR_ABOVE() ? width : height) - 20, 0, 20, 10);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");

  // Top right => bottom right
  rectInFixed = CGRectMake((iOS8_0_OR_ABOVE() ? height : width) - 10, 0, 10, 20);
  actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
  expectedRect = CGRectMake((iOS8_0_OR_ABOVE() ? width : height) - 20,
                            (iOS8_0_OR_ABOVE() ? height : width) - 10,
                            20, 10);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");
}

- (void)testCGRectFixedToVariableScreenCoordinates_landscapeLeft {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];

  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat width = CGRectGetWidth(screenBounds);
  CGFloat height = CGRectGetHeight(screenBounds);
  CGRect rectInFixed = CGRectMake((iOS8_0_OR_ABOVE() ? height : width) - 120, 50, 120, 100);
  CGRect actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
  CGRect expectedRect = CGRectMake(50, 0, 100, 120);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");

  rectInFixed = CGRectMake(0, (iOS8_0_OR_ABOVE() ? width : height), 0, 0);
  actualRect = CGRectFixedToVariableScreenCoordinates(rectInFixed);
  expectedRect =
      CGRectMake((iOS8_0_OR_ABOVE() ? width : height), (iOS8_0_OR_ABOVE() ? height : width), 0, 0);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");
}

#pragma mark - CGRectVariableToFixedScreenCoordinates

- (void)testCGRectVariableToFixedScreenCoordinates_portrait {
  CGRect actualRect = CGRectVariableToFixedScreenCoordinates(CGRectMake(40, 50, 100, 120));
  GREYAssertTrue(CGRectEqualToRect(actualRect, CGRectMake(40, 50, 100, 120)), @"should be true");
}

- (void)testCGRectVariableToFixedScreenCoordinates_portraitUpsideDown {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown errorOrNil:nil];

  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat width = CGRectGetWidth(screenBounds);
  CGFloat height = CGRectGetHeight(screenBounds);
  CGRect actualRect = CGRectVariableToFixedScreenCoordinates(CGRectMake(40, 50, 100, 120));
  CGRect expectedRect = CGRectMake(width - 40 - 100, height - 50 - 120, 100, 120);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");
}


- (void)testCGRectVariableToFixedScreenCoordinates_landscapeRight {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];

  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat width = CGRectGetWidth(screenBounds);
  CGFloat height = CGRectGetHeight(screenBounds);
  CGRect actualRect = CGRectVariableToFixedScreenCoordinates(CGRectMake(0, 0, 0, 0));
  CGRect expectedRect = CGRectMake(0, (iOS8_0_OR_ABOVE() ? width : height), 0, 0);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");
}

- (void)testCGRectVariableToFixedScreenCoordinates_landscapeLeft {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];

  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat width = CGRectGetWidth(screenBounds);
  CGFloat height = CGRectGetHeight(screenBounds);
  CGRect actualRect = CGRectVariableToFixedScreenCoordinates(CGRectMake(50, 0, 100, 120));
  CGRect expectedRect = CGRectMake((iOS8_0_OR_ABOVE() ? height : width) - 120, 50, 120, 100);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");

  CGRect rectInVariable =
      CGRectMake((iOS8_0_OR_ABOVE() ? width : height), (iOS8_0_OR_ABOVE() ? height : width), 0, 0);
  actualRect = CGRectVariableToFixedScreenCoordinates(rectInVariable);
  expectedRect = CGRectMake(0, (iOS8_0_OR_ABOVE() ? width : height), 0, 0);
  GREYAssertTrue(CGRectEqualToRect(actualRect, expectedRect), @"should be true");
}

@end
