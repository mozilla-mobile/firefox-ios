// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import TabDataStore
@testable import Client

@MainActor
final class TabGroupManagerTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: MockProfile.unmanaged())
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    private func makeManager(_ storage: MockTabGroupStorage = MockTabGroupStorage()) async throws -> TabGroupManager {
        let manager = TabGroupManager(storage: storage)
        try await manager.restore()
        return manager
    }

    private func makeTab(window: UUID = UUID()) -> Tab {
        let tab = Tab(profile: MockProfile.unmanaged(), windowUUID: window)
        tab.url = URL(string: "https://example.com")
        return tab
    }

    func testLoadOnceAndNoWritesForReading() async throws {
        let storage = MockTabGroupStorage()
        let manager = try await makeManager(storage)
        try await manager.restore()
        let count = await storage.loadCount
        let writes = await storage.savedSnapshots
        XCTAssertEqual(count, 1)
        XCTAssertTrue(writes.isEmpty)
        XCTAssertTrue(manager.groups.isEmpty)
    }

    func testRestore_whenTabAppearsInMultipleGroups_keepsFirstMembership() async throws {
        let firstTab = makeTab().dataForSaving()
        let secondTab = makeTab().dataForSaving()
        let firstID = firstTab.id.uuidString
        let secondID = secondTab.id.uuidString
        let firstGroup = TabGroup(title: "First", tabIDs: [firstID, firstID])
        let secondGroup = TabGroup(title: "Second", tabIDs: [firstID, secondID])
        let storage = MockTabGroupStorage()
        await storage.setSnapshot(TabGroupSnapshot(groups: [firstGroup, secondGroup], tabs: [firstTab, secondTab]))

        let manager = try await makeManager(storage)

        XCTAssertEqual(manager.tabIDs(in: firstGroup.id), [firstID])
        XCTAssertEqual(manager.tabIDs(in: secondGroup.id), [secondID])
        XCTAssertEqual(manager.groupID(for: firstID), firstGroup.id)
        XCTAssertEqual(manager.groupID(for: secondID), secondGroup.id)
    }

    func testMutationsRequireSuccessfulLoad() async throws {
        let storage = MockTabGroupStorage()
        await storage.setFailure(load: true)
        let manager = TabGroupManager(storage: storage)
        do {
            try await manager.restore()
            XCTFail("Expected load failure")
        } catch {}
        XCTAssertThrowsError(try manager.createGroup(title: "Unsafe overwrite"))
        let writes = await storage.savedSnapshots
        XCTAssertTrue(writes.isEmpty)
        await storage.setFailure()
        try await manager.restore()
        XCTAssertTrue(manager.isLoaded)
    }

    func testMoveAndUngroupUpdatesLiveMembershipAndSavedRecords() async throws {
        let manager = try await makeManager()
        let first = try manager.createGroup(title: "First")
        let second = try manager.createGroup(title: "Second")
        let tab = makeTab()
        manager.bind(tab)
        try manager.moveTab(tab, to: first)
        try manager.moveTab(tab, to: second)
        XCTAssertEqual(tab.groupID, second)
        XCTAssertTrue(manager.tabIDs(in: first).isEmpty)
        XCTAssertEqual(try manager.tabs(in: second).first?.siteUrl, "https://example.com")
        try manager.moveTab(tab, to: nil)
        XCTAssertNil(tab.groupID)
        XCTAssertTrue(manager.persistedTabIDs.isEmpty)
        XCTAssertEqual(manager.groups.count, 2)
        try await manager.flush()
    }

    func testBulkMoveKeepsUniqueOrderedMembership() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Work")
        let first = makeTab()
        let second = makeTab(window: first.windowUUID)
        manager.bind(first)
        manager.bind(second)
        try manager.moveTabs([first, second, first], to: group)
        XCTAssertEqual(manager.tabIDs(in: group), [first.tabUUID, second.tabUUID])
        XCTAssertEqual(first.groupID, group)
        XCTAssertEqual(second.groupID, group)
        try await manager.flush()
    }

    func testBulkMoveRejectsTabsFromDifferentWindows() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Work")
        let first = makeTab()
        let second = makeTab()
        manager.bind(first)
        manager.bind(second)
        XCTAssertThrowsError(try manager.moveTabs([first, second], to: group))
        XCTAssertTrue(manager.tabIDs(in: group).isEmpty)
        XCTAssertNil(manager.activeWindow(for: group))
        XCTAssertNil(first.groupID)
        XCTAssertNil(second.groupID)
        try await manager.flush()
    }

    func testGroupCanOnlyBeActiveInOneWindow() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Shared")
        let firstWindow = UUID()
        let secondWindow = UUID()
        XCTAssertEqual(try manager.openGroup(group, in: firstWindow), firstWindow)
        XCTAssertEqual(try manager.openGroup(group, in: secondWindow), firstWindow)
        XCTAssertEqual(manager.activeWindow(for: group), firstWindow)
        let tab = makeTab(window: secondWindow)
        manager.bind(tab)
        XCTAssertThrowsError(try manager.moveTab(tab, to: group))
        XCTAssertNil(tab.groupID)
        try await manager.flush()
    }

    func testClosingWrongWindowDoesNotReleaseGroup() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Shared")
        let window = UUID()
        _ = try manager.openGroup(group, in: window)
        manager.closeGroup(group, in: UUID())
        manager.closeWindow(UUID())
        XCTAssertEqual(manager.activeWindow(for: group), window)
        try await manager.flush()
    }

    func testCloseWindowPreservesGroupAndTabsAcrossColdLoad() async throws {
        let storage = MockTabGroupStorage()
        let manager = try await makeManager(storage)
        let group = try manager.createGroup(title: "Durable", color: .purple)
        let tab = makeTab()
        manager.bind(tab)
        try manager.moveTab(tab, to: group)
        manager.closeWindow(tab.windowUUID)
        XCTAssertNil(manager.activeWindow(for: group))
        XCTAssertEqual(manager.groupID(for: tab.tabUUID), group)
        XCTAssertNil(tab.groupID)
        XCTAssertThrowsError(try manager.moveTab(tab, to: nil))
        try await manager.flush()
        let restored = try await makeManager(storage)
        XCTAssertNil(restored.activeWindow(for: group))
        XCTAssertEqual(restored.groups.first?.color, .purple)
        XCTAssertEqual(try restored.tabs(in: group).first?.id.uuidString, tab.tabUUID)
        let newWindow = UUID()
        XCTAssertEqual(try restored.openGroup(group, in: newWindow), newWindow)
    }

    func testCloseGroupPreservesSavedTabsAndAllowsAnotherWindow() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Durable")
        let tab = makeTab()
        manager.bind(tab)
        try manager.moveTab(tab, to: group)
        manager.closeGroup(group, in: tab.windowUUID)
        XCTAssertEqual(manager.groups.count, 1)
        XCTAssertEqual(try manager.tabs(in: group).count, 1)
        let destination = UUID()
        XCTAssertEqual(try manager.openGroup(group, in: destination), destination)
        try await manager.flush()
    }

    func testDeleteExplicitlyRemovesMetadataMembershipAndRecords() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Delete")
        let tab = makeTab()
        manager.bind(tab)
        try manager.moveTab(tab, to: group)
        try manager.deleteGroup(group)
        XCTAssertNil(tab.groupID)
        XCTAssertTrue(manager.groups.isEmpty)
        XCTAssertTrue(manager.persistedTabIDs.isEmpty)
        XCTAssertNil(manager.activeWindow(for: group))
        try await manager.flush()
    }

    func testRemovingLastTabKeepsEmptyGroup() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Keep")
        let tab = makeTab()
        manager.bind(tab)
        try manager.moveTab(tab, to: group)
        manager.removeTab(tab.tabUUID)
        XCTAssertEqual(manager.groups.count, 1)
        XCTAssertTrue(manager.tabIDs(in: group).isEmpty)
        XCTAssertNil(tab.groupID)
        try await manager.flush()
    }

    func testPrivateAndUnboundTabsAreRejected() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Normal")
        let privateTab = Tab(profile: MockProfile.unmanaged(), isPrivate: true, windowUUID: UUID())
        manager.bind(privateTab)
        XCTAssertThrowsError(try manager.moveTab(privateTab, to: group))
        XCTAssertThrowsError(try manager.moveTab(makeTab(), to: group))
        XCTAssertTrue(manager.persistedTabIDs.isEmpty)
        try await manager.flush()
    }

    func testUnknownGroupDoesNotChangeExistingMembership() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Keep")
        let tab = makeTab()
        manager.bind(tab)
        try manager.moveTab(tab, to: group)
        XCTAssertThrowsError(try manager.moveTab(tab, to: UUID()))
        XCTAssertEqual(tab.groupID, group)
        try await manager.flush()
    }

    func testSaveFailureRetainsLiveStateAndFlushRetries() async throws {
        let storage = MockTabGroupStorage()
        let manager = try await makeManager(storage)
        await storage.setFailure(save: true)
        let group = try manager.createGroup(title: "Retry")
        do {
            try await manager.flush()
            XCTFail("Expected save failure")
        } catch {}
        XCTAssertEqual(manager.groups.first?.id, group)
        XCTAssertNotNil(manager.lastPersistenceError)
        await storage.setFailure()
        try await manager.flush()
        let saved = await storage.snapshot
        XCTAssertEqual(saved.groups.first?.id, group)
        XCTAssertNil(manager.lastPersistenceError)
    }

    func testWritesAreSerializedAndKeepLatestSnapshot() async throws {
        let storage = MockTabGroupStorage()
        let manager = try await makeManager(storage)
        await storage.suspendNextSave()
        let group = try manager.createGroup(title: "Initial")
        await storage.waitUntilSaving()
        let tab = makeTab()
        manager.bind(tab)
        try manager.moveTab(tab, to: group)
        try manager.updateGroup(group, title: "Latest", color: .green)
        manager.closeWindow(tab.windowUUID)
        await storage.resumeSave()
        try await manager.flush()
        let saves = await storage.savedSnapshots
        XCTAssertEqual(saves.count, 2)
        XCTAssertEqual(saves.last?.groups.first?.title, "Latest")
        XCTAssertEqual(saves.last?.groups.first?.tabIDs, [tab.tabUUID])
        XCTAssertEqual(saves.last?.tabs.first?.id.uuidString, tab.tabUUID)
    }

    func testMissingSavedTabFailsLoadWithoutOverwritingData() async throws {
        let storage = MockTabGroupStorage()
        await storage.setSnapshot(TabGroupSnapshot(groups: [TabGroup(title: "Missing", tabIDs: [UUID().uuidString])]))
        let manager = TabGroupManager(storage: storage)
        do {
            try await manager.restore()
            XCTFail("Expected invalid snapshot")
        } catch {}
        XCTAssertFalse(manager.isLoaded)
        XCTAssertThrowsError(try manager.createGroup(title: "Overwrite"))
        let writes = await storage.savedSnapshots
        XCTAssertTrue(writes.isEmpty)
    }

    func testReorderingPersistsOrderAndPreservingTabsKeepsLatestPageState() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Ordered")
        let window = UUID()
        let first = makeTab(window: window)
        let second = makeTab(window: window)
        manager.bind(first)
        manager.bind(second)
        try manager.moveTab(first, to: group)
        try manager.moveTab(second, to: group)
        first.url = URL(string: "https://example.com/latest")
        manager.reorderTabs([second.tabUUID, first.tabUUID], in: window)
        manager.preserveTabs([first.dataForSaving(), second.dataForSaving()], in: window)
        XCTAssertEqual(manager.tabIDs(in: group), [second.tabUUID, first.tabUUID])
        XCTAssertEqual(try manager.tabs(in: group).last?.siteUrl, "https://example.com/latest")
        try await manager.flush()
    }

    func testMembershipLookupDoesNotRetainManager() async throws {
        let storage = MockTabGroupStorage()
        var manager: TabGroupManager? = try await makeManager(storage)
        weak var weakManager = manager
        let tab = makeTab()
        manager?.bind(tab)
        manager = nil
        XCTAssertNil(weakManager)
        XCTAssertNil(tab.groupID)
    }
}
