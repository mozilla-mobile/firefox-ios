// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import TabDataStore
@testable import Client

final class TabManagerGroupMembershipTests: TabManagerTestsBase {
    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.removeObject(forKey: "SettingsBundleSkipSessionRestore")
    }

    @MainActor
    func testOneShotCreationAndPopupInheritMembershipBeforeCallback() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Group")
        let observer = MembershipObserver()
        subject.addDelegate(observer)
        let tab = subject.addTab(URLRequest(url: URL(string: "https://example.com")!), zombie: true, groupID: group)
        XCTAssertEqual(observer.added.last?.groupID, group)
        XCTAssertEqual(tab.groupID, group)
        try await subject.tabGroupManager.flush()
    }

    @MainActor
    func testCloseGroupRetainsRecordsAndRestoresInAnotherWindow() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Durable")
        let tab = subject.addTab(URLRequest(url: URL(string: "https://example.com")!), zombie: true, groupID: group)
        let secondTab = subject.addTab(zombie: true, groupID: group)
        let tabID = tab.tabUUID
        subject.closeTabGroup(group)
        XCTAssertFalse(subject.tabs.contains(where: { $0.tabUUID == tabID }))
        XCTAssertFalse(subject.tabs.contains(secondTab))
        XCTAssertEqual(subject.tabGroupManager.groups.count, 1)
        XCTAssertNil(subject.tabGroupManager.activeWindow(for: group))
        try await subject.tabGroupManager.flush()

        let destination = UUID()
        let second = createSubject(windowUUID: destination, groupManager: subject.tabGroupManager)
        let host = try await second.openTabGroup(group)
        XCTAssertEqual(host, destination)
        let restored = try XCTUnwrap(second.tabs.first(where: { $0.tabUUID == tabID }))
        XCTAssertEqual(restored.url?.absoluteString, "https://example.com")
        XCTAssertEqual(restored.groupID, group)
        XCTAssertEqual(restored.windowUUID, destination)
        XCTAssertEqual(second.tabs.map(\.tabUUID), [tabID, secondTab.tabUUID])
        try await subject.tabGroupManager.flush()
    }

    @MainActor
    func testWindowMergePreservesGroupMembershipAndLatestSavedURL() async throws {
        let source = createSubject()
        try await source.tabGroupManager.restore()
        let group = try source.tabGroupManager.createGroup(title: "Work")
        let tab = source.addTab(URLRequest(url: URL(string: "https://example.com/first")!),
                                zombie: true,
                                groupID: group)
        tab.url = URL(string: "https://example.com/latest")
        let target = createSubject(windowUUID: UUID(), groupManager: source.tabGroupManager)
        let sourceUUID = source.windowUUID
        let sourceSaved = expectation(description: "Emptied source window saved")
        mockTabStore.onSave = { window in
            if window.id == sourceUUID {
                XCTAssertTrue(window.tabData.isEmpty)
                sourceSaved.fulfill()
            }
        }
        target.addTabs(fromWindowMergeData: source.tabDataForWindowMerge())
        source.discardTabsMovedToAnotherWindow()
        source.prepareForWindowClose()
        let moved = try XCTUnwrap(target.tabs.first { $0.tabUUID == tab.tabUUID })
        XCTAssertEqual(moved.groupID, group)
        XCTAssertEqual(moved.url?.absoluteString, "https://example.com/latest")
        XCTAssertEqual(source.tabGroupManager.activeWindow(for: group), target.windowUUID)
        XCTAssertEqual(source.tabGroupManager.tabIDs(in: group), [tab.tabUUID])
        await fulfillment(of: [sourceSaved], timeout: 5)
        try await source.tabGroupManager.flush()
    }

    @MainActor
    func testColdReopenDoesNotNeedOriginalWindowData() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Cold")
        let tab = subject.addTab(URLRequest(url: URL(string: "https://example.com/saved")!), zombie: true, groupID: group)
        subject.prepareForWindowClose()
        try await subject.tabGroupManager.flush()
        mockTabStore.fetchTabWindowData = nil
        let coldManager = TabGroupManager(storage: mockGroupStorage)
        let second = createSubject(windowUUID: UUID(), groupManager: coldManager)
        _ = try await second.openTabGroup(group)
        XCTAssertEqual(second.tabs.first?.tabUUID, tab.tabUUID)
        XCTAssertEqual(second.tabs.first?.url?.absoluteString, "https://example.com/saved")
        XCTAssertEqual(mockTabStore.fetchWindowDataCalledCount, 0)
        try await coldManager.flush()
    }

    @MainActor
    func testOpeningAlreadyActiveGroupReturnsHostWithoutChangingOtherWindow() async throws {
        let first = createSubject()
        try await first.tabGroupManager.restore()
        let group = try first.tabGroupManager.createGroup(title: "Active")
        let tab = first.addTab(zombie: true, groupID: group)
        let second = createSubject(windowUUID: UUID(), groupManager: first.tabGroupManager)
        let otherTab = second.addTab(zombie: true)
        second.selectTab(otherTab)
        let host = try await second.openTabGroup(group)
        XCTAssertEqual(host, first.windowUUID)
        XCTAssertEqual(second.tabs, [otherTab])
        XCTAssertEqual(second.selectedTab, otherTab)
        XCTAssertEqual(first.tabs, [tab])
        try await first.tabGroupManager.flush()
    }

    @MainActor
    func testRepeatedOpenDoesNotDuplicateTabs() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Open")
        let tab = subject.addTab(zombie: true, groupID: group)
        _ = try await subject.openTabGroup(group)
        _ = try await subject.openTabGroup(group)
        XCTAssertEqual(subject.tabs.filter { $0.tabUUID == tab.tabUUID }.count, 1)
        try await subject.tabGroupManager.flush()
    }

    @MainActor
    func testExplicitDeleteRemovesGroupAndLiveTabs() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Delete")
        let tab = subject.addTab(zombie: true, groupID: group)
        let unrelated = subject.addTab(zombie: true)
        try subject.deleteTabGroup(group)
        XCTAssertFalse(subject.tabs.contains(tab))
        XCTAssertTrue(subject.tabs.contains(unrelated))
        XCTAssertTrue(subject.tabGroupManager.groups.isEmpty)
        XCTAssertTrue(subject.tabGroupManager.persistedTabIDs.isEmpty)
        try await subject.tabGroupManager.flush()
    }

    @MainActor
    func testClosingWindowPreservesOnlyItsGroups() async throws {
        let first = createSubject()
        try await first.tabGroupManager.restore()
        let firstGroup = try first.tabGroupManager.createGroup(title: "First")
        let secondGroup = try first.tabGroupManager.createGroup(title: "Second")
        let firstTab = first.addTab(zombie: true, groupID: firstGroup)
        let second = createSubject(windowUUID: UUID(), groupManager: first.tabGroupManager)
        let secondTab = second.addTab(zombie: true, groupID: secondGroup)
        first.prepareForWindowClose()
        XCTAssertNil(first.tabGroupManager.activeWindow(for: firstGroup))
        XCTAssertEqual(first.tabGroupManager.activeWindow(for: secondGroup), second.windowUUID)
        XCTAssertEqual(first.tabGroupManager.persistedTabIDs.count, 2)
        XCTAssertNil(firstTab.groupID)
        XCTAssertEqual(secondTab.groupID, secondGroup)
        try await first.tabGroupManager.flush()
    }

    @MainActor
    func testBothRestorePathsBindFinalIDsAndRetainInactiveGroups() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 2)
            let active = TabGroup(title: "Active", tabIDs: [data[0].id.uuidString])
            let inactive = TabGroup(title: "Inactive", tabIDs: [data[1].id.uuidString])
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [active, inactive], tabs: data))
            let window = UUID()
            mockTabStore.fetchTabWindowData = WindowData(id: window, activeTabId: data[0].id, tabData: [data[0]])
            let subject = createSubject(windowUUID: window)
            let observer = MembershipObserver()
            subject.addDelegate(observer)
            let completed = XCTestExpectation(description: "Restore completed")
            AppEventQueue.wait(for: .tabRestoration(window)) { completed.fulfill() }
            subject.restoreTabs()
            await fulfillment(of: [completed], timeout: 10)
            XCTAssertEqual(subject.tabs.first?.tabUUID, data[0].id.uuidString)
            XCTAssertEqual(subject.tabs.first?.groupID, active.id)
            XCTAssertEqual(observer.restored.first?.groupID, active.id)
            if !flag { XCTAssertEqual(observer.added.first?.tabID, data[0].id.uuidString) }
            XCTAssertEqual(try subject.tabGroupManager.tabs(in: inactive.id).count, 1)
            XCTAssertNil(subject.tabGroupManager.activeWindow(for: inactive.id))
            try await subject.tabGroupManager.flush()
        }
    }

    @MainActor
    func testBothRestorePathsUseDurableRecordsAndRepairMissingMembersInOrder() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 2)
            let latest = TabData(id: data[0].id,
                                 title: "Latest page",
                                 siteUrl: "https://example.com/latest",
                                 faviconURL: nil,
                                 isPrivate: false,
                                 lastUsedTime: data[0].lastUsedTime,
                                 createdAtTime: data[0].createdAtTime,
                                 temporaryDocumentSession: [:])
            let memberIDs = [data[1].id.uuidString, data[0].id.uuidString]
            let group = TabGroup(title: "Durable", tabIDs: memberIDs)
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group], tabs: [latest, data[1]]))
            let subject = createSubject(windowUUID: UUID())
            mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID,
                                                         activeTabId: data[0].id,
                                                         tabData: [data[0]])
            let completed = XCTestExpectation(description: "Restore completed")
            AppEventQueue.wait(for: .tabRestoration(subject.windowUUID)) { completed.fulfill() }
            subject.restoreTabs()
            await fulfillment(of: [completed], timeout: 10)
            XCTAssertEqual(subject.tabs.map(\.tabUUID), memberIDs)
            XCTAssertTrue(subject.tabs.allSatisfy { $0.groupID == group.id })
            XCTAssertEqual(subject.tabs.last?.url?.absoluteString, latest.siteUrl)
            XCTAssertEqual(subject.tabs.last?.lastTitle, latest.title)
            XCTAssertEqual(subject.selectedTab?.tabUUID, latest.id.uuidString)
            try await subject.tabGroupManager.flush()
        }
    }

    @MainActor
    func testBothRestorePathsDoNotDuplicateGroupHostedElsewhere() async throws {
        let first = createSubject()
        try await first.tabGroupManager.restore()
        let group = try first.tabGroupManager.createGroup(title: "Other window")
        let tab = first.addTab(zombie: true, groupID: group)
        let data = tab.dataForSaving()
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let window = UUID()
            mockTabStore.fetchTabWindowData = WindowData(id: window, activeTabId: data.id, tabData: [data])
            let second = createSubject(windowUUID: window, groupManager: first.tabGroupManager)
            let completed = XCTestExpectation(description: "Restore completed")
            AppEventQueue.wait(for: .tabRestoration(window)) { completed.fulfill() }
            second.restoreTabs()
            await fulfillment(of: [completed], timeout: 10)
            XCTAssertFalse(second.tabs.contains(where: { $0.tabUUID == tab.tabUUID }))
            XCTAssertEqual(first.tabGroupManager.activeWindow(for: group), first.windowUUID)
        }
        try await first.tabGroupManager.flush()
    }

    @MainActor
    func testOpeningGroupDuringBothRestorePathsDoesNotDuplicateLiveTabs() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 1)
            let group = TabGroup(title: "Open", tabIDs: [data[0].id.uuidString])
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group], tabs: data))
            let subject = createSubject(windowUUID: UUID())
            mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID, activeTabId: data[0].id, tabData: data)
            let fetching = XCTestExpectation(description: "Fetching window data")
            let completed = XCTestExpectation(description: "Restored")
            AppEventQueue.wait(for: .tabRestoration(subject.windowUUID)) { completed.fulfill() }
            mockTabStore.suspendFetch = true
            mockTabStore.onFetch = { fetching.fulfill() }
            subject.restoreTabs()
            await fulfillment(of: [fetching], timeout: 10)
            _ = try await subject.openTabGroup(group.id)
            let liveTab = try XCTUnwrap(subject.tabs.first)
            mockTabStore.resumeFetch()
            await fulfillment(of: [completed], timeout: 10)
            XCTAssertEqual(subject.tabs, [liveTab])
            XCTAssertTrue(subject.selectedTab === liveTab)
            XCTAssertEqual(liveTab.groupID, group.id)
            try await subject.tabGroupManager.flush()
        }
    }

    @MainActor
    func testClosingWindowDuringBothRestorePathsKeepsGroupInactive() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 1)
            let group = TabGroup(title: "Keep", tabIDs: [data[0].id.uuidString])
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group], tabs: data))
            let subject = createSubject(windowUUID: UUID())
            mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID, activeTabId: data[0].id, tabData: data)
            let fetching = XCTestExpectation(description: "Fetching window data")
            mockTabStore.suspendFetch = true
            mockTabStore.onFetch = { fetching.fulfill() }
            subject.restoreTabs()
            await fulfillment(of: [fetching], timeout: 10)
            subject.prepareForWindowClose()
            mockTabStore.resumeFetch()
            try await subject.tabGroupManager.restore()
            await Task.yield()
            XCTAssertNil(subject.tabGroupManager.activeWindow(for: group.id))
            XCTAssertTrue(subject.tabs.isEmpty)
            XCTAssertEqual(try subject.tabGroupManager.tabs(in: group.id).count, 1)
            do {
                _ = try await subject.openTabGroup(group.id)
                XCTFail("A closed window cannot reopen groups")
            } catch {}
        }
    }

    @MainActor
    func testClosingGroupDuringBothRestorePathsDoesNotReopenIt() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 1)
            let group = TabGroup(title: "Keep", tabIDs: [data[0].id.uuidString])
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group], tabs: data))
            let subject = createSubject(windowUUID: UUID())
            try await subject.tabGroupManager.restore()
            _ = try subject.tabGroupManager.openGroup(group.id, in: subject.windowUUID)
            mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID, activeTabId: data[0].id, tabData: data)
            let saved = XCTestExpectation(description: "Closed group removed from window data")
            let tabID = data[0].id
            mockTabStore.onSave = { window in
                XCTAssertFalse(window.tabData.contains { $0.id == tabID })
                saved.fulfill()
            }
            let fetching = XCTestExpectation(description: "Fetching window data")
            let completed = XCTestExpectation(description: "Restored")
            AppEventQueue.wait(for: .tabRestoration(subject.windowUUID)) { completed.fulfill() }
            mockTabStore.suspendFetch = true
            mockTabStore.onFetch = { fetching.fulfill() }
            subject.restoreTabs()
            await fulfillment(of: [fetching], timeout: 10)
            subject.closeTabGroup(group.id)
            mockTabStore.resumeFetch()
            await fulfillment(of: [completed, saved], timeout: 10)
            XCTAssertNil(subject.tabGroupManager.activeWindow(for: group.id))
            XCTAssertFalse(subject.tabs.contains(where: { $0.tabUUID == data[0].id.uuidString }))
            XCTAssertEqual(try subject.tabGroupManager.tabs(in: group.id).count, 1)
            try await subject.tabGroupManager.flush()
        }
    }

    @MainActor
    func testSessionCleanupRetainsTabsOfInactiveGroups() async throws {
        let data = getMockTabData(count: 2)
        let group = TabGroup(title: "Inactive", tabIDs: [data[1].id.uuidString])
        await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group], tabs: [data[1]]))
        let subject = createSubject()
        mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID, activeTabId: data[0].id, tabData: [data[0]])
        let cleaned = XCTestExpectation(description: "Session cleanup")
        let inactiveID = data[1].id
        mockSessionStore.onCleanup = { ids in
            XCTAssertTrue(ids.contains(inactiveID))
            cleaned.fulfill()
        }
        subject.restoreTabs()
        await fulfillment(of: [cleaned], timeout: 10)
        XCTAssertNil(subject.tabGroupManager.activeWindow(for: group.id))
    }

    @MainActor
    func testGroupLoadFailureStillRestoresWindowTabsWithoutWritingGroupData() async throws {
        await mockGroupStorage.setFailure(load: true)
        let data = getMockTabData(count: 1)
        let subject = createSubject()
        mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID, activeTabId: data[0].id, tabData: data)
        mockSessionStore.onCleanup = { _ in XCTFail("Cannot remove sessions while group membership is unknown") }
        let completed = XCTestExpectation(description: "Restore completed")
        AppEventQueue.wait(for: .tabRestoration(subject.windowUUID)) { completed.fulfill() }
        subject.restoreTabs()
        await fulfillment(of: [completed], timeout: 10)
        XCTAssertEqual(subject.tabs.first?.tabUUID, data[0].id.uuidString)
        XCTAssertNil(subject.tabs.first?.groupID)
        let writes = await mockGroupStorage.savedSnapshots
        XCTAssertTrue(writes.isEmpty)
    }
}

@MainActor
private final class MembershipObserver: TabManagerDelegate {
    struct Membership {
        let tabID: TabUUID
        let groupID: TabGroupID?
    }
    var added: [Membership] = []
    var restored: [Membership] = []

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {
        added.append(Membership(tabID: tab.tabUUID, groupID: tab.groupID))
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        restored = tabManager.tabs.map { Membership(tabID: $0.tabUUID, groupID: $0.groupID) }
    }
}
