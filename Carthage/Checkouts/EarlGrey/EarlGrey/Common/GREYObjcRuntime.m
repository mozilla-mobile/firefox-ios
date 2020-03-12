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

#import "Common/GREYObjcRuntime.h"

#include <dlfcn.h>
#include <objc/runtime.h>

#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"

@implementation GREYObjcRuntime

+ (void)addInstanceMethodToClass:(Class)destination
                    withSelector:(SEL)methodSelector
                       fromClass:(Class)source {
  GREYFatalAssert(destination);
  GREYFatalAssert(methodSelector);
  GREYFatalAssert(source);

  Method instanceMethod = class_getInstanceMethod(source, methodSelector);
  GREYFatalAssertWithMessage(instanceMethod,
                             @"Instance method: %@ does not exist in the class %@.",
                             NSStringFromSelector(methodSelector),
                             source);

  const char *typeEncoding = method_getTypeEncoding(instanceMethod);
  GREYFatalAssertWithMessage(typeEncoding, @"Failed to get method description.");

  BOOL success = class_addMethod(destination,
                                 methodSelector,
                                 method_getImplementation(instanceMethod),
                                 typeEncoding);
  GREYFatalAssertWithMessage(success, @"Failed to add method:%@ to class:%@",
                             NSStringFromSelector(methodSelector), destination);
}

@end
