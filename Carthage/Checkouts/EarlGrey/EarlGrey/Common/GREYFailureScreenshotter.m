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

#import "Common/GREYFailureScreenshotter.h"

#import "Common/GREYConfiguration.h"
#import "Common/GREYScreenshotUtil+Internal.h"
#import "Common/GREYScreenshotUtil.h"
#import "Common/GREYVisibilityChecker.h"

NSString *const kScreenshotAtFailure = @"Screenshot At Failure";
NSString *const kScreenshotBeforeImage = @"Visibility Checker Most Recent Before Image";
NSString *const kScreenshotExpectedAfterImage =
    @"Visibility Checker Most Recent Expected After Image";
NSString *const kScreenshotActualAfterImage =
    @"Visibility Checker Most Recent Actual After Image";

static inline NSInteger getNextScreenshotCount() {
  static NSInteger count = 0;
  count++;
  return count;
}

@implementation GREYFailureScreenshotter

+ (NSDictionary *)generateAppScreenshotsWithPrefix:(NSString *)screenshotPrefix
                                           failure:(NSString *)failureName {
  NSString *screenshotDir = GREY_CONFIG_STRING(kGREYConfigKeyArtifactsDirLocation);
  NSString *uniqueSubDirName =
      [NSString stringWithFormat:@"%@-%@-%@",
                                 screenshotPrefix,
                                 failureName,
                                 [[NSUUID UUID] UUIDString]];
  screenshotDir = [screenshotDir stringByAppendingPathComponent:uniqueSubDirName];
  return [self generateAppScreenshotsWithPrefix:screenshotPrefix
                                        failure:failureName
                                  screenshotDir:screenshotDir];
}

+ (NSDictionary *)generateAppScreenshotsWithPrefix:(NSString *)screenshotPrefix
                                           failure:(NSString *)failureName
                                     screenshotDir:(NSString *)screenshotDir {
  NSMutableDictionary *appScreenshots = [[NSMutableDictionary alloc] init];

  // Save and log screenshot and before and after images (if available).
  NSString *screenshotPath;
  NSString *fileName;
  UIImage *screenshot;

  NSString *screenshotName;
  if (screenshotPrefix) {
    screenshotName = screenshotPrefix;
  } else {
    screenshotName =
        [NSString stringWithFormat:@"unknown_%ld", (unsigned long)getNextScreenshotCount()];
  }

  screenshot = [GREYScreenshotUtil grey_takeScreenshotAfterScreenUpdates:NO];
  if (screenshot) {
    fileName = [NSString stringWithFormat:@"%@.png", screenshotName];
    screenshotPath = [GREYScreenshotUtil saveImageAsPNG:screenshot
                                                 toFile:fileName
                                            inDirectory:screenshotDir];
    appScreenshots[kScreenshotAtFailure] = screenshotPath;
  }

  screenshot = [GREYVisibilityChecker grey_lastActualBeforeImage];
  if (screenshot) {
    fileName = [NSString stringWithFormat:@"%@_before.png", screenshotName];
    screenshotPath = [GREYScreenshotUtil saveImageAsPNG:screenshot
                                                 toFile:fileName
                                            inDirectory:screenshotDir];
    appScreenshots[kScreenshotBeforeImage] = screenshotPath;
  }

  screenshot = [GREYVisibilityChecker grey_lastExpectedAfterImage];
  if (screenshot) {
    fileName = [NSString stringWithFormat:@"%@_after_expected.png", screenshotName];
    screenshotPath = [GREYScreenshotUtil saveImageAsPNG:screenshot
                                                 toFile:fileName
                                            inDirectory:screenshotDir];
    appScreenshots[kScreenshotExpectedAfterImage] = screenshotPath;
  }

  screenshot = [GREYVisibilityChecker grey_lastActualAfterImage];
  if (screenshot) {
    fileName = [NSString stringWithFormat:@"%@_after_actual.png", screenshotName];
    screenshotPath = [GREYScreenshotUtil saveImageAsPNG:screenshot
                                                 toFile:fileName
                                            inDirectory:screenshotDir];
    appScreenshots[kScreenshotActualAfterImage] = screenshotPath;
  }

  return appScreenshots;
}

@end
