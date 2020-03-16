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

#import "Common/GREYTestCaseInvocation.h"

#import "Additions/XCTestCase+GREYAdditions.h"

static NSString *const kGREYTestCaseInvocationExceptionName = @"GREYTestCaseInvocationException";

inline static void checkXCTestCaseIsTypeOfTarget(id target) {
  if (![target isKindOfClass:[XCTestCase class]]) {
    [[NSException exceptionWithName:kGREYTestCaseInvocationExceptionName
                             reason:@"The target of a GREYTestCaseInvocation must be an XCTestCase"
                           userInfo:nil] raise];
  }
}

@implementation GREYTestCaseInvocation

- (void)invokeWithTarget:(id)target {
  checkXCTestCaseIsTypeOfTarget(target);

  @try {
    [super invokeWithTarget:target];
  } @catch (NSException *exception) {
    [(XCTestCase *)self.target grey_setStatus:kGREYXCTestCaseStatusFailed];
    @throw;
  }
}

- (void)invoke {
  checkXCTestCaseIsTypeOfTarget(self.target);

  @try {
    [super invoke];
  } @catch (NSException *exception) {
    [(XCTestCase *)self.target grey_setStatus:kGREYXCTestCaseStatusFailed];
    @throw;
  }
}

@end
