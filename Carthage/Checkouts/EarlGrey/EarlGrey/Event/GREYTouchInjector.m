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

#import "Event/GREYTouchInjector.h"

#import <QuartzCore/QuartzCore.h>
#include <mach/mach_time.h>

#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/UITouch+GREYAdditions.h"
#import "Additions/UIWebView+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYAppleInternals.h"
#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYThrowDefines.h"
#import "Event/GREYZeroToleranceTimer.h"
#import "Synchronization/GREYRunLoopSpinner.h"

const NSTimeInterval kGREYTouchInjectionFrequency = 60.0;

/**
 *  The time interval in seconds between each touch injection.
 */
static const NSTimeInterval kGREYTouchInjectionInterval = 1.0 / kGREYTouchInjectionFrequency;

#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
/**
 *  Maximum time to wait for UIWebView delegates to get called after the
 *  last touch (i.e. @c isLastTouch is @c YES).
 */
static const NSTimeInterval kGREYMaxIntervalForUIWebViewResponse = 2.0;
#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0

@interface GREYTouchInjector() <GREYZeroToleranceTimerTarget>
@end

@implementation GREYTouchInjector {
  // Window to which touches will be delivered.
  UIWindow *_window;
  // List of objects that aid in creation of UITouches.
  NSMutableArray *_enqueuedTouchInfoList;
  // A timer used for injecting touches.
  GREYZeroToleranceTimer *_timer;
  // Touch objects created to start the touch sequence for every
  // touch points. It stores one UITouch object for each finger
  // in a touch event.
  NSMutableArray *_ongoingUITouches;
  // Time at which previous touch event was delivered.
  CFTimeInterval _previousTouchDeliveryTime;
  // Current state of the injector.
  GREYTouchInjectorState _state;
  // The previously injected touch event. Used to determine
  // whether an injected touch needs to be stationary or not.
  // May be nil.
  GREYTouchInfo *_previousTouchInfo;
}

- (instancetype)initWithWindow:(UIWindow *)window {
  GREYThrowOnNilParameter(window);

  self = [super init];
  if (self) {
    _window = window;
    _enqueuedTouchInfoList = [[NSMutableArray alloc] init];
    _state = kGREYTouchInjectorPendingStart;
    _ongoingUITouches = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)enqueueTouchInfoForDelivery:(GREYTouchInfo *)touchInfo {
  GREYFatalAssertMainThread();
  [_enqueuedTouchInfoList addObject:touchInfo];
}

- (GREYTouchInjectorState)state {
  return _state;
}

- (void)startInjecting {
  GREYFatalAssertMainThread();

  if (_state == kGREYTouchInjectorStarted) {
    return;
  }

  _state = kGREYTouchInjectorStarted;
  if (!_timer) {
    _timer = [[GREYZeroToleranceTimer alloc] initWithInterval:kGREYTouchInjectionInterval
                                                       target:self];
  }
}

- (void)waitUntilAllTouchesAreDeliveredUsingInjector {
  GREYFatalAssertMainThread();

  // Start if necessary.
  if (_state == kGREYTouchInjectorPendingStart || _state == kGREYTouchInjectorStopped) {
    [self startInjecting];
  }

  // Now wait for it to finish.
  GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];
  runLoopSpinner.timeout = DBL_MAX;
  runLoopSpinner.minRunLoopDrains = 0;
  runLoopSpinner.maxSleepInterval = DBL_MAX;
  [runLoopSpinner spinWithStopConditionBlock:^BOOL {
    return (_state == kGREYTouchInjectorStopped);
  }];
}

#pragma mark - GREYZeroToleranceTimer

- (void)timerFiredWithZeroToleranceTimer:(GREYZeroToleranceTimer *)timer {
  GREYFatalAssertMainThread();

  GREYTouchInfo *touchInfo =
      [self grey_dequeueTouchInfoForDeliveryWithCurrentTime:CACurrentMediaTime()];
  if (!touchInfo) {
    if (_enqueuedTouchInfoList.count == 0) {
      // Queue is empty - we are done delivering touches.
      [self grey_stopTouchInjection];
    }
    return;
  }
  if ([_ongoingUITouches count] == 0) {
    [self grey_extractAndChangeTouchToStartPhase:touchInfo];
  } else if (touchInfo.phase == GREYTouchInfoPhaseTouchEnded) {
    [self grey_changeTouchToEndPhase:touchInfo];
  } else {
    [self grey_changeTouchToMovePhase:touchInfo];
  }
  [self grey_injectTouches:touchInfo];
}


#pragma mark - Private

/**
 *  Helper method to return UITouch object at @c index from the @c ongoingTouches array.
 *
 *  @param index Index of the @c ongoingTouches array.
 *
 *  @return UITouch object at that given @c index of the @c ongoingTouches array.
 */
