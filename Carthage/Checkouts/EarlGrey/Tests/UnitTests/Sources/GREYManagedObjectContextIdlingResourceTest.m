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

#import <CoreData/CoreData.h>

#import <EarlGrey/GREYConfiguration.h>
#import <EarlGrey/GREYManagedObjectContextIdlingResource.h>
#import "Synchronization/GREYUIThreadExecutor+Internal.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

static const NSTimeInterval kSemaphoreTimeoutSeconds = 0.1;
static const NSTimeInterval kExpectationTimeoutSeconds = 1.0;

@interface GREYManagedObjectContextIdlingResourceTest : GREYBaseTest
@end

@implementation GREYManagedObjectContextIdlingResourceTest

- (void)testIdleAfterInitializingAndDrainingOnBackgroundQueue {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:YES];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testIdleAfterInitializingAndDrainingOnMainQueue {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSMainQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:YES];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testBusyAfterAddingAsyncBlockOnBackgroundQueue {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:YES];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);

  XCTestExpectation *expecation = [self expectationWithDescription:@"Async block fired"];
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  [managedObjectContext performBlock:^{
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(kSemaphoreTimeoutSeconds * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, timeout);
    [expecation fulfill];
  }];
  XCTAssertFalse([managedObjectContextIdlingResource isIdleNow]);
  dispatch_semaphore_signal(semaphore);
  [self waitForExpectationsWithTimeout:kExpectationTimeoutSeconds handler:nil];
  // Drain the queue in order to avoid the race condition where the expectation has been fulfilled
  // by the async task and the main thread resumes before that async task completes.
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testBusyAfterAddingAsyncBlockOnMainQueue {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSMainQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:YES];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);

  XCTestExpectation *expecation = [self expectationWithDescription:@"Async block fired"];

  [managedObjectContext performBlock:^{
    [expecation fulfill];
  }];
  XCTAssertFalse([managedObjectContextIdlingResource isIdleNow]);
  [self waitForExpectationsWithTimeout:kExpectationTimeoutSeconds handler:nil];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testIdleAfterSyncBlockOnBackgroundQueue {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:YES];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);

  [managedObjectContext performBlockAndWait:^{}];

  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testIdleAfterSyncBlockOnMainQueue {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSMainQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:YES];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);

  [managedObjectContext performBlockAndWait:^{}];

  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testBusyAfterSyncMutationBlockOnBackgroundQueue {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:YES];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);

  [managedObjectContext performBlockAndWait:^{
    [self insertSimpleManagedObjectIntoContext:managedObjectContext];
  }];
  // Drain to make sure that we the the block didn't kick off another operation on the queue.
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertFalse([managedObjectContextIdlingResource isIdleNow],
                 @"Should be busy because of pending change.");
  [managedObjectContext performBlockAndWait:^{
    [managedObjectContext save:nil];
  }];
  // Need to drain since the save kicks off another async task.
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testBusyAfterSyncMutationBlockOnMainQueue {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSMainQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:YES];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);

  [managedObjectContext performBlockAndWait:^{
    [self insertSimpleManagedObjectIntoContext:managedObjectContext];
  }];
  // Drain to make sure that we the the block didn't kick off another operation on the queue.
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertFalse([managedObjectContextIdlingResource isIdleNow],
                 @"Should be busy because of pending change.");
  [managedObjectContext performBlockAndWait:^{
    [managedObjectContext save:nil];
  }];
  // Need to drain since the save kicks off another async task.
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testIdleAfterSyncMutationBlockOnBackgroundQueueWhenNotTrackingPendingChanges {
  NSManagedObjectContext *managedObjectContext =
      [self setUpContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
  GREYManagedObjectContextIdlingResource *managedObjectContextIdlingResource =
      [self setUpContextIdlingResourceWithContext:managedObjectContext
                           trackingPendingChanges:NO];
  [self drainDispatchQueue:[managedObjectContextIdlingResource managedObjectContextDispatchQueue]];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);

  [managedObjectContext performBlockAndWait:^{
    [self insertSimpleManagedObjectIntoContext:managedObjectContext];
  }];
  XCTAssertTrue([managedObjectContextIdlingResource isIdleNow]);
}

- (void)testIdlingResourceWeaklyHoldsContextAndDeregistersItself {
  GREYManagedObjectContextIdlingResource *contextIdlingResource;
  GREYUIThreadExecutor *threadExecutor = [GREYUIThreadExecutor sharedInstance];

  @autoreleasepool {
    __autoreleasing NSManagedObjectContext *managedObjectContext =
        [self setUpContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
    contextIdlingResource =
        [self setUpContextIdlingResourceWithContext:managedObjectContext
                             trackingPendingChanges:YES];
    [threadExecutor registerIdlingResource:contextIdlingResource];

    XCTAssertTrue([threadExecutor grey_isTrackingIdlingResource:contextIdlingResource]);
  }
  XCTAssertTrue([contextIdlingResource isIdleNow]);
  XCTAssertFalse([threadExecutor grey_isTrackingIdlingResource:contextIdlingResource]);
}

#pragma mark - Private Methods

- (NSManagedObjectContext *)
    setUpContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType {
  NSEntityDescription *entity = [[NSEntityDescription alloc] init];
  [entity setName:@"EarlGreyCustomEntity"];
  [entity setManagedObjectClassName:@"NSManagedObject"];

  NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] init];
  [managedObjectModel setEntities:@[entity]];

  // In memory coordinator
  NSPersistentStoreCoordinator *coordinator =
      [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];

  [coordinator addPersistentStoreWithType:NSInMemoryStoreType
                            configuration:nil
                                      URL:nil
                                  options:nil
                                    error:nil];

  // Context with |concurrencyType|
  NSManagedObjectContext *managedObjectContext =
      [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
  managedObjectContext.persistentStoreCoordinator = coordinator;

  return managedObjectContext;
}

- (GREYManagedObjectContextIdlingResource *)
    setUpContextIdlingResourceWithContext:(NSManagedObjectContext *)context
                   trackingPendingChanges:(BOOL)trackChanges {

  NSString *resourceName = @"Test managed objectidling resource";

  GREYManagedObjectContextIdlingResource *idlingResource =
      [GREYManagedObjectContextIdlingResource resourceWithManagedObjectContext:context
                                                           trackPendingChanges:trackChanges
                                                                          name:resourceName];
  return idlingResource;
}

- (void)drainDispatchQueue:(dispatch_queue_t)dispatchQueue {
  if (dispatchQueue == dispatch_get_main_queue()) {
    // Call dispatch_sync on the main dispatch queue from the main thread will cause a deadlock,
    // so we need to dispatch an async operation and wait on it.
    XCTestExpectation *expectation = [self expectationWithDescription:@"Async block fired."];
    dispatch_async(dispatchQueue, ^{
      [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
  } else {
    // Drain the private queue by dispatching a synchronous task.
    dispatch_sync(dispatchQueue, ^{});
  }
}

- (void)insertSimpleManagedObjectIntoContext:(NSManagedObjectContext *)managedObjectContext {
  NSEntityDescription *entityDescription =
      [NSEntityDescription entityForName:@"EarlGreyCustomEntity"
                  inManagedObjectContext:managedObjectContext];

  // NSManagedObject::initWithEntity:insertIntoManagedObjectContext: initializes a managed object
  // and inserts it into the context. To keep the compiler from complaining about not using the
  // initialized object, we hold on to the reference with an unused variable.
  __unused NSManagedObject *managedObject =
      [[NSManagedObject alloc] initWithEntity:entityDescription
               insertIntoManagedObjectContext:managedObjectContext];
}

@end
