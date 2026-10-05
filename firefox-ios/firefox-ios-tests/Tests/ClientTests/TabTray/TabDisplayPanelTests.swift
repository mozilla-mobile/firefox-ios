// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import TabDataStore

@testable import Client
final class TabDisplayPanelTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func testIsPrivateTabsEmpty() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: true)

        XCTAssertTrue(subject.tabsState.isPrivateTabsEmpty)
    }

    @MainActor
    func testIsPrivateTabsNotEmpty() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: false)

        XCTAssertFalse(subject.tabsState.isPrivateTabsEmpty)
    }

    @MainActor
    func testNormalPanelShowsOnlySelectedGroupTabs() async throws {
        let delegate = MockTabDisplayViewDragAndDropInteraction()
        let subject = TabDisplayPanelViewController(isPrivateMode: false,
                                                    windowUUID: .XCTestDefaultUUID,
                                                    dragAndDropDelegate: delegate)
        let ids = (0..<2).map { _ in UUID().uuidString }
        let controller = try await groupController(tabIDs: [ids[0]])
        subject.tabGroupsController = controller
        let state = TabsPanelState(windowUUID: .XCTestDefaultUUID, isPrivateMode: false)
            .copy(tabs: [TabModel.emptyState(tabUUID: ids[0], title: "A"),
                         TabModel.emptyState(tabUUID: ids[1], title: "B")])

        subject.newState(state: state)

        XCTAssertEqual(subject.tabDisplayView.tabsState.tabs.map(\.tabUUID), [ids[0]])
    }

    @MainActor
    func testGroupScrollTargetUsesVisibleIndex() async throws {
        let delegate = MockTabDisplayViewDragAndDropInteraction()
        let subject = TabDisplayPanelViewController(isPrivateMode: false,
                                                    windowUUID: .XCTestDefaultUUID,
                                                    dragAndDropDelegate: delegate)
        let ids = (0..<4).map { _ in UUID().uuidString }
        let controller = try await groupController(tabIDs: [ids[1], ids[3]])
        subject.tabGroupsController = controller
        let state = TabsPanelState(windowUUID: .XCTestDefaultUUID, isPrivateMode: false)
            .copy(tabs: [TabModel.emptyState(tabUUID: ids[0], title: "A"),
                         TabModel.emptyState(tabUUID: ids[1], title: "B"),
                         TabModel.emptyState(tabUUID: ids[2], title: "C"),
                         TabModel.emptyState(tabUUID: ids[3], title: "D")])
        subject.newState(state: state)

        XCTAssertEqual(subject.tabDisplayView.translatedScrollState(.init(toIndex: 3, withAnimation: false)),
                       .init(toIndex: 1, withAnimation: false))
        XCTAssertNil(subject.tabDisplayView.translatedScrollState(.init(toIndex: 0, withAnimation: false)))
    }

    @MainActor
    private func groupController(tabIDs: [TabUUID]) async throws -> TabGroupsController {
        let profile = makeProfile()
        let records = tabIDs.map { id in
            let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
            tab.tabUUID = id
            return tab.dataForSaving()
        }
        let storage = MockTabGroupStorage()
        let group = TabGroup(title: "Work", tabIDs: tabIDs)
        await storage.setSnapshot(TabGroupSnapshot(groups: [group], tabs: records))
        let manager = TabGroupManager(storage: storage)
        try await manager.restore()
        _ = try manager.openGroup(group.id, in: .XCTestDefaultUUID)
        let controller = TabGroupsController(groupManager: manager, windowUUID: .XCTestDefaultUUID)
        controller.selectGroup(id: group.id)
        return controller
    }

    // MARK: - Private
    @MainActor
    private func createSubject(isPrivateMode: Bool,
                               emptyTabs: Bool,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabDisplayPanelViewController {
        let subjectState = createSubjectState(isPrivateMode: isPrivateMode,
                                              emptyTabs: emptyTabs)
        let delegate = MockTabDisplayViewDragAndDropInteraction()
        let subject = TabDisplayPanelViewController(isPrivateMode: isPrivateMode,
                                                    windowUUID: .XCTestDefaultUUID,
                                                    dragAndDropDelegate: delegate)
        subject.newState(state: subjectState)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createSubjectState(isPrivateMode: Bool,
                                    emptyTabs: Bool) -> TabsPanelState {
        let tabs = createTabs(emptyTabs)
        return TabsPanelState(windowUUID: .XCTestDefaultUUID, isPrivateMode: isPrivateMode)
            .copy(tabs: tabs)
    }

    private func createTabs(_ emptyTabs: Bool) -> [TabModel] {
        guard !emptyTabs else { return [TabModel]() }

        var tabs = [TabModel]()
        for index in 0...2 {
            let tabModel = TabModel.emptyState(tabUUID: "UUID", title: "Tab \(index)")
            tabs.append(tabModel)
        }
        return tabs
    }
}
