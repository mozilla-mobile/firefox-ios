// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class TabModelTests: XCTestCase {
    func testEqualModels_areEqualWithSameHash() {
        let tab = createTab(tabUUID: "tab-1")
        let sameTab = createTab(tabUUID: "tab-1")

        XCTAssertEqual(tab, sameTab)
        XCTAssertEqual(tab.hashValue, sameTab.hashValue)
    }

    func testSameUUIDWithDifferentContent_areNotEqualButShareHash() {
        let tab = createTab(tabUUID: "tab-1")
        let updatedTab = createTab(tabUUID: "tab-1",
                                   tabTitle: "Updated title",
                                   url: URL(string: "https://www.example.com"),
                                   screenshot: UIImage())

        // The hash is intentionally based only on the tab's identity (its UUID) so the
        // diffable data source doesn't pay for string hashing of titles/URLs, while
        // equality still reflects content changes for Redux state propagation.
        XCTAssertNotEqual(tab, updatedTab)
        XCTAssertEqual(tab.hashValue, updatedTab.hashValue)
    }

    func testDifferentContent_selectionChange_areNotEqual() {
        let tab = createTab(tabUUID: "tab-1")
        let selectedTab = createTab(tabUUID: "tab-1", isSelected: true)

        XCTAssertNotEqual(tab, selectedTab)
        XCTAssertEqual(tab.hashValue, selectedTab.hashValue)
    }

    // MARK: - Private

    private func createTab(tabUUID: TabUUID,
                           isSelected: Bool = false,
                           tabTitle: String = "Homepage",
                           url: URL? = URL(string: "https://www.mozilla.org"),
                           screenshot: UIImage? = nil) -> TabModel {
        return TabModel(tabUUID: tabUUID,
                        isSelected: isSelected,
                        isPrivate: false,
                        isFxHomeTab: false,
                        tabTitle: tabTitle,
                        url: url,
                        screenshot: screenshot,
                        hasHomeScreenshot: false,
                        hasScreenshotOnDisk: false)
    }
}
