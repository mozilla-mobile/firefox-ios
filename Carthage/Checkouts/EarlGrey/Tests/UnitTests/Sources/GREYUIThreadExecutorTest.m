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

#include <objc/runtime.h>

#import "Additions/UIView+GREYAdditions.h"
#import <EarlGrey/GREYFrameworkException.h>
#import <EarlGrey/GREYOperationQueueIdlingResource.h>
#import "Synchronization/GREYTimedIdlingResource.h"
#import "Synchronization/GREYUIThreadExecutor+Internal.h"
#import "Synchronization/GREYUIThreadExecutor+Internal.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

static BOOL gAppStateTrackerIdle;

#pragma mark - Test Helpers

@interface GREYTestIdlingResource : NSObject<GREYIdlingResource>
@property(nonatomic, strong) BOOL(^isIdleNowBlock)(void);
@end

@implementation GREYTestIdlingResource

- (BOOL)isIdleNow {
  return self.isIdleNowBlock();
}

- (NSString *)idlingResourceName {
  return @"Test Idling Resource";
}

- (NSString *)idlingResourceDescription {
  return @"Test Idling Resource";
}

@end

#pragma mark -

@interface GREYUIThreadExecutorTest : GREYBaseTest
@end

// These tests rely on method swizzling, hence they must be run sequentially and each test must go
// through proper setup and teardown to guarantee no global state corruption.
@implementation GREYUIThreadExecutorTest {
  GREYUIThreadExecutor *_threadExecutor;
  NSOperationQueue *_backgroundQueue;
}

- (BOOL)grey_isIdleNow {
  return gAppStateTrackerIdle;
}

- (void)setUp {
  [super setUp];

  gAppStateTrackerIdle = YES;

  // Swizzle isIdleNow so we can set the UI state to to whatever we like. This is useful for
  // testing various workflows where UI is in idle and non-idle state.
  method_exchangeImplementations(
      class_getInstanceMethod([GREYAppStateTracker class], @selector(isIdleNow)),
      class_getInstanceMethod([self class], @selector(grey_isIdleNow)));

  _threadExecutor = [GREYUIThreadExecutor sharedInstance];

  _backgroundQueue = [[NSOperationQueue alloc] init];
  GREYOperationQueueIdlingResource *resource =
      [GREYOperationQueueIdlingResource resourceWithNSOperationQueue:_backgroundQueue
                                                                name:@"background thread"];

  [_threadExecutor registerIdlingResource:resource];
}

- (void)tearDown {
  // Undo swizzling.
  method_exchangeImplementations(
      class_getInstanceMethod([GREYAppStateTracker class], @selector(isIdleNow)),
      class_getInstanceMethod([self class], @selector(grey_isIdleNow)));

  [[NSOperationQueue mainQueue] cancelAllOperations];
  [_backgroundQueue cancelAllOperations];

  [super tearDown];
}

- (void)testBusyToIdleBackgroundThreadResource {
  __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  // Add a block that signals background thread to continue. Until this block is executed,
  // the background thread will be in busy state.
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    dispatch_semaphore_signal(semaphore);
  }];

  // Add operation on background thread that will wait for the main queue block to execute.
  [_backgroundQueue addOperationWithBlock:^{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  }];

  NSError *error;
  BOOL success = [_threadExecutor executeSync:^{} error:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error);
}

- (void)testTimeoutWithAlwaysBusyBackgroundResource {
  [_backgroundQueue addOperationWithBlock:^{
    [NSThread sleepForTimeInterval:1.0];
  }];

  NSError *error;
  BOOL success = [_threadExecutor executeSyncWithTimeout:0.1 block:^{} error:&error];
  XCTAssertFalse(success);
  XCTAssertEqualObjects(kGREYUIThreadExecutorErrorDomain, error.domain);
  XCTAssertEqual(kGREYUIThreadExecutorTimeoutErrorCode, error.code);
}

