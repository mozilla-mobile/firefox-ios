// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared
@testable import Client

final class TabManagerReorderTabsTests: TabManagerTestsBase {
    // MARK: - reorderTabs

    @MainActor
    func testReorderTabs_movesTabForward_withinNormalTabs() {
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: normalTabs)
        let firstTab = subject.normalTabs[0]

        subject.reorderTabs(isPrivate: false, fromIndex: 0, toIndex: 2)

        XCTAssertEqual(subject.normalTabs[2], firstTab, "Tab should have moved to index 2")
    }

    @MainActor
    func testReorderTabs_movesTabBackward_withinNormalTabs() {
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: normalTabs)
        let lastTab = subject.normalTabs[2]

        subject.reorderTabs(isPrivate: false, fromIndex: 2, toIndex: 0)

        XCTAssertEqual(subject.normalTabs[0], lastTab, "Tab should have moved to index 0")
    }

    @MainActor
    func testReorderTabs_doesNotAffectPrivateTabs_whenReorderingNormalTabs() {
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let privateTabs = generateTabs(ofType: .privateAny, count: 2)
        let subject = createSubject(tabs: normalTabs + privateTabs)
        let privateTabsBeforeReorder = subject.privateTabs

        subject.reorderTabs(isPrivate: false, fromIndex: 0, toIndex: 2)

        XCTAssertEqual(subject.privateTabs, privateTabsBeforeReorder, "Private tabs should be unaffected")
    }

    @MainActor
    func testReorderTabs_reordersPrivateTabs_independently() {
        let normalTabs = generateTabs(ofType: .normal, count: 2)
        let privateTabs = generateTabs(ofType: .privateAny, count: 3)
        let subject = createSubject(tabs: normalTabs + privateTabs)
        let firstPrivateTab = subject.privateTabs[0]
        let normalTabsBeforeReorder = subject.normalTabs

        subject.reorderTabs(isPrivate: true, fromIndex: 0, toIndex: 2)

        XCTAssertEqual(subject.privateTabs[2], firstPrivateTab, "First private tab should have moved to index 2")
        XCTAssertEqual(subject.normalTabs, normalTabsBeforeReorder, "Normal tabs should be unaffected")
    }

    @MainActor
    func testReorderTabs_updatesSelectedIndex_afterReorder() {
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: normalTabs)
        guard let firstTab = subject.normalTabs.first else {
            XCTFail("Test did not meet preconditions")
            return
        }

        subject.selectTab(firstTab)
        XCTAssertEqual(subject.selectedIndex, 0)

        subject.reorderTabs(isPrivate: false, fromIndex: 0, toIndex: 2)

        XCTAssertEqual(subject.selectedTab, firstTab, "Selected tab should remain the same")
        XCTAssertEqual(subject.selectedIndex, 2, "Selected index should reflect the tab's new position")
    }

    @MainActor
    func testReorderTabs_doesNothing_whenIndexOutOfBounds() {
        let normalTabs = generateTabs(ofType: .normal, count: 3)
        let subject = createSubject(tabs: normalTabs)
        let tabsBeforeReorder = subject.normalTabs

        subject.reorderTabs(isPrivate: false, fromIndex: 10, toIndex: 0)
        XCTAssertEqual(subject.normalTabs, tabsBeforeReorder, "Order should not change when fromIndex is out of bounds")

        subject.reorderTabs(isPrivate: false, fromIndex: 0, toIndex: 10)
        XCTAssertEqual(subject.normalTabs, tabsBeforeReorder, "Order should not change when toIndex is out of bounds")
    }
}
