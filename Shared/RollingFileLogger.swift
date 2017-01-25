/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger

//// A rolling file logger that saves to a different log file based on given timestamp.
open class RollingFileLogger: XCGLogger {

    fileprivate static let TwoMBsInBytes: Int64 = 2 * 100000
    fileprivate let sizeLimit: Int64
    fileprivate let logDirectoryPath: String?

    let fileLogIdentifierPrefix = "com.mozilla.firefox.filelogger."

    fileprivate static let DateFormatter: DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        return formatter
    }()

    let root: String

    public init(filenameRoot: String, logDirectoryPath: String?, sizeLimit: Int64 = TwoMBsInBytes) {
        root = filenameRoot
        self.sizeLimit = sizeLimit
        self.logDirectoryPath = logDirectoryPath
        super.init()
    }

    /**
    Create a new log file with the given timestamp to log events into

    :param: date Date for with to start and mark the new log file
    */
    open func newLogWithDate(_ date: Date) {
        // Don't start a log if we don't have a valid log directory path
        if logDirectoryPath == nil {
            return
        }

        if let filename = filenameWithRoot(root, withDate: date) {
            remove(destinationWithIdentifier: fileLogIdentifierWithRoot(root))
            add(destination: FileDestination(owner: self, writeToFile: filename, identifier: fileLogIdentifierWithRoot(root)))
            info("Created file destination for logger with root: \(self.root) and timestamp: \(date)")
        } else {
            error("Failed to create a new log with root name: \(self.root) and timestamp: \(date)")
        }
    }

    open func deleteOldLogsDownToSizeLimit() {
        // Check to see we haven't hit our size limit and if we did, clear out some logs to make room.
        while sizeOfAllLogFilesWithPrefix(self.root, exceedsSizeInBytes: sizeLimit) {
            deleteOldestLogWithPrefix(self.root)
        }
    }

    open func logFilenamesAndURLs() throws -> [(String, URL)] {
        guard let logPath = logDirectoryPath else {
            return []
        }

        let files = try FileManager.default.contentsOfDirectoryAtPath(logPath, withFilenamePrefix: root)
        return files.flatMap { filename in
            if let url = URL(string: "\(logPath)/\(filename)") {
                return (filename, url)
            }
            return nil
        }
    }

    fileprivate func deleteOldestLogWithPrefix(_ prefix: String) {
        if logDirectoryPath == nil {
            return
        }

        do {
            let logFiles = try FileManager.default.contentsOfDirectoryAtPath(logDirectoryPath!, withFilenamePrefix: prefix)
            if let oldestLogFilename = logFiles.first {
                try FileManager.default.removeItem(atPath: "\(logDirectoryPath!)/\(oldestLogFilename)")
            }
        } catch _ as NSError {
            error("Shouldn't get here")
            return
        }
    }

    fileprivate func sizeOfAllLogFilesWithPrefix(_ prefix: String, exceedsSizeInBytes threshold: Int64) -> Bool {
        guard let path = logDirectoryPath else {
            return false
        }

        let logDirURL = URL(fileURLWithPath: path)
        do {
            return try FileManager.default.allocatedSizeOfDirectoryAtURL(logDirURL, forFilesPrefixedWith: prefix, isLargerThanBytes: threshold)
        } catch let errorValue as NSError {
            error("Error determining log directory size: \(errorValue)")
        }

        return false
    }

    fileprivate func filenameWithRoot(_ root: String, withDate date: Date) -> String? {
        if let dir = logDirectoryPath {
            return "\(dir)/\(root).\(RollingFileLogger.DateFormatter.string(from: date)).log"
        }

        return nil
    }

    fileprivate func fileLogIdentifierWithRoot(_ root: String) -> String {
        return "\(fileLogIdentifierPrefix).\(root)"
    }
}
