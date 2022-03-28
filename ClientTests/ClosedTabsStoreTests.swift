// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Storage

@testable import Client

class ClosedTabsStoreTests: XCTestCase {

    func testStoreHasNoTabsAtInit() {
        let store = createStore()
        XCTAssertEqual(store.tabs.count, 0)
    }

    func testStoreCanStoreATab() {
        let store = createStore()
        addTabs(number: 1, to: store)

        XCTAssertEqual(store.tabs.count, 1)
    }

    func testStoreCanStoreMoreThanOneTab() {
        let store = createStore()
        addTabs(number: 2, to: store)

        XCTAssertEqual(store.tabs.count, 2)
    }

    func testStoreCantHaveMoreThan10Tabs() {
        let store = createStore()
        addTabs(number: 20, to: store)

        XCTAssertEqual(store.tabs.count, 10)
    }

    func testStorePopFirstTabEmptyTabs() {
        let store = createStore()
        let firstTab = store.popFirstTab()
        XCTAssertNil(firstTab)
    }

    func testStorePopFirstTab_returnAndRemovesIt() {
        let store = createStore()
        let urlString = "thisisanotheraurl.com"
        let tabTitle = "a different title"
        store.addTab(URL(string: urlString)!, title: tabTitle, faviconURL: nil)
        XCTAssertEqual(store.tabs.count, 1)

        let firstTab = store.popFirstTab()
        XCTAssertNotNil(firstTab)
        XCTAssertEqual(firstTab?.url.absoluteString, urlString)
        XCTAssertEqual(firstTab?.title, tabTitle)
        XCTAssertEqual(store.tabs.count, 0)
    }

    func testStorePopFirstTabOfMultiples_returnAndRemovesIt() {
        let store = createStore()
        addTabs(number: 5, to: store)
        XCTAssertEqual(store.tabs.count, 5)

        let firstTab = store.popFirstTab()
        XCTAssertNotNil(firstTab)
        XCTAssertEqual(firstTab?.url.absoluteString, "thisisaurl4.com")
        XCTAssertEqual(firstTab?.title, "a title4")
        XCTAssertEqual(store.tabs.count, 4)
    }

    func testStoreCanClearTabs() {
        let store = createStore()
        store.addTab(URL(string: "thisisaurl.com")!, title: "a title", faviconURL: nil)
        store.addTab(URL(string: "thisisaurl2.com")!, title: "a title2", faviconURL: nil)
        store.clearTabs()

        XCTAssertEqual(store.tabs.count, 0)
    }
}

// MARK: - Helpers
private extension ClosedTabsStoreTests {

    func createStore() -> ClosedTabsStore {
        let mockProfilePrefs = MockProfilePrefs()
        return ClosedTabsStore(prefs: mockProfilePrefs)
    }

    func addTabs(number: Int, to store: ClosedTabsStore) {
        for index in 0...number - 1 {
            store.addTab(URL(string: "thisisaurl\(index).com")!, title: "a title\(index)", faviconURL: nil)
        }
    }
}