- (void)testBusyBackgroundResourceDoesNotCauseTimeoutIfWaitForIdleIsDisabled {
  [[GREYConfiguration sharedInstance] setValue:@NO
                                  forConfigKey:kGREYConfigKeySynchronizationEnabled];

  __block BOOL wasExecuted = NO;

  [_backgroundQueue addOperationWithBlock:^{
    [NSThread sleepForTimeInterval:1.0];
    // Resets variable so if the sync operation doesn't finish before this the test will fail.
    wasExecuted = NO;
  }];

  NSError *error;
  // The operation should run even while the previously added background operation is still running.
  BOOL success = [_threadExecutor executeSyncWithTimeout:0.1
                                                     block:^{ wasExecuted = YES; }
                                                     error:&error];
  XCTAssertTrue(success);
  XCTAssertNil(error);
  XCTAssertTrue(wasExecuted);
}

- (void)testErrorMessageTimeoutWithBusyBackgroundResource {
  [_backgroundQueue addOperationWithBlock:^{
    [NSThread sleepForTimeInterval:1.0];
  }];

  NSError *error;
  BOOL success = [_threadExecutor executeSyncWithTimeout:0.1 block:^{} error:&error];
  XCTAssertFalse(success);
  XCTAssertEqualObjects(kGREYUIThreadExecutorErrorDomain, error.domain);
  XCTAssertEqual(kGREYUIThreadExecutorTimeoutErrorCode, error.code);

  NSString *errorSubstring = @"background thread";
  BOOL errorMatched = [error.description rangeOfString:errorSubstring].length > 0;
  XCTAssertTrue(errorMatched,
                @"Reason '%@' does not contain substring '%@'",
                error.description,
                errorSubstring);
}

- (void)testTimeoutWithUIThreadBusy {
  // We want to force throwing an exception here due to busy UI thread.
  gAppStateTrackerIdle = NO;

  NSError *error;
  // We should get exception because UI drain failed.
  BOOL success = [_threadExecutor executeSyncWithTimeout:0.1 block:^{} error:&error];
  XCTAssertFalse(success, @"UI should be in busy state.");
  XCTAssertEqualObjects(kGREYUIThreadExecutorErrorDomain, error.domain);
  XCTAssertEqual(kGREYUIThreadExecutorTimeoutErrorCode, error.code);
}

- (void)testDrainOnce {
  __block BOOL performBlockExecuted = NO;
  // Add operation on main thread.
  CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
    performBlockExecuted = YES;
  });

  [_threadExecutor drainOnce];
  XCTAssertTrue(performBlockExecuted,
                @"All perform blocks should execute after single drain of the runloop.");
}

- (void)testDrainForTimeBlocksForAtLeastTheSpecifiedTime {
  __block BOOL mainQueueExecuted = NO;
  // Add operation on main thread.
  CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
    mainQueueExecuted = YES;
  });

  CFTimeInterval timeBeforeDrain = CACurrentMediaTime();
  [_threadExecutor drainForTime:0.5];

  XCTAssertGreaterThanOrEqual(CACurrentMediaTime() - timeBeforeDrain, 0.5,
                              @"Should take at least the specified time");
  XCTAssertTrue(mainQueueExecuted, @"Should have executed the operation in main nsoperation queue");
}

- (void)testDrainForTimeBlocksForAtLeastTheSpecifiedTimeWhenSyncIsDisabled {
  [[GREYConfiguration sharedInstance] setValue:@NO
                                  forConfigKey:kGREYConfigKeySynchronizationEnabled];

  CFTimeInterval timeBeforeDrain = CACurrentMediaTime();
  [_threadExecutor drainForTime:0.5];

  XCTAssertGreaterThanOrEqual(CACurrentMediaTime() - timeBeforeDrain, 0.5,
                              "Should take at least the specified time");
}

- (void)testDrainForTimeForZeroSecondsStillDrains {
  __block BOOL mainQueueExecuted = NO;
  // Add operation on main thread.
  CFRunLoopPerformBlock([[NSRunLoop mainRunLoop] getCFRunLoop], kCFRunLoopDefaultMode, ^{
    mainQueueExecuted = YES;
  });

  [_threadExecutor drainForTime:0];

  XCTAssertTrue(mainQueueExecuted, @"Should have executed the operation in main nsoperation queue");
}

