/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Shared

class RollingFileLoggerTests: XCTestCase {
    var logger: RollingFileLogger!
    var logDir: String!
    var sizeLimit: Int = 5000

    private lazy var formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        return formatter
    }()

    override func setUp() {
        super.setUp()
        logDir = (NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!) + "/Logs"
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(logDir, withIntermediateDirectories: false, attributes: nil)
        } catch _ {
        }
        logger = RollingFileLogger(filenameRoot: "test", logDirectoryPath: logDir, sizeLimit: Int64(sizeLimit))
    }

    func testNewLogCreatesLogFileWithTimestamp() {
        let date = NSDate()
        let expected = "test.\(formatter.stringFromDate(date)).log"
        let expectedPath = "\(logDir)/\(expected)"
        logger.newLogWithDate(date)
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(expectedPath), "Log file should exist")

        let testMessage = "Logging some text"
        logger.info(testMessage)
        let logData = NSData(contentsOfFile: expectedPath)
        XCTAssertNotNil(logData, "Log data should not be nil")
        let logString = NSString(data: logData!, encoding: NSUTF8StringEncoding)
        XCTAssertTrue(logString!.containsString(testMessage), "Log should contain our test message that we wrote")
    }

    func testNewLogDeletesPreviousLogIfItsTooLarge() {
        let manager = NSFileManager.defaultManager()
        let dirURL = NSURL(fileURLWithPath: logDir)
        let prefix = "test"
        let expectedPath = createNewLogFileWithSize(sizeLimit + 1)

        let directorySize = try! manager.getAllocatedSizeOfDirectoryAtURL(dirURL, forFilesPrefixedWith: prefix)

        // Pre-condition: Folder needs to be larger than the size limit
        XCTAssertGreaterThan(directorySize, Int64(sizeLimit), "Log folder should be larger than size limit")

        let exceedsSmaller = try! manager.allocatedSizeOfDirectoryAtURL(dirURL, forFilesPrefixedWith: prefix, isLargerThanBytes: directorySize - 1)
        let doesNotExceedLarger = try! manager.allocatedSizeOfDirectoryAtURL(dirURL, forFilesPrefixedWith: prefix, isLargerThanBytes: sizeLimit + 2)
        XCTAssertTrue(exceedsSmaller)
        XCTAssertTrue(doesNotExceedLarger)

        let newDate = NSDate().dateByAddingTimeInterval(60*60) // Create a log file using a date an hour ahead
        let newExpected = "\(prefix).\(formatter.stringFromDate(newDate)).log"
        let newExpectedPath = "\(logDir)/\(newExpected)"
        logger.newLogWithDate(newDate)

        XCTAssertTrue(manager.fileExistsAtPath(newExpectedPath), "New log file should exist")
        XCTAssertTrue(manager.fileExistsAtPath(expectedPath), "Old log file exists until pruned")
        logger.deleteOldLogsDownToSizeLimit()
        XCTAssertFalse(manager.fileExistsAtPath(expectedPath), "Old log file should NOT exist")
    }

    func testNewLogDeletesOldestLogFileToMakeRoomForNewFile() {
        let manager = NSFileManager.defaultManager()
        let dirURL = NSURL(fileURLWithPath: logDir)
        let prefix = "test"

        // Create 5 log files with spread out over 5 hours and reorder paths so oldest is first
        let logFilePaths = [0, 1, 2, 3, 4].map { self.createNewLogFileWithSize(200, withDate: NSDate().dateByAddingTimeInterval(60 * 60 * $0)) }
            .sort { $0 < $1 }

        let directorySize = try! manager.getAllocatedSizeOfDirectoryAtURL(dirURL, forFilesPrefixedWith: prefix)

        // Pre-condition: Folder needs to be larger than the size limit
        XCTAssertGreaterThan(directorySize, Int64(sizeLimit), "Log folder should be larger than size limit")

        let newDate = NSDate().dateByAddingTimeInterval(60*60*5) // Create a log file using a date an hour ahead
        let newExpected = "\(prefix).\(formatter.stringFromDate(newDate)).log"
        let newExpectedPath = "\(logDir)/\(newExpected)"
        logger.newLogWithDate(newDate)

        XCTAssertTrue(manager.fileExistsAtPath(newExpectedPath), "New log file should exist")
        XCTAssertTrue(manager.fileExistsAtPath(logFilePaths.first!), "Old log file exists until pruned")
        logger.deleteOldLogsDownToSizeLimit()
        XCTAssertFalse(manager.fileExistsAtPath(logFilePaths.first!), "Oldest log file should NOT exist")
    }

    /**
    Create a log file using the test logger and returns the path to that log file

    - parameter size: Size to make the log file

    - returns: Path to log file
    */
    private func createNewLogFileWithSize(size: Int, withDate date: NSDate = NSDate()) -> String {
        let expected = "test.\(formatter.stringFromDate(date)).log"
        let expectedPath = "\(logDir)/\(expected)"
        logger.newLogWithDate(date)
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(expectedPath), "Log file should exist")

        let logFileHandle = NSFileHandle(forWritingAtPath: expectedPath)
        XCTAssertNotNil(logFileHandle, "File should exist")
        let garbageBytes = malloc(size)
        let blankData = NSData(bytes: garbageBytes, length: size)
        logFileHandle!.writeData(blankData)
        logFileHandle!.closeFile()
        return expectedPath
    }
}
