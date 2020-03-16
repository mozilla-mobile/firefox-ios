//
// Copyright 2018 Google Inc.
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

public func GREYAssert(_ expression: @autoclosure () -> Bool, reason: String) {
  GREYAssert(expression(), reason, details: "Expected expression to be true")
}

public func GREYAssertTrue(_ expression: @autoclosure () -> Bool, reason: String) {
  GREYAssert(expression(), reason, details: "Expected the boolean expression to be true")
}

public func GREYAssertFalse(_ expression: @autoclosure () -> Bool, reason: String) {
  GREYAssert(!expression(), reason, details: "Expected the boolean expression to be false")
}

public func GREYAssertNotNil(_ expression: @autoclosure ()-> Any?, reason: String) {
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
  GREYAssert(left() !== right(), reason, details: "Expected left term to not equal the right term")
}

public func GREYAssertEqualObjects<T: Equatable>( _ left: @autoclosure () -> T?,
                                                  _ right: @autoclosure () -> T?,
                                                  reason: String) {
  GREYAssert(left() == right(), reason, details: "Expected object of the left term to be equal " +
    "to the object of the right term")
}

public func GREYAssertNotEqualObjects<T: Equatable>( _ left: @autoclosure () -> T?,
                                                     _ right: @autoclosure () -> T?,
                                                     reason: String) {
  GREYAssert(left() != right(), reason, details: "Expected object of the left term to not " +
    "equal the object of the right term")
}

public func GREYFail(_ reason: String) {
  EarlGrey.handle(exception: GREYFrameworkException(name: kGREYAssertionFailedException,
                                                    reason: reason),
                  details: "")
}

public func GREYFailWithDetails(_ reason: String, details: String) {
  EarlGrey.handle(exception: GREYFrameworkException(name: kGREYAssertionFailedException,
                                                    reason: reason),
                  details: details)
}

private func GREYAssert(_ expression: @autoclosure () -> Bool,
                        _ reason: String, details: String) {
  GREYSetCurrentAsFailable()
  GREYWaitUntilIdle()
  if !expression() {
    EarlGrey.handle(exception: GREYFrameworkException(name: kGREYAssertionFailedException,
                                                      reason: reason),
                    details: details)
  }
}

private func GREYSetCurrentAsFailable() {
  let greyFailureHandlerSelector =
    #selector(GREYFailureHandler.setInvocationFile(_:andInvocationLine:))
  let greyFailureHandler =
    Thread.current.threadDictionary.value(forKey: kGREYFailureHandlerKey) as! GREYFailureHandler
  if greyFailureHandler.responds(to: greyFailureHandlerSelector) {
    greyFailureHandler.setInvocationFile!(#file, andInvocationLine:#line)
  }
}

private func GREYWaitUntilIdle() {
  GREYUIThreadExecutor.sharedInstance().drainUntilIdle()
}

open class EarlGrey: NSObject {
  public static func selectElement(with matcher: GREYMatcher,
                                   file: StaticString = #file,
                                   line: UInt = #line) -> GREYInteraction {
    return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .selectElement(with: matcher)
  }

  @available(*, deprecated, renamed: "selectElement(with:)")
  open class func select(elementWithMatcher matcher:GREYMatcher,
                         file: StaticString = #file,
                         line: UInt = #line) -> GREYElementInteraction {
    return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .selectElement(with: matcher)
  }

  open class func setFailureHandler(handler: GREYFailureHandler,
                                    file: StaticString = #file,
                                    line: UInt = #line) {
    return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .setFailureHandler(handler)
  }

  open class func handle(exception: GREYFrameworkException,
                         details: String,
                         file: StaticString = #file,
                         line: UInt = #line) {
    return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .handle(exception, details: details)
  }

  @discardableResult open class func rotateDeviceTo(orientation: UIDeviceOrientation,
                                                    errorOrNil: UnsafeMutablePointer<NSError?>!,
                                                    file: StaticString = #file,
                                                    line: UInt = #line)
    -> Bool {
      return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
        .rotateDevice(to: orientation,
                      errorOrNil: errorOrNil)
  }
}

extension GREYInteraction {
  @discardableResult public func assert(_ matcher: @autoclosure () -> GREYMatcher) -> Self {
    return self.__assert(with: matcher())
  }

  @discardableResult public func assert(_ matcher: @autoclosure () -> GREYMatcher,
                                        error:UnsafeMutablePointer<NSError?>!) -> Self {
    return self.__assert(with: matcher(), error: error)
  }

  @available(*, deprecated, renamed: "assert(_:)")
  @discardableResult public func assert(with matcher: GREYMatcher!) -> Self {
    return self.__assert(with: matcher)
  }

  @available(*, deprecated, renamed: "assert(_:error:)")
  @discardableResult public func assert(with matcher: GREYMatcher!,
                                        error:UnsafeMutablePointer<NSError?>!) -> Self {
    return self.__assert(with: matcher, error: error)
  }

  @discardableResult public func perform(_ action: GREYAction!) -> Self {
    return self.__perform(action)
  }

  @discardableResult public func perform(_ action: GREYAction!,
                                         error:UnsafeMutablePointer<NSError?>!) -> Self {
    return self.__perform(action, error: error)
  }

  @discardableResult public func using(searchAction: GREYAction,
                                       onElementWithMatcher matcher: GREYMatcher) -> Self {
    return self.usingSearch(searchAction, onElementWith: matcher)
  }
}

extension GREYCondition {
  open func waitWithTimeout(seconds: CFTimeInterval) -> Bool {
    return self.wait(withTimeout: seconds)
  }

  open func waitWithTimeout(seconds: CFTimeInterval, pollInterval: CFTimeInterval)
    -> Bool {
      return self.wait(withTimeout: seconds, pollInterval: pollInterval)
  }
}