- (UITouch *)grey_UITouchForFinger:(NSUInteger)index {
  return (UITouch *)[_ongoingUITouches objectAtIndex:index];
}

/**
 *  Extracts UITouches from @c touchInfo object and inserts those in the ongoingTouches array.
 *  Phase of UITouch is set to UITouchPhaseBegan.
 *
 *  @param touchInfo The info that is used to create the UITouch.
 */
- (void)grey_extractAndChangeTouchToStartPhase:(GREYTouchInfo *)touchInfo {
  for (NSValue *touchPoint in touchInfo.points) {
    CGPoint point = [touchPoint CGPointValue];
    UITouch *touch = [[UITouch alloc] initAtPoint:point relativeToWindow:_window];
    [touch setPhase:UITouchPhaseBegan];
    [_ongoingUITouches addObject:touch];
  }
}

/**
 *  Phase of UITouches is set to UITouchPhaseEnded for the lastTouch condition.
 *
 *  @param touchInfo The info that is used to create the UITouch.
 */
- (void)grey_changeTouchToEndPhase:(GREYTouchInfo *)touchInfo {
  for (NSUInteger i = 0; i < [touchInfo.points count]; i++) {
    UITouch *touch = [self grey_UITouchForFinger:i];
    CGPoint touchPoint = [[_previousTouchInfo.points objectAtIndex:i] CGPointValue];
    [touch _setLocationInWindow:touchPoint resetPrevious:NO];
    [touch setPhase:UITouchPhaseEnded];
  }
}

/**
 *  Phase of UITouches is set to UITouchPhaseMoved and currentTouchLocation is set to the
 *  current touch point.
 *
 *  @param touchInfo The info that is used to create the UITouch.
 */
- (void)grey_changeTouchToMovePhase:(GREYTouchInfo *)touchInfo {
  for (NSUInteger i = 0; i < [touchInfo.points count]; i++) {
    CGPoint touchPoint = [[touchInfo.points objectAtIndex:i] CGPointValue];
    UITouch *touch = [self grey_UITouchForFinger:i];
    [touch _setLocationInWindow:touchPoint resetPrevious:NO];
    CGPoint previousTouchPoint = [[_previousTouchInfo.points objectAtIndex:i] CGPointValue];
    if (CGPointEqualToPoint(previousTouchPoint, touchPoint)) {
      [touch setPhase:UITouchPhaseStationary];
    } else {
      [touch setPhase:UITouchPhaseMoved];
    }
  }
}

/**
 *  Inject touches to the application.
 *
 *  @param touchInfo The info that is used to create the UITouch.
 */
