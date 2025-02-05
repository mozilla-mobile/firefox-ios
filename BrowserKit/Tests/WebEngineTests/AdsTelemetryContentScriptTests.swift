// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class AdsTelemetryContentScriptTests: XCTestCase {
    private var adsTelemetryDelegate: MockAdsTelemetryDelegate!

    override func setUp() {
        super.setUp()
        adsTelemetryDelegate = MockAdsTelemetryDelegate()
    }

    override func tearDown() {
        super.tearDown()
        adsTelemetryDelegate = nil
    }

    func testDidReceiveMessageGivenEmptyMessageThenNoDelegateCalled() {
        let subject = AdsTelemetryContentScript(delegate: adsTelemetryDelegate)

        subject.userContentController(didReceiveMessage: [])

        XCTAssertEqual(adsTelemetryDelegate.trackAdsFoundOnPageCalled, 0)
        XCTAssertEqual(adsTelemetryDelegate.trackAdsClickedOnPageCalled, 0)
    }

    func testDidReceiveMessageWithNoAdURLMatchThenNoDelegateCalled() {
        let subject = AdsTelemetryContentScript(delegate: adsTelemetryDelegate)

        subject.userContentController(didReceiveMessage: [
            "url": "https://www.someSiteWeDontCareAbout.com/search?q=something",
            "cookies": [["name": "ABCDEFGH", "value": "cookie_val"]],
            "urls": ["https://www.somewebsite.com/somepage"]
        ])

        XCTAssertEqual(adsTelemetryDelegate.trackAdsFoundOnPageCalled, 0)
        XCTAssertEqual(adsTelemetryDelegate.trackAdsClickedOnPageCalled, 0)
    }

    func testDidReceiveMessageWithBasicURLMatchButNoAdURLsThenNoDelegateCalled() {
        let subject = AdsTelemetryContentScript(delegate: adsTelemetryDelegate)

        subject.userContentController(didReceiveMessage: [
            "url": "https://www.mocksearch.com/search?q=something",
            "cookies": [["name": "ABCDEFGH", "value": "cookie_val"]],
            "urls": ["https://www.somewebsite.com/somepage"]
        ])

        XCTAssertEqual(adsTelemetryDelegate.trackAdsFoundOnPageCalled, 0)
        XCTAssertEqual(adsTelemetryDelegate.trackAdsClickedOnPageCalled, 0)
    }

    func testDidReceiveMessageWithBasicURLMatchAndMatchingAdURLsThenTrackOnPageCalled() {
        let subject = AdsTelemetryContentScript(delegate: adsTelemetryDelegate)

        subject.userContentController(didReceiveMessage: [
            "url": "https://www.mocksearch.com/search?q=something",
            "cookies": [["name": "ABCDEFGH", "value": "cookie_val"]],
            "urls": ["https://www.mocksearch.com/pagead/aclk"]
        ])

        XCTAssertEqual(adsTelemetryDelegate.trackAdsFoundOnPageCalled, 1)
        XCTAssertEqual(adsTelemetryDelegate.trackAdsClickedOnPageCalled, 0)
    }

    func testDidReceiveMessageWithBasicURLMatchAndMatchingAdURLsThenTrackOnPageCalledAndURLsSent() {
        let subject = AdsTelemetryContentScript(delegate: adsTelemetryDelegate)

        subject.userContentController(didReceiveMessage: [
            "url": "https://www.mocksearch.com/search?q=something",
            "cookies": [["name": "ABCDEFGH", "value": "cookie_val"]],
            "urls": ["https://www.mocksearch.com/pagead/aclk",
                     "https://www.mocksearch.com/pagead/bclk"]
        ])

        XCTAssertEqual(adsTelemetryDelegate.trackAdsFoundOnPageCalled, 1)
        XCTAssertEqual(adsTelemetryDelegate.savedTrackAdsOnPageURLs?.count ?? 0, 2)
        XCTAssertEqual(adsTelemetryDelegate.savedTrackAdsOnPageProviderName, "mocksearch")
        XCTAssertEqual(adsTelemetryDelegate.trackAdsClickedOnPageCalled, 0)
    }
}
