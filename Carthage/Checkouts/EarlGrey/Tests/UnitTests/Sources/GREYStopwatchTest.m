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
#import "GREYBaseTest.h"

@interface GREYStopwatchTest : XCTestCase

@end

@implementation GREYStopwatchTest

- (void)testLappingWhenWatchIsStartedAndStopped {
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  XCTAssertThrows([stopwatch lapAndReturnTime], @"Stopwatch lapping cannot be done when the "
                                                @"stopwatch wasn't turned on");
  [stopwatch start];
  XCTAssertNoThrow([stopwatch lapAndReturnTime]);
  [stopwatch stop];
  XCTAssertThrows([stopwatch lapAndReturnTime], @"Stopwatch lapping cannot be done when the "
                                                @"stopwatch is off.");
}

- (void)testCheckingElapsedTimeWhenWatchIsStartedAndStopped {
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  XCTAssertThrows([stopwatch elapsedTime], @"Stopwatch has to be started to get elapsed time.");
  [stopwatch start];
  [stopwatch stop];
  NSTimeInterval interval;
  XCTAssertNoThrow(interval = [stopwatch elapsedTime]);
  [stopwatch start];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, FALSE);
  NSTimeInterval noStopInterval = [stopwatch elapsedTime];
  XCTAssertNotEqual(noStopInterval, interval, @"Should be able to get elapsed time without "
                                              @"calling stop");
  [stopwatch stop];
  XCTAssertGreaterThan([stopwatch elapsedTime], noStopInterval, @"Since the stopwatch was stopped "
                                                                @"later than when the interval "
                                                                @"was taken, elapsed time should "
                                                                @"be greater than the interval.");
}

- (void)testStopwatchTimeOnDifferentActionsBeingPerformedBetweenChecks {
  GREYStopwatch *noActionStopwatch = [[GREYStopwatch alloc] init];
  [noActionStopwatch start];
  [noActionStopwatch stop];
  NSTimeInterval intervalOnNoActionPerformed = [noActionStopwatch elapsedTime];

  GREYStopwatch *someActionStopwatch = [[GREYStopwatch alloc] init];
  [someActionStopwatch start];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, FALSE);
  [someActionStopwatch stop];
  NSTimeInterval intervalOnSomeActionPerformed = [someActionStopwatch elapsedTime];
  XCTAssertNotEqual(intervalOnSomeActionPerformed,
                    intervalOnNoActionPerformed,
                    @"Interval on some action being performed was not greater than one without.");
}

- (void)testStopwatchWithinStopwatch {
  GREYStopwatch *outerStopwatch = [[GREYStopwatch alloc] init];
  [outerStopwatch start];
  GREYStopwatch *innerStopwatch = [[GREYStopwatch alloc] init];
  [innerStopwatch start];
  BOOL someValue = YES;
  NSAssert(someValue, @"This value is always positive");
  [innerStopwatch stop];
  NSTimeInterval timeForInnerStopwatch = [innerStopwatch elapsedTime];
  [outerStopwatch stop];
  NSTimeInterval timeForOuterStopwatch = [outerStopwatch elapsedTime];
  XCTAssertGreaterThan(timeForOuterStopwatch,
                       timeForInnerStopwatch,
                       @"The outer stop watch, should have a higher value.");
}

- (void)testStopwatchTimesWithASleepBetweenThem {
  GREYStopwatch *benchmarkStopwatch = [[GREYStopwatch alloc] init];
  GREYStopwatch *testStopwatch = [[GREYStopwatch alloc] init];
  [benchmarkStopwatch start];
  [testStopwatch start];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, FALSE);
  [benchmarkStopwatch stop];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, FALSE);
  [testStopwatch stop];
  NSTimeInterval difference =
      [testStopwatch elapsedTime] - [benchmarkStopwatch elapsedTime];
  XCTAssertGreaterThan(difference, 0.01f, @"The sleep should provide at least a difference of 0.1 "
                                          @"second.");
}

- (void)testStopwatchStoppingWithoutStarting {
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  XCTAssertThrows([stopwatch stop], @"Calling stop on a stopwatch that isn't started will fail.");
  XCTAssertThrows([stopwatch elapsedTime], @"Calling elapsed time stop on a stopwatch that"
                                           @" isn't started will return a NaN");
}

- (void)testStopwatchWithLappingAndAddingStartAndStopElapsedTimes {
  GREYStopwatch *lappingStopwatch = [[GREYStopwatch alloc] init];
  [lappingStopwatch start];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, FALSE);
  NSTimeInterval lapTime = [lappingStopwatch lapAndReturnTime];
  [lappingStopwatch stop];
  NSTimeInterval elapsedTime = [lappingStopwatch elapsedTime];
  XCTAssertGreaterThan(elapsedTime, lapTime, @"Elapsed has to be greater than lap time");
  [lappingStopwatch start];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, FALSE);
  lapTime = [lappingStopwatch lapAndReturnTime];
  [lappingStopwatch stop];
  NSTimeInterval secondElapsedTime = elapsedTime + [lappingStopwatch elapsedTime];
  XCTAssertGreaterThan(secondElapsedTime, lapTime, @"Elapsed has to be greater than lap time");
  XCTAssertGreaterThan(secondElapsedTime, elapsedTime, @"Progressive elapsed times checks must be "
                                                       @"greater than the previous ones.");
  [lappingStopwatch start];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, FALSE);
  lapTime = [lappingStopwatch lapAndReturnTime];
  [lappingStopwatch stop];
  NSTimeInterval thirdElapsedTime = secondElapsedTime + [lappingStopwatch elapsedTime];
  XCTAssertGreaterThan(thirdElapsedTime, lapTime, @"Elapsed has to be greater than lap time");
  XCTAssertGreaterThan(thirdElapsedTime, secondElapsedTime, @"Progressive elapsed times checks "
                                                            @"must be greater than the previous "
                                                            @"ones.");
}

@end
