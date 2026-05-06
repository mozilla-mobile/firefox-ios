// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import XCTest
import Shared
@testable import Client

final class TabManagerGetTabTests: TabManagerTestsBase {
    // MARK: - getTabForUUID

    @MainActor
    func testGetTabForUUID_returnsMatchingTab() {
        let tabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: tabs)
        guard let target = subject.tabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        let result = subject.getTabForUUID(uuid: target.tabUUID)

        XCTAssertEqual(result, target)
    }

    @MainActor
    func testGetTabForUUID_returnsNil_whenUUIDNotFound() {
        let tabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: tabs)

        let result = subject.getTabForUUID(uuid: "non-existent-uuid")

        XCTAssertNil(result)
    }

    @MainActor
    func testGetTabForUUID_returnsNil_whenNoTabsExist() {
        let subject = createSubject(tabs: [])

        let result = subject.getTabForUUID(uuid: "any-uuid")

        XCTAssertNil(result)
    }

    // MARK: - getTabForURL

    @MainActor
    func testGetTabForURL_returnsMatchingTab() {
        // addTab(URLRequest) calls webView.load(_:), which sets webView.url to the request URL immediately.
        let subject = createSubject()
        let addedTab = subject.addTab(URLRequest(url: URL(string: "https://mozilla.com")!), afterTab: nil, isPrivate: false)

        let result = subject.getTabForURL(URL(string: "https://mozilla.com/")!)

        XCTAssertEqual(result, addedTab)
    }

    @MainActor
    func testGetTabForURL_returnsNil_whenNoTabMatchesURL() {
        let subject = createSubject()
        subject.addTab(URLRequest(url: URL(string: "https://mozilla.com")!), afterTab: nil, isPrivate: false)

        let result = subject.getTabForURL(URL(string: "https://example.com/")!)

        XCTAssertNil(result)
    }

    // MARK: - Subscript [index]

    @MainActor
    func testSubscriptIndex_returnsCorrectTab_forValidIndex() {
        let tabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: tabs)

        XCTAssertEqual(subject[0], tabs[0])
        XCTAssertEqual(subject[1], tabs[1])
        XCTAssertEqual(subject[2], tabs[2])
    }

    @MainActor
    func testSubscriptIndex_returnsNil_forOutOfBoundsIndex() {
        let tabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: tabs)

        XCTAssertNil(subject[3])
        XCTAssertNil(subject[100])
    }

    // MARK: - Subscript [webView]

    @MainActor
    func testSubscriptWebView_returnsCorrectTab_whenWebViewMatches() {
        let subject = createSubject(tabs: [])
        // addTab creates a tab via configureTab, which calls createWebview and gives the tab a real webView
        let tab = subject.addTab()

        guard let webView = tab.webView else {
            XCTFail("Tab created via addTab should have a webView")
            return
        }

        XCTAssertEqual(subject[webView], tab)
    }

    @MainActor
    func testSubscriptWebView_returnsNil_whenNoTabHasMatchingWebView() {
        let tabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: tabs)
        let unrelatedWebView = WKWebView()

        XCTAssertNil(subject[unrelatedWebView])
    }
}
