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

#import <EarlGrey/GREYScreenshotUtil.h>
#import "GREYBaseTest.h"

@interface GREYScreenshotUtilTest : GREYBaseTest
@end

@implementation GREYScreenshotUtilTest

- (void)testExceptionOnNilImage {
  NSString *filename = @"dummyFileName";
  NSString *screenshotDir = GREY_CONFIG_STRING(kGREYConfigKeyArtifactsDirLocation);

  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertThrowsSpecificNamed([GREYScreenshotUtil greyswizzled_fakeSaveImageAsPNG:nil
                                                                            toFile:filename
                                                                       inDirectory:screenshotDir],
                               NSException,
                               NSInternalInconsistencyException);
}

- (void)testExceptionOnNilFileName {
  UIImage *image = [[UIImage alloc] init];
  NSString *screenshotDir = GREY_CONFIG_STRING(kGREYConfigKeyArtifactsDirLocation);

  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertThrowsSpecificNamed([GREYScreenshotUtil greyswizzled_fakeSaveImageAsPNG:image
                                                                            toFile:nil
                                                                       inDirectory:screenshotDir],
                               NSException,
                               NSInternalInconsistencyException);
}

- (void)testExceptionOnNilScreenshotDir {
  UIImage *image = [[UIImage alloc] init];
  NSString *filename = @"dummyFileName";

  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertThrowsSpecificNamed([GREYScreenshotUtil greyswizzled_fakeSaveImageAsPNG:image
                                                                            toFile:filename
                                                                       inDirectory:nil],
                               NSException,
                               NSInternalInconsistencyException);
}

- (void)testScreenshotSucceedsOnCorrectValues {
  UIImage *image = [[UIImage alloc] init];
  NSString *filename = @"dummyFileName";
  NSString *screenshotDir = GREY_CONFIG_STRING(kGREYConfigKeyArtifactsDirLocation);

  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertNoThrow([GREYScreenshotUtil greyswizzled_fakeSaveImageAsPNG:image
                                                                toFile:filename
                                                           inDirectory:screenshotDir]);
}

- (void)testSnapshotInvalidUIView {
  UIView *element = [[UIView alloc] initWithFrame:CGRectMake(1, 1, 0, 5)];
  UIImage *image = [GREYScreenshotUtil snapshotElement:element];
  XCTAssertNil(image);

  element = [[UIView alloc] initWithFrame:CGRectMake(2, 2, 5, 0)];
  image = [GREYScreenshotUtil snapshotElement:element];
  XCTAssertNil(image);
}

- (void)testSnapshotInvalidAccessibilityElement {
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  UIAccessibilityElement *element =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:container];
  element.accessibilityFrame = CGRectMake(1, 1, 0, 5);
  UIImage *image = [GREYScreenshotUtil snapshotElement:element];
  XCTAssertNil(image);

  element.accessibilityFrame = CGRectMake(2, 2, 5, 0);
  image = [GREYScreenshotUtil snapshotElement:element];
  XCTAssertNil(image);
}

@end
