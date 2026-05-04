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

final class TabManagerRemoveTabTests: TabManagerTestsBase {
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

    // MARK: - Remove Tab (removing selected normal tab)

    @MainActor
    func testRemoveTab_removeSelectednormalTab_selectsRecentParentnormalTab() async throws {
        let normalTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: normalTabs))
        guard let firstnormalTab = tabManager.normalTabs[safe: 0],
              let secondnormalTab = tabManager.normalTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondnormalTab.parent = firstnormalTab

        // Make all the tabs slightly stale
        tabManager.normalTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the parent tab the most recent tab
        firstnormalTab.lastExecutedTime = Date().toTimestamp()

        // Set the second tab as selected
        tabManager.selectTab(secondnormalTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, normalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondnormalTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondnormalTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, we expect its recent parent to be selected.
        XCTAssertEqual(tabManager.tabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstnormalTab, "Should have selected the parent tab, it's most recent")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The first tab, the parent, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectedNormalTab_selectsRightOrLeftNormalTab_ifNoParent() async throws {
        let normalTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: normalTabs))
        guard let secondNormalTab = tabManager.normalTabs[safe: 1],
              let thirdNormalTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected
        tabManager.selectTab(secondNormalTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, normalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondNormalTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalTab, "Should select tab on the right since no parent")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectednormalTab_selectsRightOrLeftNormalTab_ifParentNotRecent() async throws {
        let normalTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: normalTabs))
        guard let firstnormalTab = tabManager.normalTabs[safe: 0],
              let secondnormalTab = tabManager.normalTabs[safe: 1],
              let thirdnormalTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondnormalTab.parent = firstnormalTab

        // Make the parent tab staler than the others (not recent)
        firstnormalTab.lastExecutedTime = Date().dayBefore.toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondnormalTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, normalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondnormalTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondnormalTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdnormalTab, "Should select tab on the right since parent is stale")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    // MARK: - Remove Tab (removing selected private tab)

    @MainActor
    func testRemoveTab_removeSelectedPrivateTab_selectsRecentParentPrivateTab() async throws {
        let numberPrivateTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .privateAny, count: numberPrivateTabs))
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second private tab
        secondPrivateTab.parent = firstPrivateTab

        // Make all the tabs slightly stale
        tabManager.normalTabs.forEach { tab in
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
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, we expect its recent parent to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "Should have selected the parent tab, as it is most recent")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The first tab, the parent, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectedPrivateTab_selectsRightOrLeftPrivateTab_ifNoRecentParent() async throws {
        let numberPrivateTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .privateAny, count: numberPrivateTabs))
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
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed with no parent, we expect the right tab to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, thirdPrivateTab, "Should have selected the tab on the right")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now at index 1, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectedPrivateTab_selectsRightOrLeftPrivateTab_ifParentNotRecent() async throws {
        let numberPrivateTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .privateAny, count: numberPrivateTabs))
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
        tabManager.selectTab(secondPrivateTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, thirdPrivateTab, "Should select tab on the right since parent is stale")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    @MainActor
    func testRemoveTab_removeLastPrivateTab_selectNormalTab() async throws {
        let numberNormalOlderLastMonthTabs = 1
        let numberPrivateTabs = 1
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let normalOlderLastMonthTabs = generateTabs(ofType: .normalOlderLastMonth, count: numberNormalOlderLastMonthTabs)

        let tabManager = createSubject(tabs: normalOlderLastMonthTabs + privateTabs)
        guard let privateTab = tabManager.privateTabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        tabManager.selectTab(privateTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalOlderLastMonthTabs + numberPrivateTabs)
        XCTAssertEqual(tabManager.normalTabs.count, numberNormalOlderLastMonthTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, privateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the private tab, which is selected
        tabManager.removeTab(privateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last private tab is removed, we select the normal older tab
        XCTAssertEqual(tabManager.tabs.count, numberNormalOlderLastMonthTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, privateTab, "The added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    @MainActor
    func testRemoveTab_removeLastPrivateTab_isOnlyTab_createsNewNormalTab() async throws {
        let numberPrivateTabs = 1
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let tabManager = createSubject(tabs: privateTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the private tab as selected
        tabManager.selectTab(firstTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last selected private tab
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there are no normal tabs,
        // we expect a new normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing last normal tab)

    @MainActor
    func testRemoveTab_removeLastNormalTab_isOnlyTab_createsNewNormalTab() async throws {
        let numberNormalTabs = 1
        let normalTabs = generateTabs(ofType: .normal, count: numberNormalTabs)

        let tabManager = createSubject(tabs: normalTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        tabManager.selectTab(firstTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last tab, which is normal and selected
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last normal tab is removed, we expect a new normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing one unselected tab among many)

    @MainActor
    func testRemoveTab_removeUnselectedNormalTab_causesArrayShift() async throws {
        let totalTabCount = 3
        let tabs = generateTabs(ofType: .normal, count: totalTabCount)
        let tabManager = createSubject(tabs: tabs)

        guard let firstTab = tabManager.normalTabs[safe: 0],
              let thirdTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 3rd tab as selected
        tabManager.selectTab(thirdTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalTabs.count, totalTabCount)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdTab)
        XCTAssertEqual(tabManager.selectedIndex, 2)

        // Remove the unselected tab at an index smaller than the selected tab to cause an array shift
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalTabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The selected tab index should have shifted left")
    }

    @MainActor
    func testRemoveTab_removeUnselectedNormalTab_noArrayShift() async throws {
        let totalTabCount = 3
        let tabs = generateTabs(ofType: .normal, count: totalTabCount)
        let tabManager = createSubject(tabs: tabs)

        guard let firstTab = tabManager.normalTabs[safe: 0],
              let thirdTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 1st tab as selected
        tabManager.selectTab(firstTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalTabs.count, totalTabCount)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the unselected tab at an index larger than the selected tab so no array shift is necessary
        tabManager.removeTab(thirdTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalTabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should not have shifted")
    }

    @MainActor
    func testRemoveTab_removeUnselectedPrivateTab_causesArrayShift() async throws {
        let numberNormalTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numberNormalTabs + numberPrivateTabs
        let normal = generateTabs(ofType: .normal, count: numberNormalTabs)
        let privateAny = generateTabs(ofType: .privateAny, count: numberPrivateTabs)

        let tabManager = createSubject(tabs: normal + privateAny)

        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 2nd private tab as selected (will cause a shift when the 1st private tab is deleted)
        tabManager.selectTab(secondPrivateTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalTabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 4)

        // Remove the unselected private tab at an index smaller than the selected tab to cause an array shift
        tabManager.removeTab(firstPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalTabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 3, "The selected tab index should have shifted left")
    }

    @MainActor
    func testRemoveTab_removeUnselectedPrivateTab_fromManyMixedTabs_noArrayShift() async throws {
        let numberNormalOlderLastMonthTabs = 3
        let normalTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numberNormalOlderLastMonthTabs + numberPrivateTabs + normalTabs
        let normalOlderLastMonth = generateTabs(ofType: .normalOlderLastMonth, count: numberNormalOlderLastMonthTabs)
        let normal = generateTabs(ofType: .normal, count: normalTabs)
        let privateAny = generateTabs(ofType: .privateAny, count: numberPrivateTabs)

        let tabManager = createSubject(tabs: normalOlderLastMonth + normal + privateAny)

        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let thirdPrivateTab = tabManager.privateTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first private tab as selected
        tabManager.selectTab(firstPrivateTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs + numberNormalOlderLastMonthTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 6)

        // Remove the unselected private tab at an index larger than the selected private tab so no array shift is necessary
        // for the selected tab
        tabManager.removeTab(thirdPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs + numberNormalOlderLastMonthTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 6, "The selected tab index should have shifted left")
    }

    // MARK: - Remove Tab (removing unselected tabs at array bounds)

    @MainActor
    func testRemoveTab_removeFirstTab_removeLastTime_removeOnlyTab() async throws {
        let normalTabs = 3
        let tabs = generateTabs(ofType: .normal, count: normalTabs)

        let tabManager = createSubject(tabs: tabs)

        guard let firstTab = tabManager.normalTabs[safe: 0],
              let secondTab = tabManager.normalTabs[safe: 1],
              let thirdTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected
        tabManager.selectTab(secondTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, normalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // [1] First, remove the tab at index 0
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should have shifted left")

        // [2] Second, remove the tab at count - 1 (last tab)
        tabManager.removeTab(thirdTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, normalTabs - 2)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 2)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should not change")

        // [3] Finally, remove the only tab (which is also the selected tab)
        tabManager.removeTab(secondTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // We expect a new normal tab will be created
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, secondTab, "This tab should have been removed")
        XCTAssertEqual(tabManager.selectedIndex, 0, "Index of new normal tab")
    }
}
