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

#import "Exception/GREYFrameworkException.h"

#import "Common/GREYDefines.h"

NSString *const kGREYActionFailedException = @"ActionFailedException";
NSString *const kGREYAssertionFailedException = @"AssertionFailedException";
NSString *const kGREYGenericFailureException = @"GenericFailureException";
NSString *const kGREYNilException = @"NilException";
NSString *const kGREYNoMatchingElementException = @"NoMatchingElementException";
NSString *const kGREYMultipleElementsFoundException = @"MultipleElementsFoundException";
NSString *const kGREYNotNilException = @"NotNilException";
NSString *const kGREYTimeoutException = @"TimeoutException";
NSString *const kGREYConstraintFailedException = @"ConstraintFailedException";

@implementation GREYFrameworkException

+ (instancetype)exceptionWithName:(NSString *)name reason:(NSString *)reason {
  return [self exceptionWithName:name reason:reason userInfo:nil];
}

+ (instancetype)exceptionWithName:(NSString *)name
                           reason:(NSString *)reason
                         userInfo:(NSDictionary *)userInfo {
  return [[GREYFrameworkException alloc] initWithName:name reason:reason userInfo:userInfo];
}

@end
