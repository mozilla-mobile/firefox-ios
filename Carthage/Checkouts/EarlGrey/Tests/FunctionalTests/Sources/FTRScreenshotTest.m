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

@interface FTRScreenshotTest : FTRBaseIntegrationTest
@end

@implementation FTRScreenshotTest {
  UIInterfaceOrientation _originalOrientation;
}

- (void)setUp {
  [super setUp];
  _originalOrientation = [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)tearDown {
  // Undo orientation changes after test is finished.
  [EarlGrey rotateDeviceToOrientation:(UIDeviceOrientation)_originalOrientation errorOrNil:nil];
  [super tearDown];
}

- (void)testSnapshotAXElementInPortraitMode {
  [self openTestViewNamed:@"Accessibility Views"];

  UIImage *snapshot;
  // Snapshot Accessibility Element.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"OnScreenRectangleElementLabel")]
      performAction:grey_snapshot(&snapshot)];

  // TODO: Verify the content of the image as well.
  CGSize expectedSize = CGSizeMake(64, 128);
  CGFloat expectedScale = [UIScreen mainScreen].scale;
  GREYAssertEqual(expectedSize.width, snapshot.size.width, @"should be equal");
  GREYAssertEqual(expectedSize.height, snapshot.size.height, @"should be equal");
  GREYAssertEqual(expectedScale, snapshot.scale, @"should be equal");

  NSError *error = nil;
  // Snapshot Accessibility Element with zero height should be an error.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ElementWithZeroHeight")]
      performAction:grey_snapshot(&snapshot) error:&error];
  GREYAssertEqualObjects(kGREYInteractionErrorDomain, error.domain, @"should be equal");
}

- (void)testSnapshotAXElementInLandscapeMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
  [self openTestViewNamed:@"Accessibility Views"];

  UIImage *snapshot;
  // Snapshot Accessibility Element.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"OnScreenRectangleElementLabel")]
      performAction:grey_snapshot(&snapshot)];

  // TODO: Verify the content of the image as well.
  CGSize expectedSize = CGSizeMake(64, 128);
  if (!iOS8_0_OR_ABOVE()) {
    // Width and height are interchanged on versions before iOS 8.0
    expectedSize = CGSizeMake(expectedSize.height, expectedSize.width);
  }
  CGFloat expectedScale = [UIScreen mainScreen].scale;
  GREYAssertEqual(expectedSize.width, snapshot.size.width, @"should be equal");
  GREYAssertEqual(expectedSize.height, snapshot.size.height, @"should be equal");
  GREYAssertEqual(expectedScale, snapshot.scale, @"should be equal");

  NSError *error = nil;
  // Snapshot Accessibility Element with zero height should be an error.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ElementWithZeroHeight")]
      performAction:grey_snapshot(&snapshot) error:&error];
  GREYAssertEqualObjects(kGREYInteractionErrorDomain, error.domain, @"should be equal");
}

- (void)testTakeScreenShotForAppStoreInPortraitMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait errorOrNil:nil];
  UIImage *screenshot = [GREYScreenshotUtil takeScreenshotForAppStore];
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self ftr_expectedImageRectForAppStore]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotForAppStoreInPortraitUpsideDownMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown errorOrNil:nil];

  UIImage *screenshot = [GREYScreenshotUtil takeScreenshotForAppStore];
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self ftr_expectedImageRectForAppStore]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotForAppStoreInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];

  UIImage *screenshot = [GREYScreenshotUtil takeScreenshotForAppStore];
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self ftr_expectedImageRectForAppStore]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotForAppStoreInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];

  UIImage *screenshot = [GREYScreenshotUtil takeScreenshotForAppStore];
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self ftr_expectedImageRectForAppStore]),
                 @"Screenshot isn't correct dimension");
}

#pragma mark - Private

- (CGRect)ftr_expectedImageRectForAppStore {
  CGRect screenRect = [UIScreen mainScreen].bounds;
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

  BOOL isLandscape = (orientation == UIInterfaceOrientationLandscapeLeft ||
                      orientation == UIInterfaceOrientationLandscapeRight);
  // Pre-iOS 8, interface is in fixed screen coordinates. We need to rotate it.
  if ([UIDevice currentDevice].systemVersion.intValue < 8 && isLandscape) {
    screenRect = CGRectMake(0, 0, screenRect.size.height, screenRect.size.width);
  }
  return screenRect;
}

@end
