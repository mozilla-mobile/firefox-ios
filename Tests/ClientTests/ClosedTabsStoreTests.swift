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

    // MARK: Pop first

    func testStorePopFirstTabEmptyTabs() {
        let store = createStore()
        let firstTab = store.popFirstTab()
        XCTAssertNil(firstTab)
    }

    func testStorePopFirstTab_returnAndRemovesIt() {
        let store = createStore()
        let urlString = "thisisanotheraurl.com"
        let tabTitle = "a different title"
        store.addTab(URL(string: urlString)!, title: tabTitle, lastExecutedTime: nil)
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

    // MARK: Clear

    func testStoreCanClearTabs() {
        let store = createStore()
        store.addTab(URL(string: "thisisaurl.com")!, title: "a title", lastExecutedTime: nil)
        store.addTab(URL(string: "thisisaurl2.com")!, title: "a title2", lastExecutedTime: nil)
        store.clearTabs()

        XCTAssertEqual(store.tabs.count, 0)
    }

    // MARK: Remove at date

    func testStoreRemoveTabs_yesterdayRemovesAllTabs() {
        let store = createStore()
        addTabs(number: 4, to: store, lastExecutedTime: Date.now())
        store.removeTabsFromDate(Date.yesterday)

        XCTAssertEqual(store.tabs.count, 0)
    }

    func testStoreRemoveTabs_futureDateRemovesNoTabs() {
        let store = createStore()
        addTabs(number: 4, to: store, lastExecutedTime: Date.now())
        store.removeTabsFromDate(Date.tomorrow)

        XCTAssertEqual(store.tabs.count, 4)
    }

    func testStoreRemoveTabs_nilDateRemovesNoTabs() {
        let store = createStore()
        addTabs(number: 4, to: store, lastExecutedTime: nil)
        store.removeTabsFromDate(Date())

        XCTAssertEqual(store.tabs.count, 4)
    }

    func testStoreRemoveTabs_mixTabsDateGetsRemovedProperly() {
        let store = createStore()
        addTabs(number: 2, to: store, lastExecutedTime: Date.now())
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        store.addTab(URL(string: "thisisaurl3.com")!, title: "a title3", lastExecutedTime: twoDaysAgo.toTimestamp())
        store.addTab(URL(string: "thisisaurl4.com")!, title: "a title4", lastExecutedTime: twoDaysAgo.toTimestamp())
        store.removeTabsFromDate(Date.yesterday)

        XCTAssertEqual(store.tabs.count, 2)
    }
}

// MARK: - Helpers
private extension ClosedTabsStoreTests {
    func createStore() -> ClosedTabsStore {
        let mockProfilePrefs = MockProfilePrefs()
        return ClosedTabsStore(prefs: mockProfilePrefs)
    }

    func addTabs(number: Int, to store: ClosedTabsStore, lastExecutedTime: Timestamp? = nil) {
        for index in 0...number - 1 {
            store.addTab(URL(string: "thisisaurl\(index).com")!, title: "a title\(index)", lastExecutedTime: lastExecutedTime)
        }
    }
}
