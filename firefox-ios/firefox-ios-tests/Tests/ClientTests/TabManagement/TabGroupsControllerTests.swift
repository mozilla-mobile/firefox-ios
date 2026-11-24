// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
    func testSwitchingDestinationsPreservesGroupMembershipAndTabs() async throws {
        let (manager, controller) = try await fixture()
        let tabs = manager.normalTabs
        let ids = tabs.map(\.tabUUID)
        let id = try XCTUnwrap(controller.createGroup(name: "Saved", tabIDs: [ids[0]], normalTabIDs: ids))
        controller.selectGroup(id: nil)
        controller.reconcile(normalTabIDs: manager.normalTabs.map(\.tabUUID))
        XCTAssertEqual(manager.tabGroupManager.tabIDs(in: id), [ids[0]])
        XCTAssertNil(controller.state.selectedGroupID)
        XCTAssertEqual(manager.normalTabs.map(\.tabUUID), ids)
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
    func testUpdateGroup_persistsIconColorAndOrder() async throws {
        let (manager, controller) = try await fixture()
        _ = try XCTUnwrap(controller.createGroup(name: "First", normalTabIDs: []))
        let second = try XCTUnwrap(controller.createGroup(name: "Second", normalTabIDs: []))
        let color = CodableColor(red: 0.20, green: 0.62, blue: 0.32)
        controller.updateGroup(id: second, name: " Work ", icon: .sfSymbol("bag.fill"), color: color)
        try await manager.tabGroupManager.flush()
        let restored = TabGroupManager(storage: mockGroupStorage)
        try await restored.restore()
        XCTAssertEqual(restored.groups.map(\.title), ["First", "Work"])
        XCTAssertEqual(restored.groups.last?.icon, .sfSymbol("bag.fill"))
        XCTAssertEqual(restored.groups.last?.color, color)
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

    @MainActor
    func testMoveAvailabilityAllowsUngroupedLocalAndEmptyUnownedGroups() async throws {
        let (manager, controller) = try await fixture()
        let ids = manager.normalTabs.map(\.tabUUID)
        let local = try XCTUnwrap(controller.createGroup(name: "Local", tabIDs: [ids[0]], normalTabIDs: ids))
        let empty = try manager.tabGroupManager.createGroup(title: "Empty")

        XCTAssertTrue(controller.canMoveTabs(to: nil))
        XCTAssertTrue(controller.canMoveTabs(to: local))
        XCTAssertTrue(controller.canMoveTabs(to: empty))
        XCTAssertFalse(controller.canMoveTabs(to: UUID()))
    }

    @MainActor
    func testMoveAvailabilityTracksEmptyGroupWindowOwnership() async throws {
        let (manager, controller) = try await fixture()
        let group = try manager.tabGroupManager.createGroup(title: "Elsewhere")
        let otherWindow = UUID()
        _ = try manager.tabGroupManager.openGroup(group, in: otherWindow)
        XCTAssertFalse(controller.canMoveTabs(to: group))

        manager.tabGroupManager.closeWindow(otherWindow)
        XCTAssertTrue(controller.canMoveTabs(to: group))

        try manager.tabGroupManager.deleteGroup(group)
        XCTAssertFalse(controller.canMoveTabs(to: group))
    }

    @MainActor
    func testMoveAvailabilityRejectsUnownedGroupWhoseTabsHaveNotRestored() async throws {
        let (manager, controller) = try await fixture()
        let ids = manager.normalTabs.map(\.tabUUID)
        let group = try XCTUnwrap(controller.createGroup(name: "Saved", tabIDs: [ids[0]], normalTabIDs: ids))
        manager.tabGroupManager.closeWindow(manager.windowUUID)

        XCTAssertNil(manager.tabGroupManager.activeWindow(for: group))
        XCTAssertFalse(controller.canMoveTabs(to: group))
        XCTAssertEqual(manager.tabGroupManager.tabIDs(in: group), [ids[0]])
    }
}
