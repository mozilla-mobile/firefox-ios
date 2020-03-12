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

#import <EarlGrey/GREYOperationQueueIdlingResource.h>
#import "Synchronization/GREYUIThreadExecutor+Internal.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYOperationQueueIdlingResourceTest : GREYBaseTest
@end

@implementation GREYOperationQueueIdlingResourceTest  {
  NSOperationQueue *_backgroundOperationQ;
}

- (void)setUp {
  [super setUp];
  _backgroundOperationQ = [[NSOperationQueue alloc] init];
}

- (void)tearDown {
  [_backgroundOperationQ cancelAllOperations];
  [_backgroundOperationQ waitUntilAllOperationsAreFinished];
  [super tearDown];
}

- (void)testQueueName {
  NSString *queueName = @"queueName";
  GREYOperationQueueIdlingResource *idlingRes =
      [GREYOperationQueueIdlingResource resourceWithNSOperationQueue:_backgroundOperationQ
                                                                name:queueName];
  XCTAssertEqual(queueName, [idlingRes idlingResourceName], @"Name differs");
}

- (void)testIsInitiallyIdle {
  GREYOperationQueueIdlingResource *idlingRes =
      [GREYOperationQueueIdlingResource resourceWithNSOperationQueue:_backgroundOperationQ
                                                                name:@"test"];
  XCTAssertTrue([idlingRes isIdleNow], @"Empty queue should be in idle state.");
}

- (void)testOccupiedQueueIdleAfterTaskCompletion {
  GREYOperationQueueIdlingResource *idlingRes =
      [GREYOperationQueueIdlingResource resourceWithNSOperationQueue:_backgroundOperationQ
                                                                name:@"test"];
  NSLock *lock = [[NSLock alloc] init];
  [lock lock];
  [_backgroundOperationQ addOperationWithBlock:^(void) {
    [lock lock];
    [lock unlock];
  }];

  XCTAssertFalse([idlingRes isIdleNow], @"Non-empty queue should not be in idle state.");
  [lock unlock];
  [_backgroundOperationQ waitUntilAllOperationsAreFinished];
  XCTAssertTrue([idlingRes isIdleNow], @"Queue should be idle after executing the only task.");
}

- (void)testIdlingResourceWeaklyHeldAndDeregistersItself {
  GREYOperationQueueIdlingResource *operationQueueIdlingResource;
  @autoreleasepool {
    __autoreleasing NSOperationQueue *queue = [[NSOperationQueue alloc] init];

    operationQueueIdlingResource =
        [GREYOperationQueueIdlingResource resourceWithNSOperationQueue:queue
                                                                  name:@"test"];
    [[GREYUIThreadExecutor sharedInstance] registerIdlingResource:operationQueueIdlingResource];
    XCTAssertTrue([[GREYUIThreadExecutor sharedInstance]
        grey_isTrackingIdlingResource:operationQueueIdlingResource]);
  }
  XCTAssertTrue([operationQueueIdlingResource isIdleNow]);
  XCTAssertFalse([[GREYUIThreadExecutor sharedInstance]
      grey_isTrackingIdlingResource:operationQueueIdlingResource]);
}

@end
