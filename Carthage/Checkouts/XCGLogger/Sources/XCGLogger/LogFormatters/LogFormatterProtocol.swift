//
//  LogFormatterProtocol.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-08-30.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - LogFormatterProtocol
/// Protocol for log formatter classes to conform to
public protocol LogFormatterProtocol: CustomDebugStringConvertible {

    /// Apply some additional formatting to the message if appropriate.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    @discardableResult func format(logDetails: inout LogDetails, message: inout String) -> String
}
