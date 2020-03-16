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

#import "Additions/UIAnimation+GREYAdditions.h"

#include <objc/runtime.h>

#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYAppStateTracker.h"

@implementation UIAnimation_GREYAdditions

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];

    IMP implementation = [self instanceMethodForSelector:@selector(greyswizzled_markStart:)];
    BOOL swizzled = [swizzler swizzleClass:NSClassFromString(@"UIAnimation")
                         addInstanceMethod:@selector(greyswizzled_markStart:)
                        withImplementation:implementation
              andReplaceWithInstanceMethod:NSSelectorFromString(@"markStart:")];
    GREYFatalAssertWithMessage(swizzled, @"Failed to swizzle UIAnimation markStart:");

    IMP swizzledIMP = [self instanceMethodForSelector:@selector(greyswizzled_markStop)];
    swizzled = [swizzler swizzleClass:NSClassFromString(@"UIAnimation")
                    addInstanceMethod:@selector(greyswizzled_markStop)
                   withImplementation:swizzledIMP
         andReplaceWithInstanceMethod:NSSelectorFromString(@"markStop")];
    GREYFatalAssertWithMessage(swizzled, @"Failed to swizzle UIAnimation markStop");
  }
}

#pragma mark - Swizzled Implementation

/**
 *  Invoked by UIKit on the start of an animation. This is invoked, for example, when a user invokes
 *  UIScrollView::setContentEnd:finished:.
 *
 *  @param startTime The start time for the animation.
 */
- (void)greyswizzled_markStart:(double)startTime {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, self);
  objc_setAssociatedObject(self,
                           @selector(greyswizzled_markStart:),
                           object,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_markStart:), startTime);
}

/**
 *  Invoked by UIKit on the end of an animation. This is invoked, for example, after the animation
 *  triggered by a UIScrollView::setContentEnd:finished: is finished.
 */
- (void)greyswizzled_markStop {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(greyswizzled_markStart:));
  UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, object);
  objc_setAssociatedObject(self,
                           @selector(greyswizzled_markStart:),
                           nil,
                           OBJC_ASSOCIATION_ASSIGN);
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_markStop));
}

@end
