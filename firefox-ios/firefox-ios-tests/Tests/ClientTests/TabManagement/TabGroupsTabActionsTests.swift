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
    func testClosingSelectedUngroupedTabSelectsRightNeighbor() async throws {
        let tabs = generateTabs(count: 4)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        manager.selectTab(tabs[2])
        controller.recordSelectedTab(tabs[2].tabUUID, normalTabIDs: tabs.map(\.tabUUID))

        TabGroupsTabActions(controller: controller, tabManager: manager).closeTabs([tabs[2]])

        XCTAssertEqual(manager.selectedTab?.tabUUID, tabs[3].tabUUID)
    }

    @MainActor
    func testClosingSelectedLastTabReportsRemovedTabAsPreviousSelection() async throws {
        let tabs = generateTabs(count: 2)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        manager.selectTab(tabs[1])
        let observer = TabSelectionObserver()
        manager.addDelegate(observer)

        TabGroupsTabActions(controller: controller, tabManager: manager).closeTabs([tabs[1]])

        XCTAssertEqual(observer.selections.count, 1)
        let selection = try XCTUnwrap(observer.selections.first)
        XCTAssertTrue(selection.selected === tabs[0])
        XCTAssertTrue(selection.previous === tabs[1])
    }

    @MainActor
    func testClosingInterleavedGroupTabReportsRemovedTabInsteadOfUngroupedTab() async throws {
        let tabs = generateTabs(count: 4)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        let ids = tabs.map(\.tabUUID)
        _ = try XCTUnwrap(controller.createGroup(name: "Work", tabIDs: [ids[0], ids[2]], normalTabIDs: ids))
        manager.selectTab(tabs[2])
        let observer = TabSelectionObserver()
        manager.addDelegate(observer)

        TabGroupsTabActions(controller: controller, tabManager: manager).closeTabs([tabs[2]])

        XCTAssertEqual(observer.selections.count, 1)
        let selection = try XCTUnwrap(observer.selections.first)
        XCTAssertTrue(selection.selected === tabs[0])
        XCTAssertTrue(selection.previous === tabs[2])
    }

    @MainActor
    func testClosingGroupTabSelectsRightThenLeftNeighborWithinGroup() async throws {
        let tabs = generateTabs(count: 5)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        let ids = tabs.map(\.tabUUID)
        let group = try XCTUnwrap(controller.createGroup(name: "Work",
                                                         tabIDs: [ids[0], ids[2], ids[4]],
                                                         normalTabIDs: ids))
        tabs[2].parent = tabs[1]
        manager.selectTab(tabs[2])
        let actions = TabGroupsTabActions(controller: controller, tabManager: manager)

        actions.closeTabs([tabs[2]])
        XCTAssertEqual(manager.selectedTab?.tabUUID, ids[4])

        actions.closeTabs([tabs[4]])
        XCTAssertEqual(manager.selectedTab?.tabUUID, ids[0])
        XCTAssertEqual(controller.state.selectedGroupID, group)
    }

    @MainActor
    func testClosingSelectedTabPrefersSurvivingVisibleParent() async throws {
        let tabs = generateTabs(count: 4)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        tabs[2].parent = tabs[0]
        manager.selectTab(tabs[2])

        TabGroupsTabActions(controller: controller, tabManager: manager).closeTabs([tabs[2]])

        XCTAssertEqual(manager.selectedTab?.tabUUID, tabs[0].tabUUID)
    }

    @MainActor
    func testClosingNormalTabPreservesPrivateSelectionWithoutSelectingNormalTab() async throws {
        let normalTabs = generateTabs(count: 2)
        let privateTab = try XCTUnwrap(generateTabs(ofType: .privateAny, count: 1).first)
        let manager = try await createInMemoryManager(tabs: normalTabs + [privateTab])
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        manager.selectTab(privateTab)
        mockThemeManager.setPrivateThemeCalls.removeAll()
        let observer = TabSelectionObserver()
        manager.addDelegate(observer)

        TabGroupsTabActions(controller: controller, tabManager: manager).closeTabs(normalTabs)

        XCTAssertEqual(manager.selectedTab?.tabUUID, privateTab.tabUUID)
        XCTAssertEqual(manager.privateTabs.map(\.tabUUID), [privateTab.tabUUID])
        XCTAssertTrue(manager.normalTabs.isEmpty)
        XCTAssertEqual(mockThemeManager.setPrivateThemeCalls, [true])
        XCTAssertTrue(try XCTUnwrap(observer.selections.first).previous === privateTab)
    }

    @MainActor
    func testClosingBackgroundTabPreservesSelectedNormalTabAfterIndexChanges() async throws {
        let tabs = generateTabs(count: 3)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        manager.selectTab(tabs[2])

        TabGroupsTabActions(controller: controller, tabManager: manager).closeTabs([tabs[0]])

        XCTAssertEqual(manager.selectedTab?.tabUUID, tabs[2].tabUUID)
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
        let observer = TabSelectionObserver()
        tabManager.addDelegate(observer)

        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs([tabs[0]])

        let visibleIDs = controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        XCTAssertEqual(controller.state.selectedGroupID, groupID)
        XCTAssertEqual(visibleIDs.count, 1)
        XCTAssertEqual(tabManager.selectedTab?.tabUUID, visibleIDs.first)
        XCTAssertTrue(try XCTUnwrap(observer.selections.first).previous === tabs[0])
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
    func testOpeningGroupSelectsItsExistingTabs() async throws {
        let tabs = generateTabs(count: 2)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        let id = try XCTUnwrap(controller.createGroup(name: "Saved",
                                                      tabIDs: [tabs[0].tabUUID],
                                                      normalTabIDs: tabs.map(\.tabUUID)))
        controller.selectGroup(id: nil)
        let host = try await TabGroupsTabActions(controller: controller, tabManager: manager).openGroup(id)
        XCTAssertEqual(host, manager.windowUUID)
        XCTAssertEqual(manager.normalTabs.map(\.tabUUID), tabs.map(\.tabUUID))
        XCTAssertEqual(manager.selectedTab?.tabUUID, tabs[0].tabUUID)
        XCTAssertEqual(controller.state.selectedGroupID, id)
        XCTAssertEqual(manager.normalTabs.filter { $0.groupID == id }.map(\.tabUUID), [tabs[0].tabUUID])
    }

    @MainActor
    func testOpeningRestoredEmptyGroupCreatesAndSelectsTabInGroup() async throws {
        let group = TabGroup(title: "Saved")
        await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group]))
        let tabs = generateTabs(count: 1)
        let manager = createSubject(tabs: tabs)
        manager.selectTab(tabs[0])
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)

        let host = try await TabGroupsTabActions(controller: controller, tabManager: manager).openGroup(group.id)

        XCTAssertEqual(host, manager.windowUUID)
        XCTAssertEqual(controller.state.selectedGroupID, group.id)
        XCTAssertEqual(manager.selectedTab?.groupID, group.id)
        XCTAssertEqual(manager.normalTabs.count, 2)
    }

    @MainActor
    func testOpeningUngroupedDestinationWithNoTabsCreatesAndSelectsUngroupedTab() async throws {
        let tabs = generateTabs(count: 1)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        let group = try XCTUnwrap(controller.createGroup(name: "Work",
                                                         tabIDs: tabs.map(\.tabUUID),
                                                         normalTabIDs: tabs.map(\.tabUUID)))
        manager.selectTab(tabs[0])

        _ = try await TabGroupsTabActions(controller: controller, tabManager: manager).openGroup(nil)

        XCTAssertNil(controller.state.selectedGroupID)
        XCTAssertNotNil(manager.selectedTab)
        XCTAssertNil(manager.selectedTab?.groupID)
        XCTAssertNotEqual(manager.selectedTab?.tabUUID, tabs[0].tabUUID)
        XCTAssertEqual(manager.tabGroupManager.tabIDs(in: group), [tabs[0].tabUUID])
    }

    @MainActor
    func testOpeningUngroupedDestinationRestoresRememberedSelection() async throws {
        let tabs = generateTabs(count: 3)
        let manager = try await createInMemoryManager(tabs: tabs)
        let controller = TabGroupsController(groupManager: manager.tabGroupManager,
                                             windowUUID: manager.windowUUID,
                                             tabManager: manager)
        let ids = tabs.map(\.tabUUID)
        controller.recordSelectedTab(ids[2], normalTabIDs: ids)
        _ = try XCTUnwrap(controller.createGroup(name: "Work", tabIDs: [ids[0]], normalTabIDs: ids))
        manager.selectTab(tabs[0])

        _ = try await TabGroupsTabActions(controller: controller, tabManager: manager).openGroup(nil)

        XCTAssertEqual(manager.selectedTab?.tabUUID, ids[2])
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

@MainActor
private final class TabSelectionObserver: TabManagerDelegate {
    struct Selection {
        let selected: Tab
        let previous: Tab?
    }

    private(set) var selections: [Selection] = []

    func tabManager(_ tabManager: TabManager,
                    didSelectedTabChange selectedTab: Tab,
                    previousTab: Tab?,
                    isRestoring: Bool) {
        selections.append(Selection(selected: selectedTab, previous: previousTab))
    }
}
