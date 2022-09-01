// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Shared
import Storage
import UIKit
import WebKit

import XCTest

class TabManagerStoreTests: XCTestCase {

    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testNoData() {
        let manager = createManager()
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")
        XCTAssertFalse(manager.hasTabsToRestoreAtStartup)
    }

    func testPreserve_withNoTabs() {
        let manager = createManager()
        manager.preserveTabs([], selectedTab: nil)
        XCTAssertEqual(manager.testTabCountOnDisk(), 0, "Expected 0 tabs on disk")
        XCTAssertFalse(manager.hasTabsToRestoreAtStartup)
    }

    func testAddTabWithoutStoring_hasNoData() throws {
        throw XCTSkip("Test is failing intermittently on Bitrise")
//        let manager = createManager()
//        let configuration = createConfiguration()
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
//        XCTAssertEqual(manager.tabs.count, 2)
//        XCTAssertEqual(manager.testTabCountOnDisk(), 0)
//        XCTAssertEqual(profile.numberOfTabsStored, 0)
    }

    func testPrivateTabsAreArchived() throws {
        throw XCTSkip("Test is failing intermittently on Bitrise")
//        let manager = createManager()
//        let configuration = createConfiguration()
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2, isPrivate: true)
//        XCTAssertEqual(manager.tabs.count, 2)
//
//        // Private tabs aren't stored in remote tabs
//        waitStoreChanges(manager: manager, managerTabCount: 2, profileTabCount: 0)
    }

    func testNormalTabsAreArchived_storeMultipleTimesProperly() throws {
        throw XCTSkip("Test is failing intermittently on Bitrise")
//        let manager = createManager()
//        let configuration = createConfiguration()
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
//        XCTAssertEqual(manager.tabs.count, 2)
//
//        waitStoreChanges(manager: manager, managerTabCount: 2, profileTabCount: 2)
//
//        // Add 2 more tabs
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
//        XCTAssertEqual(manager.tabs.count, 4)
//
//        waitStoreChanges(manager: manager, managerTabCount: 4, profileTabCount: 4)
    }

    func testRemoveAndAddTab_doesntStoreRemovedTabs() throws {
        throw XCTSkip("Test is failing intermittently on Bitrise")
//        let manager = createManager()
//        let configuration = createConfiguration()
//        addNumberOfTabs(manager: manager, configuration: configuration, tabNumber: 2)
//        XCTAssertEqual(manager.tabs.count, 2)
//
//        // Remove all tabs, and add just 1 tab
//        manager.removeAll()
//        addTabWithSessionData(manager: manager, configuration: configuration)
//
//        waitStoreChanges(manager: manager, managerTabCount: 1, profileTabCount: 1)
    }
}

// MARK: - Helper methods
private extension TabManagerStoreTests {

    func createManager(file: StaticString = #file, line: UInt = #line) -> TabManagerStoreImplementation {
        let manager = TabManagerStoreImplementation(prefs: profile.prefs, imageStore: nil)
        manager.clearArchive()
        trackForMemoryLeaks(manager, file: file, line: line)
        return manager
    }

    func createConfiguration(file: StaticString = #file, line: UInt = #line) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()

        trackForMemoryLeaks(configuration, file: file, line: line)
        return configuration
    }

    func createTabs(configuration: WKWebViewConfiguration,
                    tabNumber: Int,
                    isPrivate: Bool = false) -> [Tab] {
        var tabs = [Tab]()
        for _ in 0..<tabNumber {
            let tab = createTab(configuration: configuration, isPrivate: isPrivate)
            tabs.append(tab)
        }
        return tabs
    }

    // Without session data, a Tab can't become a SavedTab and get archived
    func createTab(configuration: WKWebViewConfiguration,
                   isPrivate: Bool = false) -> Tab {
        let tab = Tab(profile: profile, configuration: configuration, isPrivate: isPrivate)
        tab.url = URL(string: "http://yahoo.com")!
        tab.sessionData = SessionData(currentPage: 0, urls: [tab.url!], lastUsedTime: Date.now())
        return tab
    }
}
