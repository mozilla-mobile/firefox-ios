// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import WebKit
import Shared
import Common
@testable import Client

class TabManagerTests: XCTestCase {
    var tabWindowUUID: WindowUUID!
    var mockTabStore: MockTabDataStore!
    var mockSessionStore: MockTabSessionStore!
    var mockProfile: MockProfile!
    var mockDiskImageStore: MockDiskImageStore!
    let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        // For this test suite, use a consistent window UUID for all test cases
        let uuid: WindowUUID = .XCTestDefaultUUID
        tabWindowUUID = uuid

        mockProfile = MockProfile()
        mockDiskImageStore = MockDiskImageStore()
        mockTabStore = MockTabDataStore()
        mockSessionStore = MockTabSessionStore()
    }

    override func tearDown() {
        super.tearDown()
        mockProfile = nil
        mockDiskImageStore = nil
        mockTabStore = nil
        mockSessionStore = nil
    }

    // MARK: - Restore tabs

    func testRestoreTabs() async throws {
        throw XCTSkip("Needs to fix restore test")
        //        let subject = createSubject()
        //        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
        //                                                     isPrimary: true,
        //                                                     activeTabId: UUID(),
        //                                                     tabData: getMockTabData(count: 4))
        //
        //        subject.restoreTabs()
        //        try await Task.sleep(nanoseconds: sleepTime * 5)
        //        XCTAssertEqual(subject.tabs.count, 4)
        //        XCTAssertEqual(mockTabStore.fetchWindowDataCalledCount, 1)
    }

    func testRestoreTabsForced() async throws {
        throw XCTSkip("Needs to fix restore test")
        //        let subject = createSubject()
        //        addTabs(to: subject, count: 5)
        //        XCTAssertEqual(subject.tabs.count, 5)
        //
        //        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
        //                                                     isPrimary: true,
        //                                                     activeTabId: UUID(),
        //                                                     tabData: getMockTabData(count: 3))
        //        subject.restoreTabs(true)
        //        try await Task.sleep(nanoseconds: sleepTime * 3)
        //        XCTAssertEqual(subject.tabs.count, 3)
        //        XCTAssertEqual(mockTabStore.fetchWindowDataCalledCount, 1)
    }

    func testRestoreScreenshotsForTabs() async throws {
        throw XCTSkip("Needs to fix restore test")
        //        let subject = createSubject()
        //        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
        //                                                     isPrimary: true,
        //                                                     activeTabId: UUID(),
        //                                                     tabData: getMockTabData(count: 2))
        //
        //        subject.restoreTabs()
        //        try await Task.sleep(nanoseconds: sleepTime * 10)
        //        XCTAssertEqual(mockDiskImageStore.getImageForKeyCallCount, 2)
    }

    // MARK: - Save tabs

    func testPreserveTabsWithNoTabs() async throws {
        let subject = createSubject()
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 0)
        XCTAssertEqual(subject.tabs.count, 0)
    }

    func testPreserveTabsWithOneTab() async throws {
        let subject = createSubject()
        subject.tabRestoreHasFinished = true
        addTabs(to: subject, count: 1)
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(subject.tabs.count, 1)
    }

    func testPreserveTabsWithManyTabs() async throws {
        let subject = createSubject()
        subject.tabRestoreHasFinished = true
        addTabs(to: subject, count: 5)
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    // MARK: - Save preview screenshot

    func testSaveScreenshotWithNoImage() async throws {
        let subject = createSubject()
        addTabs(to: subject, count: 5)
        guard let tab = subject.tabs.first else {
            XCTFail("First tab was expected to be found")
            return
        }

        subject.tabDidSetScreenshot(tab, hasHomeScreenshot: false)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockDiskImageStore.saveImageForKeyCallCount, 0)
    }

    func testSaveScreenshotWithImage() async throws {
        let subject = createSubject()
        addTabs(to: subject, count: 5)
        guard let tab = subject.tabs.first else {
            XCTFail("First tab was expected to be found")
            return
        }
        tab.setScreenshot(UIImage())
        subject.tabDidSetScreenshot(tab, hasHomeScreenshot: false)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockDiskImageStore.saveImageForKeyCallCount, 1)
    }

    func testRemoveScreenshotWithImage() async throws {
        let subject = createSubject()
        addTabs(to: subject, count: 5)
        guard let tab = subject.tabs.first else {
            XCTFail("First tab was expected to be found")
            return
        }

        tab.setScreenshot(UIImage())
        subject.removeScreenshot(tab: tab)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockDiskImageStore.deleteImageForKeyCallCount, 1)
    }

    func testGetInactiveTabs() {
        let subject = createSubject()
        addTabs(to: subject, count: 3)
        XCTAssert(subject.tabs.count == 3, "Expected 3 newly added tabs.")

        // Set createdAt date for all tabs to be distant past (inactive by default)
        subject.tabs.forEach { $0.firstCreatedTime = Timestamp(0) }

        // Override lastExecutedTime of 1st tab to indicate tab active
        // and lastExecutedTime of other 2 to be distant past
        let tab1 = subject.tabs[0]
        let tab2 = subject.tabs[1]
        let tab3 = subject.tabs[2]
        let lastExecutedDate = Calendar.current.add(numberOfDays: 1, to: Date())
        tab1.lastExecutedTime = lastExecutedDate?.toTimestamp()
        tab2.lastExecutedTime = 0
        tab3.lastExecutedTime = 0

        let inactiveTabs = subject.getInactiveTabs()
        let expectedInactiveTabs = 2

        // Expect 2 of 3 tabs are inactive (except 1st)
        XCTAssertEqual(inactiveTabs.count, expectedInactiveTabs)
    }

    func test_addTabsForURLs() {
        let subject = createSubject()

        subject.addTabsForURLs([URL(string: "https://www.mozilla.org/privacy/firefox")!], zombie: false, shouldSelectTab: false)

        XCTAssertEqual(subject.tabs.count, 1)
        XCTAssertEqual(subject.tabs.first?.url?.absoluteString, "https://www.mozilla.org/privacy/firefox")
        XCTAssertEqual(subject.tabs.first?.isPrivate, false)
    }

    func test_addTabsForURLs_forPrivateMode() {
        let subject = createSubject()

        subject.addTabsForURLs([URL(string: "https://www.mozilla.org/privacy/firefox")!], zombie: false, shouldSelectTab: false, isPrivate: true)

        XCTAssertEqual(subject.tabs.count, 1)
        XCTAssertEqual(subject.tabs.first?.url?.absoluteString, "https://www.mozilla.org/privacy/firefox")
        XCTAssertEqual(subject.tabs.first?.isPrivate, true)
    }

    // MARK: - Helper methods

    private func createSubject() -> TabManagerImplementation {
        let subject = TabManagerImplementation(profile: mockProfile,
                                               imageStore: mockDiskImageStore,
                                               uuid: ReservedWindowUUID(uuid: tabWindowUUID, isNew: false),
                                               tabDataStore: mockTabStore,
                                               tabSessionStore: mockSessionStore)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func addTabs(to subject: TabManagerImplementation, count: Int) {
        for _ in 0..<count {
            let tab = Tab(profile: mockProfile, windowUUID: windowUUID)
            tab.url = URL(string: "https://mozilla.com")!
            subject.tabs.append(tab)
        }
    }

    private func getMockTabData(count: Int) -> [TabData] {
        var tabData = [TabData]()
        for _ in 0..<count {
            let tab = TabData(id: UUID(),
                              title: "Firefox",
                              siteUrl: "www.firefox.com",
                              faviconURL: "",
                              isPrivate: false,
                              lastUsedTime: Date(),
                              createdAtTime: Date(),
                              tabGroupData: TabGroupData())
            tabData.append(tab)
        }
        return tabData
    }
}
