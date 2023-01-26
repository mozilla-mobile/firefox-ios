// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import Common

final class LoggerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        cleanUp()
    }

    override func tearDown() {
        super.tearDown()
        cleanUp()
    }

    func testVerbose() {
        let subject = DefaultLogger(swiftyBeaver: MockSwiftyBeaver.self)
        subject.verbose("Verbose log", category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.verboseCalled, 1)
    }

    func testDebug() {
        let subject = DefaultLogger(swiftyBeaver: MockSwiftyBeaver.self)
        subject.debug("Debug log", category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.debugCalled, 1)
    }

    func testInfo() {
        let subject = DefaultLogger(swiftyBeaver: MockSwiftyBeaver.self)
        subject.info("Info log", category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.infoCalled, 1)
    }

    func testWarning() {
        let subject = DefaultLogger(swiftyBeaver: MockSwiftyBeaver.self)
        subject.warning("Warning log", category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.warningCalled, 1)
    }

    func testError() {
        let subject = DefaultLogger(swiftyBeaver: MockSwiftyBeaver.self)
        subject.error("Error log", category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.errorCalled, 1)
    }

    func testFatal() {
        let subject = DefaultLogger(swiftyBeaver: MockSwiftyBeaver.self)
        subject.fatal("Fatal log", category: .setup)
        XCTAssertEqual(MockSwiftyBeaver.errorCalled, 1)
    }
}

// MARK: - Helper
private extension LoggerTests {
    func cleanUp() {
        MockSwiftyBeaver.verboseCalled = 0
        MockSwiftyBeaver.debugCalled = 0
        MockSwiftyBeaver.infoCalled = 0
        MockSwiftyBeaver.warningCalled = 0
        MockSwiftyBeaver.errorCalled = 0
    }
}

// MARK: - MockSwiftyBeaver
class MockSwiftyBeaver: SwiftyBeaverWrapper {
    static var verboseCalled = 0
    static func verbose(_ message: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) {
        verboseCalled += 1
    }

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
