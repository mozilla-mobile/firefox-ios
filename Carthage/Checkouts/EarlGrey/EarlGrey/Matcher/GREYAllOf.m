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

#import "Matcher/GREYAllOf.h"

#import "Common/GREYThrowDefines.h"
#import "Matcher/GREYDescription.h"
#import "Matcher/GREYStringDescription.h"

@implementation GREYAllOf {
  NSArray *_matchers;
}

- (instancetype)initWithMatchers:(NSArray *)matchers {
  GREYThrowOnFailedCondition(matchers.count > 0);

  self = [super init];
  if (self) {
    _matchers = matchers;
  }
  return self;
}

#pragma mark - GREYMatcher

- (BOOL)matches:(id)item {
  return [self matches:item describingMismatchTo:[[GREYStringDescription alloc] init]];
}

- (BOOL)matches:(id)item describingMismatchTo:(id<GREYDescription>)mismatchDescription {
  for (id matcher in _matchers) {
    if (![matcher matches:item describingMismatchTo:mismatchDescription]) {
      return NO;
    }
  }
  return YES;
}

- (void)describeTo:(id<GREYDescription>)description {
  [description appendText:@"("];
  for (NSUInteger i = 0; i < _matchers.count - 1; i++) {
    [[description appendDescriptionOf:_matchers[i]] appendText:@" && "];
  }
  [description appendDescriptionOf:_matchers[_matchers.count - 1]];
  [description appendText:@")"];
}

@end

#if !(GREY_DISABLE_SHORTHAND)

id<GREYMatcher> grey_allOf(id<GREYMatcher> first,
                           id<GREYMatcher> second,
                           id<GREYMatcher> thirdOrNil,
                           ...) {
  va_list args;
  va_start(args, thirdOrNil);

  NSMutableArray *matcherList = [[NSMutableArray alloc] initWithObjects:first, second, nil];
  if (thirdOrNil != nil) {
    id<GREYMatcher> nextMatcher = thirdOrNil;
    do {
      [matcherList addObject:nextMatcher];
    } while ((nextMatcher = va_arg(args, id<GREYMatcher>)) != nil);
  }

  va_end(args);
  return [[GREYAllOf alloc] initWithMatchers:matcherList];
}

id<GREYMatcher> grey_allOfMatchers(NSArray<GREYMatcher> *matchers) {
  return [[GREYAllOf alloc] initWithMatchers:matchers];
}

#endif // GREY_DISABLE_SHORTHAND
