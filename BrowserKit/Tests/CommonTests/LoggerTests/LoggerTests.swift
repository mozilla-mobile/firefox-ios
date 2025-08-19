// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class LoggerTests: XCTestCase {
    private var beaverBuilder: MockSwiftyBeaverBuilder!
    private var crashManager: MockCrashManager!

    override func setUp() {
        super.setUp()
        beaverBuilder = MockSwiftyBeaverBuilder()
        crashManager = MockCrashManager()
        cleanUp()
    }

    override func tearDown() {
        super.tearDown()
        beaverBuilder = nil
        crashManager = nil
        cleanUp()
    }

    // MARK: - Log to SwiftyBeaver and Sentry crash manager

    func testLog_debug() {
        let logMessage = "Debug log"
        let logLevel = LoggerLevel.debug
        let logCategory = LoggerCategory.setup

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(logMessage, level: logLevel, category: logCategory)

        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)

        XCTAssertEqual(crashManager.message, logMessage)
        XCTAssertEqual(crashManager.level, logLevel)
        XCTAssertEqual(crashManager.category, logCategory)
    }

    func testLog_info() {
        let logMessage = "Info log"
        let logLevel = LoggerLevel.info
        let logCategory = LoggerCategory.setup

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(logMessage, level: logLevel, category: logCategory)

        XCTAssertEqual(MockSwiftyBeaver.infoCalled, 1)

        XCTAssertEqual(crashManager.message, logMessage)
        XCTAssertEqual(crashManager.level, logLevel)
        XCTAssertEqual(crashManager.category, logCategory)
    }

    func testLog_warning() {
        let logMessage = "Warning log"
        let logLevel = LoggerLevel.warning
        let logCategory = LoggerCategory.setup

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(logMessage, level: logLevel, category: logCategory)

        XCTAssertEqual(MockSwiftyBeaver.warningCalled, 1)

        XCTAssertEqual(crashManager.message, logMessage)
        XCTAssertEqual(crashManager.level, logLevel)
        XCTAssertEqual(crashManager.category, logCategory)
    }

    func testLog_fatal() {
        let logMessage = "Fatal log"
        let logLevel = LoggerLevel.fatal
        let logCategory = LoggerCategory.setup

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(logMessage, level: logLevel, category: logCategory)

        XCTAssertEqual(MockSwiftyBeaver.errorCalled, 1)

        XCTAssertEqual(crashManager.message, logMessage)
        XCTAssertEqual(crashManager.level, logLevel)
        XCTAssertEqual(crashManager.category, logCategory)
    }

    func testLog_informationCorrelate_withAllParams() throws {
        let logMessage = "Debug log"
        let logLevel = LoggerLevel.debug
        let logCategory = LoggerCategory.setup
        let logExtraKey = "example"
        let logExtraValue = "test"
        let logExtra = [logExtraKey: logExtraValue]
        let logDescription = "A description"

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(
            logMessage,
            level: logLevel,
            category: logCategory,
            extra: logExtra,
            description: logDescription
        )

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, "\(logMessage) - \(logDescription) - \(logExtraKey): \(logExtraValue)")
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)

        XCTAssertEqual(crashManager.message, logMessage)
        XCTAssertEqual(crashManager.level, logLevel)
        XCTAssertEqual(crashManager.category, logCategory)
        XCTAssertEqual(crashManager.extraEvents, ["errorDescription": logDescription, logExtraKey: logExtraValue])
    }

    func testLog_informationCorrelate_withMessageAndDescriptionOnly() throws {
        let logMessage = "Debug log"
        let logLevel = LoggerLevel.debug
        let logCategory = LoggerCategory.setup
        let logDescription = "A description"

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(
            logMessage,
            level: logLevel,
            category: logCategory,
            description: logDescription
        )

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, "\(logMessage) - \(logDescription)")
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)

        XCTAssertEqual(crashManager.message, logMessage)
        XCTAssertEqual(crashManager.level, logLevel)
        XCTAssertEqual(crashManager.category, logCategory)
        XCTAssertEqual(crashManager.extraEvents, ["errorDescription": logDescription])
    }

    func testLog_informationCorrelate_withMessageAndExtra() throws {
        let logMessage = "Debug log"
        let logLevel = LoggerLevel.debug
        let logCategory = LoggerCategory.setup
        let logExtraKey = "example"
        let logExtraValue = "test"
        let logExtra = [logExtraKey: logExtraValue]

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(
            logMessage,
            level: logLevel,
            category: logCategory,
            extra: logExtra
        )

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, "Debug log - example: test")
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)

        XCTAssertEqual(crashManager.message, logMessage)
        XCTAssertEqual(crashManager.level, logLevel)
        XCTAssertEqual(crashManager.category, logCategory)
        XCTAssertEqual(crashManager.extraEvents, [logExtraKey: logExtraValue])
    }

    func testLog_informationCorrelate_withMessageOnly() throws {
        let logMessage = "Debug log"
        let logLevel = LoggerLevel.debug
        let logCategory = LoggerCategory.setup

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(logMessage, level: logLevel, category: logCategory)

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, logMessage)
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)

        XCTAssertEqual(crashManager.message, logMessage)
        XCTAssertEqual(crashManager.level, logLevel)
        XCTAssertEqual(crashManager.category, logCategory)
    }

    // MARK: - CrashManager

    func testCrashManagerLog_fatalIsSent_informationCorrelate() throws {
        let logMessage = "Fatal log"
        let logLevel = LoggerLevel.fatal
        let logCategory = LoggerCategory.setup
        let logExtraKey = "example"
        let logExtraValue = "test"
        let logExtra = [logExtraKey: logExtraValue]
        let logDescription = "A description"

        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.log(
            logMessage,
            level: logLevel,
            category: logCategory,
            extra: logExtra,
            description: logDescription
        )

        XCTAssertEqual(crashManager.message, "Fatal log")
        XCTAssertEqual(crashManager.category, .setup)
        XCTAssertEqual(crashManager.level, .fatal)
        XCTAssertEqual(crashManager.extraEvents, ["errorDescription": logDescription, logExtraKey: logExtraValue])
    }

    func testCrashManagerLog_sendCrashReportsNotCalled_onInit() {
        _ = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        XCTAssertEqual(crashManager.savedSendCrashReportsCalled, 0)
    }

    func testCrashManagerLog_sendCrashReportsCalled_onSetup() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder, crashManager: crashManager)
        subject.setup(sendCrashReports: true)

        XCTAssertEqual(crashManager.savedSendCrashReportsCalled, 1)
    }
}

