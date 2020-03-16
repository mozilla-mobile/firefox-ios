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

#import "Additions/NSRunLoop+GREYAdditions.h"

#import "Common/GREYConfiguration.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYNSTimerIdlingResource.h"

@implementation NSRunLoop (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzleSuccess =
        [swizzler swizzleClass:self
         replaceInstanceMethod:@selector(addTimer:forMode:)
                    withMethod:@selector(greyswizzled_addTimer:forMode:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle NSRunLoop addTimer:forMode:");
  }
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_addTimer:(NSTimer *)timer forMode:(NSString *)mode {
  if ([mode isEqualToString:NSDefaultRunLoopMode]) {
    // Add a idling resource for short non-repeating timers.
    if (timer.timeInterval == 0 &&
        GREY_CONFIG_DOUBLE(kGREYConfigKeyNSTimerMaxTrackableInterval) >=
        [timer.fireDate timeIntervalSinceNow]) {
      NSString *name = [NSString stringWithFormat:@"IdlingResource For Timer %@", timer];
      [GREYNSTimerIdlingResource trackTimer:timer name:name removeOnIdle:YES];
    }
  }
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_addTimer:forMode:), timer, mode);
}

@end
