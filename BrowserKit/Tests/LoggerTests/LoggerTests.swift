// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import Logger

final class LoggerTests: XCTestCase {
    private var beaverBuilder: MockSwiftyBeaverBuilder!

    override func setUp() {
        super.setUp()
        beaverBuilder = MockSwiftyBeaverBuilder()
        cleanUp()
    }

    override func tearDown() {
        super.tearDown()
        beaverBuilder = nil
        cleanUp()
    }

    func testDebug() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.log("Debug log", level: .debug, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    func testInfo() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.log("Info log", level: .info, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.infoCalled, 1)
    }

    func testWarning() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.log("Warning log", level: .warning, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.warningCalled, 1)
    }

    func testFatal() {
        let subject = DefaultLogger(swiftyBeaverBuilder: beaverBuilder)
        subject.log("Fatal log", level: .fatal, category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.errorCalled, 1)
    }
}

// MARK: - Helper
private extension LoggerTests {
    func cleanUp() {
        MockSwiftyBeaver.debugCalled = 0
        MockSwiftyBeaver.infoCalled = 0
        MockSwiftyBeaver.warningCalled = 0
        MockSwiftyBeaver.errorCalled = 0
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

    static var debugCalled = 0
    static func debug(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        debugCalled += 1
    }

    static var infoCalled = 0
    static func info(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        infoCalled += 1
    }

    static var warningCalled = 0
    static func warning(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        warningCalled += 1
    }

    static var errorCalled = 0
    static func error(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        errorCalled += 1
    }
}
