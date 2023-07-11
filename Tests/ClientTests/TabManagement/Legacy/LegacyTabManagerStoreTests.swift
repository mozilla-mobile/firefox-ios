// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Shared
import Storage
import UIKit
import WebKit

import XCTest

class LegacyTabManagerStoreTests: XCTestCase {
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

        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 0, "Expected 0 tabs on disk")
        XCTAssertFalse(manager.hasTabsToRestoreAtStartup)
    }

    // MARK: Preserve

    func testPreserve_withNoTabs() throws {
        throw XCTSkip("Skipping since test is flaky on Bitrise")
//        let manager = createManager()
//        manager.preserveTabs([], selectedTab: nil)
//
//        let retrievedTabs = manager.testTabOnDisk()
//        XCTAssertEqual(retrievedTabs.count, 0, "Expected 0 tabs on disk")
//        XCTAssertFalse(manager.hasTabsToRestoreAtStartup)
    }

    func testPreserveTabs_noSelectedTab() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3)
        manager.preserveTabs(tabs, selectedTab: nil)

        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 3, "Expected 3 tabs on disk")
        XCTAssertEqual(retrievedTabs[0].title, "Title 0 isPrivate: false")
        XCTAssertEqual(retrievedTabs[1].title, "Title 1 isPrivate: false")
        XCTAssertEqual(retrievedTabs[2].title, "Title 2 isPrivate: false")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testPreserveTabs_withSelectedNormalTab() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3)
        manager.preserveTabs(tabs, selectedTab: tabs[0])

        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 3, "Expected 3 tabs on disk")
        XCTAssertEqual(retrievedTabs[0].title, "Title 0 isPrivate: false")
        XCTAssertEqual(retrievedTabs[1].title, "Title 1 isPrivate: false")
        XCTAssertEqual(retrievedTabs[2].title, "Title 2 isPrivate: false")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testPreserveTabs_withSelectedPrivateTab() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3, isPrivate: true)
        manager.preserveTabs(tabs, selectedTab: tabs[0])

        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 3, "Expected 3 tabs on disk")
        XCTAssertEqual(retrievedTabs[0].title, "Title 0 isPrivate: true")
        XCTAssertEqual(retrievedTabs[1].title, "Title 1 isPrivate: true")
        XCTAssertEqual(retrievedTabs[2].title, "Title 2 isPrivate: true")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testPreserveTabs_clearAddAgain() {
        let manager = createManager()
        let threeTabs = createTabs(tabNumber: 3)
        manager.preserveTabs(threeTabs, selectedTab: threeTabs[0])

        manager.clearArchive()

        let twoTabs = createTabs(tabNumber: 2)
        manager.preserveTabs(twoTabs, selectedTab: nil)

        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 2, "Expected 2 tabs on disk")
        XCTAssertEqual(retrievedTabs[0].title, "Title 0 isPrivate: false")
        XCTAssertEqual(retrievedTabs[1].title, "Title 1 isPrivate: false")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
        XCTAssertEqual(fileManager.remoteItemCalledCount, 2)
        XCTAssertEqual(fileManager.fileExistsCalledCount, 2)
    }

    // MARK: Restore

    func testRestoreEmptyTabs() {
        let manager = createManager()
        let tabToSelect = manager.restoreStartupTabs(clearPrivateTabs: false,
                                                     addTabClosure: { isPrivate in
            XCTFail("Should not be called since there's no tabs to restore")
            return createTab(isPrivate: isPrivate)
        })

        XCTAssertNil(tabToSelect, "There's no tabs to restore, so nothing is selected")
        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 0, "Expected 0 tabs on disk")
        XCTAssertFalse(manager.hasTabsToRestoreAtStartup)
    }

    func testRestoreNormalTabs_noSelectedTab() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3)
        manager.preserveTabs(tabs, selectedTab: nil)

        let tabToSelect = manager.restoreStartupTabs(clearPrivateTabs: false,
                                                     addTabClosure: { isPrivate in
            XCTAssertFalse(isPrivate)
            return createTab(isPrivate: isPrivate)
        })

        XCTAssertNil(tabToSelect, "No tab was selected in restore, tab manager is expected to select one")
        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 3, "Expected 3 tabs on disk")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testRestoreNormalTabs_selectedTabIsReselected() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3)
        manager.preserveTabs(tabs, selectedTab: tabs[0])

        let tabToSelect = manager.restoreStartupTabs(clearPrivateTabs: false,
                                                     addTabClosure: { isPrivate in
            XCTAssertFalse(isPrivate)
            return createTab(isPrivate: isPrivate)
        })

        XCTAssertNotNil(tabToSelect, "Tab was selected in restore")
        XCTAssertEqual(tabToSelect?.lastTitle, tabs[0].lastTitle, "Selected tab is same that was previously selected")
        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 3, "Expected 3 tabs on disk")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testRestorePrivateTabs_noSelectedTab() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3, isPrivate: true)
        manager.preserveTabs(tabs, selectedTab: nil)

        let tabToSelect = manager.restoreStartupTabs(clearPrivateTabs: false,
                                                     addTabClosure: { isPrivate in
            XCTAssertTrue(isPrivate)
            return createTab(isPrivate: isPrivate)
        })

        XCTAssertNil(tabToSelect, "No tab was selected in restore, tab manager is expected to select one")
        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 3, "Expected 3 tabs on disk")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testRestorePrivateTabs_selectedTabIsReselected() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3, isPrivate: true)
        manager.preserveTabs(tabs, selectedTab: tabs[0])

        let tabToSelect = manager.restoreStartupTabs(clearPrivateTabs: false,
                                                     addTabClosure: { isPrivate in
            XCTAssertTrue(isPrivate)
            return createTab(isPrivate: isPrivate)
        })

        XCTAssertNotNil(tabToSelect, "Tab was selected in restore")
        XCTAssertEqual(tabToSelect?.lastTitle, tabs[0].lastTitle, "Selected tab is same that was previously selected")
        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 3, "Expected 3 tabs on disk")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    func testRestorePrivateTabs_clearPrivateTabs() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 3, isPrivate: true)
        manager.preserveTabs(tabs, selectedTab: tabs[0])

        let tabToSelect = manager.restoreStartupTabs(clearPrivateTabs: true,
                                                     addTabClosure: { isPrivate in
            XCTFail("Shouldn't be called as there's no more tabs after clear private tabs is done")
            return createTab(isPrivate: isPrivate)
        })

        XCTAssertNil(tabToSelect, "No tab is selected since all tabs were removed (since they were private)")
    }

    func testRestoreNormalAndPrivateTabs_clearPrivateTabs() {
        let manager = createManager()
        let normalTabs = createTabs(tabNumber: 2)
        let privateTabs = createTabs(tabNumber: 3, isPrivate: true)
        let allTabs = normalTabs + privateTabs
        manager.preserveTabs(allTabs, selectedTab: privateTabs[0])

        let tabToSelect = manager.restoreStartupTabs(clearPrivateTabs: true,
                                                     addTabClosure: { isPrivate in
            XCTAssertFalse(isPrivate)
            return createTab(isPrivate: isPrivate)
        })

        XCTAssertNil(tabToSelect, "No tab selected since the selected one was deleted, tab manager will deal with it")
    }

    // MARK: - Migration

    func testMigrationForward_savingOnlyWithDeprecatedMethod() {
        let manager = createManager()
        let tabs = createTabs(tabNumber: 2)
        // Save tabs only with deprecated method, as if we're in v105
        manager.preserveTabs(tabs, selectedTab: nil)

        // Retrieve tabs as if we're in v106
        let tabToSelect = manager.restoreStartupTabs(clearPrivateTabs: false,
                                                     addTabClosure: { isPrivate in
            XCTAssertFalse(isPrivate)
            return createTab(isPrivate: isPrivate)
        })

        XCTAssertNil(tabToSelect, "No tab was selected in restore, tab manager is expected to select one")
        let retrievedTabs = manager.testTabOnDisk()
        XCTAssertEqual(retrievedTabs.count, 2, "Expected 2 tabs on disk")
        XCTAssertTrue(manager.hasTabsToRestoreAtStartup)
    }

    // MARK: - Helper methods

    func createManager(file: StaticString = #file,
                       line: UInt = #line) -> LegacyTabManagerStoreImplementation {
        let manager = LegacyTabManagerStoreImplementation(prefs: profile.prefs,
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
        var tabs = [Tab]()
        (0..<tabNumber).forEach { index in
            let tab = createTab(title: "Title \(index) isPrivate: \(isPrivate)",
                                isPrivate: isPrivate,
                                file: file,
                                line: line)
            tabs.append(tab)
        }
        return tabs
    }

    // Without session data, a Tab can't become a LegacySavedTab and get archived
    func createTab(title: String? = nil,
                   isPrivate: Bool = false,
                   file: StaticString = #file,
                   line: UInt = #line) -> Tab {
        let configuration = createConfiguration(file: file, line: line)

        let tab = Tab(profile: profile, configuration: configuration, isPrivate: isPrivate)
        tab.url = URL(string: "http://yahoo.com/")!
        tab.lastTitle = title
        tab.sessionData = LegacySessionData(currentPage: 0, urls: [tab.url!], lastUsedTime: Date.now())
        return tab
    }
}

class MockFileManager: LegacyTabFileManager {
    var remoteItemCalledCount = 0
    func removeItem(at URL: URL) throws {
        remoteItemCalledCount += 1
        try FileManager.default.removeItem(at: URL)
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
