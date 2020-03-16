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

#import "Additions/UIViewController+GREYAdditions.h"

#include <objc/runtime.h>

#import "Common/GREYAppleInternals.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYAppStateTrackerObject.h"

/**
 *  The class for UICompatibilityInputViewController which isn't tracked here since we've faced
 *  issues with tracking it when it comes to typing on keyboards with accessory views.
 */
static Class gInputAccessoryVCClass;

@implementation UIViewController (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    // Swizzle viewWillAppear.
    BOOL swizzleSuccess = [swizzler swizzleClass:self
                           replaceInstanceMethod:@selector(viewWillAppear:)
                                      withMethod:@selector(greyswizzled_viewWillAppear:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIViewController viewWillAppear");
    // Swizzle viewDidAppear.
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(viewDidAppear:)
                                 withMethod:@selector(greyswizzled_viewDidAppear:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIViewController viewDidAppear");
    // Swizzle viewWillDisappear.
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(viewWillDisappear:)
                                 withMethod:@selector(greyswizzled_viewWillDisappear:)];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIViewController viewWillDisappear");
    // Swizzle viewDidDisappear.
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(viewDidDisappear:)
                                 withMethod:@selector(greyswizzled_viewDidDisappear:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIViewController viewDidDisappear");
    // Swizzle viewWillMoveToWindow.
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(viewWillMoveToWindow:)
                                 withMethod:@selector(greyswizzled_viewWillMoveToWindow:)];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIViewController viewWillMoveToWindow:");
    // Swizzle viewDidMoveToWindow:shouldAppearOrDisappear.
    SEL swizzledSel = @selector(greyswizzled_viewDidMoveToWindow:shouldAppearOrDisappear:);
    swizzleSuccess =
        [swizzler swizzleClass:self
         replaceInstanceMethod:@selector(viewDidMoveToWindow:shouldAppearOrDisappear:)
                    withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIViewController viewDidMoveToWindow:"
                               @"shouldAppearOrDisappear:");
  }
}

__attribute__((constructor)) static void initialize(void) {
  if (iOS13_OR_ABOVE()) {
    gInputAccessoryVCClass = NSClassFromString(@"UIEditingOverlayViewController");
  } else {
    gInputAccessoryVCClass = NSClassFromString(@"UICompatibilityInputViewController");
  }
}

- (void)grey_trackAsRootViewControllerForWindow:(UIWindow *)window {
  // Untrack state for hidden (or nil) windows. When window becomes visible, this method will be
  // called again.
  if (!window || window.hidden) {
    GREYAppStateTrackerObject *object =
        objc_getAssociatedObject(self, @selector(greyswizzled_viewWillAppear:));
    GREYAppState state = kGREYPendingViewsToAppear | kGREYPendingRootViewControllerToAppear;
    UNTRACK_STATE_FOR_OBJECT(state, object);
  } else if (![self grey_hasAppeared]) {
    GREYAppStateTrackerObject *object =
        TRACK_STATE_FOR_OBJECT(kGREYPendingRootViewControllerToAppear, self);
    objc_setAssociatedObject(self,
                             @selector(greyswizzled_viewWillAppear:),
                             object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_viewWillMoveToWindow:(id)window {
  objc_setAssociatedObject(self,
                           @selector(grey_isMovingToNilWindow),
                           (window == nil) ? @(YES) : @(NO),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_viewWillMoveToWindow:), window);
}

- (void)greyswizzled_viewDidMoveToWindow:(id)window
                 shouldAppearOrDisappear:(BOOL)appearOrDisappear {
  // Untrack the UIViewController when it moves to a nil window. We must clear the state regardless
  // of |arg|, because viewDidAppear, viewWillDisappear or viewDidDisappear will not be called.
  if (!window) {
    GREYAppStateTrackerObject *object =
        objc_getAssociatedObject(self, @selector(greyswizzled_viewWillAppear:));
    GREYAppState state = (kGREYPendingViewsToAppear |
                          kGREYPendingRootViewControllerToAppear |
                          kGREYPendingViewsToDisappear);
    UNTRACK_STATE_FOR_OBJECT(state, object);
  }
  INVOKE_ORIGINAL_IMP2(void,
                       @selector(greyswizzled_viewDidMoveToWindow:shouldAppearOrDisappear:),
                       window,
                       appearOrDisappear);
}

- (void)greyswizzled_viewWillAppear:(BOOL)animated {
  // For UICompatibilityInputViewController and UIEditingOverlayViewController, which are keyboard
  // related classes, do not track this state due to issues seen with untracking.
  if (![self isKindOfClass:gInputAccessoryVCClass]) {
    BOOL movingToNilWindow = [self grey_isMovingToNilWindow];
    if (movingToNilWindow) {
      GREYLogVerbose(@"View is moving to nil window. Skipping viewWillAppear state tracking.");
    }

    if (!movingToNilWindow) {
      // Interactive transitions can cancel and cause imbalance of will and did calls.
      id<UIViewControllerTransitionCoordinator> coordinator = [self transitionCoordinator];
      if (coordinator && [coordinator initiallyInteractive]) {
        void (^contextBlock)(id<UIViewControllerTransitionCoordinatorContext>) =
            ^(id<UIViewControllerTransitionCoordinatorContext> context) {
              if ([context isCancelled]) {
                id object = objc_getAssociatedObject(self, @selector(greyswizzled_viewWillAppear:));
                UNTRACK_STATE_FOR_OBJECT(kGREYPendingViewsToAppear, object);
              }
            };
#if !defined(__IPHONE_10_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0)
        [coordinator notifyWhenInteractionEndsUsingBlock:contextBlock];
#else
        [coordinator notifyWhenInteractionChangesUsingBlock:contextBlock];
#endif
      }

      GREYAppStateTrackerObject *object =
          TRACK_STATE_FOR_OBJECT(kGREYPendingViewsToAppear, self);
      objc_setAssociatedObject(self,
                               @selector(greyswizzled_viewWillAppear:),
                               object,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_viewWillAppear:), animated);
}

- (void)greyswizzled_viewDidAppear:(BOOL)animated {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(greyswizzled_viewWillAppear:));
  GREYAppState state = kGREYPendingViewsToAppear | kGREYPendingRootViewControllerToAppear;
  UNTRACK_STATE_FOR_OBJECT(state, object);

  [self grey_setAppeared:YES];
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_viewDidAppear:), animated);
}

- (void)greyswizzled_viewWillDisappear:(BOOL)animated {
  BOOL movingToNilWindow = [self grey_isMovingToNilWindow];
  if (movingToNilWindow) {
    GREYLogVerbose(@"View is moving to nil window. Skipping viewWillDisappear state tracking.");
  }

  if (!movingToNilWindow) {
    // Interactive transitions can cancel and cause imbalance of will and did calls.
    id<UIViewControllerTransitionCoordinator> coordinator = [self transitionCoordinator];
    if (coordinator && [coordinator initiallyInteractive]) {
      void (^contextBlock)(id<UIViewControllerTransitionCoordinatorContext>) =
          ^(id<UIViewControllerTransitionCoordinatorContext> context) {
            if ([context isCancelled]) {
              GREYAppStateTrackerObject *object =
                  objc_getAssociatedObject(self, @selector(greyswizzled_viewWillAppear:));
              UNTRACK_STATE_FOR_OBJECT(kGREYPendingViewsToDisappear, object);
            }
          };
#if !defined(__IPHONE_10_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0)
      [coordinator notifyWhenInteractionEndsUsingBlock:contextBlock];
#else
      [coordinator notifyWhenInteractionChangesUsingBlock:contextBlock];
#endif
    }

    GREYAppStateTrackerObject *object =
        TRACK_STATE_FOR_OBJECT(kGREYPendingViewsToDisappear, self);
    objc_setAssociatedObject(self,
                             @selector(greyswizzled_viewWillAppear:),
                             object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_viewWillDisappear:), animated);
}

- (void)greyswizzled_viewDidDisappear:(BOOL)animated {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(greyswizzled_viewWillAppear:));
  GREYAppState state = (kGREYPendingViewsToAppear |
                        kGREYPendingRootViewControllerToAppear |
                        kGREYPendingViewsToDisappear);
  UNTRACK_STATE_FOR_OBJECT(state, object);

  [self grey_setAppeared:NO];
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_viewDidDisappear:), animated);
}

#pragma mark - Private

/**
 *  @return @c YES if the view backed by this view controller has UIViewController::viewDidAppear:
 *          callback called and no other disappearance methods have been invoked.
 */
- (BOOL)grey_hasAppeared {
  return [objc_getAssociatedObject(self, @selector(grey_hasAppeared)) boolValue];
}

/**
 *  Sets the appearance state of the view backed by this view controller to value of @c appeared.
 *  Use UIViewController::grey_hasAppeared to query this value.
 *
 *  @param appeared A @c BOOL indicating if the view backed by this view controller has appeared.
 */
- (void)grey_setAppeared:(BOOL)appeared {
  objc_setAssociatedObject(self,
                           @selector(grey_hasAppeared),
                           @(appeared),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 *  @return @c YES if self or any ancestor of the view controller is moving to a @c nil window.
 */
- (BOOL)grey_isMovingToNilWindow {
  UIViewController *parent = self;
  while (parent) {
    if ([objc_getAssociatedObject(parent, @selector(grey_isMovingToNilWindow)) boolValue]) {
      return YES;
    }
    parent = [parent parentViewController];
  }
  return NO;
}

@end
