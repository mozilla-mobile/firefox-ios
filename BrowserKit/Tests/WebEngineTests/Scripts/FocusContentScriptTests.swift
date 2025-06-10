// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class FocusContentScriptTests: XCTestCase {
    private var contentScriptDelegate: MockContentScriptDelegate!

    override func setUp() {
        super.setUp()
        contentScriptDelegate = MockContentScriptDelegate()
    }

    override func tearDown() {
        contentScriptDelegate = nil
        super.tearDown()
    }

    func testUserContentControllerGivenEmptyDataDoesNotCallContentScriptDelegate() {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [:])

        XCTAssertEqual(contentScriptDelegate.contentScriptDidSendEventCalled, 0)
        XCTAssertNil(contentScriptDelegate.lastContentScriptEvent)
    }

    func testUserContentControllerGivenFocusEventCallsContentScriptDelegate() throws {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [
            "eventType": "focus",
            "elementType": "field"
        ])

        let event = try XCTUnwrap(contentScriptDelegate.lastContentScriptEvent)
        XCTAssertEqual(contentScriptDelegate.contentScriptDidSendEventCalled, 1)
        XCTAssertEqual(event, .fieldFocusChanged(true))
    }

    func testUserContentControllerGivenBlurEventCallsContentScriptDelegate() throws {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [
            "eventType": "blur",
            "elementType": "field"
        ])

        let event = try XCTUnwrap(contentScriptDelegate.lastContentScriptEvent)
        XCTAssertEqual(contentScriptDelegate.contentScriptDidSendEventCalled, 1)
        XCTAssertEqual(event, .fieldFocusChanged(false))
    }

    private func createSubject() -> FocusContentScript {
        let subject = FocusContentScript(delegate: contentScriptDelegate)
        trackForMemoryLeaks(subject)
        return subject
    }
}
