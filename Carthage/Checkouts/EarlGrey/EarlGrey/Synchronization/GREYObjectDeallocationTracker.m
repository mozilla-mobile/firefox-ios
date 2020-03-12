//
// Copyright 2017 Google Inc.
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

#import "Synchronization/GREYObjectDeallocationTracker.h"

#import <objc/runtime.h>

#import "Common/GREYThrowDefines.h"

@interface GREYObjectDeallocationTracker ()

/**
 *  Weakly held delegate property to convey the message that the object is being deallocated.
 */
@property(nonatomic, weak) id<GREYObjectDeallocationTrackerDelegate> deallocDelegate;

@end

@implementation GREYObjectDeallocationTracker

- (void)dealloc {
  [self.deallocDelegate objectTrackerDidDeallocate:self];
}

- (instancetype)initWithObject:(id)object
                      delegate:(id<GREYObjectDeallocationTrackerDelegate>)delegate {
  self = [super init];
  if (self) {
    _deallocDelegate = delegate;
    // Create a strong reference from @c object to self. This is necessary so that when @c object
    // deallocates then self deallocates. In this way, GREYObjectDeallocatingTracker knows about
    // the deallocation of @c object.
    objc_setAssociatedObject(object,
                             @selector(initWithObject:delegate:),
                             self,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return self;
}

+ (GREYObjectDeallocationTracker *)deallocationTrackerRegisteredWithObject:(id)object {
  return objc_getAssociatedObject(object, @selector(initWithObject:delegate:));
}

@end
