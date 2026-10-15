// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TabGroupsToolbarButtonViewModelTests: TabManagerTestsBase {
    func testToolbarUsesSelectedGroupEmoji() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let tabs = generateTabs(count: 3)
        let manager = createSubject(tabs: tabs, groupManager: groups)
        let ids = tabs.map(\.tabUUID)
        let windowUUID = manager.windowUUID
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: "tabCount",
                                                numberOfTabs: 1,
                                                isEnabled: true,
                                                a11yLabel: "Tabs",
                                                a11yId: "tabs")

        XCTAssertEqual(TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID), action)

        controller.createGroup(name: "Work", emoji: "💼", tabIDs: [ids[0]], normalTabIDs: ids)
        let configured = TabGroupsToolbarButtonViewModel.configure(action, for: windowUUID)

        if TabGroupsFeatureFlag.isEnabled {
            XCTAssertEqual(configured.actionLabel, "💼")
            XCTAssertNil(configured.iconName)
            XCTAssertNil(configured.numberOfTabs)
            XCTAssertEqual(configured.a11yLabel, "Work Tab Group")
        } else {
            XCTAssertEqual(configured, action)
        }
    }

    func testToolbarCountsOnlyMobileTabs() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let tabs = generateTabs(count: 3)
        let manager = createSubject(tabs: tabs, groupManager: groups)
        let ids = tabs.map(\.tabUUID)
        let windowUUID = manager.windowUUID
        defer { TabGroupsSessionStore.removeController(for: windowUUID) }
        let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
        let action = ToolbarActionConfiguration(actionType: .tabs,
                                                iconName: "tabCount",
                                                numberOfTabs: 3,
                                                isEnabled: true,
                                                a11yLabel: "Tabs",
                                                a11yId: "tabs")
        controller.createGroup(name: "Work", tabIDs: [ids[0], ids[2]], normalTabIDs: ids)
        controller.selectGroup(id: nil)

        let configured = TabGroupsToolbarButtonViewModel.configure(action,
                                                                   for: windowUUID,
                                                                   normalTabIDs: ids)

        XCTAssertEqual(configured.numberOfTabs, TabGroupsFeatureFlag.isEnabled ? 1 : 3)
    }
}
