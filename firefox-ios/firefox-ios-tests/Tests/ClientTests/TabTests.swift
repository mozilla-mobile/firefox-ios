// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared
@testable import Client

class TabTests: XCTestCase {
    private var tabDelegate: MockLegacyTabDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        // Disable debug flag for faster inactive tabs and perform tests based on the real 14 day time to inactive
        UserDefaults.standard.set(false, forKey: PrefsKeys.FasterInactiveTabsOverride)
    }

    override func tearDown() {
        super.tearDown()
        tabDelegate = nil
    }

    func testShareURL_RemovingReaderModeComponents() {
        let url = URL(string: "http://localhost:123/reader-mode/page?url=https://mozilla.org")!

        guard let newUrl = url.displayURL else {
            XCTFail("expected valid url without reader mode components")
            return
        }

        XCTAssertEqual(newUrl.host, "mozilla.org")
    }

    func testDisplayTitle_ForHomepageURL() {
        let url = URL(string: "internal://local/about/home")!
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.url = url
        let expectedDisplayTitle = String.LegacyAppMenu.AppMenuOpenHomePageTitleString
        XCTAssertEqual(tab.displayTitle, expectedDisplayTitle)
    }

    func testTabDoesntLeak() {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.tabDelegate = tabDelegate
        trackForMemoryLeaks(tab)
    }

    func testTabIsActive_within14Days() {
        // Tabs use the current date by default, so this one should be considered recent and active on initialization
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)

        XCTAssertTrue(tab.isActive)
        XCTAssertFalse(tab.isInactive)
    }

    func testTabIsInactive_outside14Days() {
        let lastMonthDate = Date().lastMonth
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID, tabCreatedTime: lastMonthDate)

        XCTAssertFalse(tab.isActive)
        XCTAssertTrue(tab.isInactive)
    }
}

// MARK: - MockLegacyTabDelegate
class MockLegacyTabDelegate: LegacyTabDelegate {
    func tab(_ tab: Tab, didAddSnackbar bar: SnackBar) {}

    func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar) {}

    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String) {}

    func tab(_ tab: Tab, didSelectSearchWithFirefoxForSelection selection: String) {}

    func tab(_ tab: Tab, didCreateWebView webView: WKWebView) {}

    func tab(_ tab: Tab, willDeleteWebView webView: WKWebView) {}
}
