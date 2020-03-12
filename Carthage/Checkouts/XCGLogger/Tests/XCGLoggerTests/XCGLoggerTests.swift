//
//  XCGLoggerTests.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-09.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import XCTest
@testable import XCGLogger

/// Tests
class XCGLoggerTests: XCTestCase {
    /// This file's fileName for use in testing expected log messages
    let fileName = { return (#file as NSString).lastPathComponent }()

    /// Calculate a base identifier to use for the giving function name.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///
    /// - Returns:  A string to use as the base identifier for objects in the test
    ///
    func functionIdentifier(_ functionName: StaticString = #function) -> String {
        return "\(XCGLogger.Constants.baseIdentifier).\(functionName)"
    }

    /// Set up prior to each test
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    /// Tear down after each test
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //    func testExample() {
    //        // This is an example of a functional test case.
    //        XCTAssert(true, "Pass")
    //    }
    //
    //    func testPerformanceExample() {
    //        // This is an example of a performance test case.
    //        self.measureBlock() {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }

    /// Test that if we request the default instance multiple times, we always get the same instance
    func test_00010_defaultInstance() {
        let defaultInstance1: XCGLogger = XCGLogger.default
        let defaultInstance2: XCGLogger = XCGLogger.default

        XCTAssert(defaultInstance1 === defaultInstance2, "Fail: default is not returning a common instance")
    }

    /// Test that if we request the multiple instances, we get different instances
    func test_00020_distinctInstances() {
        let instance1: XCGLogger = XCGLogger()
        instance1.identifier = "instance1"

        let instance2: XCGLogger = XCGLogger()
        instance2.identifier = "instance2" // this should not affect instance1

        XCTAssert(instance1.identifier != instance2.identifier, "Fail: same instance is being returned")
    }

    /// Test our default instance starts with the correct default destinations
    func test_00022_defaultInstanceDestinations() {
        let defaultInstance: XCGLogger = XCGLogger.default

        let consoleDestination: ConsoleDestination? = defaultInstance.destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination

        XCTAssert(consoleDestination != nil, "Fail: default console destination not attached to our default instance")
        XCTAssert(defaultInstance.destinations.count == 1, "Fail: Incorrect number of destinations on our default instance")

        let log = XCGLogger(identifier: functionIdentifier(), includeDefaultDestinations: false)
        XCTAssert(log.destinations.count == 0, "Fail: Logger included default destinations when it shouldn't have")
    }

    /// Test that we can add additional destinations
    func test_00030_addDestination() {
        let log = XCGLogger(identifier: functionIdentifier())
        let destinationCountAtStart = log.destinations.count

        let additionalConsoleLogger = ConsoleDestination(identifier: log.identifier + ".second.console")

        let additionSuccess = log.add(destination: additionalConsoleLogger)
        let destinationCountAfterAddition = log.destinations.count

        XCTAssert(additionSuccess, "Fail: didn't add additional destination")
        XCTAssert(destinationCountAtStart == (destinationCountAfterAddition - 1), "Fail: didn't add additional destination")
    }

    /// Test we can remove existing destinations
    func test_00040_removeDestination() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let destinationCountAtStart = log.destinations.count

        let removeSuccess = log.remove(destinationWithIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier)
        let destinationCountAfterRemoval = log.destinations.count

        XCTAssert(removeSuccess, "Fail: didn't remove destination")
        XCTAssert(destinationCountAtStart == (destinationCountAfterRemoval + 1), "Fail: didn't remove destination")

        let nonExistantDestination: DestinationProtocol? = log.destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier)
        XCTAssert(nonExistantDestination == nil, "Fail: didn't remove specified destination")
    }

    /// Test that we can not add a destination with a duplicate identifier
    func test_00050_denyAdditionOfDestinationWithDuplicateIdentifier() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testIdentifier = log.identifier + ".testIdentifier"
        let additionalConsoleLogger = ConsoleDestination(identifier: testIdentifier)
        let additionalConsoleLogger2 = ConsoleDestination(identifier: testIdentifier)

        let additionSuccess = log.add(destination: additionalConsoleLogger)
        let destinationCountAfterAddition = log.destinations.count

