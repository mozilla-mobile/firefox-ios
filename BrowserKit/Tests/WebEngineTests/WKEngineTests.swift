// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebEngine

final class WKEngineTests: XCTestCase {
    private var userScriptManager: MockWKUserScriptManager!
    private var webServerUtil: MockWKWebServerUtil!
    private var sourceTimerFactory: MockDispatchSourceTimerFactory!

    override func setUp() {
        super.setUp()
        userScriptManager = MockWKUserScriptManager()
        webServerUtil = MockWKWebServerUtil()
        sourceTimerFactory = MockDispatchSourceTimerFactory()
    }

    override func tearDown() {
        userScriptManager = nil
        webServerUtil = nil
        sourceTimerFactory = nil
        super.tearDown()
    }

    func testCreateViewThenCreatesView() {
        let subject = createSubject()
        XCTAssertNotNil(subject.createView())
    }

    func testCreateSessionThenCreatesSession() throws {
        let subject = createSubject()

        let params = WKWebviewParameters(blockPopups: true, isPrivate: false)
        let dependencies = EngineSessionDependencies(webviewParameters: params)
        let session = try XCTUnwrap(subject.createSession(dependencies: dependencies))
        XCTAssertNotNil(session)
    }

    func testWarmEngineCallsSetupEngine() {
        let subject = createSubject()
        subject.warmEngine()

        XCTAssertEqual(sourceTimerFactory.dispatchSource.cancelCalled, 0)
        XCTAssertEqual(webServerUtil.setUpWebServerCalled, 1)
    }

    func testWarmEngineAfterIdle() {
        let subject = createSubject()
        subject.idleEngine()
        subject.warmEngine()

        XCTAssertEqual(sourceTimerFactory.dispatchSource.cancelCalled, 1)
        XCTAssertEqual(webServerUtil.setUpWebServerCalled, 1)
    }

    func testIdleEngineCallsStopEngine() {
        let subject = createSubject()
        subject.idleEngine()

        XCTAssertEqual(sourceTimerFactory.dispatchSource.scheduleCalled, 1)
        XCTAssertEqual(sourceTimerFactory.dispatchSource.setEventHandlerCalled, 1)
        XCTAssertEqual(sourceTimerFactory.dispatchSource.resumeCalled, 1)
        XCTAssertEqual(webServerUtil.stopWebServerCalled, 1)
    }

    // MARK: Helper

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> WKEngine {
        let subject = WKEngine(userScriptManager: userScriptManager,
                               webServerUtil: webServerUtil,
                               sourceTimerFactory: sourceTimerFactory,
                               engineDependencies: engineDependencies)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private var engineDependencies: EngineDependencies {
        let readerModeConfiguration = ReaderModeConfiguration(loadingText: "loadingText",
                                                              loadingFailedText: "loadingFailedText",
                                                              loadOriginalText: "loadOriginalText",
                                                              readerModeErrorText: "readerModeErrorText")
        return EngineDependencies(readerModeConfiguration: readerModeConfiguration)
    }
}
