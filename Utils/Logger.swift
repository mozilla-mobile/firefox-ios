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

    /// Logger used for logging database errors such as corruption
    static let corruptLogger: XCGLogger = RollingFileLogger(filenameRoot: "dbCorruption", logDirectoryPath: Logger.logFileDirectoryPath())

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

    static private func fileLoggerWithName(name: String) -> XCGLogger {
        let log = XCGLogger()
        if let logFileURL = urlForLogNamed(name) {
            let fileDestination = XCGFileLogDestination(
                owner: log,
                writeToFile: logFileURL.absoluteString,
                identifier: "com.mozilla.firefox.filelogger.\(name)"
            )
            log.addLogDestination(fileDestination)
        }
        return log
    }

    static private func urlForLogNamed(name: String) -> NSURL? {
        guard let logDir = Logger.logFileDirectoryPath() else {
            return nil
        }

        return NSURL(string: "\(logDir)/\(name).log")
    }

    /**
     Grabs all of the configured logs that write to disk and returns them in NSData format along with their
     associated filename.

     - returns: Tuples of filenames to each file's contexts in a NSData object
     */
    static func diskLogFilenamesAndData() throws -> [(String, NSData?)] {
        var filenamesAndURLs = [(String, NSURL)]()
        filenamesAndURLs.append(("browser", urlForLogNamed("browser")!))
        filenamesAndURLs.append(("keychain", urlForLogNamed("keychain")!))

        // Grab all sync log files
        if let logDir = Logger.logFileDirectoryPath() {
            let syncFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(logDir, withFilenamePrefix: syncLogger.root)
            let syncFilenamesAndURLS: [(String, NSURL)] = syncFiles.flatMap { filename in
                if let url = NSURL(string: "\(logDir)/\(filename)") {
                    return (filename, url)
                }
                return nil
            }
            filenamesAndURLs += syncFilenamesAndURLS
        }

        return filenamesAndURLs.map { ($0, NSData(contentsOfFile: $1.absoluteString)) }
    }
}

