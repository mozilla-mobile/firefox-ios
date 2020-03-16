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

#import "Additions/UIGestureRecognizer+GREYAdditions.h"

#import <UIKit/UIGestureRecognizerSubclass.h>
#include <objc/runtime.h>

#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYAppStateTrackerObject.h"

static Class gKeyboardPinchGestureRecognizerClass;

@implementation UIGestureRecognizer (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    gKeyboardPinchGestureRecognizerClass = NSClassFromString(@"UIKeyboardPinchGestureRecognizer");
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzled = [swizzler swizzleClass:self
                     replaceInstanceMethod:NSSelectorFromString(@"_setDirty")
                                withMethod:@selector(greyswizzled_setDirty)];
    GREYFatalAssertWithMessage(swizzled, @"Failed to swizzle UIGestureRecognizer _setDirty");

    swizzled = [swizzler swizzleClass:self
                replaceInstanceMethod:NSSelectorFromString(@"_resetGestureRecognizer")
                           withMethod:@selector(greyswizzled_resetGestureRecognizer)];
    GREYFatalAssertWithMessage(swizzled,
                               @"Failed to swizzle UIGestureRecognizer _resetGestureRecognizer");

    swizzled = [swizzler swizzleClass:self
                replaceInstanceMethod:@selector(setState:)
                           withMethod:@selector(greyswizzled_setState:)];
    GREYFatalAssertWithMessage(swizzled, @"Failed to swizzle UIGestureRecognizer setState:");
  }
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_setDirty {
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_setDirty));
  if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad ||
      ![self isKindOfClass:gKeyboardPinchGestureRecognizerClass]) {
    GREYAppStateTrackerObject *object =
    TRACK_STATE_FOR_OBJECT(kGREYPendingGestureRecognition, self);
    objc_setAssociatedObject(self,
                             @selector(greyswizzled_setState:),
                             object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}

- (void)greyswizzled_resetGestureRecognizer {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(greyswizzled_setState:));
  UNTRACK_STATE_FOR_OBJECT(kGREYPendingGestureRecognition, object);
  objc_setAssociatedObject(self,
                           @selector(greyswizzled_setState:),
                           nil,
                           OBJC_ASSOCIATION_ASSIGN);
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_resetGestureRecognizer));
}

- (void)greyswizzled_setState:(UIGestureRecognizerState)state {
  // This is needed only for a few cases where reset isn't called on the gesture recognizer when
  // keyboard is shown. We need to manually untrack when state is set to failed.
  if (state == UIGestureRecognizerStateFailed) {
    GREYAppStateTrackerObject *object =
        objc_getAssociatedObject(self, @selector(greyswizzled_setState:));
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingGestureRecognition, object);
    objc_setAssociatedObject(self,
                             @selector(greyswizzled_setState:),
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setState:), state);
}

@end

