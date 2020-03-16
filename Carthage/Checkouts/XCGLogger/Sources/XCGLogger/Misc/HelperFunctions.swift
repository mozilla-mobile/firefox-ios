//
//  HelperFunctions.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation
import ObjcExceptionBridging

/// Extract the type name from the given object
///
/// - parameter someObject: the object for which you need the type name
///
/// - returns: the type name of the object
func extractTypeName(_ someObject: Any) -> String {
    return (someObject is Any.Type) ? "\(someObject)" : "\(type(of: someObject))"
}

// MARK: - Swiftier interface to the Objective-C exception handling functions
/// Throw an Objective-C exception with the specified name/message/info
///
/// - parameter name:     The name of the exception to throw
/// - parameter message:  The message to include in the exception (why it occurred)
/// - parameter userInfo: A dictionary with arbitrary info to be passed along with the exception
func _try(_ tryClosure: @escaping () -> (), catch catchClosure: @escaping (_ exception: NSException) -> (), finally finallyClosure: (() -> ())? = nil) {
    _try_objc(tryClosure, catchClosure, finallyClosure ?? {})
}

/// Throw an Objective-C exception with the specified name/message/info
///
/// - parameter name:     The name of the exception to throw
/// - parameter message:  The message to include in the exception (why it occurred)
/// - parameter userInfo: A dictionary with arbitrary info to be passed along with the exception
func _throw(name: String, message: String? = nil, userInfo: [AnyHashable: Any]? = nil) {
    _throw_objc(NSException(name: NSExceptionName(rawValue: name), reason: message ?? name, userInfo: userInfo))
}
