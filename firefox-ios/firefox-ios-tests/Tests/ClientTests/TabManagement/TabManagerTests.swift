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

        // Disable debug flag for faster inactive tabs and perform tests based on the real 14 day time to inactive
        UserDefaults.standard.set(false, forKey: PrefsKeys.FasterInactiveTabsOverride)

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

    // MARK: - Remove Tab (removing selected normal active tab)

    func testRemoveTab_removeSelectedNormalActiveTab_selectsRecentParentNormalActiveTab() async throws {
        let tabManager = createSubject()

        let numberNormalActiveTabs = 3
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        guard let firstNormalActiveTab = tabManager.normalActiveTabs[safe: 0],
              let secondNormalActiveTab = tabManager.normalActiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondNormalActiveTab.parent = firstNormalActiveTab

        // Make all the tabs slightly stale
        tabManager.normalActiveTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the parent tab the most recent tab
        firstNormalActiveTab.lastExecutedTime = Date().toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondNormalActiveTab.tabUUID)

        // Remove the selected tab
        tabManager.removeTab(secondNormalActiveTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, we expect its recent parent to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstNormalActiveTab, "Should have selected the parent tab, it's most recent")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The first tab, the parent, should be selected")
    }

    func testRemoveTab_removeSelectedNormalActiveTab_selectsRightOrLeftNormalActiveTab_ifNoParent() async throws {
        let tabManager = createSubject()

        let numberNormalActiveTabs = 3
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        guard let secondNormalActiveTab = tabManager.normalActiveTabs[safe: 1],
              let thirdNormalActiveTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondNormalActiveTab.tabUUID)

        // Remove the selected tab
        tabManager.removeTab(secondNormalActiveTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalActiveTab, "Should select tab on the right since no parent")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    func testRemoveTab_removeSelectedNormalActiveTab_selectsRightOrLeftActiveTab_ifParentNotRecent() async throws {
        let tabManager = createSubject()

        let numberNormalActiveTabs = 3
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        guard let firstNormalActiveTab = tabManager.normalActiveTabs[safe: 0],
              let secondNormalActiveTab = tabManager.normalActiveTabs[safe: 1],
              let thirdNormalActiveTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondNormalActiveTab.parent = firstNormalActiveTab

        // Make the parent tab staler than the others (not recent)
        firstNormalActiveTab.lastExecutedTime = Date().dayBefore.toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondNormalActiveTab.tabUUID)

        // Remove the selected tab
        tabManager.removeTab(secondNormalActiveTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalActiveTab, "Should select tab on the right since parent is stale")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    // MARK: - Remove Tab (removing selected private tab)

    func testRemoveTab_removeSelectedPrivateTab_selectsRecentParentPrivateTab() async throws {
        let tabManager = createSubject()

        let numberPrivateTabs = 3
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second private tab
        secondPrivateTab.parent = firstPrivateTab

        // Make all the tabs slightly stale
        tabManager.normalActiveTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the parent tab the most recent tab
        firstPrivateTab.lastExecutedTime = Date().toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondPrivateTab.tabUUID)

        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, we expect its recent parent to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "Should have selected the parent tab, as it is most recent")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The first tab, the parent, should be selected")
    }

    func testRemoveTab_removeSelectedPrivateTab_selectsRightOrLeftPrivateTab_ifNoRecentParent() async throws {
        let tabManager = createSubject()

        let numberPrivateTabs = 3
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1],
              let thirdPrivateTab = tabManager.privateTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second private tab
        secondPrivateTab.parent = firstPrivateTab

        // But make the parent tab a bit stale, so it's not the most recent tab (so it should not be selected)
        firstPrivateTab.lastExecutedTime = Date().dayBefore.toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondPrivateTab.tabUUID)

        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed with no parent, we expect the right tab to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, thirdPrivateTab, "Should have selected the tab on the right")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now at index 1, should be selected")
    }

    func testRemoveTab_removeSelectedPrivateTab_selectsRightOrLeftPrivateTab_ifParentNotRecent() async throws {
        let tabManager = createSubject()

        let numberPrivateTabs = 3
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1],
              let thirdPrivateTab = tabManager.privateTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondPrivateTab.parent = firstPrivateTab

        // Make the parent tab staler than the others (not recent)
        firstPrivateTab.lastExecutedTime = Date().dayBefore.toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondPrivateTab.tabUUID)

        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, thirdPrivateTab, "Should select tab on the right since parent is stale")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    // MARK: - Remove Tab (removing selected inactive tab, weird edge case)

    func testRemoveTab_removeSelectedNormalInactiveTab_createsNewNormalActiveTab() async throws {
        // This is a weird edge case that shouldn't happen in practice, but let's make sure we can handle it.
        // If the selected tab is removed, and it also happens to be inactive, treat it like a normal active tab.
        let tabManager = createSubject()

        let numberInactiveTabs = 3
        let numberActiveTabs = 3
        addTabs(to: tabManager, ofType: .normalInactive, count: numberInactiveTabs)
        addTabs(to: tabManager, ofType: .normalActive, count: numberActiveTabs)
        guard let secondInactiveTab = tabManager.normalInactiveTabs[safe: 1],
              let secondNormalTab = tabManager.normalActiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        let initialTabs = tabManager.tabs

        // Make all the active tabs slightly stale (but not inactive)
        tabManager.normalActiveTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the second normal active tab the most recent
        secondNormalTab.lastExecutedTime = Date().toTimestamp()

        // Set the first inactive tab as selected
        await MainActor.run {
            tabManager.selectTab(secondInactiveTab)
            // Selecting a tab makes it active, so reset to inactive again with an old timestamp
            secondInactiveTab.lastExecutedTime = Date().lastMonth.toTimestamp()
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs + numberActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondInactiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondInactiveTab.tabUUID)

        // Remove the selected inactive tab
        tabManager.removeTab(secondInactiveTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When a selected inactive tab is removed, this is a strange state. Handle like regular active tabs being cleared.
        // In this case, we'd expect the most recent active tab to be chosen since `firstInactiveTab` has no parent and no
        // left/right tab that's viable in the array (surrounded by two inactive tabs).
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs + numberActiveTabs, "Size won't change as new tab replaces")
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberInactiveTabs - 1)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberActiveTabs + 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        for tab in initialTabs {
            XCTAssertNotEqual(tabManager.selectedTab, tab, "None of the initial tabs should be selected")
        }
        XCTAssertEqual(tabManager.selectedIndex, 5, "The newly appended active tab should be selected")
    }

    // MARK: - Remove Tab (removing last private tab)

    func testRemoveTab_removeLastPrivateTab_hasNormalTabs_selectsRecentNormalTab() async throws {
        let tabManager = createSubject()

        let numberPrivateTabs = 1
        let numberNormalActiveTabs = 3
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        guard let privateTab = tabManager.privateTabs[safe: 0],
              let secondNormalTab = tabManager.normalActiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make all the active tabs slightly stale (but not inactive)
        tabManager.normalActiveTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the third normal active tab the most recent
        secondNormalTab.lastExecutedTime = Date().toTimestamp()

        // Set the private tab as selected
        await MainActor.run {
            tabManager.selectTab(privateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs + numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, privateTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, privateTab.tabUUID)

        // Remove the last selected private tab
        tabManager.removeTab(privateTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there's a recent active tab, we expect that to be selected
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalTab, "Should select the most recently executed normal active tab")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The second normal tab should be selected")
    }

    func testRemoveTab_removeLastPrivateTab_isOnlyTab_createsNewNormalActiveTab() async throws {
        let tabManager = createSubject()

        let numberPrivateTabs = 1
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the private tab as selected
        await MainActor.run {
            tabManager.selectTab(firstTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, firstTab.tabUUID)

        // Remove the last selected private tab
        tabManager.removeTab(firstTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there are no normal active tabs,
        // we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    func testRemoveTab_removeLastPrivateTab_onlyOtherTabsAreNormalInactiveTabs_createsNewNormalActiveTab() async throws {
        let tabManager = createSubject()

        let numberPrivateTabs = 1
        let numberInactiveTabs = 3
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        addTabs(to: tabManager, ofType: .normalInactive, count: numberInactiveTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        let initialTabs = tabManager.tabs

        // Set the private tab as selected
        await MainActor.run {
            tabManager.selectTab(firstTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs + numberInactiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, firstTab.tabUUID)

        // Remove the last selected private tab
        tabManager.removeTab(firstTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there are no only inactive normal tabs remaining,
        // we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs + numberInactiveTabs, "Removed tab is replaced, count same")
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1, "A new active tab should be added")
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        for tab in initialTabs {
            XCTAssertNotEqual(tabManager.selectedTab, tab, "None of the initial tabs should be selected")
        }
        XCTAssertEqual(tabManager.selectedIndex, 3, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing last normal active tab)

    func testRemoveTab_removeLastNormalActiveTab_isOnlyTab_createsNewNormalActiveTab() async throws {
        let tabManager = createSubject()

        let numberNormalActiveTabs = 1
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        await MainActor.run {
            tabManager.selectTab(firstTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, firstTab.tabUUID)

        // Remove the last tab, which is active and selected
        tabManager.removeTab(firstTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last active tab is removed, we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing last normal inactive tab, which means it's selected, another weird edge case)

    func testRemoveTab_removeLastNormalInactiveTab_isOnlyTab_createsNewNormalActiveTab() async throws {
        let tabManager = createSubject()

        let numberInactiveTabs = 1
        addTabs(to: tabManager, ofType: .normalInactive, count: numberInactiveTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        await MainActor.run {
            tabManager.selectTab(firstTab)
            // Selecting a tab makes it active, so reset to inactive again with an old timestamp
            firstTab.lastExecutedTime = Date().lastMonth.toTimestamp()
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, firstTab.tabUUID)

        // Remove the last tab, which is inactive and selected
        tabManager.removeTab(firstTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected inactive tab is removed, we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing one unselected tabs among many)

    func testRemoveTab_removeUnselectedNormalActiveTab_fromManyMixedTabs_causesArrayShift() async throws {
        let tabManager = createSubject()

        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberNormalActiveTabs
        // Mix up the normal active and inactive tabs in the `tabs` array
        addTabs(to: tabManager, ofType: .normalInactive, count: 1)
        addTabs(to: tabManager, ofType: .normalActive, count: 2)
        addTabs(to: tabManager, ofType: .normalInactive, count: 2)
        addTabs(to: tabManager, ofType: .normalActive, count: 1)
        guard let firstNormalActiveTab = tabManager.normalActiveTabs[safe: 0],
              let thirdNormalActiveTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 3rd normal active tab as selected
        await MainActor.run {
            tabManager.selectTab(thirdNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 5)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, thirdNormalActiveTab.tabUUID)

        // Remove the unselected normal active tab at an index smaller than the selected tab to cause an array shift for the
        // selected tab
        tabManager.removeTab(firstNormalActiveTab)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalActiveTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 4, "The selected tab index should have shifted left")
    }

    func testRemoveTab_removeUnselectedNormalActiveTab_fromManyMixedTabs_noArrayShift() async throws {
        let tabManager = createSubject()

        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberNormalActiveTabs
        // Mix up the normal active and inactive tabs in the `tabs` array
        addTabs(to: tabManager, ofType: .normalInactive, count: 1)
        addTabs(to: tabManager, ofType: .normalActive, count: 2)
        addTabs(to: tabManager, ofType: .normalInactive, count: 2)
        addTabs(to: tabManager, ofType: .normalActive, count: 1)
        guard let firstNormalActiveTab = tabManager.normalActiveTabs[safe: 0],
              let thirdNormalActiveTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 1st normal active tab as selected
        await MainActor.run {
            tabManager.selectTab(firstNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, firstNormalActiveTab.tabUUID)

        // Remove the unselected normal active tab at an index larger than the selected tab so no array shift is necessary
        // for the selected tab
        tabManager.removeTab(thirdNormalActiveTab)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstNormalActiveTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The selected tab index should not have shifted")
    }

    func testRemoveTab_removeUnselectedPrivateTab_fromManyMixedTabs_causesArrayShift() async throws {
        let tabManager = createSubject()

        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberPrivateTabs + numberNormalActiveTabs
        addTabs(to: tabManager, ofType: .normalInactive, count: numberNormalInactiveTabs)
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 2nd private tab as selected (will cause a shift when the 1st private tab is deleted)
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 7)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondPrivateTab.tabUUID)

        // Remove the unselected private tab at an index smaller than the selected tab to cause an array shift for the
        // selected tab
        tabManager.removeTab(firstPrivateTab)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 6, "The selected tab index should have shifted left")
    }

    func testRemoveTab_removeUnselectedPrivateTab_fromManyMixedTabs_noArrayShift() async throws {
        let tabManager = createSubject()

        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberPrivateTabs + numberNormalActiveTabs
        addTabs(to: tabManager, ofType: .normalInactive, count: numberNormalInactiveTabs)
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let thirdPrivateTab = tabManager.privateTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first private tab as selected
        await MainActor.run {
            tabManager.selectTab(firstPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 6)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, firstPrivateTab.tabUUID)

        // Remove the unselected private tab at an index larger than the selected private tab so no array shift is necessary
        // for the selected tab
        tabManager.removeTab(thirdPrivateTab)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 6, "The selected tab index should have shifted left")
    }

    func testRemoveTab_removeUnselectedNormalInactiveTab_fromManyMixedTabs_causesArrayShift() async throws {
        let tabManager = createSubject()

        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberPrivateTabs + numberNormalActiveTabs
        addTabs(to: tabManager, ofType: .normalInactive, count: numberNormalInactiveTabs)
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        addTabs(to: tabManager, ofType: .privateAny, count: numberPrivateTabs)
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let firstNormalInactiveTab = tabManager.normalInactiveTabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 1st private tab as selected (if you set a normal tab, the private tabs get automatically closed on select)
        await MainActor.run {
            tabManager.selectTab(firstPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 6)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, firstPrivateTab.tabUUID)

        // Remove the unselected inactive normal tab at an index smaller than the selected tab to cause an array shift for
        // the selected tab
        tabManager.removeTab(firstNormalInactiveTab)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs - 1)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 5, "The selected tab index should have shifted left")
    }

    // MARK: - Remove Tab (removing unselected tabs at array bounds)

    func testRemoveTab_removeFirstTab_removeLastTime_removeOnlyTab() async throws {
        let tabManager = createSubject()

        let numberNormalActiveTabs = 3
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        guard let firstTab = tabManager.normalActiveTabs[safe: 0],
              let secondTab = tabManager.normalActiveTabs[safe: 1],
              let thirdTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondTab.tabUUID)

        // [1] First, remove the tab at index 0
        tabManager.removeTab(firstTab)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should have shifted left")

        // [2] Second, remove the tab at count - 1 (last tab)
        tabManager.removeTab(thirdTab)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 2)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 2)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should not change")

        // [3] Finally, remove the only tab (which is also the selected tab)
        tabManager.removeTab(secondTab)
        try await Task.sleep(nanoseconds: sleepTime)

        // We expect a new normal active tab will be created
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, secondTab, "This tab should have been removed")
        XCTAssertEqual(tabManager.selectedIndex, 0, "Index of new normal active tab")
    }

    // MARK: - removeAllInactiveTabs (removing unselected tabs at array bounds)

    func testRemoveAllInactiveTabs_whenOnlyInactiveTabs_opensNewActiveTab() async throws {
        // This is a strange edge case that can happen if your active tab goes inactive (most commonly with 10s debug timer).
        let tabManager = createSubject()

        let numberNormalInactiveTabs = 3
        addTabs(to: tabManager, ofType: .normalInactive, count: numberNormalInactiveTabs)
        guard let secondTab = tabManager.normalInactiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected (edge case that an inactive tab is the selected tab)
        await MainActor.run {
            tabManager.selectTab(secondTab)
            // Selecting a tab makes it active, so reset to inactive again with an old timestamp
            secondTab.lastExecutedTime = Date().lastMonth.toTimestamp()
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondTab.tabUUID)

        await tabManager.removeAllInactiveTabs()
        try await Task.sleep(nanoseconds: sleepTime)

        // We expect a new normal active tab will be created, all inactive tabs removed
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, secondTab, "This tab should have been removed")
        XCTAssertEqual(tabManager.selectedIndex, 0, "Index of new normal active tab")
    }

    func testRemoveAllInactiveTabs_whenNormalActiveTabsExist() async throws {
        let tabManager = createSubject()

        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        addTabs(to: tabManager, ofType: .normalInactive, count: numberNormalInactiveTabs)
        addTabs(to: tabManager, ofType: .normalActive, count: numberNormalActiveTabs)
        guard let secondTab = tabManager.normalActiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second normal tab as selected
        await MainActor.run {
            tabManager.selectTab(secondTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs + numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab)
        XCTAssertEqual(tabManager.selectedIndex, 4)
        XCTAssertEqual(tabManager.selectedTabUUID?.uuidString, secondTab.tabUUID)

        await tabManager.removeAllInactiveTabs()
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.normalInactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not have changed")
        XCTAssertEqual(tabManager.selectedIndex, 1, "Index will have shifted by the number of removed inactive tabs")
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
