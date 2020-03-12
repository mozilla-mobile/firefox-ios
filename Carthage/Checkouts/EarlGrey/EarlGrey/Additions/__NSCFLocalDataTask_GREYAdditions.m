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

#import "Additions/__NSCFLocalDataTask_GREYAdditions.h"

#include <objc/runtime.h>

#import "Additions/NSURL+GREYAdditions.h"
#import "Additions/NSURLSession+GREYAdditions.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYObjcRuntime.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYAppStateTrackerObject.h"

@implementation __NSCFLocalDataTask_GREYAdditions

+ (void)load {
  @autoreleasepool {
    // Note that we swizzle __NSCFLocalDataTask instead of NSURLSessionTask because on iOS 7.0
    // swizzling NSURLSessionTask causes a silent failure i.e. swizzling succeeds here but the
    // actual invocation of resume does not get routed to the swizzled method. Instead if we
    // swizzle __NSCFLocalDataTask it works on iOS 7.0 and 8.0. This is possibly because
    // __NSCFLocalDataTask is some kind of the internal class in use for iOS 7.0.
    Class class = NSClassFromString(@"__NSCFLocalDataTask");
    [GREYObjcRuntime addInstanceMethodToClass:class
                                 withSelector:@selector(grey_track)
                                    fromClass:self];
    [GREYObjcRuntime addInstanceMethodToClass:class
                                 withSelector:@selector(grey_untrack)
                                    fromClass:self];
    [GREYObjcRuntime addInstanceMethodToClass:class
                                 withSelector:@selector(grey_neverTrack)
                                    fromClass:self];

    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    IMP newImplementation = [self instanceMethodForSelector:@selector(greyswizzled_resume)];
    BOOL swizzleSuccess = [swizzler swizzleClass:class
                               addInstanceMethod:@selector(greyswizzled_resume)
                              withImplementation:newImplementation
                    andReplaceWithInstanceMethod:@selector(resume)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Could not swizzle resume in %@", class);
  }
}

- (void)grey_track {
  id isIgnored = objc_getAssociatedObject(self, @selector(grey_neverTrack));
  if (!isIgnored) {
    GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingNetworkRequest, self);
    // Use OBJC_ASSOCIATION_RETAIN here to make both reads and writes atomic.
    // The method below (setState:) which reads and writes this associated object can be
    // invoked on background threads. This can cause a race condition where the object
    // is set to nil by one thread and read by another. The read gets a deallocated
    // instance of the object back which causes EXC_BAD_ACCESS. Using OBJC_ASSOCIATION_RETAIN
    // prevents this.
    objc_setAssociatedObject(self,
                             @selector(grey_track),
                             object,
                             OBJC_ASSOCIATION_RETAIN);
  }
}

- (void)grey_untrack {
  GREYAppStateTrackerObject *object = objc_getAssociatedObject(self, @selector(grey_track));
  if (object) {
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingNetworkRequest, object);
    objc_setAssociatedObject(self,
                             @selector(grey_track),
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
}

- (void)grey_neverTrack {
  // Use atomic associated object (property) as this method can be accessed from across threads and
  // atomic will ensure that we return whole values.
  objc_setAssociatedObject(self,
                           @selector(grey_neverTrack),
                           @(YES),
                           OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Swizzled Implementations

- (void)greyswizzled_resume {
  // Note: since this method is added at runtime into __NSCFLocalDataTask class, self is not an
  // instance of this class but of __NSCFLocalDataTask class.
  id task = self;
  if ([[task currentRequest].URL grey_shouldSynchronize]) {
    [task grey_track];
  }
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_resume));
}

@end
