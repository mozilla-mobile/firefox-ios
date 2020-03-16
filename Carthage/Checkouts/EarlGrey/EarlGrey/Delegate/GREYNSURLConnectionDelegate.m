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

#import "Delegate/GREYNSURLConnectionDelegate.h"

#import "Additions/NSURLConnection+GREYAdditions.h"
#import "Common/GREYDefines.h"
#import "Synchronization/GREYAppStateTracker.h"

@implementation GREYNSURLConnectionDelegate

- (instancetype)initWithOriginalNSURLConnectionDelegate:(id)originalDelegate {
  return [super initWithOriginalDelegate:originalDelegate isWeak:NO];
}

#pragma mark - NSURLConnectionDelegate Protocol

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [connection grey_untrackPending];

  if ([self.originalDelegate respondsToSelector:_cmd]) {
    [self.originalDelegate connection:connection didFailWithError:error];
  }
}

#pragma mark - NSURLConnectionDataDelegate Protocol

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  [connection grey_untrackPending];

  if ([self.originalDelegate respondsToSelector:_cmd]) {
    [self.originalDelegate connectionDidFinishLoading:connection];
  }
}

@end
