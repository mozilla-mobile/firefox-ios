// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared
@testable import Client

final class TabManagerClearHistoryTests: TabManagerTestsBase {
    // MARK: - clearAllTabsHistory

    @MainActor
    func testClearAllTabsHistory_replacesSelectedTab_withNewTab() {
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: normalTabs)
        guard let originalTab = subject.normalTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }
        let originalUUID = originalTab.tabUUID
        let originalCount = subject.tabs.count

        subject.selectTab(originalTab)
        subject.clearAllTabsHistory()

        XCTAssertEqual(subject.tabs.count, originalCount, "Tab count should remain the same (one added, one removed)")
        XCTAssertFalse(
            subject.tabs.contains { $0.tabUUID == originalUUID },
            "Original selected tab should have been removed"
        )
        XCTAssertNotNil(subject.selectedTab, "A new tab should be selected")
    }

    @MainActor
    func testClearAllTabsHistory_preservesPrivacyMode_forNewTab() {
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.Settings.closePrivateTabs)
        let privateTabs = generateTabs(ofType: .privateAny, count: 2)
        let subject = createSubject(tabs: privateTabs)
        guard let originalTab = subject.privateTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }

        subject.selectTab(originalTab)
        subject.clearAllTabsHistory()

        XCTAssertTrue(subject.selectedTab?.isPrivate ?? false, "New selected tab should preserve private mode")
    }

    @MainActor
    func testClearAllTabsHistory_doesNothing_whenNoSelectedTab() {
        let subject = createSubject(tabs: [])

        XCTAssertNil(subject.selectedTab)
        subject.clearAllTabsHistory()

        XCTAssertEqual(subject.tabs.count, 0, "No tabs should be created when there is no selected tab")
    }

    @MainActor
    func testClearAllTabsHistory_doesNothing_whenSelectedTabHasNoURL() {
        let tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        tab.url = nil
        let subject = createSubject(tabs: [tab])
        subject.selectTab(tab)

        XCTAssertNil(subject.selectedTab?.url)
        subject.clearAllTabsHistory()

        XCTAssertEqual(subject.tabs.count, 1, "Tab count should not change when selected tab has no URL")
        XCTAssertEqual(subject.selectedTab?.tabUUID, tab.tabUUID, "Original tab should still be selected")
    }
}
