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

final class TabManagerTests: TabManagerTestsBase {
    @MainActor
    func testRecentlyAccessedNormalTabs() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .normalOlderLastMonth, count: 2))
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 2))
        let subject = createSubject(tabs: tabs)
        let normalTabs = subject.recentlyAccessedNormalTabs
        XCTAssertEqual(normalTabs.count, 7)
    }

    @MainActor
    func testTabIndexSubscript() {
        let subject = createSubject(tabs: generateTabs(count: 5))
        let tab = subject[0]
        XCTAssertNotNil(tab)
    }

    @MainActor
    func testRemoveTabs() {
        let subject = createSubject(tabs: generateTabs(count: 5))
        let tabs = subject.tabs
        subject.removeTabs(tabs)
        XCTAssertEqual(subject.tabs.count, 0)
    }

    @MainActor
    func testRemoveTabsByURLs() {
        let subject = createSubject(tabs: generateTabs(count: 5))
        subject.removeTabs(by: [URL(string: "https://mozilla.com?item=4")!, URL(string: "https://mozilla.com?item=1")!])
        let remainingURLs = subject.tabs.compactMap { $0.url?.absoluteString }
        XCTAssertEqual(remainingURLs, ["https://mozilla.com?item=0", "https://mozilla.com?item=2", "https://mozilla.com?item=3"])
    }

    @MainActor
    func testRemoveAllTabsForPrivateMode() {
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 4))
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.tabs.count, 9)
        subject.removeAllTabs(isPrivateMode: true)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    // This test has to be run on the main thread since we are messing with the WebView.
    @MainActor
    func testRemoveAllTabsCallsSaveTabSession() {
        let subject = createSubject()
        let tab = subject.addTab(URLRequest(url: URL(string: "https://mozilla.com")!), afterTab: nil, isPrivate: false)
        subject.selectTab(tab)
        subject.removeAllTabs(isPrivateMode: false)

        // Save tab session is actually called 3 times for one remove all call
        // 1. Save tab session for currently selected tab before delete to preserve scroll position
        // 1. AddTab for the new created homepage tab calls commitChanges
        // 2. selectTab persists changes for currently selected tab before moving to new Tab
        XCTAssertEqual(mockSessionStore.saveTabSessionCallCount, 3)
    }

    @MainActor
    func testRemoveAllTabsForNotPrivateModeWhenClosePrivateTabsSettingIsFalse() {
        (mockProfile.prefs as? MockProfilePrefs)?.things[PrefsKeys.Settings.closePrivateTabs] = false
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 4))
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.tabs.count, 9)
        subject.removeAllTabs(isPrivateMode: false)
        // 5, private mode tabs (4) plus one new normal tab (1)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    @MainActor
    func testRemoveAllTabsForNotPrivateModeWhenClosePrivateTabsSettingIsTrue() {
        (mockProfile.prefs as? MockProfilePrefs)?.things[PrefsKeys.Settings.closePrivateTabs] = true
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 4))
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.tabs.count, 9)
        subject.removeAllTabs(isPrivateMode: false)
        // One new normal tab (1)
        XCTAssertEqual(subject.tabs.count, 1)
    }

    @MainActor
    func testGetTabForUUID() {
        let subject = createSubject(tabs: generateTabs(count: 1))
        let uuid = subject.tabs.first!.tabUUID
        let tab = subject.getTabForUUID(uuid: uuid)
        XCTAssertEqual(tab, subject.tabs.first)
    }

    // This test has to be run on the main thread since we are messing with the WebView.
    @MainActor
    func testGetTabForURL() {
        let subject = createSubject()
        let addedTab = subject.addTab(URLRequest(url: URL(string: "https://mozilla.com")!), afterTab: nil, isPrivate: false)
        let tab = subject.getTabForURL(URL(string: "https://mozilla.com/")!)
        XCTAssertEqual(tab, addedTab)
    }

    @MainActor
    func testGetTabsAndChangeLastExecutedTime() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        let totalTabCount = 3
        let subject = createSubject(tabs: generateTabs(count: totalTabCount))

        // Preconditions
        XCTAssertEqual(subject.tabs.count, totalTabCount, "Expected 3 newly added tabs.")
        XCTAssertEqual(subject.normalTabs.count, totalTabCount, "All tabs should be normal on initialization")

        // Override lastExecutedTime of 1st tab to be recent (i.e. normal)
        // and lastExecutedTime of other 2 to be distant past (i.e. older tabs)
        let lastExecutedDate = Calendar.current.add(numberOfDays: 1, to: Date())!
        subject.tabs[0].lastExecutedTime = lastExecutedDate.toTimestamp()
        subject.tabs[1].lastExecutedTime = 0
        subject.tabs[2].lastExecutedTime = 0

        // Test
        XCTAssertEqual(subject.normalTabs.count, totalTabCount, "The total tab count should not have changed")
    }

    @MainActor
    func test_addTabsForURLs() {
        let subject = createSubject()

        subject.addTabsForURLs([URL(string: "https://www.mozilla.org/privacy/firefox")!], zombie: false, shouldSelectTab: false)

        XCTAssertEqual(subject.tabs.count, 1)
        XCTAssertEqual(subject.tabs.first?.url?.absoluteString, "https://www.mozilla.org/privacy/firefox")
        XCTAssertEqual(subject.tabs.first?.isPrivate, false)
    }

    @MainActor
    func test_addTabsForURLs_forPrivateMode() {
        let subject = createSubject()

        subject.addTabsForURLs([URL(string: "https://www.mozilla.org/privacy/firefox")!], zombie: false, shouldSelectTab: false, isPrivate: true)

        XCTAssertEqual(subject.tabs.count, 1)
        XCTAssertEqual(subject.tabs.first?.url?.absoluteString, "https://www.mozilla.org/privacy/firefox")
        XCTAssertEqual(subject.tabs.first?.isPrivate, true)
    }

    // MARK: - Document pause - restore

    @MainActor
    func testSelectTab_pauseCurrentDocumentDownload() throws {
        let tabs = generateTabs(count: 2)
        let document = MockTemporaryDocument(withFileURL: URL(string: "https://www.example.com")!)
        let subject = createSubject(tabs: tabs)

        let tab = try XCTUnwrap(tabs.first)
        tab.enqueueDocument(document)

        subject.selectTab(tabs[1], previous: tab)

        XCTAssertEqual(document.pauseDownloadCalled, 1)
    }

    // MARK: - Test findRightOrLeftTab helper

    @MainActor
    func testFindRightOrLeftTab_forEmptyArray() {
        // Set up a tab array as follows:
        // [] Empty
        // Will pretend to delete a normal tab at index 0.
        // Expect no tab to be returned.
        let tabManager = createSubject()

        let deletedIndex = 0 // Pretend the only tab in the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: []
        XCTAssertNil(rightOrLeftTab, "Cannot return a tab when the array is empty")
    }

    @MainActor
    func testFindRightOrLeftTab_forSingleTabInArray_ofSameType() {
        // Set up a tab array as follows:
        // [N1]
        // Will pretend to delete a normal tab at index 0.
        // Expect N1 tab to be returned.
        let numberTabs = 1
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: numberTabs))

        let deletedIndex = 0
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(rightOrLeftTab, tabManager.tabs[safe: 0], "Should return neighbour of same type, as one exists")
    }

    @MainActor
    func testFindRightOrLeftTab_forSingleTabInArray_ofDifferentType() {
        // Set up a tab array as follows:
        // [N1]
        // Will pretend to delete a private tab at index 0.
        // Expect no tab to be returned (no other private tabs).
        let numberTabs = 1
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: numberTabs))

        let deletedIndex = 0
        let removedTab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID) // Private tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNil(rightOrLeftTab, "Cannot return neighbour tab of same type, as no other private tabs exist")
    }

    @MainActor
    func testFindRightOrLeftTab_forDeletedIndexInMiddle_uniformTabTypes() {
        // Set up a tab array as follows:
        // [N1, N2, N3, N4, N5, N6, N7]
        //   0   1   2   3   4   5   6
        // Will pretend to delete a normal tab at index 3.
        // Expect N4 tab to be returned.
        let numberTabs = 7
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: numberTabs))

        let deletedIndex = 3
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(rightOrLeftTab, tabManager.tabs[safe: 3], "Should pick tab N4 at the same position as deletedIndex")
    }

    @MainActor
    func testFindRightOrLeftTab_forDeletedIndexInMiddle_mixedTabTypes() {
        // Set up a tab array as follows:
        // [N1, P1, P2, P3, N2, N3, N4, N5, P4]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal tab at index 5.
        // Expect to return N2 (nearest normal tab on left).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 5 // Pretend a normal tab between N2 and N4 was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [N1, N2, N3, N4, N5]
        // For "deleted" index 5 in the main array, that should be mapped down to index 2 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right first, in this case, N4 (third normal tab)
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalTabs[safe: 2],
            "Should choose the third normal tab as the nearest neighbour on the right"
        )
    }

    @MainActor
    func testFindRightOrLeftTab_forDeletedIndexAtStart() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        // Set up a tab array as follows:
        // [N1, P1, P2, P3, N2, N3, N4, N5, P4]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal tab at index 0.
        // Expect to return N2 (nearest normal tab on right).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()
        let deletedIndex = 0 // Pretend a normal tab at the start of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [N1, N2, N3, N4, N5]
        // For "deleted" index 0 in the main array, that should be mapped down to index 0 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right first, in this case, N2 (first normal tab)
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalTabs[safe: 0],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    @MainActor
    func testFindRightOrLeftTab_forDeletedIndexAtEnd() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        // Set up a tab array as follows:
        // [N1, P1, P2, P3, N2, N3, N4, N5, P4]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal tab at index 9.
        // Expect to return N5 (nearest normal tab on left, since there is no right tab available).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 9 // Pretend a normal tab at the end of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [N1, N2, N3, N4, N5]
        // For "deleted" index 9 in the main array, that should be mapped down to index 6 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the left (since no right tab exists), in this case, N6
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalTabs[safe: 4],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    @MainActor
    func testFindRightOrLeftTab_prefersRightTabOverLeftTab() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        // Set up a tab array as follows:
        // [N1, P1, P2, P3, N2, N3, N4, N5, P4]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a private tab at index 2.
        // Expect to return P3 (nearest private tab on the right, as right is given preference to left).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 2 // Pretend a private tab was just deleted
        let removedTab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID)

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [P1, P2, P3]
        // For "deleted" index 1 in the main array, that should be mapped down to index 0 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right, in this case, P2
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.privateTabs[safe: 1],
            "Should choose the second private tab as the nearest neighbour on the right"
        )
    }
}
