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

#import "Synchronization/GREYAppStateTracker.h"

#include <objc/runtime.h>
#include <pthread.h>

#import "Additions/NSObject+GREYAdditions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"
#import "Common/GREYThrowDefines.h"
#import "Synchronization/GREYAppStateTrackerObject.h"
#import "Synchronization/GREYObjectDeallocationTracker.h"

/**
 *  Enum to specify the type of operation that is being performed on an object.
 */
typedef NS_ENUM(NSUInteger, GREYStateOperation) {
  kGREYTrackState,
  kGREYUnTrackState,
  kGREYClearState
};

/**
 *  Lock protecting object state map.
 */
static pthread_mutex_t gStateLock = PTHREAD_RECURSIVE_MUTEX_INITIALIZER;

/**
 *  The number of app states that exist. Used as a hint in creating @c _stateDictionary.
 */
static const unsigned short kNumGREYAppStates = 12;

@interface GREYAppStateTracker() <GREYObjectDeallocationTrackerDelegate>

@end

@implementation GREYAppStateTracker {
  /**
   *  Stores the GREYAppStateTrackerObjects that are being used to track objects.
   */
  NSMutableSet<GREYAppStateTrackerObject *> *_externalTrackerObjects;
  /**
   *  The app state for which any state changes are not tracked. This can be a bitwise-OR of
   *  multiple app states.
   *  Access should be guarded by @c gStateLock lock.
   */
  GREYAppState _ignoredAppState;
  /**
   *  The current state of the app. Access should be guarded by @c gStateLock lock.
   */
  GREYAppState _currentState;
  /**
   *  A dictionary that maps the state to the number of objects that are currently in that state.
   *  Access should be guarded by @c gStateLock lock.
   */
  NSMutableDictionary<NSNumber *, NSNumber *> *_stateDictionary;
}

+ (instancetype)sharedInstance {
  static GREYAppStateTracker *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[GREYAppStateTracker alloc] initOnce];
  });
  return instance;
}

/**
 *  Initializes the state tracker. Not thread-safe. Must be invoked under a race-free synchronized
 *  environment by the caller.
 *
 *  @return The initialized instance.
 */
- (instancetype)initOnce {
  self = [super init];
  if (self) {
    _currentState = kGREYIdle;
    _externalTrackerObjects = [[NSMutableSet alloc] init];
    _ignoredAppState = kGREYIdle;
    _stateDictionary = [[NSMutableDictionary alloc] initWithCapacity:kNumGREYAppStates];
  }
  return self;
}

- (GREYAppStateTrackerObject *)trackState:(GREYAppState)state forObject:(id)object {
  return [self grey_changeState:state
                     usingOperation:kGREYTrackState
                          forObject:object
orInternalObjectDeallocationTracker:nil
    orExternalAppStateTrackerObject:nil];
}

- (void)untrackState:(GREYAppState)state forObject:(GREYAppStateTrackerObject *)object {
  [self grey_changeState:state
                     usingOperation:kGREYUnTrackState
                          forObject:nil
orInternalObjectDeallocationTracker:nil
    orExternalAppStateTrackerObject:object];
}

- (GREYAppState)currentState {
  return [[self grey_performBlockInCriticalSection:^id {
    return @(_currentState);
  }] unsignedIntegerValue];
}

/**
 *  @return A string description of current pending UI event state.
 */
- (NSString *)description {
  NSMutableString *description = [[NSMutableString alloc] init];

  [self grey_performBlockInCriticalSection:^id {
    GREYAppState state = [self currentState];
    [description appendString:[self grey_stringFromState:state]];

    if (state != kGREYIdle) {
      [description appendString:@"\n\n"];
      [description appendString:@"Full state transition call stack for all objects:\n"];
      for (GREYAppStateTrackerObject *object in _externalTrackerObjects) {
        [description appendFormat:@"<%@> => %@\n",
                                  object.objectDescription,
                                  [self grey_stringFromState:object.state]];
        [description appendFormat:@"%@\n", [object stateAssignmentCallStack]];
      }
    }
    return nil;
  }];
  return description;
}

