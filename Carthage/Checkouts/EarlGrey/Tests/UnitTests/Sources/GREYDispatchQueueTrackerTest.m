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

#import <EarlGrey/GREYConfiguration.h>
#import "Synchronization/GREYDispatchQueueTracker.h"
#import "GREYBaseTest.h"

/**
 *  A simple container class used to pass objects as a context to @c testFunction() through
 *  dispatch_*_f calls.
 */
@interface GREYTestContainer : NSObject
@property(nonatomic) XCTestExpectation *expectation;
@property(nonatomic) GREYDispatchQueueTracker *tracker;
@property(nonatomic) dispatch_semaphore_t semaphore;
@end

@implementation GREYTestContainer
@end

/** Test worker function for dispatch_*_f calls. */
static void testFunction(void *context) {
  GREYDispatchQueueTracker *tracker = [((__bridge GREYTestContainer *)context) tracker];
  XCTestExpectation *expectation = [((__bridge GREYTestContainer *)context) expectation];
  dispatch_semaphore_t semaphore = [((__bridge GREYTestContainer *)context) semaphore];

  if (semaphore) {
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(5.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, timeout);
  }

  // The tracker should not be idle. If it is idle, then we will propagate the failure by not
  // fulfilling the expectation.
  if (![tracker isIdleNow]) {
    [expectation fulfill];
  }
}

static const NSTimeInterval kSecondsWaitInTestBlocks = 0.1;
static const int kMaxAggresiveCalls = 100;

@interface GREYDispatchQueueTrackerTest : GREYBaseTest
@end

@implementation GREYDispatchQueueTrackerTest {
  dispatch_queue_t _serialQueue;
}

- (void)setUp {
  [super setUp];
  _serialQueue = dispatch_queue_create("GREYDispatchQueueTrackerTest", DISPATCH_QUEUE_SERIAL);
}

- (void)tearDown {
  [[GREYConfiguration sharedInstance] reset];
  [super tearDown];
}

- (void)testIsInitiallyIdle {
  [[GREYConfiguration sharedInstance] setValue:@(1.0)
                                  forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  XCTAssertTrue([tracker isIdleNow], @"Empty queue should be in idle state.");
}

- (void)testAggresiveCalling {
  [[GREYConfiguration sharedInstance] setValue:@(1.0)
                                  forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  // We must verify that sending isIdleNow message itself does not make the queue busy.
  for (int i = 0; i < kMaxAggresiveCalls; i++) {
    [tracker isIdleNow];
  }

  XCTAssertTrue([tracker isIdleNow], @"Empty queue should be in idle state.");
}

- (void)testOccupiedQueueNotIdle {
  [[GREYConfiguration sharedInstance] setValue:@(1.0)
                                  forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  dispatch_async(_serialQueue, ^{
    [NSThread sleepForTimeInterval:kSecondsWaitInTestBlocks];
  });
  XCTAssertFalse([tracker isIdleNow], @"Non-empty queue should not be in idle state.");
}

- (void)testMainQueueIdle {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:dispatch_get_main_queue()];
  XCTAssertTrue([tracker isIdleNow], @"Main queue must be idle.");
}

- (void)testIsIdleNowDoesNotAffectMainQueue {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:dispatch_get_main_queue()];
  // We must verify that sending isIdleNow message itself does not make main queue busy.
  for (int i = 0; i < kMaxAggresiveCalls; i++) {
    [tracker isIdleNow];
  }

  XCTAssertTrue([tracker isIdleNow], @"Main queue must be idle.");
}

- (void)testMainQueueNotIdle {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:dispatch_get_main_queue()];
  for (int i = 0; i < 10; i++) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [NSThread sleepForTimeInterval:kSecondsWaitInTestBlocks];
    });
  }
  XCTAssertFalse([tracker isIdleNow], @"Main queue must not be idle.");
}

