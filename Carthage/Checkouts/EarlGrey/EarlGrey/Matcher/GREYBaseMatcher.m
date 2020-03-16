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

#import "Matcher/GREYBaseMatcher.h"
#import "Matcher/GREYStringDescription.h"

@implementation GREYBaseMatcher

- (NSString *)description {
  id<GREYDescription> stringDescription = [[GREYStringDescription alloc] init];
  [self describeTo:stringDescription];
  return stringDescription.description;
}

- (BOOL)matches:(id)item {
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (BOOL)matches:(id)item describingMismatchTo:(id<GREYDescription>)mismatchDescription {
  BOOL matchResult = [self matches:item];
  if (!matchResult) {
    [self describeTo:mismatchDescription];
  }
  return matchResult;
}

- (void)describeMismatchOf:(id)item to:(id<GREYDescription>)mismatchDescription {
  [self describeTo:mismatchDescription];
}

- (void)describeTo:(id<GREYDescription>)description {
  [self doesNotRecognizeSelector:_cmd];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return self;
}

@end
