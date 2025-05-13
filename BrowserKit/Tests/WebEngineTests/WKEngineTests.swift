// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class WKEngineTests: XCTestCase {
    private var userScriptManager: MockWKUserScriptManager!
    private var webServerUtil: MockWKWebServerUtil!
    private var sourceTimerFactory: MockDispatchSourceTimerFactory!

    override func setUp() async throws {
        try await super.setUp()
        userScriptManager = await MockWKUserScriptManager()
        webServerUtil = MockWKWebServerUtil()
        sourceTimerFactory = MockDispatchSourceTimerFactory()
    }

    override func tearDown() {
        userScriptManager = nil
        webServerUtil = nil
        sourceTimerFactory = nil
        super.tearDown()
    }

    @MainActor
    func testCreateViewThenCreatesView() async {
        let subject = await createSubject()
        XCTAssertNotNil(subject.createView())
    }

    func testCreateSessionThenCreatesSession() async throws {
        let subject = await createSubject()
        let session = try await subject.createSession(dependencies: DefaultTestDependencies().sessionDependencies)
        XCTAssertNotNil(session)
    }

    func testWarmEngineCallsSetupEngine() async {
        let subject = await createSubject()
        subject.warmEngine()

        XCTAssertEqual(sourceTimerFactory.dispatchSource.cancelCalled, 0)
        XCTAssertEqual(webServerUtil.setUpWebServerCalled, 1)
    }

    func testWarmEngineAfterIdle() async {
        let subject = await createSubject()
        subject.idleEngine()
        subject.warmEngine()

        XCTAssertEqual(sourceTimerFactory.dispatchSource.cancelCalled, 1)
        XCTAssertEqual(webServerUtil.setUpWebServerCalled, 1)
    }

    func testIdleEngineCallsStopEngine() async {
        let subject = await createSubject()
        subject.idleEngine()

        XCTAssertEqual(sourceTimerFactory.dispatchSource.scheduleCalled, 1)
        XCTAssertEqual(sourceTimerFactory.dispatchSource.setEventHandlerCalled, 1)
        XCTAssertEqual(sourceTimerFactory.dispatchSource.resumeCalled, 1)
        XCTAssertEqual(webServerUtil.stopWebServerCalled, 1)
    }

    // MARK: Helper

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) async -> WKEngine {
        let configProvider = await MockWKEngineConfigurationProvider()
        let subject = await WKEngine(userScriptManager: userScriptManager,
                                     webServerUtil: webServerUtil,
                                     sourceTimerFactory: sourceTimerFactory,
                                     configProvider: configProvider,
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
