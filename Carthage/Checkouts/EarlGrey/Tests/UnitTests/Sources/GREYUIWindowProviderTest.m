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

#import "Common/GREYAppleInternals.h"
#import <EarlGrey/GREYConfiguration.h>
#import <EarlGrey/GREYElementMatcherBlock.h>
#import <EarlGrey/GREYMatchers.h>
#import "Provider/GREYUIWindowProvider.h"
#import "GREYBaseTest.h"

static NSMutableArray *gAppWindows;

@interface GREYUIWindowProviderTest : GREYBaseTest

@end

@implementation GREYUIWindowProviderTest {
  GREYElementMatcherBlock *niceMatcher;
}

- (void)setUp {
  [super setUp];

  gAppWindows = [[NSMutableArray alloc] init];
  [[[self.mockSharedApplication stub] andReturn:gAppWindows] windows];
}

- (void)testDataEnumeratorContainsAllApplicationWindows {
  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithAllWindows];
  XCTAssertEqual(0u,
                 [[[provider dataEnumerator] allObjects] count],
                 @"App doesn't contain any windows");

  [gAppWindows addObject:[[UIWindow alloc] init]];
  XCTAssertEqualObjects(gAppWindows,
                        [[provider dataEnumerator] allObjects],
                        @"App should contain exactly one window");

  [gAppWindows addObject:[[UIWindow alloc] init]];
  // Since we added the 2nd window last, it will be on top of all windows so the ordering needs
  // to be reversed since window provider will return windows from top - bottom level.
  XCTAssertEqualObjects([[gAppWindows reverseObjectEnumerator] allObjects],
                        [[provider dataEnumerator] allObjects],
                        @"App should contain two windows");
}

- (void)testDataEnumeratorContainsWindowInitializedWith {
  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithWindows:gAppWindows];
  [gAppWindows addObject:[[UIWindow alloc] init]];
  XCTAssertEqual(0u,
                 [[[provider dataEnumerator] allObjects] count],
                 @"App shouldn't contain any windows because initializing provider with data should"
                  "make a copy of that data");

  provider = [GREYUIWindowProvider providerWithWindows:gAppWindows];
  XCTAssertEqualObjects(gAppWindows,
                        [[provider dataEnumerator] allObjects],
                        @"App should contain same windows as initialized with.");

  [gAppWindows addObject:[[UIWindow alloc] init]];
  provider = [GREYUIWindowProvider providerWithWindows:gAppWindows];
  XCTAssertEqualObjects(gAppWindows,
                        [[provider dataEnumerator] allObjects],
                        @"App should contain same windows as initialized with.");
}

- (void)testDataEnumeratorContainsKeyWindow {
  UIWindow *window = [[UIWindow alloc] init];
  [[[self.mockSharedApplication stub] andReturn:window] keyWindow];

  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithAllWindows];
  XCTAssertEqual(1u,
                 [[[provider dataEnumerator] allObjects] count],
                 @"App should contain exactly one window");
  XCTAssertEqualObjects(window,
                        [[[provider dataEnumerator] allObjects] firstObject],
                        @"Only keyWindow should be in the window provider");
}

- (void)testDataEnumeratorContainsStatusBarWindow {
  [[GREYConfiguration sharedInstance] setValue:@YES
                                  forConfigKey:kGREYConfigKeyIncludeStatusBarWindow];

  UIWindow *window = [[UIWindow alloc] init];
  [[[self.mockSharedApplication stub] andReturn:window] statusBarWindow];

  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithAllWindows];
  XCTAssertEqual(1u,
                 [[[provider dataEnumerator] allObjects] count],
                 @"App should contain exactly one window");
  XCTAssertEqualObjects(window,
                        [[[provider dataEnumerator] allObjects] firstObject],
                        @"Only statusBarWindow should be in the window provider");
}

- (void)testDataEnumeratorContainsAppDelegateWindow {
  UIWindow *window = [[UIWindow alloc] init];
  id delegate = [OCMockObject mockForProtocol:@protocol(UIApplicationDelegate)];
  [[[self.mockSharedApplication stub] andReturn:delegate] delegate];
  [[[delegate stub] andReturn:window] window];

  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithAllWindows];
  XCTAssertEqual(1u,
                 [[[provider dataEnumerator] allObjects] count],
                 @"App should contain exactly one window");
  XCTAssertEqualObjects(window,
                        [[[provider dataEnumerator] allObjects] firstObject],
                        @"Only delegate window should be in the window provider");
}

- (void)testDataEnumeratorContainsAllWindows {
  [[GREYConfiguration sharedInstance] setValue:@YES
                                  forConfigKey:kGREYConfigKeyIncludeStatusBarWindow];

  UIWindow *window1 = [[UIWindow alloc] init];
  [window1 setWindowLevel:UIWindowLevelNormal];
  UIWindow *window2 = [[UIWindow alloc] init];
  [window2 setWindowLevel:UIWindowLevelNormal];
  UIWindow *window3 = [[UIWindow alloc] init];
  [window3 setWindowLevel:UIWindowLevelStatusBar];
  UIWindow *window4 = [[UIWindow alloc] init];
  [window4 setWindowLevel:UIWindowLevelAlert];

  [gAppWindows addObject:window1];
  id delegate = [OCMockObject mockForProtocol:@protocol(UIApplicationDelegate)];
  [[[self.mockSharedApplication stub] andReturn:delegate] delegate];
  [[[delegate stub] andReturn:window2] window];
  [[[self.mockSharedApplication stub] andReturn:window3] statusBarWindow];
  [[[self.mockSharedApplication stub] andReturn:window4] keyWindow];

  NSArray *expected = @[ window4, window3, window2, window1 ];

  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithAllWindows];
  XCTAssertEqualObjects(expected,
                        [[provider dataEnumerator] allObjects],
                        @"Provider should return all registered windows.");
}

@end
