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

#import "Matcher/GREYNot.h"

#import "Common/GREYThrowDefines.h"

@implementation GREYNot {
  id<GREYMatcher> _matcher;
}

- (instancetype)initWithMatcher:(id<GREYMatcher>)matcher {
  GREYThrowOnNilParameter(matcher);

  self = [super init];
  if (self) {
    _matcher = matcher;
  }
  return self;
}

#pragma mark - GREYMatcher

- (BOOL)matches:(id)item {
  return ![_matcher matches:item];
}

- (void)describeTo:(id<GREYDescription>)description {
  [[[description appendText:@"!("] appendDescriptionOf:_matcher] appendText:@")"];
}

@end

#if !(GREY_DISABLE_SHORTHAND)

GREY_EXPORT id<GREYMatcher> grey_not(id<GREYMatcher> matcher) {
  return [[GREYNot alloc] initWithMatcher:matcher];
}

#endif // GREY_DISABLE_SHORTHAND