- (void)ignoreChangesToState:(GREYAppState)state {
  GREYThrowOnFailedConditionWithMessage(state != kGREYIdle,
                                        @"Do not directly set kGREYIdle as the state to be "
                                        @"ignored, to clear the states, use GREYAppStateTracker::"
                                        @"clearIgnoredStates instead.");

  [self grey_performBlockInCriticalSection:^id {
    _ignoredAppState = state;
    return nil;
  }];
}

- (void)clearIgnoredStates {
  [self grey_performBlockInCriticalSection:^id {
    _ignoredAppState = kGREYIdle;
    return nil;
  }];
}

#pragma mark - GREYIdlingResource

- (BOOL)isIdleNow {
  return [self currentState] == kGREYIdle;
}

- (NSString *)idlingResourceName {
  return NSStringFromClass([self class]);
}

- (NSString *)idlingResourceDescription {
  return [self description];
}

#pragma mark - Private

- (NSString *)grey_stringFromState:(GREYAppState)state {
  NSMutableArray *eventStateString = [[NSMutableArray alloc] init];
  if (state == kGREYIdle) {
    return @"Idle";
  }

  if (state & kGREYPendingViewsToAppear) {
    [eventStateString addObject:@"Waiting for viewDidAppear: call on the view controller. Please "
                                @"ensure that this view controller and its subclasses call "
                                @"through to their super's implementation."];
  }
  if (state & kGREYPendingViewsToDisappear) {
    [eventStateString addObject:@"Waiting for viewDidDisappear: call on the view controller. "
                                @"Please ensure that this view controller and it's subclasses call "
                                @"through to their super's implementation."];
  }
  if (state & kGREYPendingCAAnimation) {
    [eventStateString addObject:@"Waiting for CAAnimations to finish. Continuous animations may "
                                @"never finish and must be stopped explicitly. Animations attached "
                                @"to hidden view may still be running in the background."];
  }
  if (state & kGREYPendingNetworkRequest) {
    NSString *stateMsg =
        [NSString stringWithFormat:@"Waiting for network requests to finish. By default, EarlGrey "
                                   @"tracks all network requests. To change this behavior, refer "
                                   @"to %@.", [GREYConfiguration class]];
    [eventStateString addObject:stateMsg];
  }
  if (state & kGREYPendingRootViewControllerToAppear) {
    [eventStateString addObject:@"Waiting for window's rootViewController to appear. "
                                @"This should happen in the next runloop drain after a window's "
                                @"state is changed to visible."];
  }
  if (state & kGREYPendingGestureRecognition) {
    [eventStateString addObject:@"Waiting for gesture recognizer to detect or fail an ongoing "
                                @"gesture."];
  }
  if (state & kGREYPendingUIScrollViewScrolling) {
    [eventStateString addObject:@"Waiting for UIScrollView to finish scrolling and come to "
                                @"standstill."];
  }
  if (state & kGREYPendingUIWebViewAsyncRequest) {
    [eventStateString addObject:@"Waiting for UIWebView to finish loading asynchronous request."];
  }
  if (state & kGREYPendingUIAnimation) {
    [eventStateString addObject:@"Waiting for UIAnimation to complete. This internal animation was "
                                @"triggered by UIKit and completes when -[UIAnimation markStop] "
                                @"is invoked."];
  }
  if (state & kGREYIgnoringSystemWideUserInteraction) {
    NSString *stateMsg =
        [NSString stringWithFormat:@"System wide interaction events are being ignored via %@. "
                                   @"Call %@ to enable interactions again.",
                                   NSStringFromSelector(@selector(beginIgnoringInteractionEvents)),
                                   NSStringFromSelector(@selector(endIgnoringInteractionEvents))];

    [eventStateString addObject:stateMsg];
  }
  if (state & kGREYPendingKeyboardTransition) {
    [eventStateString addObject:@"Waiting for keyboard transition to finish."];
  }
  if (state & kGREYPendingDrawLayoutPass) {
    [eventStateString addObject:@"Waiting for UIView's draw/layout pass to complete. A "
                                @"draw/layout pass normally completes in the next runloop drain."];
  }
  GREYFatalAssertWithMessage([eventStateString count] > 0,
                             @"Did we forget to describe some states?");
  return [eventStateString componentsJoinedByString:@"\n"];
}

