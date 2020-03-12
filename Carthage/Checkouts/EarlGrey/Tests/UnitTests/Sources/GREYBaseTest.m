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

#import "GREYBaseTest.h"

#import <OCMock/OCMock.h>
#import <objc/message.h>

#import "Additions/UIApplication+GREYAdditions.h"
#import <EarlGrey/GREYConfiguration.h>
#import "Common/GREYScreenshotUtil+Internal.h"
#import "Common/GREYSwizzler.h"
#import "GREYExposedForTesting.h"

// A list containing UIImage that are returned by each invocation of takeScreenShot of
// GREYScreenshotUtil. After a screenshot is returned (in-order), it is removed from this list.
static NSMutableArray *gScreenShotsToReturnByGREYScreenshotUtil;

// Real, original / unmocked shared UIApplication.
static id gRealSharedApplication;

// A CGRect value to use for instantiating views
const CGRect kTestRect = { { 0.0f, 0.0f }, { 10.0f, 10.0f } };

#pragma mark - GREYUTFailureHandler

@implementation GREYUTFailureHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  NSMutableString *errorString = [[NSMutableString alloc] init];
  [errorString appendString:@"Exception thrown during unit test: "];
  [errorString appendFormat:@"%@\nReason: %@",
                             [exception name],
                             [exception reason]];
  if (details) {
    [errorString appendFormat:@"\nDetails:\n%@", details];
  }
  NSLog(@"%@", errorString);
  [exception raise];
}

@end

#pragma mark - GREYScreenshotUtil

// We don't want to take screenshot during unit tests or save an image for that matter.
@implementation GREYScreenshotUtil (UnitTest)

+ (void)load {
  @autoreleasepool {
    Class screenshotUtilClass = [GREYScreenshotUtil class];
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    SEL fakeSelector = @selector(greyswizzled_fakeTakeScreenshotAfterScreenUpdates:);
    BOOL success = [swizzler swizzleClass:screenshotUtilClass
                       replaceClassMethod:@selector(grey_takeScreenshotAfterScreenUpdates:)
                               withMethod:fakeSelector];
    NSAssert(success, @"Couldn't swizzle GREYScreenshotUtil takeScreenshot");

    success =
        [swizzler swizzleClass:screenshotUtilClass
            replaceClassMethod:@selector(saveImageAsPNG:toFile:inDirectory:)
                    withMethod:@selector(greyswizzled_fakeSaveImageAsPNG:toFile:inDirectory:)];
    NSAssert(success, @"Couldn't swizzle GREYScreenshotUtil saveImageAsPNG:toFile:");

    gScreenShotsToReturnByGREYScreenshotUtil = [[NSMutableArray alloc] init];
  }
}

#pragma mark - Swizzled Implementation

+ (UIImage *)greyswizzled_fakeTakeScreenshotAfterScreenUpdates:(BOOL)afterScreenUpdates {
  UIImage *image;

  if (gScreenShotsToReturnByGREYScreenshotUtil.count > 0) {
    image = [gScreenShotsToReturnByGREYScreenshotUtil firstObject];
    [gScreenShotsToReturnByGREYScreenshotUtil removeObjectAtIndex:0];
  }
  return image;
}

+ (NSString *)greyswizzled_fakeSaveImageAsPNG:(UIImage *)image
                                     toFile:(NSString *)filename
                                inDirectory:(NSString *)directoryPath {
  return nil;
}

@end

#pragma mark - GREYBaseTest

@implementation GREYBaseTest {
  id _mockSharedApplication;
}

+ (void)initialize {
  if (!gRealSharedApplication) {
    gRealSharedApplication = [UIApplication sharedApplication];
  }
}

- (void)setUp {
  [super setUp];

  self.activeRunLoopMode = NSDefaultRunLoopMode;

  // Setup Mocking for UIApplication.
  _mockSharedApplication = OCMClassMock([UIApplication class]);
  id classMockApplication = OCMClassMock([UIApplication class]);
  [OCMStub([classMockApplication sharedApplication]) andReturn:_mockSharedApplication];

  // Runloop mode is required by thread executor so we always call real implementation here.
  OCMStub([_mockSharedApplication grey_activeRunLoopMode])
      .andCall(self, @selector(activeRunLoopMode));

  // Resets configuration in case it was changed by the previous test.
  [[GREYConfiguration sharedInstance] reset];

  // We don't want verbose logging in unit test as it can interfere with some timeout related tests.
  [EarlGrey setFailureHandler:[[GREYUTFailureHandler alloc] init]];

  // Force busy polling so that the thread executor and waiting conditions do not allow the
  // main thread to sleep.
  [GREYUIThreadExecutor sharedInstance].forceBusyPolling = YES;
}

- (void)tearDown {
  [EarlGrey setFailureHandler:nil];
  self.activeRunLoopMode = nil;
  [gScreenShotsToReturnByGREYScreenshotUtil removeAllObjects];

  [[NSOperationQueue mainQueue] cancelAllOperations];
  [[GREYAppStateTracker sharedInstance] grey_clearState];
  // Registered idling resources can leak from one failed test to another if they're not removed on
  // failure. This can cause cascading failures. As a safety net, we remove them here.
  [[GREYUIThreadExecutor sharedInstance] grey_resetIdlingResources];
  // Disable analytics for unit tests. Do this in tearDown so it is not affected by tests
  // that reset configuration.
  [[GREYConfiguration sharedInstance] setValue:@NO forConfigKey:kGREYConfigKeyAnalyticsEnabled];

  // This drains all the pending operations in the main queue.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  _mockSharedApplication = nil;
  [super tearDown];
}

- (void)addToScreenshotListReturnedByScreenshotUtil:(UIImage *)screenshot {
  [gScreenShotsToReturnByGREYScreenshotUtil addObject:screenshot];
}

- (id)mockSharedApplication {
  NSAssert([UIApplication sharedApplication] == _mockSharedApplication,
           @"UIApplication sharedApplication isn't a mock.");
  return _mockSharedApplication;
}

- (id)realSharedApplication {
  return gRealSharedApplication;
}

@end
