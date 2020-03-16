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

#import "Additions/CAAnimation+GREYAdditions.h"

#include <objc/runtime.h>

#import "Additions/NSObject+GREYAdditions.h"
#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Delegate/GREYCAAnimationDelegate.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYAppStateTrackerObject.h"

@implementation CAAnimation (GREYAdditions)

// TODO: Investigate moving all swizzled methods in +load to +initialize.
+ (void)load {
  @autoreleasepool {
    // Swizzle the animation's CAAnimation::delegate and CAAnimation::setDelegate methods
    // with EarlGrey's custom methods for tracking the CAAnimationDelegate:animationDidStart: and
    // CAAnimationDelegate:animationDidStop:finished: methods on the delegate.
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzleSuccess = [swizzler swizzleClass:self
                           replaceInstanceMethod:@selector(delegate)
                                      withMethod:@selector(greyswizzled_delegate)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CAAnimation delegate");
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(setDelegate:)
                                 withMethod:@selector(greyswizzled_setDelegate:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CAAnimation setDelegate:");
  }
}

- (void)greyswizzled_setDelegate:(id)delegate {
  id surrogate = [GREYCAAnimationDelegate surrogateDelegateForDelegate:delegate];
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setDelegate:), surrogate);
}

- (void)grey_setAnimationState:(GREYCAAnimationState)state {
  objc_setAssociatedObject(self,
                           @selector(grey_animationState),
                           @(state),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  if (state == kGREYAnimationStarted) {
    [self grey_trackForDurationOfAnimation];
  } else {
    [self grey_untrack];
  }
}

- (GREYCAAnimationState)grey_animationState {
  NSNumber *animationState = objc_getAssociatedObject(self, @selector(grey_animationState));
  if (!animationState) {
    return kGREYAnimationPendingStart;
  } else {
    return animationState.unsignedIntegerValue;
  }
}

- (void)grey_trackForDurationOfAnimation {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, self);
  objc_setAssociatedObject(self,
                           @selector(grey_trackForDurationOfAnimation),
                           object,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  CFTimeInterval animRuntimeTime =
      self.duration + self.repeatCount * self.duration + self.repeatDuration;
  // Add extra padding to the animation runtime just as a safeguard. This comes into play when
  // animatonDidStop delegate is not invoked before the expected end-time is reached.
  // The state is then automatically cleared for this animation as it should have finished by now.
  animRuntimeTime += MIN(animRuntimeTime, 1.0);
  // EarlGrey swizzles this method. Call directly to the original implementation.
  INVOKE_ORIGINAL_IMP4(void,
                       @selector(greyswizzled_performSelector:withObject:afterDelay:inModes:),
                       @selector(grey_untrack),
                       nil,
                       animRuntimeTime,
                       @[ NSRunLoopCommonModes ]);
}

- (void)grey_untrack {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(grey_trackForDurationOfAnimation));
  UNTRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, object);
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(grey_untrack)
                                             object:nil];
}

/**
 *  @return The Swizzled EarlGrey animation delegate. When called, a surrogate is returned which
 *          has delegate methods swizzled for EarlGrey synchronization.
 */
- (id)greyswizzled_delegate {
  id delegate = INVOKE_ORIGINAL_IMP(id, @selector(greyswizzled_delegate));
  return [GREYCAAnimationDelegate surrogateDelegateForDelegate:delegate];
}

@end
