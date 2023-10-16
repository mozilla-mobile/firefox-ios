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

    // MARK: - Log

    func testLog_debug() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Debug log", level: .debug, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    func testLog_info() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Info log", level: .info, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.infoCalled, 1)
    }

    func testLog_warning() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Warning log", level: .warning, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.warningCalled, 1)
    }

    func testLog_fatal() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Fatal log", level: .fatal, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.errorCalled, 1)
    }

    func testLog_informationCorrelate_withAllParams() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Debug log",
                    level: .debug,
                    category: .setup,
                    extra: ["example": "test"],
                    description: "A description")

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, "Debug log - A description - example: test")
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    func testLog_informationCorrelate_withMessageAndDescriptionOnly() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Debug log",
                    level: .debug,
                    category: .setup,
                    description: "A description")

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, "Debug log - A description")
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    func testLog_informationCorrelate_withMessageAndExtra() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Debug log",
                    level: .debug,
                    category: .setup,
                    extra: ["example": "test"])

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, "Debug log - example: test")
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    func testLog_informationCorrelate_withMessageOnly() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Debug log",
                    level: .debug,
                    category: .setup)

        XCTAssertEqual(MockSwiftyBeaver.savedMessage, "Debug log")
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    // MARK: - CrashManager

    func testCrashManagerLog_withoutCrashManager_doesNotLog() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.log("Debug log", level: .debug, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)

        XCTAssertNil(crashManager.message)
        XCTAssertNil(crashManager.category)
        XCTAssertNil(crashManager.level)
    }

    func testCrashManagerLog_fatalIsSent_informationCorrelate() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.log("Fatal log",
                    level: .fatal,
                    category: .setup,
                    extra: ["example": "test"],
                    description: "A description")

        XCTAssertEqual(crashManager.message, "Fatal log")
        XCTAssertEqual(crashManager.category, .setup)
        XCTAssertEqual(crashManager.level, .fatal)
        let extra = try XCTUnwrap(crashManager.extraEvents)
        XCTAssertEqual(extra, ["example": "test", "errorDescription": "A description"])
    }

    func testCrashManagerLog_sendUsageDataNotCalled() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        XCTAssertNil(crashManager.savedSendUsageData)
    }

    func testCrashManagerLog_sendUsageDataCalled() throws {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.configure(crashManager: crashManager)
        subject.setup(sendUsageData: true)

        let savedSendUsageData = try XCTUnwrap(crashManager.savedSendUsageData)
        XCTAssertTrue(savedSendUsageData)
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
class MockSwiftyBeaver: SwiftyBeaverWrapper {
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
class MockCrashManager: CrashManager {
    var crashedLastLaunch = false

    var savedSendUsageData: Bool?
    func setup(sendUsageData: Bool) {
        savedSendUsageData = sendUsageData
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
