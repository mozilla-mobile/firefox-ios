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
 *  @file GREYThrowDefines.h
 *
 *  @brief Macros for checking and throwing exception to the callers of public interfaces.
 *
 *  These macros use the assertion handler to raise exceptions for invalid inputs or state in the
 *  public interface. Exception raised are catchable so callers *may* choose to ignore these
 *  exceptions thats why it's important that a program can recover from these exceptions. If you
 *  need a stricter check, consider using fatal asserts defined in GREYFatalAsserts.h.
 *
 *  @note Unlike NSAssert, these are never compiled out and present in all flavors of the build
 *        until they're removed explicitly.
 */

#ifndef GREY_THROW_DEFINES_H
#define GREY_THROW_DEFINES_H

#import <Foundation/Foundation.h>

/**
 *  Throws an @c NSInternalInconsistencyException if @c parameter is nil or NULL.
 *
 *  @note @c NSAssertionHandler is used to raise the exception.
 *
 *  @param parameter Argument to check for validity.
 */
#define GREYThrowOnNilParameter(parameter) \
({ \
  if (!(parameter)) { \
    GREYThrow(@"Parameter cannot be nil or NULL."); \
  } \
})

/**
 *  Throws an @c NSInternalInconsistencyException with the provided @c message if @c parameter
 *  is nil or NULL.
 *
 *  @note @c NSAssertionHandler is used to raise the exception.
 *
 *  @param parameter Argument to check for validity.
 *  @param message   Message to print when @c parameter is invalid.
 *  @param ...       Variable args for @c message if it is a format string.
 */
#define GREYThrowOnNilParameterWithMessage(parameter, message, ...) \
({ \
  if (!(parameter)) { \
    GREYThrow(message, ##__VA_ARGS__); \
  } \
})

/**
 *  Throws an @c NSInternalInconsistencyException if @c condition evaluates to false.
 *
 *  @note @c NSAssertionHandler is used to raise the exception.
 *
 *  @param condition The condition to evaluate.
 */
#define GREYThrowOnFailedCondition(condition) \
({ \
  if (!(condition)) { \
    GREYThrow(@"Condition evaluated to false"); \
  } \
})

/**
 *  Throws an @c NSInternalInconsistencyException with the provided @c message if @c condition
 *  evaluates to false.
 *
 *  @note @c NSAssertionHandler is used to raise the exception.
 *
 *  @param condition The condition to evaluate.
 *  @param message   Message to print when @c condition evaluates to false.
 *  @param ...       Variable args for @c message if it is a format string.
 */
#define GREYThrowOnFailedConditionWithMessage(condition, message, ...) \
({ \
  if (!(condition)) { \
    GREYThrow(message, ##__VA_ARGS__); \
  } \
})

/**
 *  Throws an @c NSInternalInconsistencyException with the provided @c message.
 *
 *  @note @c NSAssertionHandler is used to raise the exception.
 *
 *  @param message   Message to print
 *  @param ...       Variable args for @c message if it is a format string.
 */
#define GREYThrow(message, ...) \
({ \
  [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd \
                                                      object:self \
                                                        file:@(__FILE__) \
                                                  lineNumber:__LINE__ \
                                                 description:(message), ##__VA_ARGS__]; \
})

#endif // GREY_THROW_DEFINES_H
