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

#import "Common/GREYStopwatch.h"

#include <mach/mach_time.h>

#import "Common/GREYThrowDefines.h"

@implementation GREYStopwatch {
  /**
   *  The last time GREYStopwatch::start was called on the stopwatch.
   */
  uint64_t _startTime;
  /**
   *  The last time GREYStopwatch::stop was called on the stopwatch.
   */
  uint64_t _stopTime;
  /**
   *  The last time GREYStopwatch::lapAndReturnTime was called on the stopwatch.
   */
  uint64_t _lastLapTime;
  /**
   *  A Boolean to check if GREYStopwatch::start was called without a corresponding
   *  GREYStopwatch::stop.
   */
  BOOL _isRunning;
}

- (void)start {
  _startTime = mach_absolute_time();
  _isRunning = YES;
}

- (void)stop {
  // Save the time first to prevent any performance overhead.
  uint64_t stoppedTime = mach_absolute_time();
  GREYThrowOnFailedConditionWithMessage(_isRunning, @"Stopwatch must have been started.");
  _stopTime = stoppedTime;
  _isRunning = NO;
}

- (NSTimeInterval)elapsedTime {
  // Save the time first to prevent any performance overhead.
  uint64_t elapsedTime = mach_absolute_time();
  GREYThrowOnFailedConditionWithMessage(_startTime != 0, @"Stopwatch was never started.");
  if (_stopTime && _stopTime >= _startTime) {
    return grey_timeIntervalBetween(_startTime, _stopTime);
  } else {
    return grey_timeIntervalBetween(_startTime, elapsedTime);
  }
}

- (NSTimeInterval)lapAndReturnTime {
  // Save the time first to prevent any performance overhead.
  uint64_t lapTime = mach_absolute_time();
  GREYThrowOnFailedConditionWithMessage(_isRunning, @"Stopwatch must have been started.");
  uint64_t startTime = _lastLapTime ? _lastLapTime : _startTime;
  _lastLapTime = lapTime;
  return grey_timeIntervalBetween(startTime, lapTime);
}

#pragma mark - private

/**
 *  Obtain the difference in seconds between two provided times (each in terms of the Mach absolute
 *  time unit).
 *
 *  @param startTime The lesser of the two times to be measured between in terms of the Mach
 *                   absolute time unit.
 *  @param endTime   The greater of the two times being measured between in terms of the Mach
 *                   absolute time unit.
 *
 *  @return an NSTimeInterval with the interval in seconds between @c startTime and @c endTime.
 */
static inline NSTimeInterval grey_timeIntervalBetween(uint64_t startTime, uint64_t endTime) {
  static mach_timebase_info_data_t info;

  if (info.denom == 0) {
    (void) mach_timebase_info(&info);
  }

  NSTimeInterval intervalInSeconds =
      (double)((endTime - startTime) * info.numer) / (info.denom * NSEC_PER_SEC);
  return intervalInSeconds;
}

@end
