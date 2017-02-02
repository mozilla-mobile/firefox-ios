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

let greyFailureHandler =
	Thread.currentThread().threadDictionary
		.valueForKey(kGREYFailureHandlerKey) as! GREYFailureHandler

public func grey_allOfMatchers(_ args: AnyObject...) -> GREYMatcher! {
	return GREYAllOf(matchers: args)
}

public func grey_anyOfMatchers(_ args: AnyObject...) -> GREYMatcher! {
	return GREYAnyOf(matchers: args)
}

public func EarlGrey(_ file: String = #file, line: UInt = #line) -> EarlGreyImpl! {
	return EarlGreyImpl.invokedFromFile(file, lineNumber: line)
}

public func GREYAssert(_ expression: @autoclosure () -> Bool, reason: String) {
	GREYAssert(expression, reason, details: "Expected expression to be true")
}

public func GREYAssertTrue(_ expression: @autoclosure () -> Bool, reason: String) {
	GREYAssert(expression().boolValue,
	           reason,
	           details: "Expected the boolean expression to be true")
}

public func GREYAssertFalse(_ expression: @autoclosure () -> Bool, reason: String) {
	GREYAssert(!expression().boolValue,
	           reason,
	           details: "Expected the boolean expression to be false")
}

public func GREYAssertNotNil(_ expression: @autoclosure () -> Any?, reason: String) {
	GREYAssert(expression() != nil, reason, details: "Expected expression to be not nil")
}

public func GREYAssertNil(_ expression: @autoclosure () -> Any?, reason: String) {
	GREYAssert(expression() == nil, reason, details: "Expected expression to be nil")
}

public func GREYAssertEqual(_ left: @autoclosure () -> AnyObject?,
                                         _ right: @autoclosure () -> AnyObject?, reason: String) {
	GREYAssert(left() === right(), reason, details: "Expected left term to be equal to right term")
}

public func GREYAssertNotEqual(_ left: @autoclosure () -> AnyObject?,
                                            _ right: @autoclosure () -> AnyObject?, reason: String) {
	GREYAssert(left() !== right(), reason, details: "Expected left term to not be equal to right" +
		" term")
}

public func GREYAssertEqualObjects<T: Equatable>(_ left: @autoclosure () -> T?,
                                   _ right: @autoclosure () -> T?, reason: String) {
	GREYAssert(left() == right(), reason, details: "Expected object of the left term to be equal" +
		" to the object of the right term")
}

public func GREYAssertNotEqualObjects<T: Equatable>(_ left: @autoclosure () -> T?,
                                      _ right: @autoclosure () -> T?, reason: String) {
	GREYAssert(left() != right(), reason, details: "Expected object of the left term to not be" +
		" equal to the object of the right term")
}

public func GREYFail(_ reason: String) {
	greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
		reason: reason),
	                                   details: "")
}

@available(*, deprecated: 1.2.0, message: "Please use GREYFAIL::withDetails instead.")
public func GREYFail(_ reason: String, details: String) {
	greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
		reason: reason),
	                                   details: details)
}

public func GREYFailWithDetails(_ reason: String, details: String) {
	greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
		reason: reason),
	                                   details: details)
}

private func GREYAssert(_ expression: @autoclosure () -> Bool,
                                     _ reason: String, details: String) {
	GREYSetCurrentAsFailable()
	if !expression().boolValue {
		greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
			reason: reason),
		                                   details: details)
	}
}

private func GREYSetCurrentAsFailable(_ file: String = #file, line: UInt = #line) {
	let greyFailureHandlerSelector =
		#selector(GREYFailureHandler.setInvocationFile(_:andInvocationLine:))
	if greyFailureHandler.respondsToSelector(greyFailureHandlerSelector) {
		greyFailureHandler.setInvocationFile!(file, andInvocationLine: line)
	}
}
