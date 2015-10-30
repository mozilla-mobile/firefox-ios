/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger

public struct Logger {}

// MARK: - Singleton Logger Instances
public extension Logger {
    static let logPII = false

    /// Logger used for recording happenings with Sync, Accounts, Providers, Storage, and Profiles
    static let syncLogger = RollingFileLogger(filenameRoot: "sync", logDirectoryPath: Logger.logFileDirectoryPath())

    /// Logger used for recording frontend/browser happenings
    static let browserLogger: XCGLogger = Logger.fileLoggerWithName("browser")

    /// Logger used for recording interactions with the keychain
    static let keychainLogger: XCGLogger = Logger.fileLoggerWithName("keychain")

    /**
    Return the log file directory path. If the directory doesn't exist, make sure it exist first before returning the path.

    :returns: Directory path where log files are stored
    */
    static func logFileDirectoryPath() -> String? {
        if let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first {
            let logDir = "\(cacheDir)/Logs"
            if !NSFileManager.defaultManager().fileExistsAtPath(logDir) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(logDir, withIntermediateDirectories: false, attributes: nil)
                    return logDir
                } catch _ as NSError {
                    return nil
                }
            } else {
                return logDir
            }
        }

        return nil
    }

    static private func fileLoggerWithName(filename: String) -> XCGLogger {
        let log = XCGLogger()
        if let logDir = Logger.logFileDirectoryPath() {
            let fileDestination = XCGFileLogDestination(owner: log, writeToFile: "\(logDir)/\(filename).log", identifier: "com.mozilla.firefox.filelogger.\(filename)")
            log.addLogDestination(fileDestination)
        }
        return log
    }
}

