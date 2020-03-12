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

#import "Assertion/GREYAssertionBlock.h"

#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYDefines.h"
#import "Common/GREYThrowDefines.h"

@implementation GREYAssertionBlock {
  NSString *_name;
  GREYCheckBlockWithError _checkBlockWithError;
}

+ (instancetype)assertionWithName:(NSString *)name
          assertionBlockWithError:(GREYCheckBlockWithError)block {
  return [[GREYAssertionBlock alloc] initWithName:name assertionBlockWithError:block];
}

- (instancetype)initWithName:(NSString *)name
      assertionBlockWithError:(GREYCheckBlockWithError)block {
  GREYThrowOnNilParameter(name);
  GREYThrowOnNilParameter(block);

  self = [super init];
  if (self) {
    _name = name;
    _checkBlockWithError = [block copy];
  }
  return self;
}

#pragma mark - GREYAssertion

- (NSString *)name {
  return _name;
}

- (BOOL)assert:(id)element error:(__strong NSError **)errorOrNil {
  return _checkBlockWithError(element, errorOrNil);
}

@end
