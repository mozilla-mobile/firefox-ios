/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Shared

class RollingFileLoggerTests: XCTestCase {
    var logger: RollingFileLogger!
    var logDir: String!
    var sizeLimit: Int64 = 5000

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
        logger = RollingFileLogger(filenameRoot: "test", logDirectoryPath: logDir, sizeLimit: sizeLimit)
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
        let expectedPath = createNewLogFileWithSize(5001)

        let directorySize = try! NSFileManager.defaultManager().getAllocatedSizeOfDirectoryAtURL(NSURL(fileURLWithPath: logDir), forFilesPrefixedWith: "test")

        // Pre-condition: Folder needs to be larger than the size limit
        XCTAssertGreaterThan(directorySize, sizeLimit, "Log folder should be larger than size limit")

        let newDate = NSDate().dateByAddingTimeInterval(60*60) // Create a log file using a date an hour ahead
        let newExpected = "test.\(formatter.stringFromDate(newDate)).log"
        let newExpectedPath = "\(logDir)/\(newExpected)"
        logger.newLogWithDate(newDate)

        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(newExpectedPath), "New log file should exist")
        XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(expectedPath), "Old log file should NOT exist")
    }

    func testNewLogDeletesOldestLogFileToMakeRoomForNewFile() {
        // Create 5 log files with spread out over 5 hours
        var logFilePaths = [0,1,2,3,4].map { self.createNewLogFileWithSize(200, withDate: NSDate().dateByAddingTimeInterval(60 * 60 * $0)) }

        // Reorder paths so oldest is first
        logFilePaths.sortInPlace { $0 < $1 }

        let directorySize = try! NSFileManager.defaultManager().getAllocatedSizeOfDirectoryAtURL(NSURL(fileURLWithPath: logDir), forFilesPrefixedWith: "test")

        // Pre-condition: Folder needs to be larger than the size limit
        XCTAssertGreaterThan(directorySize, sizeLimit, "Log folder should be larger than size limit")

        let newDate = NSDate().dateByAddingTimeInterval(60*60*5) // Create a log file using a date an hour ahead
        let newExpected = "test.\(formatter.stringFromDate(newDate)).log"
        let newExpectedPath = "\(logDir)/\(newExpected)"
        logger.newLogWithDate(newDate)

        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(newExpectedPath), "New log file should exist")
        XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(logFilePaths.first!), "Oldest log file should NOT exist")
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
