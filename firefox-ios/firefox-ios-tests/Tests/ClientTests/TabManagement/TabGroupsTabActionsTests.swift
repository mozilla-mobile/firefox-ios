// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class TabGroupsTabActionsTests: TabManagerTestsBase {
    @MainActor
    private func createInMemoryManager(tabs: [Tab]) async throws -> TabManagerImplementation {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        return createSubject(tabs: tabs, groupManager: groups)
    }

    @MainActor
    func testClosingActiveGroupTabSelectsAnotherTabInThatGroup() async throws {
        let tabs = generateTabs(count: 3)
        let tabManager = try await createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController(groupManager: tabManager.tabGroupManager,
                                             windowUUID: tabManager.windowUUID,
                                             tabManager: tabManager)
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work",
                                                           tabIDs: [tabs[0].tabUUID, tabs[1].tabUUID],
                                                           normalTabIDs: tabs.map(\.tabUUID)))

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs([tabs[0]])

        XCTAssertEqual(controller.state.selectedGroupID, groupID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)), [tabs[1].tabUUID])
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, tabs[1].tabUUID)
    }

    @MainActor
    func testClosingAllTabsInGroupOpensBlankTabInGroup() async throws {
        let tabs = generateTabs(count: 2)
        let tabManager = try await createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController(groupManager: tabManager.tabGroupManager,
                                             windowUUID: tabManager.windowUUID,
                                             tabManager: tabManager)
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work",
                                                           tabIDs: [tabs[0].tabUUID],
                                                           normalTabIDs: tabs.map(\.tabUUID)))

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs([tabs[0]])

        let visibleIDs = controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        XCTAssertEqual(controller.state.selectedGroupID, groupID)
        XCTAssertEqual(visibleIDs.count, 1)
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, visibleIDs.first)
    }

    @MainActor
    func testClosingAllMobileTabsOpensBlankMobileTab() async throws {
        let tabs = generateTabs(count: 2)
        let tabManager = try await createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController(groupManager: tabManager.tabGroupManager,
                                             windowUUID: tabManager.windowUUID,
                                             tabManager: tabManager)
        controller.createGroup(name: "Work", tabIDs: [tabs[1].tabUUID], normalTabIDs: tabs.map(\.tabUUID))
        controller.selectGroup(id: nil)

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs([tabs[0]])

        let visibleIDs = controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        XCTAssertNil(controller.state.selectedGroupID)
        XCTAssertEqual(visibleIDs.count, 1)
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, visibleIDs.first)
    }

    @MainActor
    func testClosingAllNormalTabsCreatesOneBlankTab() async throws {
        let tabs = generateTabs(count: 2)
        let tabManager = try await createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController(groupManager: tabManager.tabGroupManager,
                                             windowUUID: tabManager.windowUUID,
                                             tabManager: tabManager)

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs(tabs)

        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, tabManager.normalTabs.first?.tabUUID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)).count, 1)
    }

    @MainActor
    func testMovingActiveTabSwitchesDestinationAndKeepsItSelected() async throws {
        let tabs = generateTabs(count: 2)
        let tabManager = try await createInMemoryManager(tabs: tabs)
        tabManager.selectTab(tabs[0])
        let controller = TabGroupsController(groupManager: tabManager.tabGroupManager,
                                             windowUUID: tabManager.windowUUID,
                                             tabManager: tabManager)
        let groupID = try XCTUnwrap(controller.createGroup(name: "Work", normalTabIDs: tabs.map(\.tabUUID)))
        controller.selectGroup(id: nil)

        TabGroupsTabActions(controller: controller, tabManager: tabManager).moveTab(tabs[0].tabUUID, to: groupID)

        XCTAssertEqual(controller.state.selectedGroupID, groupID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)), [tabs[0].tabUUID])
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, tabs[0].tabUUID)
    }
    @MainActor
    func testOpeningClosedGroupReconstructsTabsBeforeSelectingIt() async throws {
        let tabs = generateTabs(count: 2)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        let id = try XCTUnwrap(controller.createGroup(name: "Saved",
                                                      tabIDs: [tabs[0].tabUUID],
                                                      normalTabIDs: tabs.map(\.tabUUID)))
        manager.closeTabGroup(id)
        let host = try await TabGroupsTabActions(controller: controller, tabManager: manager).openGroup(id)
        XCTAssertEqual(host, manager.windowUUID)
        XCTAssertEqual(controller.state.selectedGroupID, id)
        XCTAssertEqual(manager.normalTabs.filter { $0.groupID == id }.map(\.tabUUID), [tabs[0].tabUUID])
    }

    @MainActor
    func testOpeningGroupInAnotherWindowPreservesCurrentDestination() async throws {
        let tabs = generateTabs(count: 2)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        let id = try XCTUnwrap(controller.createGroup(name: "Work",
                                                      tabIDs: [tabs[0].tabUUID],
                                                      normalTabIDs: tabs.map(\.tabUUID)))
        let other = createSubject(windowUUID: UUID(), groupManager: manager.tabGroupManager)
        let otherController = TabGroupsController(groupManager: manager.tabGroupManager,
                                                  windowUUID: other.windowUUID,
                                                  tabManager: other)
        let host = try await TabGroupsTabActions(controller: otherController, tabManager: other).openGroup(id)
        XCTAssertEqual(host, manager.windowUUID)
        XCTAssertNil(otherController.state.selectedGroupID)
        XCTAssertTrue(other.normalTabs.isEmpty)
        XCTAssertEqual(controller.state.selectedGroupID, id)
    }
}
