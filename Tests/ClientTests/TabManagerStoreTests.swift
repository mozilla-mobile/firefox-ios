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
    private var fileManager: MockFileManager!
    private var serialQueue: MockDispatchQueue!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        fileManager = MockFileManager()
        serialQueue = MockDispatchQueue()
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        fileManager = nil
        serialQueue = nil
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

    func testPreserveTabs_noSelectedTab() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3)
        manager.preserveTabs(tabs, selectedTab: nil)

        XCTAssertEqual(manager.testTabCountOnDisk(), 3, "Expected 3 tabs on disk")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testPreserveTabs_withSelectedTab() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3)
        manager.preserveTabs(tabs, selectedTab: tabs[0])

        XCTAssertEqual(manager.testTabCountOnDisk(), 3, "Expected 3 tabs on disk")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testPreserveTabs_clearAddAgain() {
        let manager = createManager()
        let threeTabs = createTabs(tabNumber: 3)
        manager.preserveTabs(threeTabs, selectedTab: threeTabs[0])

        manager.clearArchive()

        let twoTabs = createTabs(tabNumber: 2)
        manager.preserveTabs(twoTabs, selectedTab: nil)

        XCTAssertEqual(manager.testTabCountOnDisk(), 2, "Expected 2 tabs on disk")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
        XCTAssertEqual(fileManager.remoteItemCalledCount, 2)
        XCTAssertEqual(fileManager.fileExistsCalledCount, 2)
    }
}

// MARK: - Helper methods
private extension TabManagerStoreTests {

    func createManager(file: StaticString = #file,
                       line: UInt = #line) -> TabManagerStoreImplementation {
        let manager = TabManagerStoreImplementation(prefs: profile.prefs,
                                                    imageStore: nil,
                                                    fileManager: fileManager,
                                                    serialQueue: serialQueue)
        manager.clearArchive()
        trackForMemoryLeaks(manager, file: file, line: line)
        return manager
    }

    func createConfiguration(file: StaticString = #file,
                             line: UInt = #line) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()

        trackForMemoryLeaks(configuration, file: file, line: line)
        return configuration
    }

    func createTabs(tabNumber: Int,
                    isPrivate: Bool = false,
                    file: StaticString = #file,
                    line: UInt = #line) -> [Tab] {
        let configuration = createConfiguration(file: file, line: line)

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

class MockFileManager: TabFileManager {

    var remoteItemCalledCount = 0
    func removeItem(atPath path: String) throws {
        remoteItemCalledCount += 1
        try FileManager.default.removeItem(atPath: path)
    }

    var fileExistsCalledCount = 0
    func fileExists(atPath path: String) -> Bool {
        fileExistsCalledCount += 1
        return FileManager.default.fileExists(atPath: tabPath!)
    }

    var tabPath: String? {
        return FileManager.default.temporaryDirectory.path
    }
}
