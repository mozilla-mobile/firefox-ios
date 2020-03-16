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

#import "Additions/_UIModalItemsPresentingViewController_GREYAdditions.h"

#include <objc/message.h>

#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"

@implementation _UIModalItemsPresentingViewController_GREYAdditions

+ (void)load {
  @autoreleasepool {
    // Bug is fixed in iOS 9. Swizzle only for prior versions.
    if (!iOS9_OR_ABOVE()) {
      GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
      IMP implementation = [self methodForSelector:@selector(greyswizzled_viewWillDisappear:)];
      Class clazz = NSClassFromString(@"_UIModalItemsPresentingViewController");
      SEL swizzledSEL = @selector(greyswizzled_viewWillDisappear:);
      BOOL swizzled = [swizzler swizzleClass:clazz
                           addInstanceMethod:swizzledSEL
                          withImplementation:implementation
                andReplaceWithInstanceMethod:@selector(viewWillDisappear:)];
      GREYFatalAssertWithMessage(swizzled,
                                 @"Failed to swizzle "
                                 @"_UIModalItemsPresentingViewController::viewWillDisappear:");
    }
  }
}

#pragma mark - Swizzled Implementation

/**
 *  Fixes a bug in _UIModalItemsPresentingViewController that doesn't call through to super in
 *  _UIModalItemsPresentingViewController::viewWillDisappear: implementation.
 *
 *  @param animated A @c BOOL indicating if the view is being animated.
 */
+ (void)greyswizzled_viewWillDisappear:(BOOL)animated {
  struct objc_super superClassStruct = { self, [self superclass] };
  ((void (*)(struct objc_super *, SEL, BOOL))objc_msgSendSuper)
      (&superClassStruct, @selector(viewWillDisappear:), animated);

  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_viewWillDisappear:), animated);
}

@end
