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

#import "Matcher/GREYHCMatcher.h"

#import <OCHamcrest/HCMatcher.h>
#import <OCHamcrest/HCStringDescription.h>

#import "Common/GREYFatalAsserts.h"

@implementation GREYHCMatcher {
  id<HCMatcher> _hamcrestMatcher;
}

- (instancetype)initWithHCMatcher:(id)HCMatcher {
  GREYFatalAssertWithMessage([HCMatcher conformsToProtocol:@protocol(HCMatcher)],
                             @"matcher must be an HCMatcher");

  self = [super init];
  if(self) {
    _hamcrestMatcher = HCMatcher;
  }
  return self;
}

- (BOOL)matches:(id)item {
  return [_hamcrestMatcher matches:item];
}

- (BOOL)matches:(id)item describingMismatchTo:(id<GREYDescription>)mismatchDescription {
  HCStringDescription *stringDescription = [HCStringDescription stringDescription];
  BOOL matches = [_hamcrestMatcher matches:item describingMismatchTo:stringDescription];
  NSString *returnedStringDescription = stringDescription.description;
  if (returnedStringDescription) {
    [mismatchDescription appendText:returnedStringDescription];
  }
  return matches;
}

- (void)describeMismatchOf:(id)item to:(id<GREYDescription>)mismatchDescription {
  HCStringDescription *stringDescription = [HCStringDescription stringDescription];
  [_hamcrestMatcher describeMismatchOf:item to:stringDescription];
  NSString *returnedStringDescription = stringDescription.description;
  if (returnedStringDescription) {
    [mismatchDescription appendText:returnedStringDescription];
  }
}

- (void)describeTo:(id<GREYDescription>)description {
  HCStringDescription *stringDescription = [HCStringDescription stringDescription];
  [_hamcrestMatcher describeTo:stringDescription];
  NSString *returnedStringDescription = stringDescription.description;
  if (returnedStringDescription) {
    [description appendText:returnedStringDescription];
  }
}

@end
