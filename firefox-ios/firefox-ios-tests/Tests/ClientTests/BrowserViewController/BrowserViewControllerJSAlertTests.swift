// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import XCTest
import Common
import Shared

@testable import Client

@MainActor
final class BrowserViewControllerJSAlertTests: XCTestCase {
    var profile: MockProfile!
    var tabManager: MockTabManager!

    override func setUp() async throws {
        try await super.setUp()
        tabManager = MockTabManager()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManager)
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        tabManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // Popup on its own tab does not block.
    func testAlertCouldFreeze_falseForTheSelectedTabItself() {
        let subject = createSubject()
        let tab = makeTab()
        setTabs([tab], selected: tab)

        // A tab's own dialog blocks only itself
        XCTAssertFalse(subject.alertCouldFreezeSelectedTab(webView(of: tab)))
    }

    func testAlertCouldFreeze_falseForIndependentBackgroundTab() {
        let subject = createSubject()
        let visible = makeTab()
        let background = makeTab()
        setTabs([visible, background], selected: visible)

        XCTAssertFalse(subject.alertCouldFreezeSelectedTab(webView(of: background)))
    }

    func testAlertCouldFreeze_falseWhenRelatedButNotAPopup() {
        let subject = createSubject()
        let opener = makeTab()
        // Has a parent ("open in new tab"), but not a window.open popup, so it uses a fresh configuration
        let child = makeTab(parent: opener, isPopup: false)
        setTabs([opener, child], selected: child)

        XCTAssertFalse(subject.alertCouldFreezeSelectedTab(webView(of: opener)))
    }

    func testAlertCouldFreeze_trueWhenOpenerAlertsWhilePopupIsVisible() {
        let subject = createSubject()
        let opener = makeTab()
        let popup = makeTab(parent: opener, isPopup: true)
        setTabs([opener, popup], selected: popup)

        XCTAssertTrue(subject.alertCouldFreezeSelectedTab(webView(of: opener)))
    }

    func testAlertCouldFreeze_trueWhenPopupAlertsWhileOpenerIsVisible() {
        let subject = createSubject()
        let opener = makeTab()
        let popup = makeTab(parent: opener, isPopup: true)
        setTabs([opener, popup], selected: opener)

        XCTAssertTrue(subject.alertCouldFreezeSelectedTab(webView(of: popup)))
    }

    func testAlertCouldFreeze_falseWhenTabChainIsBroken() {
        let subject = createSubject()
        let opener = makeTab()
        let middle = makeTab(parent: opener, isPopup: false) // not a popup -> own process
        let popup = makeTab(parent: middle, isPopup: true)
        setTabs([opener, middle, popup], selected: popup)

        XCTAssertFalse(subject.alertCouldFreezeSelectedTab(webView(of: opener)))
    }

    // MARK: - Utilities

    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> BrowserViewController {
        let subject = BrowserViewController(profile: profile, tabManager: tabManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    /// Creates a tab and associated webView. `isPopup` indicates it is a window.open popup
    private func makeTab(parent: Tab? = nil, isPopup: Bool = false) -> Tab {
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: .init())
        tab.parent = parent
        if isPopup {
            tab.requiredPopupConfiguration = WKWebViewConfiguration()
        }
        return tab
    }

    private func setTabs(_ tabs: [Tab], selected: Tab?) {
        tabManager.tabs = tabs
        tabManager.selectedTab = selected
    }

    private func webView(of tab: Tab) -> WKWebView {
        guard let webView = tab.webView else { XCTFail("Tab is expected to have a webView"); return WKWebView() }
        return webView
    }
}