- (void)grey_injectTouches:(GREYTouchInfo *)touchInfo {
  UITouchesEvent *event = [[UIApplication sharedApplication] _touchesEvent];
  // Clean up before injecting touches.
  [event _clearTouches];

  // Array to store all hidEvent references to be released later.
  NSMutableArray *hidEvents = [NSMutableArray arrayWithCapacity:[_ongoingUITouches count]];

  uint64_t machAbsoluteTime = mach_absolute_time();
  AbsoluteTime timeStamp;
  timeStamp.hi = (UInt32)(machAbsoluteTime >> 32);
  timeStamp.lo = (UInt32)(machAbsoluteTime);

  UIView *currentTouchView = nil;
  for (NSUInteger i = 0; i < [_ongoingUITouches count]; i++) {
    UITouch *currentTouch = [self grey_UITouchForFinger:i];
    if (i == 0) {
      currentTouchView = currentTouch.view;
    }
    [currentTouch setTimestamp:[[NSProcessInfo processInfo] systemUptime]];

    IOHIDDigitizerEventMask eventMask = (currentTouch.phase == UITouchPhaseMoved)
        ? kIOHIDDigitizerEventPosition
        : (kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch);

    CGPoint touchLocation = [currentTouch locationInView:currentTouch.window];

    // Both range and touch are set to 0 if phase is UITouchPhaseEnded, 1 otherwise.
    Boolean isRangeAndTouch = (currentTouch.phase != UITouchPhaseEnded);
    IOHIDEventRef hidEvent = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault,
                                                                  timeStamp,
                                                                  0,
                                                                  2,
                                                                  eventMask,
                                                                  touchLocation.x,
                                                                  touchLocation.y,
                                                                  0,
                                                                  0,
                                                                  0,
                                                                  isRangeAndTouch,
                                                                  isRangeAndTouch,
                                                                  0);

    [hidEvents addObject:[NSValue valueWithPointer:hidEvent]];

    if ([currentTouch respondsToSelector:@selector(_setHidEvent:)]) {
      [currentTouch _setHidEvent:hidEvent];
    }
    [event _addTouch:currentTouch forDelayedDelivery:NO];
  }
  [event _setHIDEvent:[[hidEvents objectAtIndex:0] pointerValue]];
  // iOS adds an autorelease pool around every event-based interaction.
  // We should mimic that if we want to relinquish bits in a timely manner.
  @autoreleasepool {
    _previousTouchDeliveryTime = CACurrentMediaTime();
    _previousTouchInfo = touchInfo;
    BOOL touchViewContainsWKWebView = NO;

    @try {
      [[UIApplication sharedApplication] sendEvent:event];

      if (currentTouchView) {
        // If a WKWebView is being tapped, don't call [event _clearTouches], as this causes long
        // presses to fail. For this case, the child of |currentTouchView| is a WKCompositingView.
        UIView *firstChild = currentTouchView.subviews.firstObject;
        if ([firstChild isKindOfClass:NSClassFromString(@"WKCompositingView")]) {
          touchViewContainsWKWebView = YES;
        }
        if (touchInfo.phase == GREYTouchInfoPhaseTouchEnded) {
#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
          UIWebView *touchWebView = nil;
          if ([currentTouchView isKindOfClass:[UIWebView class]]) {
            touchWebView = (UIWebView *)currentTouchView;
          } else {
            NSArray *webViewContainers =
                [currentTouchView grey_containersAssignableFromClass:[UIWebView class]];
            if (webViewContainers.count > 0) {
              touchWebView = (UIWebView *)[webViewContainers firstObject];
            }
          }
          [touchWebView grey_pendingInteractionForTime:kGREYMaxIntervalForUIWebViewResponse];
#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
        }
      }
    } @catch (NSException *e) {
      [self grey_stopTouchInjection];
      @throw;
    } @finally {
      // Clear all touches so that it is not leaked, except for WKWebViews, where these calls
      // can prevent the app tracker from becoming idle.
      if (!touchViewContainsWKWebView) {
        [event _clearTouches];
      }
      // We need to release the event manually, otherwise it will leak.
      for (NSValue *hidEventValue in hidEvents) {
        IOHIDEventRef hidEvent = [hidEventValue pointerValue];
        CFRelease(hidEvent);
      }
      [hidEvents removeAllObjects];
      if (touchInfo.phase == GREYTouchInfoPhaseTouchEnded) {
        [_ongoingUITouches removeAllObjects];
      }
    }
  }
}

/**
 *  Stops touch injection by invalidating the current timer and clearing the touch info list.
 */
- (void)grey_stopTouchInjection {
  _state = kGREYTouchInjectorStopped;
  [_timer invalidate];
  _timer = nil;
  [_enqueuedTouchInfoList removeAllObjects];
}

/**
 *  Dequeues the next touch to be delivered based on @c currentTime.
 *
 *  @param currentTime The time for the next touch to be dequeued.
 *
 *  @return The touch info for the next touch. If a touch could not be dequeued
 *          (which can happen if queue is empty or if we attempt to dequeue too early)
 *          @c nil is returned.
 */
- (GREYTouchInfo *)grey_dequeueTouchInfoForDeliveryWithCurrentTime:(CFTimeInterval)currentTime {
  if (_enqueuedTouchInfoList.count == 0) {
    return nil;
  }
  // Count the number of stale touches.
  NSUInteger staleTouches = 0;
  CFTimeInterval simulatedPreviousDeliveryTime = _previousTouchDeliveryTime;
  for (GREYTouchInfo *touchInfo in _enqueuedTouchInfoList) {
    simulatedPreviousDeliveryTime += touchInfo.deliveryTimeDeltaSinceLastTouch;
    if (touchInfo.isExpendable &&
        simulatedPreviousDeliveryTime < currentTime) {
      staleTouches++;
    } else {
      break;
    }
  }

  // Remove all but the last stale touch if any.
  NSUInteger touchesToRemove = (staleTouches > 1) ? (staleTouches - 1) : 0;
  [_enqueuedTouchInfoList removeObjectsInRange:NSMakeRange(0, touchesToRemove)];
  GREYTouchInfo *dequeuedTouchInfo = [_enqueuedTouchInfoList firstObject];

  CFTimeInterval expectedTouchDeliveryTime =
      dequeuedTouchInfo.deliveryTimeDeltaSinceLastTouch + _previousTouchDeliveryTime;
  if (expectedTouchDeliveryTime > currentTime) {
    // This touch is scheduled to be delivered in the future.
    return nil;
  }
  [_enqueuedTouchInfoList removeObjectAtIndex:0];
  return dequeuedTouchInfo;
}

@end
