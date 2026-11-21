// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

final class TabGroupsTabCardMenuTests: TabManagerTestsBase {
    override func setUp() async throws {
        try await super.setUp()
        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: true) }
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.tabGroupsFeature.with { variables in TabGroupsFeature(variables) }
        try await super.tearDown()
    }

    @MainActor
    func testContextMenu_insertsMoveBeforeNonDestructiveCloseAndPreservesSharedActions() async throws {
        let (manager, controller) = try await makeFixture()
        _ = try manager.tabGroupManager.createGroup(title: "Work")
        let subject = createSubject(controller: controller)
        let bookmark = UIAction(title: .TabPeekAddToBookmarks) { _ in }
        let copy = UIAction(title: .TabPeekCopyUrl) { _ in }
        let close = UIAction(title: .TabPeekCloseTab) { _ in }
        let sharedMenu = UIMenu(title: "Shared", options: .displayInline, children: [bookmark, copy, close])

        let menu = subject.tabContextMenu(sharedMenu, for: manager.normalTabs[0].tabUUID)

        XCTAssertFalse(close.attributes.contains(.destructive))
        XCTAssertEqual(menu.children.count, 4)
        XCTAssertTrue(menu.children[0] === bookmark)
        XCTAssertTrue(menu.children[1] === copy)
        XCTAssertEqual((menu.children[2] as? UIMenu)?.title, String.TabGroups.MoveTab)
        XCTAssertTrue(menu.children[3] === close)
        XCTAssertEqual(menu.title, sharedMenu.title)
        XCTAssertEqual(menu.options, sharedMenu.options)
    }

    @MainActor
    func testContextMenu_withFeatureDisabled_returnsOriginalSharedMenu() async throws {
        let (manager, controller) = try await makeFixture()
        let subject = createSubject(controller: controller)
        let bookmark = UIAction(title: .TabPeekAddToBookmarks) { _ in }
        let copy = UIAction(title: .TabPeekCopyUrl) { _ in }
        let close = UIAction(title: .TabPeekCloseTab) { _ in }
        let sharedMenu = UIMenu(title: "Shared", children: [bookmark, copy, close])
        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: false) }

        let menu = subject.tabContextMenu(sharedMenu, for: manager.normalTabs[0].tabUUID)

        XCTAssertTrue(menu === sharedMenu)
        XCTAssertEqual(menu.children.count, 3)
        XCTAssertTrue(menu.children[0] === bookmark)
        XCTAssertTrue(menu.children[1] === copy)
        XCTAssertTrue(menu.children[2] === close)
    }

    @MainActor
    func testMoveAction_withoutGroups_offersDirectCreation() async throws {
        let (manager, controller) = try await makeFixture()
        let subject = createSubject(controller: controller)

        let action = try XCTUnwrap(subject.tabGroupMoveAction(for: manager.normalTabs[0].tabUUID) as? UIAction)

        XCTAssertEqual(action.title, String.TabGroups.MoveTabToNewGroup)
        XCTAssertNotNil(action.image)
    }

    @MainActor
    func testMoveAction_withGroups_containsCountedUngroupedDestinationAndColoredGroups() async throws {
        let (manager, controller) = try await makeFixture()
        let ids = manager.normalTabs.map(\.tabUUID)
        _ = controller.createGroup(name: "Houses", tabIDs: [ids[0]], normalTabIDs: ids)
        let subject = createSubject(controller: controller)

        let menu = try XCTUnwrap(subject.tabGroupMoveAction(for: ids[0]) as? UIMenu)
        let sections = menu.children.compactMap { $0 as? UIMenu }
        let actions = sections.flatMap { $0.children.compactMap { $0 as? UIAction } }

        XCTAssertEqual(menu.title, String.TabGroups.MoveTab)
        XCTAssertEqual(sections.map(\.children.count), [1, 1, 1])
        XCTAssertEqual(actions.map(\.title), [
            String(format: "%@ Tabs", 2.formatted()), "Houses", String.TabGroups.NewTabGroupMenu
        ])
        XCTAssertEqual(actions[0].state, .off)
        XCTAssertEqual(actions[1].state, .on)
        XCTAssertEqual(actions[1].image?.renderingMode, .alwaysOriginal)
    }

    @MainActor
    func testMoveAction_checksClickedTabsGroupRatherThanSelectedGroup() async throws {
        let (manager, controller) = try await makeFixture()
        let ids = manager.normalTabs.map(\.tabUUID)
        _ = controller.createGroup(name: "First", tabIDs: [ids[0]], normalTabIDs: ids)
        _ = controller.createGroup(name: "Second", tabIDs: [ids[1]], normalTabIDs: ids)
        let subject = createSubject(controller: controller)

        let actions = try destinationActions(subject, for: ids[0])

        XCTAssertEqual(actions.first { $0.title == "First" }?.state, .on)
        XCTAssertEqual(actions.first { $0.title == "Second" }?.state, .off)
    }

    @MainActor
    func testMoveAction_withoutFeatureControllerOrNormalTab_returnsNil() async throws {
        let (manager, controller) = try await makeFixture()
        let id = manager.normalTabs[0].tabUUID
        let normal = createSubject(controller: controller)
        let privatePanel = createSubject(controller: controller, panelType: .privateTabs)
        let privateTab = createSubject(controller: controller, containsPrivateTabs: true)
        let disconnected = createSubject(controller: nil)

        XCTAssertNil(privatePanel.tabGroupMoveAction(for: id))
        XCTAssertNil(privateTab.tabGroupMoveAction(for: id))
        XCTAssertNil(disconnected.tabGroupMoveAction(for: "tab"))
        XCTAssertNil(normal.tabGroupMoveAction(for: "missing"))

        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: false) }

        XCTAssertNil(normal.tabGroupMoveAction(for: id))
    }

    @MainActor
    func testMoveAction_disablesForeignAndUnrestoredGroupDestinations() async throws {
        let (manager, controller) = try await makeFixture()
        let ids = manager.normalTabs.map(\.tabUUID)
        _ = controller.createGroup(name: "Unrestored", tabIDs: [ids[0]], normalTabIDs: ids)
        manager.tabGroupManager.closeWindow(manager.windowUUID)
        let foreign = try manager.tabGroupManager.createGroup(title: "Other Window")
        _ = try manager.tabGroupManager.openGroup(foreign, in: UUID())
        _ = try manager.tabGroupManager.createGroup(title: "Empty")
        let subject = createSubject(controller: controller)

        let actions = try destinationActions(subject, for: ids[1])

        XCTAssertEqual(actions.first { $0.title == "Unrestored" }?.attributes, .disabled)
        XCTAssertEqual(actions.first { $0.title == "Other Window" }?.attributes, .disabled)
        XCTAssertEqual(actions.first { $0.title == "Empty" }?.attributes, [])
    }

    @available(iOS 16.0, *)
    @MainActor
    func testCreationAction_passesOriginalTabAndRechecksFlag() async throws {
        let (manager, controller) = try await makeFixture()
        let id = manager.normalTabs[0].tabUUID
        let subject = createSubject(controller: controller)
        var createdFor: [TabUUID] = []
        subject.onCreateGroupForTab = { createdFor.append($0) }
        let action = try XCTUnwrap(subject.tabGroupMoveAction(for: id) as? UIAction)

        action.performWithSender(nil, target: nil)
        FxNimbus.shared.features.tabGroupsFeature.with { _ in TabGroupsFeature(enabled: false) }
        action.performWithSender(nil, target: nil)

        XCTAssertEqual(createdFor, [id])
    }

    @available(iOS 16.0, *)
    @MainActor
    func testDestinationAction_currentGroupDoesNotMoveOrReorderTab() async throws {
        let (manager, controller) = try await makeFixture()
        let ids = manager.normalTabs.map(\.tabUUID)
        let current = try XCTUnwrap(controller.createGroup(name: "Current", tabIDs: ids, normalTabIDs: ids))
        let subject = createSubject(controller: controller)
        var moveCount = 0
        subject.onMoveTabToGroup = { _, _ in moveCount += 1 }
        let action = try XCTUnwrap(try destinationActions(subject, for: ids[0]).first { $0.title == "Current" })

        action.performWithSender(nil, target: nil)

        XCTAssertEqual(moveCount, 0)
        XCTAssertEqual(manager.tabGroupManager.tabIDs(in: current), ids)
    }

    @available(iOS 16.0, *)
    @MainActor
    func testDestinationAction_movesOriginalTabAndRechecksAvailability() async throws {
        let (manager, controller) = try await makeFixture()
        let id = manager.normalTabs[0].tabUUID
        let destination = try manager.tabGroupManager.createGroup(title: "Destination")
        let subject = createSubject(controller: controller)
        var movedTabIDs: [TabUUID] = []
        var movedGroupIDs: [TabGroupID?] = []
        subject.onMoveTabToGroup = { movedTabIDs.append($0); movedGroupIDs.append($1) }
        let action = try XCTUnwrap(try destinationActions(subject, for: id).first { $0.title == "Destination" })

        action.performWithSender(nil, target: nil)
        _ = try manager.tabGroupManager.openGroup(destination, in: UUID())
        action.performWithSender(nil, target: nil)

        XCTAssertEqual(movedTabIDs, [id])
        XCTAssertEqual(movedGroupIDs, [destination])
    }

    @MainActor
    func testSelectionMode_disablesCardGroupMenuAndSwipeClosure() async throws {
        let (manager, controller) = try await makeFixture()
        let subject = createSubject(controller: controller)
        let animator = SwipeAnimator(animatingView: UIView())

        XCTAssertTrue(subject.swipeAnimatorIsAnimateAwayEnabled(animator))

        subject.isSelectingTabs = true

        XCTAssertNil(subject.tabGroupMoveAction(for: manager.normalTabs[0].tabUUID))
        XCTAssertFalse(subject.swipeAnimatorIsAnimateAwayEnabled(animator))
    }

    @MainActor
    private func destinationActions(_ subject: TabDisplayView, for tabID: TabUUID) throws -> [UIAction] {
        let menu = try XCTUnwrap(subject.tabGroupMoveAction(for: tabID) as? UIMenu)
        return menu.children.compactMap { $0 as? UIMenu }.flatMap { $0.children.compactMap { $0 as? UIAction } }
    }

    @MainActor
    private func makeFixture() async throws -> (TabManagerImplementation, TabGroupsController) {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let manager = createSubject(tabs: generateTabs(count: 3), groupManager: groups)
        let controller = TabGroupsController(groupManager: groups, windowUUID: manager.windowUUID, tabManager: manager)
        trackForMemoryLeaks(controller)
        return (manager, controller)
    }

    @MainActor
    private func createSubject(controller: TabGroupsController?,
                               panelType: TabTrayPanelType = .tabs,
                               containsPrivateTabs: Bool = false,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabDisplayView {
        let ids = controller?.tabManager?.normalTabs.map(\.tabUUID) ?? ["tab"]
        let tabs = ids.map { TabModel.emptyState(tabUUID: $0, title: $0, isPrivate: containsPrivateTabs) }
        let state = TabsPanelState(windowUUID: .XCTestDefaultUUID,
                                   isPrivateMode: panelType == .privateTabs).copy(tabs: tabs)
        let subject = TabDisplayView(panelType: panelType,
                                     state: state,
                                     windowUUID: .XCTestDefaultUUID,
                                     tabTrayUtils: MockTabTrayUtils())
        subject.tabGroupsController = controller
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
