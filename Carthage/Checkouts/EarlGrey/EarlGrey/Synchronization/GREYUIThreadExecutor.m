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

#import "Synchronization/GREYUIThreadExecutor.h"

#import "Additions/NSError+GREYAdditions.h"
#import "Additions/UIApplication+GREYAdditions.h"
#import "Additions/XCTestCase+GREYAdditions.h"
#import "AppSupport/GREYIdlingResource.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYConstants.h"
#import "Common/GREYDefines.h"
#import "Common/GREYError.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"
#import "Common/GREYStopwatch.h"
#import "Common/GREYThrowDefines.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYDispatchQueueIdlingResource.h"
#import "Synchronization/GREYOperationQueueIdlingResource.h"
#import "Synchronization/GREYRunLoopSpinner.h"

// Extern.
NSString *const kGREYUIThreadExecutorErrorDomain =
    @"com.google.earlgrey.GREYUIThreadExecutorErrorDomain";

/**
 *  The number of times idling resources are queried for idleness to be considered "really" idle.
 *  The value used here has worked in practice and has negligible impact on performance.
 */
static const int kConsecutiveTimesIdlingResourcesMustBeIdle = 3;

/**
 *  The default maximum time that the main thread is allowed to sleep while the thread executor is
 *  attempting to synchronize.
 */
static const CFTimeInterval kMaximumSynchronizationSleepInterval = 0.1;

/**
 *  The maximum amount of time to wait for the UI and idling resources to become idle in
 *  grey_forcedStateTrackerCleanUp before forcefully clearing the state of GREYAppStateTracker.
 */
static const CFTimeInterval kDrainTimeoutSecondsBeforeForcedStateTrackerCleanup = 10;

// Execution states.
typedef NS_ENUM(NSInteger, GREYExecutionState) {
  kGREYExecutionNotStarted = -1,
  kGREYExecutionWaitingForIdle,
  kGREYExecutionCompleted,
  kGREYExecutionTimeoutIdlingResourcesAreBusy,
  kGREYExecutionTimeoutAppIsBusy,
};

@interface GREYUIThreadExecutor ()

/**
 *  Property added for unit tests to keep the main thread awake while synchronizing.
 */
@property(nonatomic, assign) BOOL forceBusyPolling;

@end

@implementation GREYUIThreadExecutor {
  /**
   *  All idling resources that are registered with the framework using registerIdlingResource:.
   *  This list excludes the idling resources that are monitored by default and do not require
   *  registration.
   */
  NSMutableOrderedSet *_registeredIdlingResources;

  /**
   *  Idling resources that are monitored by default and cannot be deregistered.
   */
  NSOrderedSet *_defaultIdlingResources;
}

+ (instancetype)sharedInstance {
  static GREYUIThreadExecutor *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[GREYUIThreadExecutor alloc] initOnce];
  });
  return instance;
}

/**
 *  Initializes the thread executor. Not thread-safe. Must be invoked under a race-free synchronized
 *  environment by the caller.
 *
 *  @return The initialized instance.
 */
- (instancetype)initOnce {
  self = [super init];
  if (self) {
    _registeredIdlingResources = [[NSMutableOrderedSet alloc] init];

    // Create the default idling resources.
    NSString *trackerName = @"Main NSOperation Queue Tracker";
    id<GREYIdlingResource> mainNSOperationQIdlingResource =
        [GREYOperationQueueIdlingResource resourceWithNSOperationQueue:[NSOperationQueue mainQueue]
                                                                  name:trackerName];
    id<GREYIdlingResource> mainDispatchQIdlingResource =
        [GREYDispatchQueueIdlingResource resourceWithDispatchQueue:dispatch_get_main_queue()
                                                              name:@"Main Dispatch Queue Tracker"];
    id<GREYIdlingResource> appStateTrackerIdlingResource = [GREYAppStateTracker sharedInstance];

    // The default resources' order is important as it affects the order in which the resources
    // will be checked.
    _defaultIdlingResources =
        [[NSOrderedSet alloc] initWithObjects:appStateTrackerIdlingResource,
                                              mainNSOperationQIdlingResource,
                                              mainDispatchQIdlingResource, nil];
    // To forcefully clear GREYAppStateTracker state during test case teardown if it is not idle.
    // This prevents the next test case from timing out in case the previous one puts the app into
    // a non-idle state.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(grey_forcedStateTrackerCleanUp)
                                                 name:kGREYXCTestCaseInstanceDidTearDown
                                               object:nil];
  }
  return self;
}

- (void)drainOnce {
  // Drain the active run loop once. Do not allow the run loop to sleep.
  GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];

  // Spin the run loop with an always true stop condition. The spinner will only drain the run loop
  // for its minimum number of drains before checking this condition and returning.
  [runLoopSpinner spinWithStopConditionBlock:^BOOL {
    return YES;
  }];
}

