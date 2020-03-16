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

#import "Synchronization/GREYManagedObjectContextIdlingResource.h"

#import <CoreData/CoreData.h>
#import <objc/runtime.h>

#import "Common/GREYThrowDefines.h"
#import "Synchronization/GREYDispatchQueueIdlingResource.h"
#import "Synchronization/GREYUIThreadExecutor+Internal.h"

@implementation GREYManagedObjectContextIdlingResource {
  BOOL _trackPendingChanges;
  NSString *_name;

  /**
   *  The managed object context being tracked by this idling resource. The managed object context
   *  is held weakly so that it can be deallocated normally.
   */
  __weak NSManagedObjectContext *_managedObjectContext;

  /**
   *  A dispatch queue idling resource used by this idling resource to track the managed object
   *  context's internal dispatch queue.
   */
  GREYDispatchQueueIdlingResource *_dispatchQueueIdlingResource;
}

+ (instancetype)resourceWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                             trackPendingChanges:(BOOL)trackPendingChanges
                                            name:(NSString *)name {
  return [[GREYManagedObjectContextIdlingResource alloc]
      initWithManagedObjectContext:managedObjectContext
               trackPendingChanges:trackPendingChanges
                              name:name];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                         trackPendingChanges:(BOOL)trackPendingChanges
                                        name:(NSString *)name {
  GREYThrowOnNilParameter(managedObjectContext);
  GREYThrowOnNilParameter(name);

  self = [super init];
  if (self) {
    _managedObjectContext = managedObjectContext;
    _trackPendingChanges = trackPendingChanges;
    _name = [name copy];

    NSString *dispatchQueueResourceName =
        [NSString stringWithFormat:@"DispatchQueueForNSManagedObject: %@", _name];

    dispatch_queue_t managedContextQueue = [self managedObjectContextDispatchQueue];

    _dispatchQueueIdlingResource =
        [GREYDispatchQueueIdlingResource resourceWithDispatchQueue:managedContextQueue
                                                              name:dispatchQueueResourceName];
  }
  return self;
}

#pragma mark - GREYIdlingResource

- (NSString *)idlingResourceName {
  return _name;
}

- (NSString *)idlingResourceDescription {
  return _name;
}

- (BOOL)isIdleNow {
  NSManagedObjectContext *strongManagedObjectContext = _managedObjectContext;
  if (!strongManagedObjectContext) {
    [[GREYUIThreadExecutor sharedInstance] deregisterIdlingResource:self];
    return YES;
  }
  BOOL busyBecauseOfChanges = _trackPendingChanges && strongManagedObjectContext.hasChanges;
  BOOL busyBecauseOfDispatchQueue = ![_dispatchQueueIdlingResource isIdleNow];
  return !busyBecauseOfChanges && !busyBecauseOfDispatchQueue;
}

#pragma mark - Internal Methods Exposed For Testing

/**
 *  @return The private dispatch queue for this idling resource's tracked managed object context.
 */
- (dispatch_queue_t)managedObjectContextDispatchQueue {
  Ivar queueIvar = class_getInstanceVariable([NSManagedObjectContext class], "_dispatchQueue");
  return object_getIvar(_managedObjectContext, queueIvar);
}

@end
