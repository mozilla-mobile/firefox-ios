//
//  PrePostFixLogFormatter.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-09-20.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

// MARK: - PrePostFixLogFormatter
/// A log formatter that will optionally add a prefix, and/or postfix string to a message
open class PrePostFixLogFormatter: LogFormatterProtocol, CustomDebugStringConvertible {

    /// Internal cache of the prefix strings for each log level
    internal var prefixStrings: [XCGLogger.Level: String] = [:]

    /// Internal cache of the postfix strings codes for each log level
    internal var postfixStrings: [XCGLogger.Level: String] = [:]

    public init() {
    }

    /// Set the prefix/postfix strings for a specific log level.
    ///
    /// - Parameters:
    ///     - prefix:   A string to prepend to log messages.
    ///     - postfix:  A string to postpend to log messages.
    ///     - level:    The log level.
    ///
    /// - Returns:  Nothing
    ///
    open func apply(prefix: String? = nil, postfix: String? = nil, to level: XCGLogger.Level? = nil) {
        guard let level = level else {
            guard prefix != nil || postfix != nil else { clearFormatting(); return }

            // No level specified, so, apply to all levels
            for level in XCGLogger.Level.allCases {
                self.apply(prefix: prefix, postfix: postfix, to: level)
            }
            return
        }

        if let prefix = prefix {
            prefixStrings[level] = prefix
        }
        else {
            prefixStrings.removeValue(forKey: level)
        }

        if let postfix = postfix {
            postfixStrings[level] = postfix
        }
        else {
            postfixStrings.removeValue(forKey: level)
        }
    }

    /// Clear all previously set colours. (Sets each log level back to default)
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    open func clearFormatting() {
        prefixStrings = [:]
        postfixStrings = [:]
    }

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
        message = "\(prefixStrings[logDetails.level] ?? "")\(message)\(postfixStrings[logDetails.level] ?? "")"
        return message
    }

    // MARK: - CustomDebugStringConvertible
    open var debugDescription: String {
        get {
            var description: String = "\(extractTypeName(self)): "
            for level in XCGLogger.Level.allCases {
                description += "\n\t- \(level) > \(prefixStrings[level] ?? "None") | \(postfixStrings[level] ?? "None")"
            }

            return description
        }
    }
}
