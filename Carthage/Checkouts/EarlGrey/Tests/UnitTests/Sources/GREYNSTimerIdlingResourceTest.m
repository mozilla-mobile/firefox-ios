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

#import <OCMock/OCMock.h>

#import <EarlGrey/GREYNSTimerIdlingResource.h>
#import "GREYBaseTest.h"

@interface GREYNSTimerIdlingResourceTest : GREYBaseTest
@end

@implementation GREYNSTimerIdlingResourceTest {
  NSInteger timerElapseInvocationCount;
}

- (void)testRepeatingShortTimersAreNotTracked {
  NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                target:self
                                              selector:@selector(timerElapsed:)
                                              userInfo:nil
                                               repeats:YES];
  timerElapseInvocationCount = 0;
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual(timerElapseInvocationCount, 0);
  [timer invalidate];
}

- (void)testMultipleShortTimersCanBeTracked {
  [NSTimer scheduledTimerWithTimeInterval:0.1
                                   target:self
                                 selector:@selector(timerElapsed:)
                                 userInfo:nil
                                  repeats:NO];
  [NSTimer scheduledTimerWithTimeInterval:0.2
                                   target:self
                                 selector:@selector(timerElapsed:)
                                 userInfo:nil
                                  repeats:NO];
  [NSTimer scheduledTimerWithTimeInterval:0.3
                                   target:self
                                 selector:@selector(timerElapsed:)
                                 userInfo:nil
                                  repeats:NO];

  timerElapseInvocationCount = 0;
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual(timerElapseInvocationCount, 3);
}

- (void)testMultipleTimersAreTrackedAccurately {
  [NSTimer scheduledTimerWithTimeInterval:0.1
                                   target:self
                                 selector:@selector(timerElapsed:)
                                 userInfo:nil
                                  repeats:NO];
  // Scheduling a timer that does not get tracked by using a large (> 1.5) timeout value.
  NSTimer *longTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                        target:self
                                                      selector:@selector(timerElapsed:)
                                                      userInfo:nil
                                                       repeats:NO];
  [NSTimer scheduledTimerWithTimeInterval:0.3
                                   target:self
                                 selector:@selector(timerElapsed:)
                                 userInfo:nil
                                  repeats:NO];

  timerElapseInvocationCount = 0;
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:3.0];
  XCTAssertEqual(timerElapseInvocationCount, 2);
  XCTAssertTrue(longTimer.isValid,
                @"Since EarlGrey does not track |longTimer| it must still be valid and ready to"
                @" fire.");
  [longTimer invalidate];
}

- (void)testTimersAddedToRunLoopAreTracked {
  NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1]
                                            interval:0
                                              target:self
                                            selector:@selector(timerElapsed:)
                                            userInfo:nil
                                             repeats:NO];
  [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
  timerElapseInvocationCount = 0;
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual(timerElapseInvocationCount, 1);
}

- (void)testTimersNotAddedToMainRunLoopAreNotTracked {
  NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]
                                            interval:0
                                              target:self
                                            selector:@selector(timerElapsed:)
                                            userInfo:nil
                                             repeats:NO];
  [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
  timerElapseInvocationCount = 0;
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual(timerElapseInvocationCount, 0);
  XCTAssertTrue(timer.isValid,
                @"Since EarlGrey does not track timers not added with NSDefaultRunLoopMode it"
                @" must still be valid (ready to fire).");
  [timer invalidate];
}

- (void)testLongTimersAddedToRunLoopAreNotTracked {
  NSTimer *longTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:2.0]
                                                interval:0
                                                  target:self
                                                selector:@selector(timerElapsed:)
                                                userInfo:nil
                                                 repeats:NO];
  [[NSRunLoop mainRunLoop] addTimer:longTimer forMode:NSDefaultRunLoopMode];
  timerElapseInvocationCount = 0;
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual(timerElapseInvocationCount, 0);
  XCTAssertTrue(longTimer.isValid,
                @"Since EarlGrey does not track |longTimer| it must still be valid and ready"
                @" to fire.");
  [longTimer invalidate];
}

// TODO: Enable this test after the timers being created by the selector
// performSelector:withObject:afterDelay: are also tracked.
- (void)disabled_testPerformActionWithSelectorAfterDelayIsTracked {
  [self performSelector:@selector(timerElapsed:) withObject:nil afterDelay:0.1];
  timerElapseInvocationCount = 0;
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:1.0];
  XCTAssertEqual(timerElapseInvocationCount, 1);
}

#pragma mark - Test Helpers

- (void)timerElapsed:(NSTimer *)timer {
  timerElapseInvocationCount++;
}

@end
