//
//  DestinationProtocol.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - DestinationProtocol
/// Protocol for destination classes to conform to
public protocol DestinationProtocol: CustomDebugStringConvertible {
    // MARK: - Properties
    /// Logger that owns the destination object
    var owner: XCGLogger? {get set}

    /// Identifier for the destination (should be unique)
    var identifier: String {get set}

    /// Log level for this destination
    var outputLevel: XCGLogger.Level {get set}

    /// Flag whether or not we've logged the app details to this destination
    var haveLoggedAppDetails: Bool { get set }

    /// Array of log formatters to apply to messages before they're output
    var formatters: [LogFormatterProtocol]? { get set }

    /// Array of log filters to apply to messages before they're output
    var filters: [FilterProtocol]? { get set }

    // MARK: - Methods
    /// Process the log details.
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    func process(logDetails: LogDetails)

    /// Process the log details (internal use, same as processLogDetails but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    func processInternal(logDetails: LogDetails)

    /// Check if the destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    ///
    func isEnabledFor(level: XCGLogger.Level) -> Bool

    /// Apply filters to determine if the log message should be logged.
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

    /// Apply formatters.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    func applyFormatters(logDetails: inout LogDetails, message: inout String)
}

extension DestinationProtocol {

    /// Iterate over all of the log filters in this destination, or the logger if none set for the destination.
    ///
    /// - Parameters:
    ///     - logDetails: The log details.
    ///     - message: Formatted/processed message ready for output.
    ///
    /// - Returns:
    ///     - true:     Drop this log message.
    ///     - false:    Keep this log message and continue processing.
    ///
    public func shouldExclude(logDetails: inout LogDetails, message: inout String) -> Bool {
        guard let filters = self.filters ?? self.owner?.filters, filters.count > 0 else { return false }

        for filter in filters {
            if filter.shouldExclude(logDetails: &logDetails, message: &message) {
                return true
            }
        }

        return false
    }

    /// Iterate over all of the log formatters in this destination, or the logger if none set for the destination.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    public func applyFormatters(logDetails: inout LogDetails, message: inout String) {
        guard let formatters = self.formatters ?? self.owner?.formatters, formatters.count > 0 else { return }

        for formatter in formatters {
            formatter.format(logDetails: &logDetails, message: &message)
        }
    }
}
