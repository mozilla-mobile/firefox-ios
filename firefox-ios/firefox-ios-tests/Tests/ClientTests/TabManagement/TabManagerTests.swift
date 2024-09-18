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

    func testGetActiveAndInactiveTabs() {
        let totalTabCount = 3
        let subject = createSubject()
        addTabs(to: subject, count: totalTabCount)

        // Preconditions
        XCTAssertEqual(subject.tabs.count, totalTabCount, "Expected 3 newly added tabs.")
        XCTAssertEqual(subject.normalActiveTabs.count, totalTabCount, "All tabs should be active on initialization")

        // Override lastExecutedTime of 1st tab to be recent (i.e. active)
        // and lastExecutedTime of other 2 to be distant past (i.e. inactive)
        let lastExecutedDate = Calendar.current.add(numberOfDays: 1, to: Date())!
        subject.tabs[0].lastExecutedTime = lastExecutedDate.toTimestamp()
        subject.tabs[1].lastExecutedTime = 0
        subject.tabs[2].lastExecutedTime = 0

        // Test
        XCTAssertEqual(subject.normalActiveTabs.count, 1, "Only one tab remains active")
        XCTAssertEqual(subject.normalInactiveTabs.count, 2, "Two tabs should now be inactive")
        XCTAssertEqual(subject.normalTabs.count, totalTabCount, "The total tab count should not have changed")
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

    // MARK: - Test findRightOrLeftTab helper

    func testFindRightOrLeftTab_forEmptyArray() async throws {
        // Set up a tab array as follows:
        // [] Empty
        // Will pretend to delete a normal active tab at index 0.
        // Expect no tab to be returned.
        let tabManager = createSubject()

        let deletedIndex = 0 // Pretend the only tab in the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: []
        XCTAssertNil(rightOrLeftTab, "Cannot return a tab when the array is empty")
    }

    func testFindRightOrLeftTab_forSingleTabInArray_ofSameType() async throws {
        // Set up a tab array as follows:
        // [A1]
        // Will pretend to delete a normal active tab at index 0.
        // Expect A1 tab to be returned.
        let tabManager = createSubject()
        let numberActiveTabs = 1
        addTabs(to: tabManager, ofType: .normalActive, count: numberActiveTabs)

        let deletedIndex = 0
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(rightOrLeftTab, tabManager.tabs[safe: 0], "Should return neighbour of same type, as one exists")
    }

    func testFindRightOrLeftTab_forSingleTabInArray_ofDifferentType() async throws {
        // Set up a tab array as follows:
        // [A1]
        // Will pretend to delete a private tab at index 0.
        // Expect no tab to be returned (no other private tabs).
        let tabManager = createSubject()
        let numberActiveTabs = 1
        addTabs(to: tabManager, ofType: .normalActive, count: numberActiveTabs)

        let deletedIndex = 0
        let removedTab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID) // Private tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNil(rightOrLeftTab, "Cannot return neighbour tab of same type, as no other private tabs exist")
    }

    func testFindRightOrLeftTab_forDeletedIndexInMiddle_uniformTabTypes() async throws {
        // Set up a tab array as follows:
        // [A1, A2, A3, A4, A5, A6, A7]
        //   0   1   2   3   4   5   6
        // Will pretend to delete a normal active tab at index 3.
        // Expect A4 tab to be returned.
        let tabManager = createSubject()
        let numberActiveTabs = 7
        addTabs(to: tabManager, ofType: .normalActive, count: numberActiveTabs)

        let deletedIndex = 3
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(rightOrLeftTab, tabManager.tabs[safe: 3], "Should pick tab A4 at the same position as deletedIndex")
    }

    func testFindRightOrLeftTab_forDeletedIndexInMiddle_mixedTabTypes() async throws {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal active tab at index 5.
        // Expect to return A3 (nearest active tab on right).
        let tabManager = createSubject()
        setupForFindRightOrLeftTab_mixedTypes(tabManager)

        let deletedIndex = 5 // Pretend a normal active tab between A2 and I2 was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [A1, A2, A3, A4]
        // For "deleted" index 5 in the main array, that should be mapped down to index 2 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right first, in this case, A3 (third active tab)
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalActiveTabs[safe: 2],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    func testFindRightOrLeftTab_forDeletedIndexAtStart() async throws {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal active tab at index 0.
        // Expect to return A1 (nearest active tab on right).
        let tabManager = createSubject()
        setupForFindRightOrLeftTab_mixedTypes(tabManager)

        let deletedIndex = 0 // Pretend a normal active tab at the start of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [A1, A2, A3, A4]
        // For "deleted" index 0 in the main array, that should be mapped down to index 0 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right first, in this case, A1 (first active tab)
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalActiveTabs[safe: 0],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    func testFindRightOrLeftTab_forDeletedIndexAtEnd() async throws {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal active tab at index 9.
        // Expect to return A4 (nearest active tab on left, since there is no right tab available).
        let tabManager = createSubject()
        setupForFindRightOrLeftTab_mixedTypes(tabManager)

        let deletedIndex = 9 // Pretend a normal active tab at the end of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [A1, A2, A3, A4]
        // For "deleted" index 9 in the main array, that should be mapped down to index 4 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the left (since no right tab exists), in this case, A4
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalActiveTabs[safe: 3],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    func testFindRightOrLeftTab_prefersRightTabOverLeftTab() async throws {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete an inactive active tab at index 4.
        // Expect to return I2 (nearest inactive tab on the right, as right is given preference to left).
        let tabManager = createSubject()
        setupForFindRightOrLeftTab_mixedTypes(tabManager)

        let deletedIndex = 4 // Pretend a normal active tab at the end of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        removedTab.lastExecutedTime = Date().lastMonth.toTimestamp() // Inactive normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [I1, I2]
        // For "deleted" index 4 in the main array, that should be mapped down to index 1 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right, in this case, I2
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalInactiveTabs[safe: 1],
            "Should choose the second inactive tab as the nearest neighbour on the right"
        )
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

    enum TabType {
        case normalActive
        case normalInactive
        case privateAny // `private` alone is a reserved compiler keyword
    }

    private func addTabs(to subject: LegacyTabManager, ofType type: TabType = .normalActive, count: Int) {
        for i in 0..<count {
            let tab: Tab

            switch type {
            case .normalActive:
                tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
            case .normalInactive:
                let lastMonthDate = Date().lastMonth
                tab = Tab(profile: MockProfile(), windowUUID: tabWindowUUID, tabCreatedTime: lastMonthDate)
            case .privateAny:
                tab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID)
            }

            tab.url = URL(string: "https://mozilla.com?item=\(i)")!
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

    private func setupForFindRightOrLeftTab_mixedTypes(_ tabManager: TabManagerImplementation) {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        addTabs(to: tabManager, ofType: .normalActive, count: 1)
        addTabs(to: tabManager, ofType: .privateAny, count: 2)
        addTabs(to: tabManager, ofType: .normalInactive, count: 1)
        addTabs(to: tabManager, ofType: .normalActive, count: 1)
        addTabs(to: tabManager, ofType: .normalInactive, count: 1)
        addTabs(to: tabManager, ofType: .normalActive, count: 2)
        addTabs(to: tabManager, ofType: .privateAny, count: 1)

        // Check preconditions
        XCTAssertEqual(tabManager.tabs.count, 9)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 4)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 2)
        XCTAssertEqual(tabManager.privateTabs.count, 3)
    }
}
