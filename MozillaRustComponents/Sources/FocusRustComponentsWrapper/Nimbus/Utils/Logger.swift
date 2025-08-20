/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import os.log

class Logger {
    private let log: OSLog

    /// Creates a new logger instance with the specified tag value
    ///
    /// - parameters:
    ///     * tag: `String` value used to tag log messages
    init(tag: String) {
        self.log = OSLog(
            subsystem: Bundle.main.bundleIdentifier!,
            category: tag
        )
    }

    /// Output a debug log message
    ///
    /// - parameters:
    ///     * message: The message to log
    func debug(_ message: String) {
        log(message, type: .debug)
    }

    /// Output an info log message
    ///
    /// - parameters:
    ///     * message: The message to log
    func info(_ message: String) {
        log(message, type: .info)
    }

    /// Output an error log message
    ///
    /// - parameters:
    ///     * message: The message to log
    func error(_ message: String) {
        log(message, type: .error)
    }

    /// Private function that calls os_log with the proper parameters
    ///
    /// - parameters:
    ///     * message: The message to log
    ///     * level: The `LogLevel` at which to output the message
    private func log(_ message: String, type: OSLogType) {
        os_log("%@", log: self.log, type: type, message)
    }
}
