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

#import "Synchronization/GREYOperationQueueIdlingResource.h"

#import "Common/GREYDefines.h"
#import "Common/GREYThrowDefines.h"
#import "Synchronization/GREYUIThreadExecutor+Internal.h"
#import "Synchronization/GREYUIThreadExecutor.h"

@implementation GREYOperationQueueIdlingResource {
  NSString *_operationQueueName;
  __weak NSOperationQueue *_operationQueue;
}

+ (instancetype)resourceWithNSOperationQueue:(NSOperationQueue *)queue name:(NSString *)name {
  GREYThrowOnNilParameter(queue);

  GREYOperationQueueIdlingResource *resource = [[GREYOperationQueueIdlingResource alloc]
                                                 initWithNSOperationQueue:queue
                                                                  andName:name];
  return resource;
}

- (instancetype)initWithNSOperationQueue:(NSOperationQueue *)queue andName:(NSString *)name {
  self = [super init];
  if (self) {
    _operationQueueName = [name copy];
    _operationQueue = queue;
  }
  return self;
}

#pragma mark - GREYIdlingResource

- (NSString *)idlingResourceName {
  return _operationQueueName;
}

- (NSString *)idlingResourceDescription {
  return _operationQueueName;
}

- (BOOL)isIdleNow {
  if (!_operationQueue) {
    [[GREYUIThreadExecutor sharedInstance] deregisterIdlingResource:self];
    return YES;
  }
  return [_operationQueue operationCount] == 0;
}

@end
