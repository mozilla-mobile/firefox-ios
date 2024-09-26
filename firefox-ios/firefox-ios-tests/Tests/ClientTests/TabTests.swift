// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
@testable import Client

class TabTests: XCTestCase {
    private var tabDelegate: MockLegacyTabDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        tabDelegate = MockLegacyTabDelegate()
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

    // MARK: - isActive, isInactive

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

    // MARK: - isSameTypeAs

    func testIsSameTypeAs_trueForTwoPrivateTabs_oneActive_oneInactive() {
        let lastMonthDate = Date().lastMonth

        let privateActiveTab = Tab(
            profile: MockProfile(),
            isPrivate: true,
            windowUUID: windowUUID
        )
        let privateInactiveTab = Tab(
            profile: MockProfile(),
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // We do not want to differentiate between inactive and active for private tabs. They are all grouped together.
        XCTAssertTrue(privateActiveTab.isSameTypeAs(privateInactiveTab))
        XCTAssertTrue(privateInactiveTab.isSameTypeAs(privateActiveTab))
    }

    func testIsSameTypeAs_trueForTwoPrivateTabs_bothActive() {
        let privateActiveTab1 = Tab(
            profile: MockProfile(),
            isPrivate: true,
            windowUUID: windowUUID
        )
        let privateActiveTab2 = Tab(
            profile: MockProfile(),
            isPrivate: true,
            windowUUID: windowUUID
        )

        XCTAssertTrue(privateActiveTab1.isSameTypeAs(privateActiveTab2))
        XCTAssertTrue(privateActiveTab2.isSameTypeAs(privateActiveTab1))
    }

    func testIsSameTypeAs_trueForTwoPrivateTabs_bothInactive() {
        let lastMonthDate = Date().lastMonth

        let privateInctiveTab1 = Tab(
            profile: MockProfile(),
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )
        let privateInactiveTab2 = Tab(
            profile: MockProfile(),
            isPrivate: true,
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        XCTAssertTrue(privateInctiveTab1.isSameTypeAs(privateInactiveTab2))
        XCTAssertTrue(privateInactiveTab2.isSameTypeAs(privateInctiveTab1))
    }

    func testIsSameTypeAs_falseForNormalTabAndPrivateTab() {
        let lastMonthDate = Date().lastMonth

        let privateTab = Tab(
            profile: MockProfile(),
            isPrivate: true,
            windowUUID: windowUUID
        )
        let normalActiveTab = Tab(
            profile: MockProfile(),
            windowUUID: windowUUID
        )
        let normalInactiveTab = Tab(
            profile: MockProfile(),
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // A normal tab and a private tab should never be the same, regardless of the normal tab's inactive/active state.
        XCTAssertFalse(privateTab.isSameTypeAs(normalActiveTab))
        XCTAssertFalse(privateTab.isSameTypeAs(normalInactiveTab))
        XCTAssertFalse(normalActiveTab.isSameTypeAs(privateTab))
        XCTAssertFalse(normalInactiveTab.isSameTypeAs(privateTab))
    }

    func testIsSameTypeAs_falseForNormalActiveTab_andNormalInactiveTab() {
        let lastMonthDate = Date().lastMonth

        let normalActiveTab = Tab(
            profile: MockProfile(),
            windowUUID: windowUUID
        )
        let normalInactiveTab = Tab(
            profile: MockProfile(),
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        // In the app, a normal active tab is a different type of tab than a normal inactive tab.
        XCTAssertFalse(normalActiveTab.isSameTypeAs(normalInactiveTab))
        XCTAssertFalse(normalInactiveTab.isSameTypeAs(normalActiveTab))
    }

    func testIsSameTypeAs_trueForTwoNormalTabs_bothActive() {
        let normalActiveTab1 = Tab(
            profile: MockProfile(),
            windowUUID: windowUUID
        )
        let normalActiveTab2 = Tab(
            profile: MockProfile(),
            windowUUID: windowUUID
        )

        XCTAssertTrue(normalActiveTab1.isSameTypeAs(normalActiveTab2))
        XCTAssertTrue(normalActiveTab2.isSameTypeAs(normalActiveTab1))
    }

    func testIsSameTypeAs_trueForTwoNormalTabs_bothInactive() {
        let lastMonthDate = Date().lastMonth

        let normalInctiveTab1 = Tab(
            profile: MockProfile(),
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )
        let normalInctiveTab2 = Tab(
            profile: MockProfile(),
            windowUUID: windowUUID,
            tabCreatedTime: lastMonthDate
        )

        XCTAssertTrue(normalInctiveTab1.isSameTypeAs(normalInctiveTab2))
        XCTAssertTrue(normalInctiveTab2.isSameTypeAs(normalInctiveTab1))
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
