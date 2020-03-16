//
//  Base64LogFormatter.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-08-30.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - Base64LogFormatter
/// An example log formatter to show how encryption could be used to secure log messages, in this case, we just Base64 encode them
open class Base64LogFormatter: LogFormatterProtocol, CustomDebugStringConvertible {

    // MARK: - LogFormatterProtocol
    /// Apply some additional formatting to the message if appropriate.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    ///
    /// - Returns:  message with the additional formatting
    ///
    @discardableResult open func format(logDetails: inout LogDetails, message: inout String) -> String {
        guard let utf8Message = message.data(using: .utf8) else { return message }

        message = utf8Message.base64EncodedString()
        return message
    }

    /// Initializer, doesn't do anything other than make the class publicly available
    public init() {
    }

    // MARK: - CustomDebugStringConvertible
    open var debugDescription: String {
        get {
            return "\(extractTypeName(self))"
        }
    }
}
