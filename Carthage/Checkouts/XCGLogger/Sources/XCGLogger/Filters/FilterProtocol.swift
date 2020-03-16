//
//  FilterProtocol.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-08-31.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - FilterProtocol
/// Protocol for log filter classes to conform to
public protocol FilterProtocol: CustomDebugStringConvertible {

    /// Check if the log message should be excluded from logging.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    ///
    /// - Returns:
    ///     - true:     Drop this log message.
    ///     - false:    Keep this log message and continue processing.
    ///
    func shouldExclude(logDetails: inout LogDetails, message: inout String) -> Bool
}
