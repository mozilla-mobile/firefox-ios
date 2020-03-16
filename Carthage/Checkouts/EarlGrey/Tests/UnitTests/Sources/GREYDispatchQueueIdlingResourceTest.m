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
#import <EarlGrey/GREYDispatchQueueIdlingResource.h>
#import "Synchronization/GREYUIThreadExecutor+Internal.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYDispatchQueueIdlingResourceTest : GREYBaseTest
@end

@implementation GREYDispatchQueueIdlingResourceTest

- (void)testQueueName {
  NSString *queueName = @"queueName";
  dispatch_queue_t queue =
      dispatch_queue_create("GREYDispatchQueueIdlingResourceTest", DISPATCH_QUEUE_SERIAL);

  GREYDispatchQueueIdlingResource *idlingRes =
      [GREYDispatchQueueIdlingResource resourceWithDispatchQueue:queue
                                                            name:queueName];
  XCTAssertEqual(queueName, [idlingRes idlingResourceName], @"Name differs");
}

- (void)testIdlingResourceWeaklyHoldsQueueAndDeregistersItselfAfterOperationsHaveCompleted {
  GREYDispatchQueueIdlingResource *dispatchQueueIdlingResource;
  GREYUIThreadExecutor *sharedThreadExecutor = [GREYUIThreadExecutor sharedInstance];
  XCTestExpectation *expectation = [self expectationWithDescription:@"Async block fired"];
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  @autoreleasepool {
    __autoreleasing dispatch_queue_t queue =
        dispatch_queue_create("GREYDispatchQueueIdlingResourceTestDealloc", DISPATCH_QUEUE_SERIAL);

    dispatchQueueIdlingResource =
        [GREYDispatchQueueIdlingResource resourceWithDispatchQueue:queue
                                                              name:@"test"];
    [[GREYUIThreadExecutor sharedInstance] registerIdlingResource:dispatchQueueIdlingResource];
    XCTAssertTrue([sharedThreadExecutor grey_isTrackingIdlingResource:dispatchQueueIdlingResource]);

    dispatch_async(queue, ^{
      dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC));
      dispatch_semaphore_wait(semaphore, timeout);
      [expectation fulfill];
    });
  }
  XCTAssertFalse([dispatchQueueIdlingResource isIdleNow]);
  XCTAssertTrue([sharedThreadExecutor grey_isTrackingIdlingResource:dispatchQueueIdlingResource]);

  dispatch_semaphore_signal(semaphore);
  [self waitForExpectationsWithTimeout:1.0 handler:nil];

  // Wait for the queue to idle to avoid the race condition where the expectation has been fulfilled
  // by the async task and the main thread resumes before that async task completes. This is the
  // best we can do since we cannot keep a reference to the queue to drain it.
  GREYCondition *idleResourceCondition =
      [GREYCondition conditionWithName:@"GREYDispatchQueueIdlingResourceTestDealloc is idle"
                                 block:^BOOL {
        return [dispatchQueueIdlingResource isIdleNow];
      }];

  XCTAssertTrue([idleResourceCondition waitWithTimeout:1.0]);
  XCTAssertFalse([sharedThreadExecutor grey_isTrackingIdlingResource:dispatchQueueIdlingResource]);
}

@end