- (id)grey_performBlockInCriticalSection:(id (^)(void))block {
  int lock = pthread_mutex_lock(&gStateLock);
  GREYFatalAssertWithMessage(lock == 0, @"Failed to lock.");
  id retVal = block();
  int unlock = pthread_mutex_unlock(&gStateLock);
  GREYFatalAssertWithMessage(unlock == 0, @"Failed to unlock.");

  return retVal;
}

- (NSString *)grey_descriptionForObject:(id)object {
  return [NSString stringWithFormat:@"%@:%p", NSStringFromClass([object class]), object];
}

- (GREYAppStateTrackerObject *)grey_changeState:(GREYAppState)state
                                 usingOperation:(GREYStateOperation)operation
                                      forObject:(id)object
            orInternalObjectDeallocationTracker:(GREYObjectDeallocationTracker *)internalObject
                orExternalAppStateTrackerObject:(GREYAppStateTrackerObject *)externalObject {
  // In some cases, the object, internalObject and externalObject are all nil. This happens when
  // we untrack objects which were never registered before. In that scenario, we simply return.
  // For example, setting a root view controller in the App Delegate calls the swizzled
  // implementation, which tries to untrack the existing root view controller that doesn't exist.
  if (!object && !externalObject && !internalObject) {
    return nil;
  }

  // Extract information to find out if it is a track call.
  BOOL track = (operation == kGREYTrackState);
  // When a untrack call is made then the @c object should be nil.
  GREYFatalAssertWithMessage(track || !object, @"Object is not nil when untracking");

  // When a clear state call is made then the @c state should be idle.
  GREYFatalAssertWithMessage(operation != kGREYClearState || state == kGREYIdle,
                             @"State is not idle when clearing state.");

  GREYFatalAssertWithMessage((object && !internalObject && !externalObject) ||
                             (!object && internalObject && !externalObject) ||
                             (!object && !internalObject && externalObject),
                             @"Provide either a valid object or a valid internalObject or "
                             @"a valid externalObject, not more than one.");
  return [self grey_performBlockInCriticalSection:^id {
    // Modify State to remove ignored states from those being changed.
    GREYAppState modifiedState = track ? state & (~_ignoredAppState) : state;
    // We return early when we try to track an object for state kGREYIdle.
    if (track && modifiedState == kGREYIdle) {
      return nil;
    }
    GREYAppStateTrackerObject *appStateTrackerObjectExternal = externalObject;

    // This autorelease pool makes sure we release any autoreleased objects added to the tracker
    // map. If we rely on external autorelease pools to be drained, we might delay removal of
    // released keys. In some cases, it could lead to a livelock (calling drainUntilIdle inside
    // drainUntilIdle where the first drainUntilIdle sets up an autorelease pool and the second
    // drainUntilIdle never returns because it is expecting the first drainUntilIdle's autorelease
    // pool to release the object so state tracker can return to idle state)
    @autoreleasepool {
      // Right now, the object ownership is as follows:
      // Object -> GREYObjectDeallocationTracker -> GREYAppStateTrackerObject
      // ('->' indicates strong ownership); and a weak reference from GREYAppStateTrackerObject to
      // GREYObjectDeallocationTracker.

      // GREYObjectDeallocationTracker's deallocDelegate is GREYAppStateTracker. We use
      // GREYObjectDeallocationTracker because it signals to the GREYAppStateTracker when
      // the object gets deallocated. The GREYObjectDeallocationTracker will deallocate because
      // only the object is holding onto it strongly.

      GREYObjectDeallocationTracker *appStateTrackerObjectInternal = internalObject;
      if (appStateTrackerObjectInternal) {
        appStateTrackerObjectExternal = objc_getAssociatedObject(appStateTrackerObjectInternal,
                                                                 @selector(currentState));
        // There is a possibility that the external object untracked itself and deallocated.
        if (!appStateTrackerObjectExternal) {
          return nil;
        }
      } else if (!appStateTrackerObjectExternal) {
        appStateTrackerObjectInternal =
            [GREYObjectDeallocationTracker deallocationTrackerRegisteredWithObject:object];
        if (appStateTrackerObjectInternal) {
          appStateTrackerObjectExternal = objc_getAssociatedObject(appStateTrackerObjectInternal,
                                                                   @selector(currentState));
        }
      }

      // There is a possibility that the GREYAppStateTrackerObject isn't part of the map,
      // and object doesn't exist. This is possible when object being removed has already been
      // untracked.
      BOOL externalObjectExistsAlready =
          [_externalTrackerObjects containsObject:appStateTrackerObjectExternal];
      if (!externalObjectExistsAlready && !object) {
        return nil;
      }

      // We haven't tracked the @c object before so we track it now.
      if (!appStateTrackerObjectExternal && !appStateTrackerObjectInternal) {
        // We set the deallocDelegate to self to inform the GREYAppStateTracker of internal object's
        // deallocation. The internal object can then find the external object using object
        // association and GREYAppStateTracker will then untrack the external object.
        appStateTrackerObjectInternal =
            [[GREYObjectDeallocationTracker alloc] initWithObject:object delegate:self];
      }

      if (!appStateTrackerObjectExternal) {
        // Create a weak reference from external to internal object so that we can clear the
        // strong association from internal to external object when we are untracking the object.
        appStateTrackerObjectExternal =
            [[GREYAppStateTrackerObject alloc]
                initWithDeallocationTracker:appStateTrackerObjectInternal];
        appStateTrackerObjectExternal.objectDescription = [self grey_descriptionForObject:object];
      }

      // We need to update the state of the object being tracked or untracked.
      GREYAppState originalState = appStateTrackerObjectExternal.state;
      GREYAppState newState;
      if (operation == kGREYClearState) {
        newState = kGREYIdle;
      } else {
        newState = track ? (originalState | modifiedState) : (originalState & ~modifiedState);
      }

      // We update the @c _currentState so that we can provide quick information if the app is idle
      // or not.
      [self objectChangingFromState:originalState toState:newState];
      appStateTrackerObjectExternal.state = newState;

      // This condition signifies that the object is going to be idle, hence, we should remove
      // the object from the map.
      if (newState == kGREYIdle) {
        [_externalTrackerObjects removeObject:appStateTrackerObjectExternal];
        if (!appStateTrackerObjectInternal) {
          appStateTrackerObjectInternal = appStateTrackerObjectExternal.object;
        }
        if (appStateTrackerObjectInternal) {
          // Since object doesn't exist, we remove the strong reference from internal object
          // to external object. This will cause the external object to deallocate.
          objc_setAssociatedObject(appStateTrackerObjectInternal,
                                   @selector(currentState),
                                   nil,
                                   OBJC_ASSOCIATION_ASSIGN);
        }
      } else {
        [_externalTrackerObjects addObject:appStateTrackerObjectExternal];
        if (appStateTrackerObjectInternal) {
          objc_setAssociatedObject(appStateTrackerObjectInternal,
                                   @selector(currentState),
                                   appStateTrackerObjectExternal,
                                   OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
      }
    }
    return appStateTrackerObjectExternal;
  }];
}

- (void)objectChangingFromState:(GREYAppState)originalState toState:(GREYAppState)newState {
  if (originalState != kGREYIdle) {
    [self grey_adjustGlobalCountByOneForState:originalState increment:YES];
  }
  if (newState != kGREYIdle) {
    [self grey_adjustGlobalCountByOneForState:newState increment:NO];
  }
}

- (void)grey_adjustGlobalCountByOneForState:(GREYAppState)state increment:(BOOL)increment {
  // The @c state could be a combination of multiple states, hence, we need to check against
  // every state.
  if (state & kGREYPendingDrawLayoutPass) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingDrawLayoutPass
                                                increment:increment];
  }
  if (state & kGREYPendingViewsToAppear) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingViewsToAppear
                                                increment:increment];
  }
  if (state & kGREYPendingViewsToDisappear) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingViewsToDisappear
                                                increment:increment];
  }
  if (state & kGREYPendingKeyboardTransition) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingKeyboardTransition
                                                increment:increment];
  }
  if (state & kGREYPendingCAAnimation) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingCAAnimation
                                                increment:increment];
  }
  if (state & kGREYPendingUIAnimation) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingUIAnimation
                                                increment:increment];
  }
  if (state & kGREYPendingRootViewControllerToAppear) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingRootViewControllerToAppear
                                                increment:increment];
  }
  if (state & kGREYPendingUIWebViewAsyncRequest) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingUIWebViewAsyncRequest
                                                increment:increment];
  }
  if (state & kGREYPendingNetworkRequest) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingNetworkRequest
                                                increment:increment];
  }
  if (state & kGREYPendingGestureRecognition) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingGestureRecognition
                                                increment:increment];
  }
  if (state & kGREYPendingUIScrollViewScrolling) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYPendingUIScrollViewScrolling
                                                increment:increment];
  }
  if (state & kGREYIgnoringSystemWideUserInteraction) {
    [self grey_updateGlobalCountByOneInDictionaryForState:kGREYIgnoringSystemWideUserInteraction
                                                increment:increment];
  }
}

