// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import XCTest

@testable import WebEngine

final class WKWebServerUtilTests: XCTestCase {
    private var webServer: MockWebServer!

    override func setUp() {
        super.setUp()
        webServer = MockWebServer()
    }

    override func tearDown() {
        webServer = nil
        super.tearDown()
    }

    func testSetupWebServerGivenIsRunningThenDoesntStart() {
        let subject = createSubject()

        subject.setUpWebServer(readerModeConfiguration: readerModeConfiguration)

        XCTAssertFalse(webServer.isRunning)
        XCTAssertEqual(webServer.startCalled, 1)
        XCTAssertEqual(webServer.addTestHandlerCalled, 1)
    }

    func testSetupWebServerGivenIsNotRunningThenStart() {
        webServer.isRunning = true
        let subject = createSubject()

        subject.setUpWebServer(readerModeConfiguration: readerModeConfiguration)

        XCTAssertTrue(webServer.isRunning)
        XCTAssertEqual(webServer.startCalled, 0)
        XCTAssertEqual(webServer.addTestHandlerCalled, 0)
    }

    func testStopWebServer() {
        let subject = createSubject()

        subject.stopWebServer()

        XCTAssertEqual(webServer.stopCalled, 1)
    }

    func createSubject() -> WKWebServerUtil {
        let subject = DefaultWKWebServerUtil(webServer: webServer)
        trackForMemoryLeaks(subject)
        return subject
    }

    private var readerModeConfiguration: ReaderModeConfiguration {
        return ReaderModeConfiguration(loadingText: "loadingText",
                                       loadingFailedText: "loadingFailedText",
                                       loadOriginalText: "loadOriginalText",
                                       readerModeErrorText: "readerModeErrorText")
    }
}