- (void)testDrainUntilIdle {
  [GREYTimedIdlingResource resourceForObject:self
                       thatIsBusyForDuration:0.1
                                        name:NSStringFromSelector(_cmd)];
  [_threadExecutor drainUntilIdle];

  XCTAssertTrue([[GREYAppStateTracker sharedInstance] isIdleNow]);
}

- (void)testTimeoutWithDrainUntilIdleWithTimeout {
  [GREYTimedIdlingResource resourceForObject:self
                       thatIsBusyForDuration:1.0
                                        name:NSStringFromSelector(_cmd)];
  BOOL success = [_threadExecutor drainUntilIdleWithTimeout:0.1];

  XCTAssertFalse(success, @"Should timeout because timed idling resource is tracked for "
                          @"significantly longer time than the timeout.");
}

- (void)testDrainUntilIdleWithTimeout {
  NSTimeInterval trackTime = 0.1;
  [GREYTimedIdlingResource resourceForObject:self
                       thatIsBusyForDuration:trackTime
                                        name:NSStringFromSelector(_cmd)];
  // Double the timeout so it has sufficient time to drain and query idling resources.
  BOOL success = [_threadExecutor drainUntilIdleWithTimeout:(trackTime * 2.0)];
  XCTAssertTrue(success, @"Draining should succeed since the timed idling resource takes half the "
                         @"time as the drain until idle timeout.");
}

- (void)testDrainUntilIdleWithOneResourceIdle {
  [GREYTimedIdlingResource resourceForObject:self
                       thatIsBusyForDuration:0.1
                                        name:@"ShortRunningResource"];
  [GREYTimedIdlingResource resourceForObject:self
                       thatIsBusyForDuration:1.0
                                        name:@"LongRunningResource"];
  BOOL idle = [_threadExecutor drainUntilIdleWithTimeout:0.3];

  XCTAssertFalse(idle,
                 @"Should not be idle, the long running resource is longer than the timeout.");
}

- (void)testCallSingletonTwice {
  XCTAssertEqualObjects([GREYUIThreadExecutor sharedInstance],
                        [GREYUIThreadExecutor sharedInstance],
                        @"Not a true singleton");
}

- (void)testCallBlock {
  __block BOOL blockExecuted = NO;
  [_threadExecutor executeSync:^(void) {
    blockExecuted = YES;
  } error:nil];
  XCTAssert(blockExecuted, @"Main thread block didn't execute");
}

- (void)testCallBlockFromOtherSources {
  __block BOOL performBlockExecuted = NO;
  __block BOOL topLevelExecBlockExecuted = NO;

  // Add execute sync block to CFRunLoopPerformBlock, then call execute sync again which will
  // cause perform block to execute its execute sync block.
  CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
    [[GREYUIThreadExecutor sharedInstance] executeSync:^{
      performBlockExecuted = YES;
    } error:nil];
  });

  // This will drain the runloop, executing the above perform block.
  [[GREYUIThreadExecutor sharedInstance] executeSync:^{
    XCTAssertTrue(performBlockExecuted, @"executeSync should drain perform block source above and "
                                        @"execute it before executing this block.");
    topLevelExecBlockExecuted = YES;
  } error:nil];

  XCTAssertTrue(topLevelExecBlockExecuted,
                @"Top level block didn't execute. Is execute sync call not blocking?");
}

- (void)testCallNestedBlocks {
  __block BOOL outerBlockExecuted = NO;
  __block BOOL innerBlock1Executed = NO;
  __block BOOL innerBlock2Executed = NO;
  [_threadExecutor executeSync:^(void) {
    [_threadExecutor executeSync:^(void) {
      innerBlock1Executed = YES;
    } error:nil];
    outerBlockExecuted = YES;
    [_threadExecutor executeSync:^(void) {
      [_threadExecutor executeSync:^(void) {
        innerBlock2Executed = YES;
      } error:nil];
    } error:nil];
  } error:nil];

  XCTAssertTrue(outerBlockExecuted, @"Outer block not executed");
  XCTAssertTrue(innerBlock1Executed, @"Inner nested block not executed");
  XCTAssertTrue(innerBlock2Executed, @"Inner nested block not executed");
}

