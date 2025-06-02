// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class AdsTelemetryContentScriptTests: XCTestCase {
    private var contentScriptDelegate: MockContentScriptDelegate!

    override func setUp() {
        super.setUp()
        contentScriptDelegate = MockContentScriptDelegate()
    }

    override func tearDown() {
        contentScriptDelegate = nil
        super.tearDown()
    }

    func testDidReceiveMessageGivenEmptyMessageThenNoDelegateCalled() {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [])

        XCTAssertEqual(contentScriptDelegate.contentScriptDidSendEventCalled, 0)
        XCTAssertNil(contentScriptDelegate.lastContentScriptEvent)
    }

    func testDidReceiveMessageWithNoAdURLMatchThenNoDelegateCalled() {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [
            "url": "https://www.someSiteWeDontCareAbout.com/search?q=something",
            "cookies": [["name": "ABCDEFGH", "value": "cookie_val"]],
            "urls": ["https://www.somewebsite.com/somepage"]
        ])

        XCTAssertEqual(contentScriptDelegate.contentScriptDidSendEventCalled, 0)
        XCTAssertNil(contentScriptDelegate.lastContentScriptEvent)
    }

    func testDidReceiveMessageWithBasicURLMatchButNoAdURLsThenNoDelegateCalled() {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [
            "url": "https://www.mocksearch.com/search?q=something",
            "cookies": [["name": "ABCDEFGH", "value": "cookie_val"]],
            "urls": ["https://www.somewebsite.com/somepage"]
        ])

        XCTAssertEqual(contentScriptDelegate.contentScriptDidSendEventCalled, 0)
        XCTAssertNil(contentScriptDelegate.lastContentScriptEvent)
    }

    func testDidReceiveMessageWithBasicURLMatchAndMatchingAdURLsThenTrackOnPageCalled() throws {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [
            "url": "https://www.mocksearch.com/search?q=something",
            "cookies": [["name": "ABCDEFGH", "value": "cookie_val"]],
            "urls": ["https://www.mocksearch.com/pagead/aclk"]
        ])

        let event = try XCTUnwrap(contentScriptDelegate.lastContentScriptEvent)
        XCTAssertEqual(contentScriptDelegate.contentScriptDidSendEventCalled, 1)
        XCTAssertEqual(event, .trackedAdsFoundOnPage(provider: "mocksearch",
                                                     urls: ["https://www.mocksearch.com/pagead/aclk"]))
    }

    func testDidReceiveMessageWithBasicURLMatchAndMatchingAdURLsThenTrackOnPageCalledAndURLsSent() throws {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [
            "url": "https://www.mocksearch.com/search?q=something",
            "cookies": [["name": "ABCDEFGH", "value": "cookie_val"]],
            "urls": ["https://www.mocksearch.com/pagead/aclk",
                     "https://www.mocksearch.com/pagead/bclk"]
        ])

        guard let event = contentScriptDelegate.lastContentScriptEvent,
              case .trackedAdsFoundOnPage(let provider, let urls) = event else {
            XCTFail("Couldn't find expected event")
            return
        }

        XCTAssertEqual(contentScriptDelegate.contentScriptDidSendEventCalled, 1)
        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(provider, "mocksearch")
    }

    private func createSubject() -> AdsTelemetryContentScript {
        let subject = AdsTelemetryContentScript(
            delegate: contentScriptDelegate,
            searchProviderModels: MockAdsTelemetrySearchProvider.mockSearchProviderModels()
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
