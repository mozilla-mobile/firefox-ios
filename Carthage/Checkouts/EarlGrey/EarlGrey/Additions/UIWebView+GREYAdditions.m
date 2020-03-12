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

#import "Additions/UIWebView+GREYAdditions.h"

#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0

#import <UIKit/UIKit.h>
#include <objc/runtime.h>

#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Delegate/GREYUIWebViewDelegate.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYAppStateTrackerObject.h"
#import "Synchronization/GREYTimedIdlingResource.h"

/**
 *  Key for tracking the web view's loading state. Used to track the web view with respect to its
 *  delegate callbacks, which is more reliable than UIWebView's isLoading method.
 */
static void const *const kUIWebViewLoadingStateKey = &kUIWebViewLoadingStateKey;

@implementation UIWebView (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzleSuccess = [swizzler swizzleClass:self
                           replaceInstanceMethod:@selector(delegate)
                                      withMethod:@selector(greyswizzled_delegate)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIWebView delegate");

    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(setDelegate:)
                                 withMethod:@selector(greyswizzled_setDelegate:)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIWebView setDelegate:");

    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(stopLoading)
                                 withMethod:@selector(greyswizzled_stopLoading)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIWebView stopLoading:");
  }
}

#pragma mark - Package Internal

- (void)grey_clearPendingInteraction {
  GREYTimedIdlingResource *timedIdlingResource =
      objc_getAssociatedObject(self, @selector(grey_pendingInteractionForTime:));
  [timedIdlingResource stopMonitoring];
  objc_setAssociatedObject(self,
                           @selector(grey_pendingInteractionForTime:),
                           nil,
                           OBJC_ASSOCIATION_ASSIGN);
}

- (void)grey_pendingInteractionForTime:(NSTimeInterval)seconds {
  [self grey_clearPendingInteraction];
  NSString *resourceName =
      [NSString stringWithFormat:@"Timed idling resource for <%@:%p>", [self class], self];
  id<GREYIdlingResource> timedResource = [GREYTimedIdlingResource resourceForObject:self
                                                              thatIsBusyForDuration:seconds
                                                                               name:resourceName];
  objc_setAssociatedObject(self,
                           @selector(grey_pendingInteractionForTime:),
                           timedResource,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)grey_trackAJAXLoading {
  GREYAppStateTrackerObject *object =
      TRACK_STATE_FOR_OBJECT(kGREYPendingUIWebViewAsyncRequest, self);
  objc_setAssociatedObject(self,
                           @selector(grey_trackAJAXLoading),
                           object,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)grey_untrackAJAXLoading {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(grey_trackAJAXLoading));
  UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIWebViewAsyncRequest, object);
  objc_setAssociatedObject(self,
                           @selector(grey_trackAJAXLoading),
                           nil,
                           OBJC_ASSOCIATION_ASSIGN);
}

- (void)grey_setIsLoadingFrame:(BOOL)loading {
  objc_setAssociatedObject(self,
                           kUIWebViewLoadingStateKey,
                           @(loading),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)grey_isLoadingFrame {
  NSNumber *loading = objc_getAssociatedObject(self, kUIWebViewLoadingStateKey);
  return [loading boolValue];
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_stopLoading {
  [self grey_untrackAJAXLoading];
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_stopLoading));
}

- (void)greyswizzled_setDelegate:(id<UIWebViewDelegate>)delegate {
  id<UIWebViewDelegate> proxyDelegate = [self grey_proxyDelegateFromDelegate:delegate];
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setDelegate:), proxyDelegate);
}

- (id<UIWebViewDelegate>)greyswizzled_delegate {
  // If a delegate was never set we still need the proxy delegate for tracking.
  // It's possible for setDelegate to be used and then delegate calls to be received w/o
  // grey_delegate being called, thus we need to check for and install the proxy delegate in both
  // grey_setDelegate and grey_delegate.
  id<UIWebViewDelegate> originalDelegate =
      INVOKE_ORIGINAL_IMP(id<UIWebViewDelegate>, @selector(greyswizzled_delegate));
  id<UIWebViewDelegate> proxyDelegate = [self grey_proxyDelegateFromDelegate:originalDelegate];
  if (originalDelegate != proxyDelegate) {
    INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setDelegate:), proxyDelegate);
  }
  return proxyDelegate;
}

#pragma mark - Private

/**
 *  Helper method for wrapping a provided delegate in a GREYUIWebViewDelegate object.
 *
 *  @param delegate The original UIWebViewDelegate being proxied.
 *
 *  @return instance of GREYUIWebViewDelegate backed by the original delegate.
 */
- (id<UIWebViewDelegate>)grey_proxyDelegateFromDelegate:(id<UIWebViewDelegate>)delegate {
  id<UIWebViewDelegate> proxyDelegate = delegate;

  if (![proxyDelegate isKindOfClass:[GREYUIWebViewDelegate class]]) {
    proxyDelegate = [[GREYUIWebViewDelegate alloc] initWithOriginalDelegate:delegate isWeak:YES];

    // We need to keep a list of all proxy delegates as someone could be holding a weak reference to
    // it. This list will get cleaned up as soon as webview is deallocated so we might have a slight
    // memory spike (as we are holding onto delegates) until then.
    NSMutableArray *delegateList = objc_getAssociatedObject(self, @selector(greyswizzled_delegate));
    if (!delegateList) {
      delegateList = [[NSMutableArray alloc] init];
    }

    [delegateList addObject:proxyDelegate];
    // Store delegate using objc_setAssociatedObject because setDelegate method doesn't retain.
    objc_setAssociatedObject(self,
                             @selector(greyswizzled_delegate),
                             delegateList,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return proxyDelegate;
}

@end

#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