- (void)testOccupiedQueueIdleAfterTaskCompletion {
  [[GREYConfiguration sharedInstance] setValue:@(0)
                                  forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Async block fired"];

  dispatch_async(_serialQueue, ^{
      [expectation fulfill];
  });
  XCTAssertFalse([tracker isIdleNow], @"Non-empty queue should not be in idle state.");
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  // Drain the queue in order to avoid the race condition where the expectation has been fulfilled
  // by the async task and the main thread resumes before that async task completes.
  dispatch_sync(_serialQueue, ^{});
  XCTAssertTrue([tracker isIdleNow], @"Queue should be idle after executing the only task.");
}

- (void)testTrackerDoesNotTrackDispatchAfterBlock {
  [[GREYConfiguration sharedInstance] setValue:@(0.05)
                                  forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  __block BOOL executed = NO;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                 _serialQueue, ^{
    executed = YES;
  });
  XCTAssertFalse(executed, @"Block should be pending execution");
  XCTAssertTrue([tracker isIdleNow], @"Idling resource should not track block with large delay");
  [NSThread sleepForTimeInterval:0.2];
  XCTAssertTrue(executed, @"Block should be been executed");
  XCTAssertTrue([tracker isIdleNow], @"Idling resource should be idle after finishing execution");
}

- (void)testTrackerTracksDispatchAfterBlock {
  [[GREYConfiguration sharedInstance] setValue:@(0.1)
                                  forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Dispatch after block fired"];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)),
                 _serialQueue, ^{
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(5.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, timeout);
    [expectation fulfill];
  });
  XCTAssertFalse([tracker isIdleNow], @"Idling resource should track block with small delay");

  dispatch_semaphore_signal(semaphore);
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  // Drain the queue in order to avoid the race condition where the expectation has been fulfilled
  // by the async task and the main thread resumes before that async task completes.
  dispatch_sync(_serialQueue, ^{});

  XCTAssertTrue([tracker isIdleNow], @"Idling resource should be idle after finishing execution");
}

- (void)testTrackerTracksDispatchAsyncBlock {
  double trackableValue = 0.05;
  [[GREYConfiguration sharedInstance] setValue:@(trackableValue)
                                  forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Dispatch async block fired"];

  dispatch_async(_serialQueue, ^{
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(5.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, timeout);
    XCTAssertFalse([tracker isIdleNow], @"Idling resource should track dispatch async block");
    [expectation fulfill];
  });

  XCTAssertFalse([tracker isIdleNow], @"Idling resource should track dispatch async block");
  dispatch_semaphore_signal(semaphore);
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  // Drain the queue in order to avoid the race condition where the expectation has been fulfilled
  // by the async task and the main thread resumes before that async task completes.
  dispatch_sync(_serialQueue, ^{});
  XCTAssertTrue([tracker isIdleNow], @"Idling resource should be idle after finishing execution");
}

- (void)testTrackerTracksDispatchSyncBlock {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  __block BOOL executed = NO;
  dispatch_sync(_serialQueue, ^{
    XCTAssertFalse([tracker isIdleNow], @"Idling resource should track dispatch sync block");
    XCTAssertFalse(executed, @"Block should be pending execution");
    executed = YES;
  });
  XCTAssertTrue(executed, @"Block should be been executed");
  XCTAssertTrue([tracker isIdleNow], @"Idling resource should be idle after finishing execution");
}

- (void)testTrackerTracksDispatchAfterFunction {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  GREYTestContainer *container = [[GREYTestContainer alloc] init];
  container.tracker = tracker;
  container.expectation = [self expectationWithDescription:@"Async function called"];
  container.semaphore = semaphore;
  dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)),
                   _serialQueue,
                   (__bridge void *)container,
                   testFunction);

  XCTAssertFalse([tracker isIdleNow]);
  dispatch_semaphore_signal(semaphore);
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  // Drain the queue in order to avoid the race condition where the expectation has been fulfilled
  // by the async task and the main thread resumes before that async task completes.
  dispatch_sync(_serialQueue, ^{});
  XCTAssertTrue([tracker isIdleNow]);
}

- (void)testTrackerTracksDispatchAsyncFunction {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  GREYTestContainer *container = [[GREYTestContainer alloc] init];
  container.tracker = tracker;
  container.expectation = [self expectationWithDescription:@"Async function called"];
  container.semaphore = semaphore;
  dispatch_async_f(_serialQueue, (__bridge void *)container, testFunction);

  XCTAssertFalse([tracker isIdleNow]);
  dispatch_semaphore_signal(semaphore);
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  // Drain the queue in order to avoid the race condition where the expectation has been fulfilled
  // by the async task and the main thread resumes before that async task completes.
  dispatch_sync(_serialQueue, ^{});
  XCTAssertTrue([tracker isIdleNow]);
}

- (void)testTrackerTracksDispatchSyncFunction {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];

  GREYTestContainer *container = [[GREYTestContainer alloc] init];
  container.tracker = tracker;
  container.expectation = [self expectationWithDescription:@"Async function called"];
  dispatch_sync_f(_serialQueue, (__bridge void *)container, testFunction);

  XCTAssertTrue([tracker isIdleNow]);
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  XCTAssertTrue([tracker isIdleNow]);
}

- (void)testSameTrackerIsReturnedForSameQueue {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  GREYDispatchQueueTracker *tracker2 =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  XCTAssertEqual(tracker, tracker2);
}

- (void)testSecondTrackerTracksQueueAfterFirstTrackerIsDeallocated {
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  @autoreleasepool {
    [GREYDispatchQueueTracker trackerForDispatchQueue:_serialQueue];
  }
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Async block fired"];
  dispatch_async(_serialQueue, ^{
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(5.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, timeout);
    [expectation fulfill];
  });
  XCTAssertFalse([tracker isIdleNow]);

  dispatch_semaphore_signal(semaphore);
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  // Drain the queue in order to avoid the race condition where the expectation has been fulfilled
  // by the async task and the main thread resumes before that async task completes.
  dispatch_sync(_serialQueue, ^{});
  XCTAssertTrue([tracker isIdleNow]);
}

- (void)testIsTrackingALiveQueueWithALivingQueue {
  NS_VALID_UNTIL_END_OF_SCOPE dispatch_queue_t queue =
      dispatch_queue_create("GREYDispatchQueueIdlingResourceTestDealloc", DISPATCH_QUEUE_SERIAL);;
  GREYDispatchQueueTracker *tracker =
      [GREYDispatchQueueTracker trackerForDispatchQueue:queue];
  XCTAssertTrue([tracker isTrackingALiveQueue]);
}

@end
