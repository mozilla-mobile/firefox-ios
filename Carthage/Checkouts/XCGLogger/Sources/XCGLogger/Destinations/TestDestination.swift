//
//  TestDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-08-26.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Dispatch

// MARK: - TestDestination
/// A destination for testing, preload it with the expected logs, send your logs, then check for success
open class TestDestination: BaseQueuedDestination {
    // MARK: - Properties
    /// Array of all expected log messages
    open var expectedLogMessages: [String] = []

    /// Array of received, unexpected log messages
    open var unexpectedLogMessages: [String] = []

    /// Number of log messages still expected
    open var remainingNumberOfExpectedLogMessages: Int {
        get {
            return expectedLogMessages.count
        }
    }

    /// Number of unexpected log messages
    open var numberOfUnexpectedLogMessages: Int {
        get {
            return unexpectedLogMessages.count
        }
    }

    /// Add the messages you expect to be logged
    ///
    /// - Parameters:
    ///     - expectedLogMessage:   The log message, formated as you expect it to be received.
    ///
    /// - Returns:  Nothing
    ///
    open func add(expectedLogMessage message: String) {
        sync {
            expectedLogMessages.append(message)
        }
    }

    /// Execute a closure on the logQueue if it exists, otherwise just execute on the current thread
    ///
    /// - Parameters:
    ///     - closure:  The closure to execute.
    ///
    /// - Returns:  Nothing
    ///
    fileprivate func sync(closure: () -> ()) {
        if let logQueue = logQueue {
            logQueue.sync {
                closure()
            }
        }
        else {
            closure()
        }
    }

    /// Reset our expectations etc for additional tests
    ///
    /// - Parameters:   Nothing
    ///
    /// - Returns:  Nothing
    ///
    open func reset() {
        haveLoggedAppDetails = false
        expectedLogMessages = []
        unexpectedLogMessages = []
    }

    // MARK: - Overridden Methods
    /// Removes line from expected log messages if there's a match, otherwise adds to unexpected log messages.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: LogDetails, message: String) {
        sync {
            var logDetails = logDetails
            var message = message

            // Apply filters, if any indicate we should drop the message, we abort before doing the actual logging
            if self.shouldExclude(logDetails: &logDetails, message: &message) {
                return
            }
            
            applyFormatters(logDetails: &logDetails, message: &message)

            let index = expectedLogMessages.firstIndex(of: message)
            if let index = index {
                expectedLogMessages.remove(at: index)
            }
            else {
                unexpectedLogMessages.append(message)
            }
        }
    }
}
