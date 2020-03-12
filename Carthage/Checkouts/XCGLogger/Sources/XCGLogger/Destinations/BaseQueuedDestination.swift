//
//  BaseQueuedDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2017-04-02.
//  Copyright © 2017 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation
import Dispatch

// MARK: - BaseQueuedDestination
/// A base class destination (with a possible DispatchQueue) that doesn't actually output the log anywhere and is intended to be subclassed
open class BaseQueuedDestination: BaseDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil

    // MARK: - Life Cycle

    // MARK: - Overridden Methods
    /// Apply filters and formatters to the message before queuing it to be written by the write method.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Message ready to be formatted for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: LogDetails, message: String) {
        let outputClosure = {
            // Create mutable versions of our parameters
            var logDetails = logDetails
            var message = message

            // Apply filters, if any indicate we should drop the message, we abort before doing the actual logging
            guard !self.shouldExclude(logDetails: &logDetails, message: &message) else { return }

            self.applyFormatters(logDetails: &logDetails, message: &message)
            self.write(message: message)
        }

        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }

    // MARK: - Methods that must be overridden in subclasses
    /// Write the log message to the destination.
    ///
    /// - Parameters:
    ///     - message:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open func write(message: String) {
        // Do something with the message in an overridden version of this method
        precondition(false, "Must override this")
    }
}
