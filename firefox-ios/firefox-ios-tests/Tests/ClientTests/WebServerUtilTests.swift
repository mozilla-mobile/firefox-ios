// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class WebServerUtilTests: XCTestCase {
    private var mockReaderMode: MockReaderModeHandlers!
    private var mockWebServer: MockWebServer!
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        mockReaderMode = MockReaderModeHandlers()
        mockWebServer = MockWebServer()
        profile = MockProfile()
    }

    override func tearDown() async throws {
        mockReaderMode = nil
        mockWebServer = nil
        profile = nil
        try await super.tearDown()
    }

    func test_setUpWebServer_startsTheServer() {
        let subject = createSubject()

        subject.setUpWebServer()

        XCTAssertEqual(mockWebServer.startIfNeededCalled, 1)
        XCTAssertEqual(mockReaderMode.registerCalled, 1)
    }

    func test_setUpWebServer_registersHandlersOnce_butStartsEachTime() {
        let subject = createSubject()

        subject.setUpWebServer()
        subject.setUpWebServer()
        subject.setUpWebServer()

        // Handlers persist on the server across stop/start, so they're only registered once,
        // but the server is (re)started on every foreground.
        XCTAssertEqual(mockReaderMode.registerCalled, 1)
        XCTAssertEqual(mockWebServer.startIfNeededCalled, 3)
    }

    private func createSubject() -> WebServerUtil {
        return WebServerUtil(
            readerModeHandler: mockReaderMode,
            webServer: mockWebServer,
            profile: profile
        )
    }
}
