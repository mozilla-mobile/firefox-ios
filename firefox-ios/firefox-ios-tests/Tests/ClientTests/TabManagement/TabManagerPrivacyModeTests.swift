// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared
@testable import Client

final class TabManagerPrivacyModeTests: TabManagerTestsBase {
    // MARK: - switchPrivacyMode

    @MainActor
    func testSwitchPrivacyMode_fromNormalTab_noPrivateTabs_createsNewPrivateTab() {
        let subject = createSubject(tabs: generateTabs(ofType: .normal, count: 2))
        guard let normalTab = subject.normalTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }
        subject.selectTab(normalTab)

        XCTAssertEqual(subject.normalTabs.count, 2)
        XCTAssertEqual(subject.privateTabs.count, 0)
        XCTAssertFalse(subject.selectedTab?.isPrivate ?? true)

        let result = subject.switchPrivacyMode()

        XCTAssertEqual(result, .createdNewTab)
        XCTAssertEqual(subject.privateTabs.count, 1)
        XCTAssertTrue(subject.selectedTab?.isPrivate ?? false)
    }

    @MainActor
    func testSwitchPrivacyMode_fromNormalTab_existingPrivateTabs_closePrivateTabsDisabled_selectsMostRecentPrivateTab() {
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Settings.closePrivateTabs)
        let normalTabs = generateTabs(ofType: .normal, count: 2)
        let privateTabs = generateTabs(ofType: .privateAny, count: 3)
        let subject = createSubject(tabs: normalTabs + privateTabs)

        guard let normalTab = subject.normalTabs.first,
              let recentPrivateTab = subject.privateTabs.last else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the last private tab the most recently executed
        subject.privateTabs.forEach { $0.lastExecutedTime = Date().dayBefore.toTimestamp() }
        recentPrivateTab.lastExecutedTime = Date().toTimestamp()

        subject.selectTab(normalTab)

        XCTAssertEqual(subject.normalTabs.count, 2)
        XCTAssertEqual(subject.privateTabs.count, 3)
        XCTAssertFalse(subject.selectedTab?.isPrivate ?? true)

        let result = subject.switchPrivacyMode()

        XCTAssertEqual(result, .usedExistingTab)
        XCTAssertEqual(subject.privateTabs.count, 3, "No new private tab should be created")
        XCTAssertEqual(subject.selectedTab, recentPrivateTab)
    }

    @MainActor
    func testSwitchPrivacyMode_fromNormalTab_closePrivateTabsEnabled_createsNewPrivateTab() {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.closePrivateTabs)
        let normalTabs = generateTabs(ofType: .normal, count: 2)
        let privateTabs = generateTabs(ofType: .privateAny, count: 3)
        let subject = createSubject(tabs: normalTabs + privateTabs)

        guard let privateTab = subject.privateTabs.first,
              let normalTab = subject.normalTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Simulate leaving private mode: switching back to a normal tab wipes all private tabs
        subject.selectTab(privateTab)
        subject.selectTab(normalTab)

        XCTAssertEqual(subject.privateTabs.count, 0, "Private tabs should have been deleted when leaving private mode")
        XCTAssertFalse(subject.selectedTab?.isPrivate ?? true)

        let result = subject.switchPrivacyMode()

        XCTAssertEqual(result, .createdNewTab)
        XCTAssertEqual(subject.privateTabs.count, 1, "A new private tab should be created since existing ones were wiped")
        XCTAssertTrue(subject.selectedTab?.isPrivate ?? false)
    }

    @MainActor
    func testSwitchPrivacyMode_fromPrivateTab_selectsMostRecentNormalTab() {
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let privateTabs = generateTabs(ofType: .privateAny, count: 2)
        let subject = createSubject(tabs: normalTabs + privateTabs)

        guard let privateTab = subject.privateTabs.first,
              let recentNormalTab = subject.normalTabs.last else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the last normal tab the most recently executed
        subject.normalTabs.forEach { $0.lastExecutedTime = Date().dayBefore.toTimestamp() }
        recentNormalTab.lastExecutedTime = Date().toTimestamp()

        subject.selectTab(privateTab)

        XCTAssertEqual(subject.normalTabs.count, 3)
        XCTAssertEqual(subject.privateTabs.count, 2)
        XCTAssertTrue(subject.selectedTab?.isPrivate ?? false)

        let result = subject.switchPrivacyMode()

        XCTAssertEqual(result, .usedExistingTab)
        XCTAssertEqual(subject.selectedTab, recentNormalTab)
        XCTAssertFalse(subject.selectedTab?.isPrivate ?? true)
    }

    @MainActor
    func testSwitchPrivacyMode_noSelectedTab_returnsUsedExistingTab() {
        let subject = createSubject(tabs: [])

        XCTAssertNil(subject.selectedTab)

        let result = subject.switchPrivacyMode()

        XCTAssertEqual(result, .usedExistingTab, "Should return usedExistingTab when no tab is selected")
        XCTAssertEqual(subject.tabs.count, 0, "No tabs should be created when selectedTab is nil")
    }

    // MARK: - removeAllPrivateTabs (triggered via selectTab)

    @MainActor
    func testRemoveAllPrivateTabs_whenSelectingNormalTab_withClosePrivateTabsEnabled() {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.closePrivateTabs)
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let privateTabs = generateTabs(ofType: .privateAny, count: 3)
        let subject = createSubject(tabs: normalTabs + privateTabs)

        guard let privateTab = subject.privateTabs.first,
              let normalTab = subject.normalTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }

        subject.selectTab(privateTab)

        XCTAssertEqual(subject.normalTabs.count, 3)
        XCTAssertEqual(subject.privateTabs.count, 3)
        XCTAssertTrue(subject.selectedTab?.isPrivate ?? false)

        // Select a normal tab — this should trigger removeAllPrivateTabs
        subject.selectTab(normalTab)

        XCTAssertEqual(subject.privateTabs.count, 0, "All private tabs should be removed")
        XCTAssertEqual(subject.normalTabs.count, 3, "Normal tabs should be untouched")
        XCTAssertEqual(subject.tabs.count, 3)
        XCTAssertFalse(subject.selectedTab?.isPrivate ?? true)
    }

    @MainActor
    func testRemoveAllPrivateTabs_whenSelectingNormalTab_withClosePrivateTabsDisabled() {
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Settings.closePrivateTabs)
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let privateTabs = generateTabs(ofType: .privateAny, count: 3)
        let subject = createSubject(tabs: normalTabs + privateTabs)

        guard let privateTab = subject.privateTabs.first,
              let normalTab = subject.normalTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }

        subject.selectTab(privateTab)
        subject.selectTab(normalTab)

        XCTAssertEqual(subject.privateTabs.count, 3, "Private tabs should be preserved when setting is disabled")
        XCTAssertEqual(subject.normalTabs.count, 3)
    }

    @MainActor
    func testRemoveAllPrivateTabs_resetsSelectedIndex_whenSelectedTabIsPrivate() {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.closePrivateTabs)
        let normalTabs = generateTabs(ofType: .normal, count: 2)
        let privateTabs = generateTabs(ofType: .privateAny, count: 2)
        let subject = createSubject(tabs: normalTabs + privateTabs)

        guard let privateTab = subject.privateTabs.first,
              let normalTab = subject.normalTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }

        subject.selectTab(privateTab)
        XCTAssertTrue(subject.selectedTab?.isPrivate ?? false)

        subject.selectTab(normalTab)

        XCTAssertEqual(subject.privateTabs.count, 0)
        XCTAssertEqual(subject.selectedTab, normalTab)
        XCTAssertGreaterThanOrEqual(subject.selectedIndex, 0, "Selected index should point to the new normal tab")
    }

    @MainActor
    func testRemoveAllPrivateTabs_notifiesDelegateForEachRemovedTab() {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.closePrivateTabs)
        let normalTabs = generateTabs(ofType: .normal, count: 2)
        let privateTabs = generateTabs(ofType: .privateAny, count: 3)
        let subject = createSubject(tabs: normalTabs + privateTabs)

        let delegate = MockTabManagerDelegatePrivacyTests()
        subject.addDelegate(delegate)

        guard let privateTab = subject.privateTabs.first,
              let normalTab = subject.normalTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }

        subject.selectTab(privateTab)
        delegate.reset()

        subject.selectTab(normalTab)

        XCTAssertEqual(delegate.didRemoveTabCallCount, 3, "Delegate should be notified once per removed private tab")
        XCTAssertTrue(delegate.removedTabs.allSatisfy { $0.isPrivate }, "All removed tabs should be private")
    }

    @MainActor
    func testRemoveAllPrivateTabs_doesNotRemoveTabs_whenNoPrivateTabsExist() {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.closePrivateTabs)
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: normalTabs)

        guard let firstNormal = subject.normalTabs.first,
              let secondNormal = subject.normalTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        subject.selectTab(firstNormal)
        subject.selectTab(secondNormal)

        XCTAssertEqual(subject.normalTabs.count, 3, "Normal tabs should be untouched when no private tabs exist")
        XCTAssertEqual(subject.privateTabs.count, 0)
    }
}

// MARK: - MockTabManagerDelegatePrivacyTests

private class MockTabManagerDelegatePrivacyTests: TabManagerDelegate {
    var didRemoveTabCallCount = 0
    var removedTabs = [Tab]()

    func reset() {
        didRemoveTabCallCount = 0
        removedTabs = []
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        didRemoveTabCallCount += 1
        removedTabs.append(tab)
    }
}
