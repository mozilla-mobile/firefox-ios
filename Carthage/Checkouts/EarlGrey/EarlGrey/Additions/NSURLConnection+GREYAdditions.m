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

#import "Additions/NSURLConnection+GREYAdditions.h"

#include <objc/runtime.h>

#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/NSURL+GREYAdditions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Delegate/GREYNSURLConnectionDelegate.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYAppStateTrackerObject.h"

typedef void (^NSURLConnectionCompletionBlock)(NSURLResponse *, NSData *, NSError *);

@implementation NSURLConnection (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    SEL originalSelector = @selector(sendAsynchronousRequest:queue:completionHandler:);
    SEL swizzledSelector = @selector(greyswizzled_sendAsynchronousRequest:queue:completionHandler:);
    BOOL swizzleSuccess = [swizzler swizzleClass:self
                              replaceClassMethod:originalSelector
                                      withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle NSURLConnection::"
                               @"sendAsynchronousRequest:queue:completionHandler:");

    originalSelector = @selector(sendSynchronousRequest:returningResponse:error:);
    swizzledSelector = @selector(greyswizzled_sendSynchronousRequest:returningResponse:error:);
    swizzleSuccess = [swizzler swizzleClass:self
                         replaceClassMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle "
                               @"NSURLConnection::sendSynchronousRequest:returningResponse:error:");

    originalSelector = @selector(connectionWithRequest:delegate:);
    swizzledSelector = @selector(greyswizzled_connectionWithRequest:delegate:);
    swizzleSuccess = [swizzler swizzleClass:self
                         replaceClassMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle NSURLConnection::connectionWithRequest:delegate:");

    originalSelector = @selector(initWithRequest:delegate:startImmediately:);
    swizzledSelector = @selector(greyswizzled_initWithRequest:delegate:startImmediately:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle "
                               @"NSURLConnection::initWithRequest:delegate:startImmediately:");

    originalSelector = @selector(initWithRequest:delegate:);
    swizzledSelector = @selector(greyswizzled_initWithRequest:delegate:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle NSURLConnection::initWithRequest:delegate:");

    originalSelector = @selector(start);
    swizzledSelector = @selector(greyswizzled_start);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle NSURLConnection::start");

    originalSelector = @selector(cancel);
    swizzledSelector = @selector(greyswizzled_cancel);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle NSURLConnection::cancel");
  }
}

#pragma mark - Package Internal

- (void)grey_trackPending {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingNetworkRequest, self);
  objc_setAssociatedObject(self,
                           @selector(grey_trackPending),
                           object,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)grey_untrackPending {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(grey_trackPending));
  UNTRACK_STATE_FOR_OBJECT(kGREYPendingNetworkRequest, object);
}

#pragma mark - Swizzled Implementation

+ (NSData *)greyswizzled_sendSynchronousRequest:(NSURLRequest *)request
                              returningResponse:(NSURLResponse **)response
                                          error:(NSError **)error {
  GREYAppStateTrackerObject *object;
  NSObject *uniqueIdentifier;
  if ([request.URL grey_shouldSynchronize] && ![NSThread isMainThread]) {
    uniqueIdentifier = [[NSObject alloc] init];
    object = TRACK_STATE_FOR_OBJECT(kGREYPendingNetworkRequest, uniqueIdentifier);
  }

  NSData *data =
      INVOKE_ORIGINAL_IMP3(NSData *,
                           @selector(greyswizzled_sendSynchronousRequest:returningResponse:error:),
                           request,
                           response,
                           error);
  if (object) {
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingNetworkRequest, object);
    // Hold a reference to the unique identifier until we no longer track the connection.
    uniqueIdentifier = nil;
  }
  return data;
}


+ (void)greyswizzled_sendAsynchronousRequest:(NSURLRequest *)request
                                       queue:(NSOperationQueue *)queue
                           completionHandler:(NSURLConnectionCompletionBlock)handler {
  void (^completionHandler)(NSURLResponse *, NSData *, NSError *) = handler;
  if ([request.URL grey_shouldSynchronize]) {
    // Use a unique identifier to track connection.
    __block NSObject *uniqueIdentifier = [[NSObject alloc] init];
    GREYAppStateTrackerObject *object =
        TRACK_STATE_FOR_OBJECT(kGREYPendingNetworkRequest, uniqueIdentifier);
    completionHandler = ^(NSURLResponse *response,
                          NSData *data,
                          NSError *error) {
      handler(response, data, error);
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingNetworkRequest, object);
      // Hold a reference to the unique identifier until we no longer track the connection.
      uniqueIdentifier = nil;
    };
  }
  INVOKE_ORIGINAL_IMP3(void,
                       @selector(greyswizzled_sendAsynchronousRequest:queue:completionHandler:),
                       request,
                       queue,
                       completionHandler);
}

+ (NSURLConnection *)greyswizzled_connectionWithRequest:(NSURLRequest *)request
                                               delegate:(id<NSURLConnectionDelegate>)delegate {
  GREYNSURLConnectionDelegate *proxyDelegate =
      [[GREYNSURLConnectionDelegate alloc] initWithOriginalNSURLConnectionDelegate:delegate];
  NSURLConnection *connection =
      INVOKE_ORIGINAL_IMP2(NSURLConnection *,
                           @selector(greyswizzled_connectionWithRequest:delegate:),
                           request,
                           proxyDelegate);
  return connection;
}

- (instancetype)greyswizzled_initWithRequest:(NSURLRequest *)request
                                    delegate:(id<NSURLConnectionDelegate>)delegate {
  GREYNSURLConnectionDelegate *proxyDelegate =
      [[GREYNSURLConnectionDelegate alloc] initWithOriginalNSURLConnectionDelegate:delegate];
  id instance = INVOKE_ORIGINAL_IMP2(id,
                                     @selector(greyswizzled_initWithRequest:delegate:),
                                     request,
                                     proxyDelegate);
  // Track since this call will begin to load data from request.
  if ([request.URL grey_shouldSynchronize]) {
    [instance grey_trackPending];
  }
  return instance;
}

- (instancetype)greyswizzled_initWithRequest:(NSURLRequest *)request
                                    delegate:(id<NSURLConnectionDelegate>)delegate
                            startImmediately:(BOOL)startImmediately {
  if (startImmediately && [request.URL grey_shouldSynchronize]) {
    [self grey_trackPending];
  }
  GREYNSURLConnectionDelegate *proxyDelegate =
      [[GREYNSURLConnectionDelegate alloc] initWithOriginalNSURLConnectionDelegate:delegate];

  return INVOKE_ORIGINAL_IMP3(id,
                              @selector(greyswizzled_initWithRequest:delegate:startImmediately:),
                              request,
                              proxyDelegate,
                              startImmediately);
}

- (void)greyswizzled_start {
  if ([self.originalRequest.URL grey_shouldSynchronize]) {
    [self grey_trackPending];
  }

  return INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_start));
}

- (void)greyswizzled_cancel {
  [self grey_untrackPending];

  return INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_cancel));
}

@end
