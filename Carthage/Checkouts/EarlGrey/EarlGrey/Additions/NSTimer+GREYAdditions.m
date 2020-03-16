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

#import "Additions/NSTimer+GREYAdditions.h"

#import "Common/GREYConfiguration.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYNSTimerIdlingResource.h"

@implementation NSTimer (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    SEL originalSel = @selector(scheduledTimerWithTimeInterval:invocation:repeats:);
    SEL swizzledSel = @selector(greyswizzled_scheduledTimerWithTimeInterval:invocation:repeats:);

    BOOL swizzleSuccess = [swizzler swizzleClass:self
                              replaceClassMethod:originalSel
                                      withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle "
                               @"NSTimer::scheduledTimerWithTimeInterval:invocation:repeats:");

    originalSel = @selector(scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:);
    swizzledSel =
        @selector(greyswizzled_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:);
    swizzleSuccess = [swizzler swizzleClass:self
                         replaceClassMethod:originalSel
                                 withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle NSTimer's %@", NSStringFromSelector(originalSel));
  }
}

#pragma mark - Swizzled Implementation

+ (NSTimer *)greyswizzled_scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                              invocation:(NSInvocation *)invocation
                                                 repeats:(BOOL)repeats {
  NSTimer *timer = INVOKE_ORIGINAL_IMP3(NSTimer *,
      @selector(greyswizzled_scheduledTimerWithTimeInterval:invocation:repeats:),
      interval,
      invocation,
      repeats);

  if (!repeats && GREY_CONFIG_DOUBLE(kGREYConfigKeyNSTimerMaxTrackableInterval) >= interval) {
    [GREYNSTimerIdlingResource trackTimer:timer
                                     name:[NSString stringWithFormat:@"Tracking Timer %@", timer]
                             removeOnIdle:YES];
  }
  return timer;
}

+ (NSTimer *)greyswizzled_scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                                  target:(id)aTarget
                                                selector:(SEL)aSelector
                                                userInfo:(id)userInfo
                                                 repeats:(BOOL)repeats {
  SEL swizzledSEL =
      @selector(greyswizzled_scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:);
  NSTimer *timer = INVOKE_ORIGINAL_IMP5(NSTimer *,
                                        swizzledSEL,
                                        interval,
                                        aTarget,
                                        aSelector,
                                        userInfo,
                                        repeats);
  if (!repeats && GREY_CONFIG_DOUBLE(kGREYConfigKeyNSTimerMaxTrackableInterval) >= interval) {
    [GREYNSTimerIdlingResource trackTimer:timer
                                     name:[NSString stringWithFormat:@"Tracking Timer %@", timer]
                             removeOnIdle:YES];
  }
  return timer;
}

@end
