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

/**
 *  @file GREYFatalAsserts.h
 *
 *  @brief Assertion macros for checking internal program state.
 *
 *  These macros resemble NSAssertion macros but they are meant to be used in places where a
 *  failure would indicate a serious bug in the code or invalid state of the program.
 *  The program cannot continue as it would corrupt the state even more and recovering from such a
 *  state is not feasible. On failure, the assertion macro aborts the program.
 *
 *  @note Unlike NSAssert, these are never compiled out and present in all flavors of the build
 *        until they're removed explicitly.
 */

#ifndef GREY_FATAL_ASSERTS_H
#define GREY_FATAL_ASSERTS_H

#import <Foundation/Foundation.h>

/**
 *  Asserts that @c condition is @c true otherwise aborts the program.
 *
 *  @param condition The condition to evaluate.
 */
#define GREYFatalAssert(condition) \
  GREYFatalAssertWithMessage(condition, @"Fatal condition failure"); \

/**
 *  Asserts that @c condition is @c true otherwise aborts the program after logging the provided
 *  @c message.
 *
 *  @param condition The condition to evaluate.
 *  @param message   Message to print when @c condition evaluates to false.
 *  @param ...       Variable args for @c message if it is a format string.
 */
#define GREYFatalAssertWithMessage(condition, message, ...) \
({ \
  if (!(condition)) { \
    NSString *message__ = [NSString stringWithFormat:message, ##__VA_ARGS__]; \
    NSString *assertFile__ = [NSString stringWithUTF8String:__FILE__]; \
    NSLog(@"Fatal failure: %@ in %@:%d", message__, assertFile__, __LINE__); \
    abort(); \
  } \
})

/**
 *  Asserts that the current thread is the main thread otherwise aborts the program.
 */
#define GREYFatalAssertMainThread() \
  GREYFatalAssertWithMessage([NSThread isMainThread], @"Execution must happen on the main thread!");

#endif // GREY_FATAL_ASSERTS_H
