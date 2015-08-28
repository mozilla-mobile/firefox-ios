/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger

//// A rolling file loggers that saves to a different log file based on given timestamp
public class RollingFileLogger: XCGLogger {

    private static let TwoMBsInBytes: UInt64 = 2 * 100000
    private let sizeLimit: UInt64
    private let logDirectoryPath: String?

    let fileLogIdentifierPrefix = "com.mozilla.firefox.filelogger."

    private static let DateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        return formatter
    }()

    let root: String

    public init(filenameRoot: String, logDirectoryPath: String?, sizeLimit: UInt64 = TwoMBsInBytes) {
        root = filenameRoot
        self.sizeLimit = sizeLimit
        self.logDirectoryPath = logDirectoryPath
        super.init()
    }

    /**
    Create a new log file with the given timestamp to log events into

    :param: date Date for with to start and mark the new log file
    */
    public func newLogWithDate(date: NSDate) {
        // Don't start a log if we don't have a valid log directory path
        if logDirectoryPath == nil {
            return
        }

        // Before we create a new log file, check to see we haven't hit our size limit and if we did, clear out some logs to make room
        while sizeOfAllLogFiles() > sizeLimit {
            deleteOldestLog()
        }

        if let filename = filenameWithRoot(root, withDate: date) {
            removeLogDestination(fileLogIdentifierWithRoot(root))
            addLogDestination(XCGFileLogDestination(owner: self, writeToFile: filename, identifier: fileLogIdentifierWithRoot(root)))
            info("Created file destination for logger with root: \(self.root) and timestamp: \(date)")
        } else {
            error("Failed to create a new log with root name: \(self.root) and timestamp: \(date)")
        }
    }

    private func deleteOldestLog() {
        if logDirectoryPath == nil {
            return
        }

        do {
            var logFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(logDirectoryPath!)
            logFiles = logFiles.filter { $0.startsWith("\(self.root).") }
            logFiles.sortInPlace { $0 < $1 }

            if let oldestLogFilename = logFiles.first {
                try NSFileManager.defaultManager().removeItemAtPath("\(logDirectoryPath!)/\(oldestLogFilename)")
            }
        } catch _ as NSError{
            error("Shouldn't get here")
            return
        }
    }

    private func sizeOfAllLogFiles() -> UInt64 {
        if logDirectoryPath == nil {
            return 0
        }

        let logDirURL = NSURL(fileURLWithPath: logDirectoryPath!)
        var dirSize: UInt64 = 0
        do {
            try NSFileManager.defaultManager().moz_getAllocatedSize(&dirSize, ofDirectoryAtURL: logDirURL, forFilesPrefixedWith: self.root)
        } catch let errorValue as NSError {
            error("Error determining log directory size: \(errorValue)")
        }
        return dirSize
    }

    private func filenameWithRoot(root: String, withDate date: NSDate) -> String? {
        if let dir = logDirectoryPath {
            return "\(dir)/\(root).\(RollingFileLogger.DateFormatter.stringFromDate(date)).log"
        }

        return nil
    }

    private func fileLogIdentifierWithRoot(root: String) -> String {
        return "\(fileLogIdentifierPrefix).\(root)"
    }
}
