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
    static let browserLogger = RollingFileLogger(filenameRoot: "browser", logDirectoryPath: Logger.logFileDirectoryPath())

    /// Logger used for recording interactions with the keychain
    static let keychainLogger: XCGLogger = Logger.fileLoggerWithName("keychain")

    /// Logger used for logging database errors such as corruption
    static let corruptLogger: RollingFileLogger = {
        let logger = RollingFileLogger(filenameRoot: "corruptLogger", logDirectoryPath: Logger.logFileDirectoryPath())
        logger.newLogWithDate(Date())
        return logger
    }()

    /**
    Return the log file directory path. If the directory doesn't exist, make sure it exist first before returning the path.

    :returns: Directory path where log files are stored
    */
    static func logFileDirectoryPath() -> String? {
        if let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            let logDir = "\(cacheDir)/Logs"
            if !FileManager.default.fileExists(atPath: logDir) {
                do {
                    try FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: false, attributes: nil)
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

    static private func fileLoggerWithName(_ name: String) -> XCGLogger {
        let log = XCGLogger()
        if let logFileURL = urlForLogNamed(name) {
            let fileDestination = FileDestination(
                owner: log,
                writeToFile: logFileURL.absoluteString,
                identifier: "com.mozilla.firefox.filelogger.\(name)"
            )
            log.add(destination: fileDestination)
        }
        return log
    }

    static private func urlForLogNamed(_ name: String) -> URL? {
        guard let logDir = Logger.logFileDirectoryPath() else {
            return nil
        }

        return URL(string: "\(logDir)/\(name).log")
    }

    /**
     Grabs all of the configured logs that write to disk and returns them in NSData format along with their
     associated filename.

     - returns: Tuples of filenames to each file's contexts in a NSData object
     */
    static func diskLogFilenamesAndData() throws -> [(String, Data?)] {
        var filenamesAndURLs = [(String, URL)]()
        filenamesAndURLs.append(("browser", urlForLogNamed("browser")!))
        filenamesAndURLs.append(("keychain", urlForLogNamed("keychain")!))

        // Grab all sync log files
        do {
            filenamesAndURLs += try syncLogger.logFilenamesAndURLs()
            filenamesAndURLs += try corruptLogger.logFilenamesAndURLs()
            filenamesAndURLs += try browserLogger.logFilenamesAndURLs()
        } catch _ {
        }

        return filenamesAndURLs.map { ($0, try? Data(contentsOf: URL(fileURLWithPath: $1.absoluteString))) }
    }
}