- (void)drainForTime:(CFTimeInterval)seconds {
  GREYThrowOnNilParameter(seconds >= 0);
  GREYLogVerbose(@"Active Run Loop being drained for %f seconds.", seconds);

  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  [stopwatch start];
  // Drain the active run loop for @c seconds. Allow the run loop to sleep.
  GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];

  runLoopSpinner.timeout = seconds;
  runLoopSpinner.maxSleepInterval = DBL_MAX;
  runLoopSpinner.minRunLoopDrains = 0;

  // Spin the run loop with an always NO stop condition. The run loop spinner will only return after
  // it times out.
  [runLoopSpinner spinWithStopConditionBlock:^BOOL{
    return NO;
  }];
  [stopwatch stop];
  GREYLogVerbose(@"Active Run Loop was drained for %f seconds", [stopwatch elapsedTime]);
}

- (void)drainUntilIdle {
  GREYLogVerbose(@"Active Run Loop being drained for an infinite timeout until the app is Idle.");
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  [stopwatch start];
  [self executeSyncWithTimeout:kGREYInfiniteTimeout block:nil error:nil];
  [stopwatch stop];
  GREYLogVerbose(@"App became idle after %f seconds", [stopwatch elapsedTime]);
}

- (BOOL)drainUntilIdleWithTimeout:(CFTimeInterval)seconds {
  NSError *ignoreError;
  GREYLogVerbose(@"Active Run Loop being drained for an %f seconds until the app is Idle.",
                 seconds);
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  [stopwatch start];
  BOOL success = [self executeSyncWithTimeout:seconds block:nil error:&ignoreError];
  [stopwatch stop];
  if (success) {
    GREYLogVerbose(@"App became idle after %f seconds", [stopwatch elapsedTime]);
  } else {
    GREYLogVerbose(@"Run loop drain timed out after %f seconds", [stopwatch elapsedTime]);
  }
  return success;
}

- (BOOL)executeSync:(GREYExecBlock)execBlock error:(__strong NSError **)error {
  GREYLogVerbose(@"Execution block: %@ is being synchronized and executed on the main thread.",
                 execBlock);
  return [self executeSyncWithTimeout:kGREYInfiniteTimeout block:execBlock error:error];
}

- (BOOL)executeSyncWithTimeout:(CFTimeInterval)seconds
                         block:(GREYExecBlock)execBlock
                         error:(__strong NSError **)error {
  GREYFatalAssertMainThread();
  GREYThrowOnFailedCondition(seconds >= 0);

  BOOL isSynchronizationEnabled = GREY_CONFIG_BOOL(kGREYConfigKeySynchronizationEnabled);
  GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];
  // It is important that we execute @c execBlock in the active run loop mode, which is guaranteed
  // by the run loop spinner's condition met handler. We want actions and other events to execute
  // in the mode that they would without EarlGrey's run loop control.
  runLoopSpinner.conditionMetHandler = ^{
    @autoreleasepool {
      if (execBlock) {
        execBlock();
      }
    }
  };

  if (isSynchronizationEnabled) {
    runLoopSpinner.timeout = seconds;
    if (self.forceBusyPolling) {
      runLoopSpinner.maxSleepInterval = kMaximumSynchronizationSleepInterval;
    }

    // Spin the run loop until the all of the resources are idle or until @c seconds.
    BOOL isAppIdle = [runLoopSpinner spinWithStopConditionBlock:^BOOL {
      return [self grey_areAllResourcesIdle];
    }];

    if (!isAppIdle) {
      NSOrderedSet *busyResources = [self grey_busyResources];
      if ([busyResources count] > 0) {
        NSString *description = @"Failed to execute block because idling resources below are busy.";
        GREYPopulateErrorNotedOrLog(error,
                                    kGREYUIThreadExecutorErrorDomain,
                                    kGREYUIThreadExecutorTimeoutErrorCode,
                                    description,
                                    [self grey_errorDictionaryForBusyResources:busyResources]);
      } else {
        GREYPopulateErrorOrLog(error,
                               kGREYUIThreadExecutorErrorDomain,
                               kGREYUIThreadExecutorTimeoutErrorCode,
                               @"Failed to idle but all resources are idle after timeout.");
      }
    }
    return isAppIdle;
  } else {
    // Spin the run loop with an always true stop condition. The spinner will only drain the run
    // loop for its minimum number of drains before executing the conditionMetHandler in the active
    // mode and returning.
    [runLoopSpinner spinWithStopConditionBlock:^BOOL{
      return YES;
    }];
    return YES;
  }
}