// MARK: - Helper
private extension LoggerTests {
    func cleanUp() {
        MockSwiftyBeaver.debugCalled = 0
        MockSwiftyBeaver.infoCalled = 0
        MockSwiftyBeaver.warningCalled = 0
        MockSwiftyBeaver.errorCalled = 0
        MockSwiftyBeaver.savedMessage = nil
    }
}

// MARK: - SwiftyBeaverBuilder
class MockSwiftyBeaverBuilder: SwiftyBeaverBuilder {
    func setup(with destination: URL?) -> SwiftyBeaverWrapper.Type {
        return MockSwiftyBeaver.self
    }
}

// MARK: - MockSwiftyBeaver
final class MockSwiftyBeaver: SwiftyBeaverWrapper {
    static func logFileDirectoryPath(inDocuments: Bool) -> String? {
        return nil
    }

    static var fileDestination: URL?
    static var savedMessage: String?

    static var debugCalled = 0
    static func debug(_ message: @autoclosure () -> Any, file: String, function: String, line: Int, context: Any?) {
        debugCalled += 1
        savedMessage = "\(message())"
    }

    static var infoCalled = 0
    static func info(_ message: @autoclosure () -> Any, file: String, function: String, line: Int, context: Any?) {
        infoCalled += 1
        savedMessage = "\(message())"
    }

    static var warningCalled = 0
    static func warning(_ message: @autoclosure () -> Any, file: String, function: String, line: Int, context: Any?) {
        warningCalled += 1
        savedMessage = "\(message())"
    }

    static var errorCalled = 0
    static func error(_ message: @autoclosure () -> Any, file: String, function: String, line: Int, context: Any?) {
        errorCalled += 1
        savedMessage = "\(message())"
    }
}

// MARK: - CrashManager
final class MockCrashManager: CrashManager, @unchecked Sendable {
    var crashedLastLaunch = false

    var savedSendCrashReportsCalled = 0
    func setup(sendCrashReports: Bool) {
        savedSendCrashReportsCalled += 1
    }

    var message: String?
    var category: LoggerCategory?
    var level: LoggerLevel?
    var extraEvents: [String: String]?
    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: String]?) {
        self.message = message
        self.category = category
        self.level = level
        self.extraEvents = extraEvents
    }

    var error: Error?
    func captureError(error: Error) {
        self.error = error
    }
}
