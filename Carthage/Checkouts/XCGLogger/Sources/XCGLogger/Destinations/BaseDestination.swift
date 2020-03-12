//
//  BaseDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation

// MARK: - BaseDestination
/// A base class destination that doesn't actually output the log anywhere and is intended to be subclassed
open class BaseDestination: DestinationProtocol, CustomDebugStringConvertible {
    // MARK: - Properties
    /// Logger that owns the destination object
    open var owner: XCGLogger?

    /// Identifier for the destination (should be unique)
    open var identifier: String

    /// Log level for this destination
    open var outputLevel: XCGLogger.Level = .debug

    /// Flag whether or not we've logged the app details to this destination
    open var haveLoggedAppDetails: Bool = false

    /// Array of log formatters to apply to messages before they're output
    open var formatters: [LogFormatterProtocol]? = nil

    /// Array of log filters to apply to messages before they're output
    open var filters: [FilterProtocol]? = nil

    /// Option: whether or not to output the log identifier
    open var showLogIdentifier: Bool = false

    /// Option: whether or not to output the function name that generated the log
    open var showFunctionName: Bool = true

    /// Option: whether or not to output the thread's name the log was created on
    open var showThreadName: Bool = false

    /// Option: whether or not to output the fileName that generated the log
    open var showFileName: Bool = true

    /// Option: whether or not to output the line number where the log was generated
    open var showLineNumber: Bool = true

    /// Option: whether or not to output the log level of the log
    open var showLevel: Bool = true

    /// Option: whether or not to output the date the log was created
    open var showDate: Bool = true

    /// Option: override descriptions of log levels
    open var levelDescriptions: [XCGLogger.Level: String] = [:]

    // MARK: - CustomDebugStringConvertible
    open var debugDescription: String {
        get {
            return "\(extractTypeName(self)): \(identifier) - Level: \(outputLevel) showLogIdentifier: \(showLogIdentifier) showFunctionName: \(showFunctionName) showThreadName: \(showThreadName) showLevel: \(showLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber) showDate: \(showDate)"
        }
    }

    // MARK: - Life Cycle
    public init(owner: XCGLogger? = nil, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier
    }

    // MARK: - Methods to Process Log Details
    /// Process the log details.
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    open func process(logDetails: LogDetails) {
        guard let owner = owner else { return }

        var extendedDetails: String = ""

        if showDate {
            extendedDetails += "\((owner.dateFormatter != nil) ? owner.dateFormatter!.string(from: logDetails.date) : logDetails.date.description) "
        }

        if showLevel {
            extendedDetails += "[\(levelDescriptions[logDetails.level] ?? owner.levelDescriptions[logDetails.level] ?? logDetails.level.description)] "
        }

        if showLogIdentifier {
            extendedDetails += "[\(owner.identifier)] "
        }

        if showThreadName {
            if Thread.isMainThread {
                extendedDetails += "[main] "
            }
            else {
                if let threadName = Thread.current.name, !threadName.isEmpty {
                    extendedDetails += "[\(threadName)] "
                }
                else if let queueName = DispatchQueue.currentQueueLabel, !queueName.isEmpty {
                    extendedDetails += "[\(queueName)] "
                }
                else {
                    extendedDetails += String(format: "[%p] ", Thread.current)
                }
            }
        }

        if showFileName {
            extendedDetails += "[\((logDetails.fileName as NSString).lastPathComponent)\((showLineNumber ? ":" + String(logDetails.lineNumber) : ""))] "
        }
        else if showLineNumber {
            extendedDetails += "[\(logDetails.lineNumber)] "
        }

        if showFunctionName {
            extendedDetails += "\(logDetails.functionName) "
        }

        output(logDetails: logDetails, message: "\(extendedDetails)> \(logDetails.message)")
    }

    /// Process the log details (internal use, same as process(logDetails:) but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    open func processInternal(logDetails: LogDetails) {
        guard let owner = owner else { return }

        var extendedDetails: String = ""

        if showDate {
            extendedDetails += "\((owner.dateFormatter != nil) ? owner.dateFormatter!.string(from: logDetails.date) : logDetails.date.description) "
        }

        if showLevel {
            extendedDetails += "[\(logDetails.level)] "
        }

        if showLogIdentifier {
            extendedDetails += "[\(owner.identifier)] "
        }

        output(logDetails: logDetails, message: "\(extendedDetails)> \(logDetails.message)")
    }

    // MARK: - Misc methods
    /// Check if the destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    ///
    open func isEnabledFor(level: XCGLogger.Level) -> Bool {
        return level >= self.outputLevel
    }

    // MARK: - Methods that must be overridden in subclasses
    /// Output the log to the destination.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open func output(logDetails: LogDetails, message: String) {
        // Do something with the text in an overridden version of this method
        precondition(false, "Must override this")
    }
}