- (void)grey_updateGlobalCountByOneInDictionaryForState:(GREYAppState)state
                                              increment:(BOOL)increment {
  NSNumber *numElements = [_stateDictionary objectForKey:@(state)];
  NSUInteger count = 1;
  if (numElements) {
    count = [numElements unsignedIntegerValue];
  }
  if (increment) {
    count -= 1;
    [_stateDictionary setObject:[NSNumber numberWithUnsignedInteger:count] forKey:@(state)];
    if (count == 0) {
      _currentState = _currentState & ~state;
    }
  } else {
    if (!numElements) {
      count = 0;
    }
    count += 1;
    [_stateDictionary setObject:[NSNumber numberWithUnsignedInteger:count] forKey:@(state)];
    if ((count == 1) && (_currentState & state) == 0) {
      _currentState = _currentState | state;
    }
  }
}

#pragma mark - Methods Only For Testing

- (GREYAppState)grey_lastKnownStateForObject:(id)object {
  return [[self grey_performBlockInCriticalSection:^id {
    GREYObjectDeallocationTracker *internal =
        [GREYObjectDeallocationTracker deallocationTrackerRegisteredWithObject:object];
    GREYAppStateTrackerObject *external =
        objc_getAssociatedObject(internal, @selector(currentState));
    return external ? @(external.state) : kGREYIdle;
  }] unsignedIntegerValue];
}

#pragma mark - Package Internal

- (void)grey_clearState {
  [self grey_performBlockInCriticalSection:^id {
    _currentState = kGREYIdle;
    [_stateDictionary removeAllObjects];
    // We get rid of the strong reference from internal to external object so that the external
    // object can get deallocated.
    for (GREYAppStateTrackerObject *externalObject in _externalTrackerObjects) {
      GREYObjectDeallocationTracker *internalObject = externalObject.object;
      objc_setAssociatedObject(internalObject,
                               @selector(currentState),
                               nil,
                               OBJC_ASSOCIATION_ASSIGN);
    }
    [_externalTrackerObjects removeAllObjects];
    return nil;
  }];
}

#pragma mark - GREYAppStateTrackerObjectDelegate

-(void)objectTrackerDidDeallocate:(GREYObjectDeallocationTracker *)objectDeallocationTracker {
  [self grey_changeState:kGREYIdle
                     usingOperation:kGREYClearState
                          forObject:nil
orInternalObjectDeallocationTracker:objectDeallocationTracker
    orExternalAppStateTrackerObject:nil];
}

@end
