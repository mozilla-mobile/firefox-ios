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

#import "Event/GREYZeroToleranceTimer.h"

#import "Common/GREYFatalAsserts.h"
#import "Common/GREYThrowDefines.h"

@implementation GREYZeroToleranceTimer {
  // The target that will handle timeouts fired from this timer.
  id<GREYZeroToleranceTimerTarget> _target;
  // The internal dispatch timer used for firing timeouts.
  dispatch_source_t _timer;
  // Holds the NSProcessInfo's activity id for high-precision timer.
  NSObject *_activityID;
}

- (instancetype)initWithInterval:(CFTimeInterval)interval
                          target:(id<GREYZeroToleranceTimerTarget>)target {
  GREYThrowOnNilParameter(target);

  self = [super init];
  if (self) {
    _target = target;
    _activityID =
        [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityLatencyCritical
                                                       reason:@"Using high-precision timer."];
    _timer = [GREYZeroToleranceTimer grey_scheduleZeroToleranceTimerWithInterval:interval
                                                                         handler:^{
      [_target timerFiredWithZeroToleranceTimer:self];
    }];
  }
  return self;
}

- (void)dealloc {
  [self invalidate];
}

- (void)invalidate {
  if (_timer) {
    dispatch_source_cancel(_timer);
    _timer = nil;
  }
  if (_activityID) {
    [[NSProcessInfo processInfo] endActivity:_activityID];
    _activityID = nil;
  }
  _target = nil;
}

/**
 *  Schedules a zero tolerance dispatch timer with the given interval and timeout handler.
 *
 *  @param interval The interval in seconds from current time for the timer to fire in.
 *  @param handler  The handler to be invoked on timeout.
 *
 *  @return A dispatch_source_t pointing to the newly created timer.
 */
+ (dispatch_source_t)grey_scheduleZeroToleranceTimerWithInterval:(CFTimeInterval)interval
                                                         handler:(void(^)(void))handler {
  dispatch_source_t timer =
      dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
  GREYFatalAssertWithMessage(timer, @"Timer could not be created");

  dispatch_time_t fireTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
  dispatch_source_set_timer(timer,
                            fireTime,
                            (uint64_t)(interval * NSEC_PER_SEC),
                            (uint64_t)(0));
  dispatch_source_set_event_handler(timer, ^{
    handler();
  });
  dispatch_resume(timer);
  return timer;
}

@end
