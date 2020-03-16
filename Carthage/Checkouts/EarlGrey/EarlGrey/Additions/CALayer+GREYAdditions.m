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

#import "Additions/CALayer+GREYAdditions.h"

#include <objc/message.h>

#import "Additions/CAAnimation+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYAppStateTrackerObject.h"

@implementation CALayer (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzleSuccess = [swizzler swizzleClass:self
                           replaceInstanceMethod:@selector(setNeedsDisplay)
                                      withMethod:@selector(greyswizzled_setNeedsDisplay)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CALayer setNeedsDisplay");

    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(setNeedsDisplayInRect:)
                                 withMethod:@selector(greyswizzled_setNeedsDisplayInRect:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CALayer setNeedsDisplayInRect");

    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(setNeedsLayout)
                                 withMethod:@selector(greyswizzled_setNeedsLayout)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CALayer setNeedsLayout");

    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(addAnimation:forKey:)
                                 withMethod:@selector(greyswizzled_addAnimation:forKey:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CALayer addAnimation:forKey:");

    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(setSpeed:)
                                 withMethod:@selector(greyswizzled_setSpeed:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CALayer setSpeed:");

    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(removeAnimationForKey:)
                                 withMethod:@selector(greyswizzled_removeAnimationForKey:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CALayer removeAnimationForKey:");

    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(removeAllAnimations)
                                 withMethod:@selector(greyswizzled_removeAllAnimations)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle CALayer removeAllAnimations");
  }
}

- (void)grey_adjustAnimationToAllowableRange:(CAAnimation *)animation {
  if (!GREY_CONFIG_BOOL(kGREYConfigKeyCALayerModifyAnimations)) {
    return;
  }

  CFTimeInterval maxAllowableAnimationDuration =
      (CFTimeInterval)GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration);
  if ([animation duration] > maxAllowableAnimationDuration) {
    GREYLogVerbose(@"Adjusting repeatCount and repeatDuration to 0 for animation %@", animation);
    GREYLogVerbose(@"Adjusting duration to %f for animation %@",
                   maxAllowableAnimationDuration,
                   animation);
    animation.duration = maxAllowableAnimationDuration;
  }
  if (animation.duration != 0) {
    CFTimeInterval allowableRepeatDuration = maxAllowableAnimationDuration - animation.duration;
    float allowableRepeatCount = (float)(allowableRepeatDuration / animation.duration);
    // Either repeatCount or repeatDuration is specified, not both.
    if (animation.repeatDuration > allowableRepeatDuration) {
      GREYLogVerbose(@"Adjusting repeatDuration to %f for animation %@",
                     allowableRepeatDuration,
                     animation);
      animation.repeatDuration = allowableRepeatDuration;
    } else if (animation.repeatCount > allowableRepeatCount) {
      GREYLogVerbose(@"Adjusting repeatCount to %f for animation %@",
                     allowableRepeatCount,
                     animation);
      animation.repeatCount = allowableRepeatCount;
    }
  }
}

- (void)grey_pauseAnimations {
  if (self.animationKeys.count > 0) {
    // Keep track of animation keys that have been idled. Used for resuming tracking.
    NSMutableSet *pausedAnimationKeys = [self grey_pausedAnimationKeys];
    if (!pausedAnimationKeys) {
      pausedAnimationKeys = [[NSMutableSet alloc] init];
      objc_setAssociatedObject(self,
                               @selector(grey_pauseAnimations),
                               pausedAnimationKeys,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // Untrack all the paused animation attached to self.
    for (NSString *key in self.animationKeys) {
      CAAnimation *animation = [self animationForKey:key];
      if (animation) {
        [animation grey_untrack];
        [pausedAnimationKeys addObject:key];
      }
    }
  }

  // Paused animations attached to sublayers.
  for (CALayer *sublayer in self.sublayers) {
    [sublayer grey_pauseAnimations];
  }
}

- (void)grey_resumeAnimations {
  NSMutableSet *pausedAnimationKeys = [self grey_pausedAnimationKeys];
  for (NSString *key in pausedAnimationKeys) {
    CAAnimation *animation = [self animationForKey:key];
    if ([animation grey_animationState] == kGREYAnimationStarted) {
      [animation grey_trackForDurationOfAnimation];
    }
  }
  // We don't need paused animation keys anymore, discard all the keys.
  [pausedAnimationKeys removeAllObjects];

  // Resume sublayer animations that are paused.
  for (CALayer *sublayer in self.sublayers) {
    if (sublayer.speed != 0) {
      [sublayer grey_resumeAnimations];
    }
  }
}

#pragma mark - Swizzled Implementations

- (void)greyswizzled_removeAllAnimations {
  for (NSString *key in [self animationKeys]) {
    CAAnimation *animation = [self animationForKey:key];
    [animation grey_untrack];
  }
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_removeAllAnimations));
}

- (void)greyswizzled_removeAnimationForKey:(NSString *)key {
  if (key) {
    CAAnimation *animation = [self animationForKey:key];
    [animation grey_untrack];
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_removeAnimationForKey:), key);
}

- (void)greyswizzled_addAnimation:(CAAnimation *)animation forKey:(NSString *)key {
  [self grey_adjustAnimationToAllowableRange:animation];

  // If no key is given, give it one.  We need a key to track what animations have been idled.
  NSString *outKey = key;
  if (!outKey) {
    outKey = [NSString stringWithFormat:@"grey_%p_%p_%f", self, animation, CACurrentMediaTime()];
  }
  // At this point, the app could be in idle state and the next runloop drain may trigger this
  // animation so track this LAYER (not animation) until next runloop drain.
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, self);
  dispatch_async(dispatch_get_main_queue(), ^{
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, object);
  });
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_addAnimation:forKey:), animation, outKey);
}

- (void)greyswizzled_setSpeed:(float)speed {
  if (speed == 0 && self.speed != 0) {
    [self grey_pauseAnimations];
  } else if (speed != 0 && self.speed == 0) {
    [self grey_resumeAnimations];
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setSpeed:), speed);
}

- (void)greyswizzled_setNeedsDisplayInRect:(CGRect)invalidRect {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, self);
  // Next runloop drain will perform the draw pass.
  dispatch_async(dispatch_get_main_queue(), ^{
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, object);
  });
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setNeedsDisplayInRect:), invalidRect);
}

- (void)greyswizzled_setNeedsDisplay {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, self);
  // Next runloop drain will perform the draw pass.
  dispatch_async(dispatch_get_main_queue(), ^{
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, object);
  });
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_setNeedsDisplay));
}

- (void)greyswizzled_setNeedsLayout {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, self);
  // Next runloop drain will perform the layout pass.
  dispatch_async(dispatch_get_main_queue(), ^ {
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, object);
  });
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_setNeedsLayout));
}

#pragma mark - Internal Methods Exposed For Testing

- (NSMutableSet *)grey_pausedAnimationKeys {
  return objc_getAssociatedObject(self, @selector(grey_pauseAnimations));
}

@end