        let additionSuccess2 = log.add(destination: additionalConsoleLogger2)
        let destinationCountAfterAddition2 = log.destinations.count

        XCTAssert(additionSuccess, "Fail: didn't add additional destination")
        XCTAssert(!additionSuccess2, "Fail: didn't prevent adding additional destination with a duplicate identifier")
        XCTAssert(destinationCountAfterAddition == destinationCountAfterAddition2, "Fail: didn't prevent adding additional destination with a duplicate identifier")
    }

    /// Test a destination has it's owner set correctly when added to or removed from a logger
    func test_00052_checkDestinationOwner() {
        let log1: XCGLogger = XCGLogger(identifier: functionIdentifier() + ".1")
        XCTAssert(log1.destinations.count == 1, "Fail: Logger didn't include the correct default destinations")

        let log2: XCGLogger = XCGLogger(identifier: functionIdentifier() + ".2", includeDefaultDestinations: false)
        XCTAssert(log2.destinations.count == 0, "Fail: Logger included default destinations when it shouldn't have")

        let consoleDestination: ConsoleDestination! = log1.destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination
        XCTAssert(consoleDestination != nil, "Fail: Didn't add our default destination")
        XCTAssert(consoleDestination.owner === log1, "Fail: default destination did not have the correct owner set")

        log1.remove(destination: consoleDestination)
        XCTAssert(consoleDestination.owner == nil, "Fail: removed destination didn't have it's owner cleared")

        log1.add(destination: consoleDestination)
        XCTAssert(consoleDestination.owner === log1, "Fail: added destination didn't have it's owner set correctly")

        log2.add(destination: consoleDestination)
        XCTAssert(consoleDestination.owner === log2, "Fail: moved destination didn't have it's owner set correctly")
    }

    /// Test a file destination correctly opens a file
    func test_00054_fileDestinationOpenedFile() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let logPath: String = NSTemporaryDirectory().appending("XCGLogger_\(UUID().uuidString).log")
        var fileDestination: FileDestination = FileDestination(writeToFile: logPath, identifier: log.identifier + ".fileDestination.1", shouldAppend: true)

        XCTAssert(fileDestination.owner == nil, "Fail: newly created FileDestination has an owner set when it should be nil")
        XCTAssert(fileDestination.logFileHandle == nil, "Fail: FileDestination has opened a file before it was assigned to a logger")

        log.add(destination: fileDestination)
        XCTAssert(fileDestination.owner === log, "Fail: file destination did not have the correct owner set")
        XCTAssert(fileDestination.logFileHandle != nil, "Fail: FileDestination been assigned to a logger, but no file has been opened")

        log.remove(destination: fileDestination)

        fileDestination = FileDestination(owner: log, writeToFile: logPath, identifier: log.identifier + ".fileDestination.2", shouldAppend: true)

        XCTAssert(fileDestination.owner === log, "Fail: file destination did not have the correct owner set")
        XCTAssert(fileDestination.logFileHandle != nil, "Fail: FileDestination been assigned to a logger, but no file has been opened")
    }

    func test_00055_checkExtendedFileAttributeURLExtensions() {
        let fileManager: FileManager = FileManager.default
        let testFileURL: URL = URL(fileURLWithPath: NSTemporaryDirectory().appending("XCGLogger_\(UUID().uuidString).txt"))
        let sampleData: Data = functionIdentifier().data(using: .utf8) ?? "\(Date())".data(using: .utf8)!
        let testKey: String = XCGLogger.Constants.extendedAttributeArchivedLogIdentifierKey

        fileManager.createFile(atPath: testFileURL.path, contents: sampleData)
        var extendedAttributes: [String] = try! testFileURL.listExtendedAttributes()
        XCTAssert(extendedAttributes.count == 0, "Fail: new file should have no extended attributes")

        var attributeData: Data? = try! testFileURL.extendedAttribute(forName: testKey)
        XCTAssert(attributeData == nil, "Fail: new file should not have a specific extended attribute")

        try? testFileURL.setExtendedAttribute(data: sampleData, forName: testKey)
        attributeData = try! testFileURL.extendedAttribute(forName: testKey)
        XCTAssert(attributeData == sampleData, "Fail: write, then read of sample data resulted in mismatched data")

        extendedAttributes = try! testFileURL.listExtendedAttributes()
        XCTAssert(extendedAttributes.count == 1 && extendedAttributes.first ?? "" == testKey, "Fail: test file should have 1 extended attribute that we just set")

        try? testFileURL.removeExtendedAttribute(forName: testKey)
        extendedAttributes = try! testFileURL.listExtendedAttributes()
        XCTAssert(extendedAttributes.count == 0, "Fail: file should have no extended attributes once we remove the one we set")

        try? fileManager.removeItem(at: testFileURL)
    }

    /// Test that log destination correctly rotates file
    func test_00056_checkAutoRotatingFileDestinationBehavesAsExpected() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug
        if var logConsoleDestination = log.destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) {
            logConsoleDestination.outputLevel = .info
        }

        let logFileURL: URL = URL(fileURLWithPath: NSTemporaryDirectory().appending("XCGLogger_\(UUID().uuidString).log"))
        let autoRotatingFileDestination: AutoRotatingFileDestination = AutoRotatingFileDestination(writeToFile: logFileURL, identifier: log.identifier + ".autoRotatingFileDestination.\(UUID().uuidString)")
        log.add(destination: autoRotatingFileDestination)

        var autoRotationClosureExecuted: Bool = false
        autoRotatingFileDestination.autoRotationCompletion = { (success: Bool) -> Void in
            autoRotationClosureExecuted = true
        }

        var archivedLogURLs: [URL] = autoRotatingFileDestination.archivedFileURLs()
        XCTAssert(archivedLogURLs.count == 0, "Fail: new logger should not have any archived files")

        // Test auto rotation by file size
        autoRotatingFileDestination.targetMaxFileSize = 2048
        autoRotatingFileDestination.targetMaxLogFiles = 3
        autoRotatingFileDestination.targetMaxTimeInterval = 3600
        for _ in 0 ... 512 {
            log.debug("\(autoRotatingFileDestination.identifier)")
            Thread.sleep(forTimeInterval: 0.05)
        }

        archivedLogURLs = autoRotatingFileDestination.archivedFileURLs()
        XCTAssert(archivedLogURLs.count > 0, "Fail: logger should have rotated log files")
        XCTAssert(archivedLogURLs.count < Int(autoRotatingFileDestination.targetMaxLogFiles) * 2, "Fail: logger should have removed some archived log files")
        XCTAssert(autoRotationClosureExecuted, "Fail: logger hasn't executed the auto rotation closure")

        // Test our archivedLogURLs are sorted
        // - Note: sorting by filename here works because we're using a known date formatter that includes the date in a sortable order.
        // - If using a custom date formatter, sorting by filename may or may not work, which is why we're using the extended attributes,
        // - they allow us to sort correctly regardless of filename.
        let archivedLogURLsSortedByName: [URL] = archivedLogURLs.sorted { (lhs: URL, rhs: URL) -> Bool in
            return lhs.path > rhs.path
        }
        XCTAssert(archivedLogURLs == archivedLogURLsSortedByName, "Fail: archivedLogURLs not sorted correctly")

        autoRotatingFileDestination.rotateFile()
        autoRotatingFileDestination.purgeArchivedLogFiles()
        archivedLogURLs = autoRotatingFileDestination.archivedFileURLs()
        XCTAssert(archivedLogURLs.count == 0, "Fail: logger should not have any archived files after purging")

        // Test auto rotation by time interval
        autoRotatingFileDestination.targetMaxFileSize = .max
        autoRotatingFileDestination.targetMaxLogFiles = 3
        autoRotatingFileDestination.targetMaxTimeInterval = 2
        for _ in 0 ... 30 {
            log.debug("\(autoRotatingFileDestination.identifier)")
            Thread.sleep(forTimeInterval: 0.25)
        }

        archivedLogURLs = autoRotatingFileDestination.archivedFileURLs()
        XCTAssert(archivedLogURLs.count > 0, "Fail: logger should have rotated log files")
        XCTAssert(archivedLogURLs.count < Int(autoRotatingFileDestination.targetMaxLogFiles) * 2, "Fail: logger should have removed some archived log files")
        autoRotatingFileDestination.purgeArchivedLogFiles()

        // Test storing archives in an alternate folder
        let alternateArchiveFolderURL: URL = URL(fileURLWithPath: NSTemporaryDirectory().appending("XCGLogger_Archives"))
        autoRotatingFileDestination.archiveFolderURL = alternateArchiveFolderURL
        log.debug("\(autoRotatingFileDestination.identifier)")
        autoRotatingFileDestination.rotateFile()
        archivedLogURLs = autoRotatingFileDestination.archivedFileURLs()
        if let archivedLogURL = archivedLogURLs.first {
            XCTAssert(archivedLogURL.resolvingSymlinksInPath().deletingLastPathComponent().path == alternateArchiveFolderURL.resolvingSymlinksInPath().path, "Fail: archived logs are not in the alternate archived log folder")
        }
        else {
            XCTAssert(false, "Fail: should have been an archived log file to test it's path")
        }

        autoRotatingFileDestination.purgeArchivedLogFiles()
    }

    /// Test that closures for a log aren't executed via string interpolation if they aren't needed
    func test_00060_avoidStringInterpolationWithAutoclosure() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        class ObjectWithExpensiveDescription: CustomStringConvertible {
            var descriptionInvoked = false

            var description: String {
                descriptionInvoked = true
                return "expensive"
            }
        }

        let thisObject = ObjectWithExpensiveDescription()

        log.verbose("The description of \(thisObject) is really expensive to create")
        XCTAssert(!thisObject.descriptionInvoked, "Fail: String was interpolated when it shouldn't have been")
    }

    /// Test that closures for a log execute when required
    func test_00070_execExecutes() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        var numberOfTimes: Int = 0
        log.debug {
            numberOfTimes += 1
            return "executed closure correctly"
        }

        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 1, "Fail: Didn't execute the closure when it should have")
    }

    /// Test that closures execute exactly once, even when being logged to multiple destinations, and even if they return nil
    func test_00080_execExecutesExactlyOnceWithNilReturnAndMultipleDestinations() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        let logPath: String = NSTemporaryDirectory().appending("XCGLogger_\(UUID().uuidString).log")
        log.setup(level: .debug, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logPath)

        var numberOfTimes: Int = 0
        log.debug {
            numberOfTimes += 1
            return nil
        }

        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 1, "Fail: Didn't execute the closure exactly once")
    }

    /// Test that closures for a log aren't executed if they aren't needed
    func test_00090_execDoesntExecute() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .error

        var numberOfTimes: Int = 0
        log.debug {
            numberOfTimes += 1
            return "executed closure incorrectly"
        }

        log.outputLevel = .debug
        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 0, "Fail: Didn't execute the closure when it should have")
    }

    /// Test that we correctly cache date formatter objects, and don't create new ones each time
    func test_00100_dateFormatterIsCached() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())

        let dateFormatter1 = log.dateFormatter
        let dateFormatter2 = log.dateFormatter

        XCTAssert(dateFormatter1 === dateFormatter2, "Fail: Received two different date formatter objects")
    }

    /// Test our custom date formatter works
    func test_00110_customDateFormatter() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let defaultDateFormatter = log.dateFormatter
        let alternateDateFormat = "MM/dd/yyyy h:mma"
        let alternateDateFormatter = DateFormatter()
        alternateDateFormatter.dateFormat = alternateDateFormat

        log.dateFormatter = alternateDateFormatter

        log.debug("Test date format is different than our default")

        XCTAssertNotNil(log.dateFormatter, "Fail: date formatter is nil")
        XCTAssertEqual(log.dateFormatter!.dateFormat, alternateDateFormat, "Fail: date format doesn't match our custom date format")
        XCTAssert(defaultDateFormatter != alternateDateFormatter, "Fail: Did not assign a custom date formatter")

        // We add this destination after the normal log.debug() call above (that's for humans to look at), because
        // there's a chance when the test runs, that we could cross time boundaries (ie, second [or even the year])
        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = true
        log.add(destination: testDestination)

        // We force the date for this part of the test to ensure a change of date as the test runs doesn't break the test
        let knownDate = Date(timeIntervalSince1970: 0)
        let message = "Testing date format output matches what we expect"
        testDestination.add(expectedLogMessage: "\(alternateDateFormatter.string(from: knownDate)) [\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(message)")

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")

        let knownLogDetails = LogDetails(level: .debug, date: knownDate, message: message, functionName: #function, fileName: #file, lineNumber: #line)
        testDestination.process(logDetails: knownLogDetails)

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test that we can log a variety of different object types
    func test_00120_variousParameters() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(level: .verbose, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.outputLevel = .verbose
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.info)] [\(fileName)] \(#function) > testVariousParameters starting")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.info("testVariousParameters starting")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.verbose)] [\(fileName)] \(#function) > ")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.verbose()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        // Should not log anything, so there are no expected log messages
        log.verbose { return nil }
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > 1.2")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(1.2)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.info)] [\(fileName)] \(#function) > true")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.info(true)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.warning)] [\(fileName)] \(#function) > [\"a\", \"b\", \"c\"]")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.warning(["a", "b", "c"])
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let knownDate = Date(timeIntervalSince1970: 0)
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.error)] [\(fileName)] \(#function) > \(knownDate)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.error { return knownDate }
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let optionalString: String? = "text"
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.severe)] [\(fileName)] \(#function) > \(optionalString ?? "")")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.severe(optionalString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test our noMessageClosure works as expected
    func test_00130_noMessageClosure() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let checkDefault = String(describing: log.noMessageClosure() ?? "__unexpected__")
        XCTAssert(checkDefault == "", "Fail: Default noMessageClosure doesn't return expected value")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > ")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        log.noMessageClosure = { return "***" }
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > ***")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let knownDate = Date(timeIntervalSince1970: 0)
        log.noMessageClosure = { return knownDate }
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(knownDate)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        log.noMessageClosure = { return nil }
        // Should not log anything, so there are no expected log messages
        log.debug()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    func test_00140_queueName() {
        let logQueue = DispatchQueue(label: functionIdentifier() + ".serialQueue.😆")

        let labelDirectlyRead: String = logQueue.label
        var labelExtracted: String? = nil

        logQueue.sync {
            labelExtracted = DispatchQueue.currentQueueLabel
        }

        XCTAssert(labelExtracted != nil, "Fail: Didn't get a label for the current queue")

        print("labelDirectlyRead: `\(labelDirectlyRead)`")
        print("labelExtracted: `\(labelExtracted!)`")

        XCTAssert(labelDirectlyRead == labelExtracted!, "Fail: Didn't get the correct queue label")
    }

    func test_00150_extractTypeName() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let className: String = extractTypeName(log)
        let stringName: String = extractTypeName(className)
        let intName: String = extractTypeName(4)

        let optionalString: String? = nil
        let optionalName: String = extractTypeName(optionalString as Any)

        log.debug("className: \(className)")
        log.debug("stringName: \(stringName)")
        log.debug("intName: \(intName)")
        log.debug("optionalName: \(optionalName)")

        XCTAssert(className == "XCGLogger", "Fail: Didn't extract the correct class name")
        XCTAssert(stringName == "String", "Fail: Didn't extract the correct class name")
        XCTAssert(intName == "Int", "Fail: Didn't extract the correct class name")
        XCTAssert(optionalName == "Optional<String>", "Fail: Didn't extract the correct class name")
    }

    func test_00160_testLogFormattersAreApplied() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let testString: String = "Black on Blue"

        let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
        ansiColorLogFormatter.colorize(level: .debug, with: .blue, on: .black, options: [.bold])
        log.formatters = [ansiColorLogFormatter]

        testDestination.add(expectedLogMessage: "\(ANSIColorLogFormatter.escape)34;40;1m[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(testString)\(ANSIColorLogFormatter.reset)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(testString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let xcodeColorsLogFormatter: XcodeColorsLogFormatter = XcodeColorsLogFormatter()
        xcodeColorsLogFormatter.colorize(level: .debug, with: .black, on: .blue)
        log.formatters = [xcodeColorsLogFormatter]

        testDestination.add(expectedLogMessage: "\(XcodeColorsLogFormatter.escape)fg0,0,0;\(XcodeColorsLogFormatter.escape)bg0,0,255;[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(testString)\(XcodeColorsLogFormatter.reset)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(testString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let base64LogFormatter: Base64LogFormatter = Base64LogFormatter()
        log.formatters = [base64LogFormatter]

        // "[Debug] [XCGLoggerTests.swift] test_00160_testLogFormattersAreApplied() > Black on Blue" base64 encoded
        testDestination.add(expectedLogMessage: "W0RlYnVnXSBbWENHTG9nZ2VyVGVzdHMuc3dpZnRdIHRlc3RfMDAxNjBfdGVzdExvZ0Zvcm1hdHRlcnNBcmVBcHBsaWVkKCkgPiBCbGFjayBvbiBCbHVl")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(testString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test log level override strings work
    func test_00170_levelDescriptionOverrides() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let testString = "Every human being has a basic instinct: to help each other out."

        // Override at the logger level
        log.levelDescriptions[.severe] = "❌"

        testDestination.add(expectedLogMessage: "[❌] [\(fileName)] \(#function) > \(testString)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.severe(testString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        // Override at the destination level
        testDestination.levelDescriptions[.severe] = "❌❌❌"

        testDestination.add(expectedLogMessage: "[❌❌❌] [\(fileName)] \(#function) > \(testString)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.severe(testString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test prefix/postfix formatter works
    func test_00180_prePostFixLogFormatter() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .verbose

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        testDestination.outputLevel = .verbose
        log.add(destination: testDestination)

        let testString = "Everything is awesome!"

        let prePostFixLogFormatter = PrePostFixLogFormatter()

        // Set a specific level
        prePostFixLogFormatter.apply(prefix: "🗯🗯🗯", postfix: "🗯🗯🗯", to: .verbose)
        prePostFixLogFormatter.apply(prefix: "🔹🔹🔹", postfix: "🔹🔹🔹", to: .debug)
        prePostFixLogFormatter.apply(prefix: "ℹ️ℹ️ℹ️", postfix: "ℹ️ℹ️ℹ️", to: .info)
        prePostFixLogFormatter.apply(prefix: "⚠️⚠️⚠️", postfix: "⚠️⚠️⚠️", to: .warning)
        prePostFixLogFormatter.apply(prefix: "‼️‼️‼️", postfix: "‼️‼️‼️", to: .error)
        prePostFixLogFormatter.apply(prefix: "💣💣💣", postfix: "💣💣💣", to: .severe)
        log.formatters = [prePostFixLogFormatter]

        testDestination.add(expectedLogMessage: "🗯🗯🗯[\(XCGLogger.Level.verbose)] [\(fileName)] \(#function) > \(testString)🗯🗯🗯")
        testDestination.add(expectedLogMessage: "🔹🔹🔹[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(testString)🔹🔹🔹")
        testDestination.add(expectedLogMessage: "ℹ️ℹ️ℹ️[\(XCGLogger.Level.info)] [\(fileName)] \(#function) > \(testString)ℹ️ℹ️ℹ️")
        testDestination.add(expectedLogMessage: "⚠️⚠️⚠️[\(XCGLogger.Level.warning)] [\(fileName)] \(#function) > \(testString)⚠️⚠️⚠️")
        testDestination.add(expectedLogMessage: "‼️‼️‼️[\(XCGLogger.Level.error)] [\(fileName)] \(#function) > \(testString)‼️‼️‼️")
        testDestination.add(expectedLogMessage: "💣💣💣[\(XCGLogger.Level.severe)] [\(fileName)] \(#function) > \(testString)💣💣💣")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 6, "Fail: Didn't correctly load all of the expected log messages")
        log.verbose(testString)
        log.debug(testString)
        log.info(testString)
        log.warning(testString)
        log.error(testString)
        log.severe(testString)

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        // Set no prefix, no postfix, and no level, should clear everything
        prePostFixLogFormatter.apply()

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.info)] [\(fileName)] \(#function) > \(testString)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.info(testString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        // Set with no level specified, so it should be applied to all levels
        prePostFixLogFormatter.apply(prefix: ">>> ", postfix: " <<<")

        testDestination.add(expectedLogMessage: ">>> [\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(testString) <<<")
        testDestination.add(expectedLogMessage: ">>> [\(XCGLogger.Level.warning)] [\(fileName)] \(#function) > \(testString) <<<")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 2, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(testString)
        log.warning(testString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    func test_00200_testLogFiltersAreApplied() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let message = "Filters are more powerful than they first appear, since they can also change the content of log messages"

        let exclusiveFileNameFilter: FileNameFilter = FileNameFilter(excludeFrom: [fileName])
        log.filters = [exclusiveFileNameFilter]

        // Should not log anything, so there are no expected log messages
        log.debug(message)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let inclusiveFileNameFilter: FileNameFilter = FileNameFilter(includeFrom: [fileName])
        log.filters = [inclusiveFileNameFilter]

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(message)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(message)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    func test_00210_testTagFilter() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let normalMessage = "The WiFi SSID is: strange"
        let sensitiveMessage = "The WiFi password is: shamballa"

        let sensitiveTag = "Sensitive"

        // No filter
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(normalMessage)")
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(sensitiveMessage)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 2, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(normalMessage)
        log.debug(sensitiveMessage, userInfo: [XCGLogger.Constants.userInfoKeyTags: sensitiveTag])
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        // Exclude messages tagged as sensitive
        let exclusiveTagFilter: TagFilter = TagFilter(excludeFrom: [sensitiveTag])
        log.filters = [exclusiveTagFilter]

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(normalMessage)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(normalMessage)
        log.debug(sensitiveMessage, userInfo: [XCGLogger.Constants.userInfoKeyTags: [sensitiveTag]])
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        // Include only messages that are sensitive
        let inclusiveTagFilter: TagFilter = TagFilter(includeFrom: [sensitiveTag])
        log.filters = [inclusiveTagFilter]

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(sensitiveMessage)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(normalMessage)
        log.debug(sensitiveMessage, userInfo: [XCGLogger.Constants.userInfoKeyTags: Set<String>([sensitiveTag])])
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    func test_00220_testDevFilter() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let daveMessage = "Hmm, checking this thing, and that thing, and then this other thing..."
        let sabbyMessage = "Yeah it works...Moving on..."

        let dave = "DW"
        let sabby = "SW"

        let chatterBoxCount = 2

        // No filter
        for _ in 0 ..< chatterBoxCount {
            testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(daveMessage)")
        }
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(sabbyMessage)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == chatterBoxCount + 1, "Fail: Didn't correctly load all of the expected log messages")
        log.logAppDetails() // adds two unexpected log messages, since we haven't added these to the expected list above
        for _ in 0 ..< chatterBoxCount {
            log.debug(daveMessage, userInfo: [XCGLogger.Constants.userInfoKeyDevs: dave])
        }
        log.debug(sabbyMessage, userInfo: [XCGLogger.Constants.userInfoKeyDevs: sabby])
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 2, "Fail: Received an unexpected log line")
        testDestination.reset()

        // Exclude log messages added by a chatter box developer
        let exclusiveDevFilter: DevFilter = DevFilter(excludeFrom: [dave])
        log.filters = [exclusiveDevFilter]

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(sabbyMessage)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.logAppDetails() // adds two unexpected log messages, since we haven't added these to the expected list above
        for _ in 0 ..< chatterBoxCount {
            log.debug(daveMessage, userInfo: [XCGLogger.Constants.userInfoKeyDevs: dave])
        }
        log.debug(sabbyMessage, userInfo: [XCGLogger.Constants.userInfoKeyDevs: sabby])
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 2, "Fail: Received an unexpected log line")
        testDestination.reset()

        // Include only messages by one developer (lets them focus on only their info)
        let inclusiveDevFilter: DevFilter = DevFilter(includeFrom: [sabby])
        inclusiveDevFilter.applyFilterToInternalMessages = true // This will mean internal (ie appDetails etc) messages will be subject to the same filter rules as normal messages
        log.filters = [inclusiveDevFilter]

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(sabbyMessage)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.logAppDetails() // this time this shouldn't add additional unexpected messages, since these should be filtered because they weren't logged by sabby
        for _ in 0 ..< chatterBoxCount {
            log.debug(daveMessage, userInfo: [XCGLogger.Constants.userInfoKeyDevs: dave])
        }
        log.debug(sabbyMessage, userInfo: [XCGLogger.Constants.userInfoKeyDevs: sabby])
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test Objective-C Exception Handling
    func test_00300_objectiveCExceptionHandling() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let exceptionMessage: String = "Objective-C Exception"

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(exceptionMessage)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")

        _try({
            _throw(name: exceptionMessage)
        },
        catch: { (exception: NSException) in
            log.debug(exception)
        })

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test logging works correctly when logs are generated from multiple threads
    func test_01010_multiThreaded() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        testDestination.logQueue = DispatchQueue(label: log.identifier + ".serialQueue")
        log.add(destination: testDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        let myConcurrentQueue = DispatchQueue(label: log.identifier + ".concurrentQueue", attributes: .concurrent)
        myConcurrentQueue.sync {
            DispatchQueue.concurrentPerform(iterations: linesToLog.count) { (index: Int) -> () in
                log.debug(linesToLog[index])
            }
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test logging with closures works correctly when generated from multiple threads
    func test_01020_multiThreaded2() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        testDestination.logQueue = DispatchQueue(label: log.identifier + ".serialQueue")
        log.add(destination: testDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        let myConcurrentQueue = DispatchQueue(label: log.identifier + ".concurrentQueue", attributes: .concurrent)
        myConcurrentQueue.sync {
            DispatchQueue.concurrentPerform(iterations: linesToLog.count) { (index: Int) -> () in
                log.debug {
                    return "\(linesToLog[index])"
                }
            }
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test that our background processing works
    func test_01030_backgroundLogging() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier(), includeDefaultDestinations: false)

        let systemDestination = AppleSystemLogDestination(identifier: log.identifier + ".systemDestination")
        systemDestination.outputLevel = .debug
        systemDestination.showThreadName = true

        // Note: The thread name included in the log message should be "main" even though the log is processed in a background thread. This is because
        // it uses the thread name of the thread the log function is called in, not the thread used to do the output.
        systemDestination.logQueue = DispatchQueue.global(qos: .background)
        log.add(destination: systemDestination)

        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(fileName)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        for line in linesToLog {
            log.debug(line)
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    // Performance Testing
    //    func test_80000_BasicPerformanceTest() {
    //        let log: XCGLogger = XCGLogger(identifier: functionIdentifier(), includeDefaultDestinations: false)
    //        log.outputLevel = .debug
    //
    //        let testDestination: TestDestination = TestDestination(identifier: log.identifier + ".testDestination")
    //        testDestination.showLogIdentifier = true
    //        testDestination.showFunctionName = true
    //        testDestination.showThreadName = true
    //        testDestination.showFileName = true
    //        testDestination.showLineNumber = true
    //        testDestination.showLevel = true
    //        testDestination.showDate = true
    //        log.add(destination: testDestination)
    //
    //        self.measure() {
    //            for _ in 1 ..< 100 {
    //                for _ in 1 ..< 1000 {
    //                    log.debug("Thanks for all the fish!")
    //                }
    //                testDestination.reset()
    //            }
    //        }
    //        // 2.224, relative standard deviation: 2.820%, values: [2.361247, 2.271706, 2.268338, 2.179494, 2.182855, 2.177256, 2.187814, 2.191347, 2.148568, 2.272234]
    //        // 2.281, relative standard deviation: 3.712%, values: [2.393395, 2.443988, 2.328165, 2.206496, 2.160873, 2.304157, 2.256671, 2.273773, 2.252598, 2.189970]
    //        // 2.301, relative standard deviation: 2.122%, values: [2.377062, 2.386740, 2.347364, 2.262827, 2.289801, 2.294484, 2.272225, 2.252910, 2.240331, 2.290241]
    //    }

    func test_99999_lastTest() {
        // Add a final test that just waits a second, so any tests using the background can finish outputting results
        Thread.sleep(forTimeInterval: 1.0)
    }
}
