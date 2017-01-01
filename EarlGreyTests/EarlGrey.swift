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

import EarlGrey
import Foundation

/*
let greyFailureHandler =
  NSThread.currentThread().threadDictionary
    .valueForKey(kGREYFailureHandlerKey) as! GREYFailureHandler
*/
public func grey_allOfMatchers(args: AnyObject...) -> GREYMatcher! {
  return GREYAllOf(matchers: args)
}

public func grey_anyOfMatchers(args: AnyObject...) -> GREYMatcher! {
  return GREYAnyOf(matchers: args)
}

public func EarlGrey(file: String = #file, line: UInt = #line) -> EarlGreyImpl! {
  return EarlGreyImpl.invokedFromFile(file, lineNumber: line)
}

public func GREYAssert(@autoclosure expression: () -> BooleanType, reason: String) {
  GREYAssert(expression, reason, details: "Expected expression to be true")
}

public func GREYAssertTrue(@autoclosure expression: () -> BooleanType, reason: String) {
  GREYAssert(expression().boolValue,
    reason,
    details: "Expected the boolean expression to be true")
}

public func GREYAssertFalse(@autoclosure expression: () -> BooleanType, reason: String) {
  GREYAssert(!expression().boolValue,
    reason,
    details: "Expected the boolean expression to be false")
}

public func GREYAssertNotNil(@autoclosure expression: () -> Any?, reason: String) {
  GREYAssert(expression() != nil, reason, details: "Expected expression to be not nil")
}

public func GREYAssertNil(@autoclosure expression: () -> Any?, reason: String) {
  GREYAssert(expression() == nil, reason, details: "Expected expression to be nil")
}

public func GREYAssertEqual(@autoclosure left: () -> AnyObject?,
    @autoclosure _ right: () -> AnyObject?, reason: String) {
  GREYAssert(left() === right(), reason, details: "Expected left term to be equal to right term")
}

public func GREYAssertNotEqual(@autoclosure left: () -> AnyObject?,
    @autoclosure _ right: () -> AnyObject?, reason: String) {
  GREYAssert(left() !== right(), reason, details: "Expected left term to not be equal to right" +
    " term")
}

public func GREYAssertEqualObjects<T : Equatable>(@autoclosure left: () -> T?,
    @autoclosure _ right: () -> T?, reason: String) {
  GREYAssert(left() == right(), reason, details: "Expected object of the left term to be equal" +
    " to the object of the right term")
}

public func GREYAssertNotEqualObjects<T : Equatable>(@autoclosure left: () -> T?,
    @autoclosure _ right: () -> T?, reason: String) {
  GREYAssert(left() != right(), reason, details: "Expected object of the left term to not be" +
    " equal to the object of the right term")
}

public func GREYFail(reason: String) {
  greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
    reason: reason),
    details: "")
}

@available(*, deprecated=1.2.0, message="Please use GREYFAIL::withDetails instead.")
public func GREYFail(reason: String, details: String) {
  greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
    reason: reason),
    details: details)
}

public func GREYFailWithDetails(reason: String, details: String) {
  greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
    reason: reason),
    details: details)
}

private func GREYAssert(@autoclosure expression: () -> BooleanType,
                        _ reason: String, details: String) {
  GREYSetCurrentAsFailable()
  if !expression().boolValue {
    greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
      reason: reason),
      details: details)
  }
}

private func GREYSetCurrentAsFailable(file: String = #file, line: UInt = #line) {
  let greyFailureHandlerSelector =
      #selector(GREYFailureHandler.setInvocationFile(_:andInvocationLine:))
  if greyFailureHandler.respondsToSelector(greyFailureHandlerSelector) {
    greyFailureHandler.setInvocationFile!(file, andInvocationLine: line)
  }
}
