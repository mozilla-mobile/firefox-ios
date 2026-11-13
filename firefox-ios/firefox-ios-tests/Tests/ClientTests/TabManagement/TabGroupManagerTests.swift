// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
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
        let firstID = UUID().uuidString
        let secondID = UUID().uuidString
        let firstGroup = TabGroup(title: "First", tabIDs: [firstID, firstID])
        let secondGroup = TabGroup(title: "Second", tabIDs: [firstID, secondID])
        let storage = MockTabGroupStorage()
        await storage.setSnapshot(TabGroupSnapshot(groups: [firstGroup, secondGroup]))

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

    func testTabRemovalWhileLoadFailsIsAppliedAfterSuccessfulRetry() async throws {
        let removedID = UUID().uuidString
        let retainedID = UUID().uuidString
        let group = TabGroup(title: "Group", tabIDs: [removedID, retainedID])
        let unrelated = TabGroup(title: "Unrelated", tabIDs: [UUID().uuidString])
        let storage = MockTabGroupStorage()
        await storage.setSnapshot(TabGroupSnapshot(groups: [group, unrelated]))
        await storage.setFailure(load: true)
        let manager = TabGroupManager(storage: storage)
        do {
            try await manager.restore()
            XCTFail("Expected load failure")
        } catch {}

        manager.removeTab(removedID)
        do {
            try await manager.restore()
            XCTFail("Expected retry to fail while storage is unavailable")
        } catch {}
        let writesBeforeRecovery = await storage.savedSnapshots
        XCTAssertTrue(writesBeforeRecovery.isEmpty)

        await storage.setFailure()
        try await manager.restore()
        try await manager.flush()

        XCTAssertNil(manager.groupID(for: removedID))
        XCTAssertEqual(manager.groupID(for: retainedID), group.id)
        var expected = group
        expected.tabIDs = [retainedID]
        XCTAssertEqual(manager.groups, [expected, unrelated])
        let saved = await storage.snapshot
        XCTAssertEqual(saved.groups, [expected, unrelated])
    }

    func testMoveAndUngroupUpdatesLiveMembershipAndStoredIDs() async throws {
        let manager = try await makeManager()
        let first = try manager.createGroup(title: "First")
        let second = try manager.createGroup(title: "Second")
        let tab = makeTab()
        manager.bind(tab)
        try manager.moveTab(tab, to: first)
        try manager.moveTab(tab, to: second)
        XCTAssertEqual(tab.groupID, second)
        XCTAssertTrue(manager.tabIDs(in: first).isEmpty)
        XCTAssertEqual(manager.tabIDs(in: second), [tab.tabUUID])
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

    func testBulkMoveRejectsPrivateTabWithoutPartialMembershipChange() async throws {
        let manager = try await makeManager()
        let source = try manager.createGroup(title: "Source")
        let destination = try manager.createGroup(title: "Destination")
        let normalTab = makeTab()
        let privateTab = Tab(profile: MockProfile.unmanaged(), isPrivate: true, windowUUID: normalTab.windowUUID)
        manager.bind(normalTab)
        manager.bind(privateTab)
        try manager.moveTab(normalTab, to: source)

        XCTAssertThrowsError(try manager.moveTabs([normalTab, privateTab], to: destination))

        XCTAssertEqual(manager.tabIDs(in: source), [normalTab.tabUUID])
        XCTAssertTrue(manager.tabIDs(in: destination).isEmpty)
        XCTAssertEqual(normalTab.groupID, source)
        XCTAssertNil(privateTab.groupID)
        try await manager.flush()
    }

    func testBulkMoveCannotClaimUnrestoredGroup() async throws {
        let group = TabGroup(title: "Stored", tabIDs: [UUID().uuidString])
        let storage = MockTabGroupStorage()
        await storage.setSnapshot(TabGroupSnapshot(groups: [group]))
        let manager = try await makeManager(storage)
        let tab = makeTab()
        manager.bind(tab)

        XCTAssertThrowsError(try manager.moveTabs([tab], to: group.id))

        XCTAssertEqual(manager.tabIDs(in: group.id), group.tabIDs)
        XCTAssertNil(manager.activeWindow(for: group.id))
        XCTAssertNil(tab.groupID)
        let writes = await storage.savedSnapshots
        XCTAssertTrue(writes.isEmpty)
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
        manager.closeWindow(UUID())
        XCTAssertEqual(manager.activeWindow(for: group), window)
        try await manager.flush()
    }

    func testCloseWindowPreservesMetadataAndIDsAcrossColdLoad() async throws {
        let storage = MockTabGroupStorage()
        let manager = try await makeManager(storage)
        let group = try manager.createGroup(title: "Durable", color: CodableColor(red: 0.6, green: 0.2, blue: 0.8))
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
        XCTAssertEqual(restored.groups.first?.color, CodableColor(red: 0.6, green: 0.2, blue: 0.8))
        XCTAssertEqual(restored.tabIDs(in: group), [tab.tabUUID])
        XCTAssertThrowsError(try restored.openGroup(group, in: UUID()))
    }

    func testBindingRestoredIDsClaimsHostWithoutWritingMetadata() async throws {
        let storage = MockTabGroupStorage()
        let tab = makeTab()
        let group = TabGroup(title: "Stored", tabIDs: [tab.tabUUID])
        await storage.setSnapshot(TabGroupSnapshot(groups: [group]))
        let manager = try await makeManager(storage)
        XCTAssertThrowsError(try manager.openGroup(group.id, in: UUID()))

        manager.bind(tab)
        manager.bind(tab)

        XCTAssertEqual(tab.groupID, group.id)
        XCTAssertEqual(try manager.openGroup(group.id, in: tab.windowUUID), tab.windowUUID)
        let writes = await storage.savedSnapshots
        XCTAssertTrue(writes.isEmpty)
    }

    func testDeleteExplicitlyRemovesMetadataAndMembership() async throws {
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
        try manager.updateGroup(group, title: "Latest", color: CodableColor(red: 0.1, green: 0.8, blue: 0.3))
        manager.closeWindow(tab.windowUUID)
        await storage.resumeSave()
        try await manager.flush()
        let saves = await storage.savedSnapshots
        XCTAssertEqual(saves.count, 2)
        XCTAssertEqual(saves.last?.groups.first?.title, "Latest")
        XCTAssertEqual(saves.last?.groups.first?.tabIDs, [tab.tabUUID])
    }

    func testStoredMembershipLoadsWithoutTabRecords() async throws {
        let storage = MockTabGroupStorage()
        let tabID = UUID().uuidString
        let group = TabGroup(title: "Stored", tabIDs: [tabID])
        await storage.setSnapshot(TabGroupSnapshot(groups: [group]))

        let manager = try await makeManager(storage)

        XCTAssertTrue(manager.isLoaded)
        XCTAssertEqual(manager.groupID(for: tabID), group.id)
        XCTAssertEqual(manager.tabIDs(in: group.id), [tabID])
        XCTAssertNil(manager.activeWindow(for: group.id))
        let writes = await storage.savedSnapshots
        XCTAssertTrue(writes.isEmpty)
    }

    func testPrivateTabCannotRetainStoredMembership() async throws {
        let tab = Tab(profile: MockProfile.unmanaged(), isPrivate: true, windowUUID: UUID())
        let group = TabGroup(title: "Normal", tabIDs: [tab.tabUUID])
        let storage = MockTabGroupStorage()
        await storage.setSnapshot(TabGroupSnapshot(groups: [group]))
        let manager = try await makeManager(storage)

        manager.bind(tab)

        XCTAssertNil(tab.groupID)
        XCTAssertNil(manager.groupID(for: tab.tabUUID))
        XCTAssertTrue(manager.tabIDs(in: group.id).isEmpty)
        try await manager.flush()
    }

    func testReorderingPersistsMemberOrder() async throws {
        let manager = try await makeManager()
        let group = try manager.createGroup(title: "Ordered")
        let window = UUID()
        let first = makeTab(window: window)
        let second = makeTab(window: window)
        manager.bind(first)
        manager.bind(second)
        try manager.moveTab(first, to: group)
        try manager.moveTab(second, to: group)
        manager.reorderTabs([second.tabUUID, first.tabUUID], in: window)
        XCTAssertEqual(manager.tabIDs(in: group), [second.tabUUID, first.tabUUID])
        try await manager.flush()
    }

    func testWindowMergeMovesOwnershipWithUnrestoredMemberIDs() async throws {
        let tab = makeTab()
        let group = TabGroup(title: "Stored", tabIDs: [tab.tabUUID, UUID().uuidString])
        let storage = MockTabGroupStorage()
        await storage.setSnapshot(TabGroupSnapshot(groups: [group]))
        let manager = try await makeManager(storage)
        manager.bind(tab)
        let destination = UUID()

        manager.moveGroupsForWindowMerge([tab.tabUUID], to: destination)

        XCTAssertEqual(manager.activeWindow(for: group.id), destination)
        XCTAssertEqual(manager.tabIDs(in: group.id), group.tabIDs)
        let writes = await storage.savedSnapshots
        XCTAssertTrue(writes.isEmpty)
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