- (void)testCallNestedBlocksWithRunLoopModeSwitch {
  __block BOOL outerBlockExecuted = NO;
  __block BOOL innerBlock1Executed = NO;
  __block BOOL innerBlock2Executed = NO;

  self.activeRunLoopMode = nil;
  [_threadExecutor executeSync:^(void) {
    XCTAssertEqualObjects([[NSRunLoop currentRunLoop] currentMode], NSDefaultRunLoopMode);
  } error:nil];

  NSString *fooRunLoopMode = @"Foo";
  self.activeRunLoopMode = fooRunLoopMode;
  [_threadExecutor executeSync:^(void) {
    XCTAssertEqualObjects([[NSRunLoop currentRunLoop] currentMode], fooRunLoopMode);
    self.activeRunLoopMode = UITrackingRunLoopMode;
    [_threadExecutor executeSync:^(void) {
      innerBlock1Executed = YES;
      XCTAssertEqualObjects([[NSRunLoop currentRunLoop] currentMode], UITrackingRunLoopMode);
    } error:nil];
    self.activeRunLoopMode = NSDefaultRunLoopMode;
    [_threadExecutor executeSync:^(void) {
      XCTAssertEqualObjects([[NSRunLoop currentRunLoop] currentMode], NSDefaultRunLoopMode);
      innerBlock2Executed = YES;
    } error:nil];
    outerBlockExecuted = YES;
    XCTAssertEqualObjects([[NSRunLoop currentRunLoop] currentMode], fooRunLoopMode);
  } error:nil];

  XCTAssertTrue(outerBlockExecuted, @"Outer block not executed");
  XCTAssertTrue(innerBlock1Executed, @"Inner nested block not executed");
  XCTAssertTrue(innerBlock2Executed, @"Inner nested block not executed");
}

- (void)testMainNSOperationQueueIsMonitoredByDefault {
  [_threadExecutor drainUntilIdle];
  XCTAssertTrue([_threadExecutor grey_areAllResourcesIdle]);
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{}];
  XCTAssertFalse([_threadExecutor grey_areAllResourcesIdle]);
}

- (void)testMainDispatchQueueIsMonitoredByDefault {
  [_threadExecutor drainUntilIdle];
  XCTAssertTrue([_threadExecutor grey_areAllResourcesIdle]);
  dispatch_async(dispatch_get_main_queue(), ^{});
  XCTAssertFalse([_threadExecutor grey_areAllResourcesIdle]);
}

- (void)testIdlingResourcesAffectingEachOthersStateAreHandledCorrectly {
  GREYTestIdlingResource *resource1 = [[GREYTestIdlingResource alloc] init];
  GREYTestIdlingResource *resource2 = [[GREYTestIdlingResource alloc] init];
  __block BOOL resource1Idle = NO;
  __block BOOL resource2Idle = NO;

  resource1.isIdleNowBlock = ^BOOL(void) {
    resource2Idle = !resource1Idle;
    return resource1Idle;
  };
  resource2.isIdleNowBlock = ^BOOL(void) {
    resource1Idle = !resource2Idle;
    return resource2Idle;
  };
  [[GREYUIThreadExecutor sharedInstance] registerIdlingResource:resource1];
  [[GREYUIThreadExecutor sharedInstance] registerIdlingResource:resource2];
  NSError *error;
  BOOL timeout = ![[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:0.1
                                                                          block:^{}
                                                                          error:&error];
  XCTAssertTrue(timeout);
  NSString *errorSubstring = @"Test Idling Resource";
  BOOL errorMatched = [error.description rangeOfString:@"Test Idling Resource"].length > 0;
  XCTAssertTrue(errorMatched,
                @"Reason '%@' does not contain substring '%@'",
                error.description,
                errorSubstring);
}

@end