#pragma mark - Package Internal

- (void)registerIdlingResource:(id<GREYIdlingResource>)resource {
  GREYFatalAssert(resource);
  @synchronized(_registeredIdlingResources) {
    // Add the object at the beginning of the ordered set. Resource checking order is important for
    // stability and the default resources should be checked last.
    [_registeredIdlingResources insertObject:resource atIndex:0];
  }
}

- (void)deregisterIdlingResource:(id<GREYIdlingResource>)resource {
  GREYFatalAssert(resource);
  @synchronized(_registeredIdlingResources) {
    [_registeredIdlingResources removeObject:resource];
  }
}

#pragma mark - Internal Methods Exposed For Testing

/**
 *  @return @c YES when all idling resources are idle, @c NO otherwise.
 *
 *  @remark More efficient than calling grey_busyResources.
 */
- (BOOL)grey_areAllResourcesIdle {
  return [[self grey_busyResourcesReturnEarly:YES] count] == 0;
}

#pragma mark - Methods Only For Testing

/**
 *  Deregisters all non-default idling resources from the thread executor.
 */
- (void)grey_resetIdlingResources {
  @synchronized(_registeredIdlingResources) {
    _registeredIdlingResources = [[NSMutableOrderedSet alloc] init];
  }
}

/**
 *  @return @c YES if the thread executor is currently tracking @c idlingResource, @c NO otherwise.
 */
- (BOOL)grey_isTrackingIdlingResource:(id<GREYIdlingResource>)idlingResource {
  @synchronized (_registeredIdlingResources) {
    return [_registeredIdlingResources containsObject:idlingResource] ||
        [_defaultIdlingResources containsObject:idlingResource];
  }
}

#pragma mark - Private

/**
 *  @return An ordered set the registered and default idling resources that are currently busy.
 */
- (NSOrderedSet *)grey_busyResources {
  return [self grey_busyResourcesReturnEarly:NO];
}

/**
 *  @param returnEarly A boolean flag to determine if this method should return
 *                     immediately after finding one busy resource.
 *
 *  @return An ordered set the registered and default idling resources that are currently busy.
 */
- (NSOrderedSet *)grey_busyResourcesReturnEarly:(BOOL)returnEarly {
  @synchronized(_registeredIdlingResources) {
    NSMutableOrderedSet *busyResources = [[NSMutableOrderedSet alloc] init];
    // Loop over all of the idling resources three times. isIdleNow calls may trigger the state
    // of other idling resources.
    for (int i = 0; i < kConsecutiveTimesIdlingResourcesMustBeIdle; ++i) {
      // Registered resources are free to remove themselves or each-other when isIdleNow is
      // invoked. For that reason, iterate over a copy.
      for (id<GREYIdlingResource> resource in [_registeredIdlingResources copy]) {
        if (![resource isIdleNow]) {
          [busyResources addObject:resource];
          if (returnEarly) {
            return busyResources;
          }
        }
      }
      for (id<GREYIdlingResource> resource in _defaultIdlingResources) {
        if (![resource isIdleNow]) {
          [busyResources addObject:resource];
          if (returnEarly) {
            return busyResources;
          }
        }
      }
    }
    return busyResources;
  }
}

/**
 *  @return An error description string for all of the resources in @c busyResources.
 */
- (NSDictionary *)grey_errorDictionaryForBusyResources:(NSOrderedSet *)busyResources {
  NSMutableDictionary *busyResourcesNameToDesc = [[NSMutableDictionary alloc] init];

  for (id<GREYIdlingResource> resource in busyResources) {
    busyResourcesNameToDesc[resource.idlingResourceName] = [resource idlingResourceDescription];
  }
  return busyResourcesNameToDesc;
}

/**
 *  Drains the UI thread and waits for both the UI and idling resources to idle, for up to
 *  @c kDrainTimeoutSecondsBeforeForcedStateTrackerCleanup seconds, before forcefully clearing
 *  the state of GREYAppStateTracker.
 */
- (void)grey_forcedStateTrackerCleanUp {
  BOOL idled = [self drainUntilIdleWithTimeout:kDrainTimeoutSecondsBeforeForcedStateTrackerCleanup];
  if (!idled) {
    NSLog(@"EarlGrey tried waiting for %.1f seconds for the application to reach an idle state. It"
          @" is now forced to clear the state of GREYAppStateTracker, because the test might have"
          @" caused the application to remain in non-idle state indefinitely."
          @"\nFull state tracker description: %@",
          kDrainTimeoutSecondsBeforeForcedStateTrackerCleanup,
          [GREYAppStateTracker sharedInstance]);
    [[GREYAppStateTracker sharedInstance] grey_clearState];
  }
}

@end
