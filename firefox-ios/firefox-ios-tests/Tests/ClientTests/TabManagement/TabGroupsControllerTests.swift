// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TabGroupsControllerTests: TabManagerTestsBase {
    @MainActor
    private func fixture() async throws -> (TabManagerImplementation, TabGroupsController) {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let tabs = generateTabs(count: 3)
        let manager = createSubject(tabs: tabs, groupManager: groups)
        let controller = TabGroupsController(groupManager: groups, windowUUID: manager.windowUUID, tabManager: manager)
        return (manager, controller)
    }

    @MainActor
    func testMembershipUsesDurableManagerAndLiveTabGroupID() async throws {
        let (manager, controller) = try await fixture()
        let tabs = manager.normalTabs
        let ids = tabs.map(\.tabUUID)
        let first = try XCTUnwrap(controller.createGroup(name: "First", tabIDs: [ids[0]], normalTabIDs: ids))
        let second = try XCTUnwrap(controller.createGroup(name: "Second", normalTabIDs: ids))
        controller.moveTabs([ids[0], ids[0]], to: second, normalTabIDs: ids)
        XCTAssertEqual(manager.tabGroupManager.tabIDs(in: first), [])
        XCTAssertEqual(tabs[0].groupID, second)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: ids), [ids[0]])
        controller.assignTab(ids[0], to: nil, normalTabIDs: ids)
        controller.selectGroup(id: nil)
        XCTAssertNil(tabs[0].groupID)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: ids), ids)
    }

    @MainActor
    func testReconcileDoesNotRemoveClosedGroupTabs() async throws {
        let (manager, controller) = try await fixture()
        let tabs = manager.normalTabs
        let ids = tabs.map(\.tabUUID)
        let id = try XCTUnwrap(controller.createGroup(name: "Saved", tabIDs: [ids[0]], normalTabIDs: ids))
        manager.closeTabGroup(id)
        controller.reconcile(normalTabIDs: manager.normalTabs.map(\.tabUUID))
        XCTAssertEqual(manager.tabGroupManager.tabIDs(in: id), [ids[0]])
        XCTAssertNil(controller.state.selectedGroupID)
        _ = try await manager.openTabGroup(id)
        controller.selectGroup(id: id)
        XCTAssertEqual(controller.visibleTabIDs(normalTabIDs: manager.normalTabs.map(\.tabUUID)), [ids[0]])
    }

    @MainActor
    func testUngroupPreservesTabsAndDeleteRemovesThem() async throws {
        let (manager, controller) = try await fixture()
        let tabs = manager.normalTabs
        let ids = tabs.map(\.tabUUID)
        let id = try XCTUnwrap(controller.createGroup(name: "First", tabIDs: [ids[0]], normalTabIDs: ids))
        controller.ungroup(id: id)
        XCTAssertEqual(manager.normalTabs.count, 3)
        XCTAssertNil(tabs[0].groupID)
        let deleted = try XCTUnwrap(controller.createGroup(name: "Second", tabIDs: [ids[0]], normalTabIDs: ids))
        controller.deleteGroup(id: deleted)
        XCTAssertFalse(manager.normalTabs.contains { $0.tabUUID == ids[0] })
        XCTAssertTrue(manager.tabGroupManager.groups.isEmpty)
    }

    @MainActor
    func testAppearanceAndOrderArePersisted() async throws {
        let (manager, controller) = try await fixture()
        _ = try XCTUnwrap(controller.createGroup(name: "First", normalTabIDs: []))
        let second = try XCTUnwrap(controller.createGroup(name: "Second", normalTabIDs: []))
        controller.updateGroup(id: second, name: " Work ", emoji: "💼", color: .green)
        controller.moveGroups(fromOffsets: IndexSet(integer: 0), toOffset: 2)
        try await manager.tabGroupManager.flush()
        let restored = TabGroupManager(storage: mockGroupStorage)
        try await restored.restore()
        XCTAssertEqual(restored.groups.map(\.title), ["Work", "First"])
        XCTAssertEqual(restored.groups.first?.emoji, "💼")
        XCTAssertEqual(restored.groups.first?.color, .green)
    }

    @MainActor
    func testInvalidNameAndPrivateMembershipAreRejected() async throws {
        let (manager, controller) = try await fixture()
        let tabs = manager.normalTabs
        XCTAssertNil(controller.createGroup(name: "  ", normalTabIDs: []))
        let privateTab = manager.addTab(nil, isPrivate: true)
        let id = try XCTUnwrap(controller.createGroup(name: "Work",
                                                      tabIDs: [privateTab.tabUUID],
                                                      normalTabIDs: tabs.map(\.tabUUID)))
        XCTAssertTrue(manager.tabGroupManager.tabIDs(in: id).isEmpty)
        XCTAssertNil(privateTab.groupID)
    }

    @MainActor
    func testSelectionRemainsLocalAndAnotherWindowCannotTakeGroup() async throws {
        let (manager, first) = try await fixture()
        let tabs = manager.normalTabs
        let secondManager = createSubject(windowUUID: UUID(), groupManager: manager.tabGroupManager)
        let second = TabGroupsController(groupManager: manager.tabGroupManager,
                                         windowUUID: secondManager.windowUUID,
                                         tabManager: secondManager)
        let id = try XCTUnwrap(first.createGroup(name: "Work",
                                                 tabIDs: [tabs[0].tabUUID],
                                                 normalTabIDs: tabs.map(\.tabUUID)))
        let host = try await secondManager.openTabGroup(id)
        second.selectGroup(id: id)
        XCTAssertEqual(host, manager.windowUUID)
        XCTAssertNil(second.state.selectedGroupID)
        XCTAssertEqual(first.state.selectedGroupID, id)
        XCTAssertEqual(second.state.groups, first.state.groups)
        XCTAssertTrue(secondManager.normalTabs.isEmpty)
    }

    @MainActor
    func testBulkMoveRejectsAnotherWindowWithoutPartialMembershipChange() async throws {
        let (manager, controller) = try await fixture()
        let tabs = manager.normalTabs
        let ids = tabs.map(\.tabUUID)
        let source = try XCTUnwrap(controller.createGroup(name: "Source", tabIDs: [ids[0]], normalTabIDs: ids))
        let destination = try manager.tabGroupManager.createGroup(title: "Elsewhere")
        _ = try manager.tabGroupManager.openGroup(destination, in: UUID())
        controller.moveTabs([ids[0], ids[1]], to: destination, normalTabIDs: ids)
        XCTAssertEqual(tabs[0].groupID, source)
        XCTAssertNil(tabs[1].groupID)
        XCTAssertEqual(controller.state.selectedGroupID, source)
    }
}
