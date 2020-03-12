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

#import "Additions/UIWindow+GREYAdditions.h"

#include <objc/runtime.h>

#import "Additions/UIViewController+GREYAdditions.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYAppStateTracker.h"

@implementation UIWindow (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzleSuccess = [swizzler swizzleClass:self
                           replaceInstanceMethod:@selector(setRootViewController:)
                                      withMethod:@selector(greyswizzled_setRootViewController:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIWindow setRootViewController");
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(setHidden:)
                                 withMethod:@selector(greyswizzled_setHidden:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIWindow setHidden");
  }
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_setHidden:(BOOL)hidden {
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setHidden:), hidden);
  // Call after invoking original implementation so that the hidden property is reflected in self.
  [self.rootViewController grey_trackAsRootViewControllerForWindow:self];
}

- (void)greyswizzled_setRootViewController:(UIViewController *)rootViewController {
  UIViewController *prevRootViewController = [self rootViewController];
  // Don't track the same rootviewcontroller more than once.
  if (prevRootViewController != rootViewController) {
    [prevRootViewController grey_trackAsRootViewControllerForWindow:nil];
    [rootViewController grey_trackAsRootViewControllerForWindow:self];
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setRootViewController:), rootViewController);
}

@end
