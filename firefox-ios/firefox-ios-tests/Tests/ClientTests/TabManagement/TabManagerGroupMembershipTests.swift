// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import TabDataStore
import Shared
@testable import Client

final class TabManagerGroupMembershipTests: TabManagerTestsBase {
    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.removeObject(forKey: "SettingsBundleSkipSessionRestore")
    }

    @MainActor
    func testOneShotCreationInheritsMembershipBeforeCallback() async throws {
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
    func testOpeningGroupOnlySelectsExistingTabs() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Existing")
        let tab = subject.addTab(zombie: true, groupID: group)
        let unrelated = subject.addTab(zombie: true)
        subject.selectTab(unrelated)

        _ = try await subject.openTabGroup(group)
        _ = try await subject.openTabGroup(group)

        XCTAssertEqual(subject.tabs, [tab, unrelated])
        XCTAssertTrue(subject.selectedTab === tab)
        try await subject.tabGroupManager.flush()
    }

    @MainActor
    func testOpeningUnrestoredGroupDoesNotCreateTabsOrClaimItsWindow() async throws {
        let group = TabGroup(title: "Stored", tabIDs: [UUID().uuidString])
        await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group]))
        let subject = createSubject()

        do {
            _ = try await subject.openTabGroup(group.id)
            XCTFail("The group's existing window tabs must be restored first")
        } catch {
            guard case TabGroupManager.GroupError.tabsNotLoaded = error else { return XCTFail("Unexpected error: \(error)") }
        }

        XCTAssertTrue(subject.tabs.isEmpty)
        XCTAssertNil(subject.tabGroupManager.activeWindow(for: group.id))
        XCTAssertEqual(subject.tabGroupManager.tabIDs(in: group.id), group.tabIDs)
    }

    @MainActor
    func testSavingTabMetadataDoesNotRewriteGroupStorage() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Work")
        let tab = subject.addTab(zombie: true, groupID: group)
        try await subject.tabGroupManager.flush()
        let previousSaves = await mockGroupStorage.savedSnapshots.count
        subject.tabRestoreHasFinished = true
        let saved = expectation(description: "Tab metadata saved to existing window store")
        let tabID = tab.tabUUID
        mockTabStore.onSave = { window in
            XCTAssertEqual(window.tabData.first?.id.uuidString, tabID)
            XCTAssertEqual(window.tabData.first?.siteUrl, "https://example.com/latest")
            saved.fulfill()
        }
        tab.url = URL(string: "https://example.com/latest")

        subject.preserveTabs(immediate: true)
        await fulfillment(of: [saved], timeout: 5)
        try await subject.tabGroupManager.flush()

        let saves = await mockGroupStorage.savedSnapshots.count
        XCTAssertEqual(saves, previousSaves)
    }

    @MainActor
    func testWindowMergePreservesMembershipAndUsesExistingTabRecords() async throws {
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
    func testExplicitDeleteRemovesGroupAndLiveTabs() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Delete")
        let tab = subject.addTab(zombie: true, groupID: group)
        let unrelated = subject.addTab(zombie: true)
        subject.selectTab(tab)
        let observer = MembershipObserver()
        subject.addDelegate(observer)

        try subject.deleteTabGroup(group)

        XCTAssertFalse(subject.tabs.contains(tab))
        XCTAssertTrue(subject.tabs.contains(unrelated))
        XCTAssertTrue(subject.tabGroupManager.groups.isEmpty)
        XCTAssertTrue(subject.tabGroupManager.persistedTabIDs.isEmpty)
        XCTAssertTrue(subject.selectedTab === unrelated)
        XCTAssertEqual(observer.selections.count, 1)
        XCTAssertEqual(observer.selections.last?.tabID, unrelated.tabUUID)
        XCTAssertEqual(observer.selections.last?.previousTabID, tab.tabUUID)
        try await subject.tabGroupManager.flush()
    }

    @MainActor
    func testDeleteGroupReindexesSurvivingNormalAndPrivateSelections() async throws {
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.Settings.closePrivateTabs)
        for isPrivate in [false, true] {
            let subject = createSubject()
            try await subject.tabGroupManager.restore()
            let group = try subject.tabGroupManager.createGroup(title: "Delete")
            let removed = subject.addTab(zombie: true, groupID: group)
            let survivor = subject.addTab(zombie: true, isPrivate: isPrivate)
            subject.selectTab(survivor)
            let observer = MembershipObserver()
            subject.addDelegate(observer)

            try subject.deleteTabGroup(group)

            XCTAssertEqual(subject.tabs, [survivor])
            XCTAssertTrue(subject.selectedTab === survivor)
            XCTAssertEqual(subject.selectedIndex, 0)
            XCTAssertEqual(observer.selections.count, 1)
            XCTAssertEqual(observer.selections.last?.previousTabID, survivor.tabUUID)
            XCTAssertFalse(subject.tabs.contains(removed))
            try await subject.tabGroupManager.flush()
        }
    }

    @MainActor
    func testDeleteGroupCreatesUngroupedTabWhenNoNormalTabsRemain() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let group = try subject.tabGroupManager.createGroup(title: "Delete")
        let first = subject.addTab(zombie: true, groupID: group)
        let selected = subject.addTab(zombie: true, groupID: group)
        subject.selectTab(selected)
        let observer = MembershipObserver()
        subject.addDelegate(observer)

        try subject.deleteTabGroup(group)

        let replacement = try XCTUnwrap(subject.selectedTab)
        XCTAssertEqual(subject.normalTabs, [replacement])
        XCTAssertNil(replacement.groupID)
        XCTAssertFalse([first.tabUUID, selected.tabUUID].contains(replacement.tabUUID))
        XCTAssertEqual(observer.selections.last?.previousTabID, selected.tabUUID)
        try await subject.tabGroupManager.flush()
    }

    @MainActor
    func testDeleteGroupCreatesUngroupedFallbackWhenOtherGroupsRemain() async throws {
        let subject = createSubject()
        try await subject.tabGroupManager.restore()
        let deletedGroup = try subject.tabGroupManager.createGroup(title: "Delete")
        let otherGroup = try subject.tabGroupManager.createGroup(title: "Keep")
        let selected = subject.addTab(zombie: true, groupID: deletedGroup)
        let otherTab = subject.addTab(zombie: true, groupID: otherGroup)
        subject.selectTab(selected)

        try subject.deleteTabGroup(deletedGroup)

        let replacement = try XCTUnwrap(subject.selectedTab)
        XCTAssertNil(replacement.groupID)
        XCTAssertFalse(replacement === otherTab)
        XCTAssertEqual(subject.normalTabs.count, 2)
        XCTAssertTrue(subject.normalTabs.contains(otherTab))
        XCTAssertEqual(otherTab.groupID, otherGroup)
        try await subject.tabGroupManager.flush()
    }

    @MainActor
    func testDeleteGroupRepairsHostSelectionAndPreservesUnaffectedWindow() async throws {
        let caller = createSubject()
        try await caller.tabGroupManager.restore()
        let privateTab = caller.addTab(zombie: true, isPrivate: true)
        caller.selectTab(privateTab)
        let callerObserver = MembershipObserver()
        caller.addDelegate(callerObserver)
        let host = createSubject(windowUUID: UUID(), groupManager: caller.tabGroupManager)
        let group = try host.tabGroupManager.createGroup(title: "Delete")
        let survivor = host.addTab(zombie: true)
        let selected = host.addTab(zombie: true, groupID: group)
        host.selectTab(selected)
        let hostObserver = MembershipObserver()
        host.addDelegate(hostObserver)
        let windows: WindowManager = AppContainer.shared.resolve()
        windows.newBrowserWindowConfigured(AppWindowInfo(tabManager: caller), uuid: caller.windowUUID)
        windows.newBrowserWindowConfigured(AppWindowInfo(tabManager: host), uuid: host.windowUUID)

        try caller.deleteTabGroup(group)

        XCTAssertEqual(host.tabs, [survivor])
        XCTAssertTrue(host.selectedTab === survivor)
        XCTAssertEqual(hostObserver.selections.last?.previousTabID, selected.tabUUID)
        XCTAssertEqual(caller.tabs, [privateTab])
        XCTAssertTrue(caller.selectedTab === privateTab)
        XCTAssertTrue(callerObserver.selections.isEmpty)
        try await caller.tabGroupManager.flush()
    }

    @MainActor
    func testDeletingGroupDuringBothRestorePathsExcludesUnrestoredMembers() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 2)
            let group = TabGroup(title: "Delete", tabIDs: [data[0].id.uuidString])
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group]))
            let subject = createSubject(windowUUID: UUID())
            mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID, activeTabId: data[0].id, tabData: data)
            let fetching = XCTestExpectation(description: "Fetching window data")
            let completed = XCTestExpectation(description: "Restored")
            AppEventQueue.wait(for: .tabRestoration(subject.windowUUID)) { completed.fulfill() }
            mockTabStore.suspendFetch = true
            mockTabStore.onFetch = { fetching.fulfill() }
            subject.restoreTabs()
            await fulfillment(of: [fetching], timeout: 10)
            let caller = createSubject(windowUUID: UUID(), groupManager: subject.tabGroupManager)
            let windows: WindowManager = AppContainer.shared.resolve()
            windows.newBrowserWindowConfigured(AppWindowInfo(tabManager: subject), uuid: subject.windowUUID)

            try caller.deleteTabGroup(group.id)

            XCTAssertTrue(subject.tabs.isEmpty)
            XCTAssertTrue(caller.tabs.isEmpty)
            mockTabStore.resumeFetch()
            await fulfillment(of: [completed], timeout: 10)
            XCTAssertEqual(subject.tabs.map(\.tabUUID), [data[1].id.uuidString])
            XCTAssertEqual(subject.selectedTab?.tabUUID, data[1].id.uuidString)
            XCTAssertTrue(subject.tabGroupManager.groups.isEmpty)
            XCTAssertTrue(subject.tabRestoreHasFinished)
            windows.windowWillClose(uuid: subject.windowUUID)
            for tab in subject.tabs { await tab.close() }
            try await subject.tabGroupManager.flush()
            mockTabStore.onFetch = nil
        }
    }

    @MainActor
    func testClosingWindowReleasesOnlyItsRuntimeOwnership() async throws {
        let first = createSubject()
        try await first.tabGroupManager.restore()
        let firstGroup = try first.tabGroupManager.createGroup(title: "First")
        let secondGroup = try first.tabGroupManager.createGroup(title: "Second")
        let firstTab = first.addTab(zombie: true, groupID: firstGroup)
        let second = createSubject(windowUUID: UUID(), groupManager: first.tabGroupManager)
        let secondTab = second.addTab(zombie: true, groupID: secondGroup)
        try await first.tabGroupManager.flush()
        let previousSaves = await mockGroupStorage.savedSnapshots.count

        first.prepareForWindowClose()

        XCTAssertNil(first.tabGroupManager.activeWindow(for: firstGroup))
        XCTAssertEqual(first.tabGroupManager.activeWindow(for: secondGroup), second.windowUUID)
        XCTAssertEqual(first.tabGroupManager.tabIDs(in: firstGroup), [firstTab.tabUUID])
        XCTAssertEqual(first.tabs, [firstTab])
        XCTAssertEqual(secondTab.groupID, secondGroup)
        let saves = await mockGroupStorage.savedSnapshots.count
        XCTAssertEqual(saves, previousSaves)
    }

    @MainActor
    func testBothRestorePathsStitchMetadataIDsOntoExistingWindowRecords() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 2)
            let group = TabGroup(title: "Stored", tabIDs: data.reversed().map { $0.id.uuidString })
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group]))
            let window = UUID()
            mockTabStore.fetchTabWindowData = WindowData(id: window, activeTabId: data[0].id, tabData: [data[0]])
            let subject = createSubject(windowUUID: window)
            let observer = MembershipObserver()
            subject.addDelegate(observer)
            let completed = XCTestExpectation(description: "Restore completed")
            AppEventQueue.wait(for: .tabRestoration(window)) { completed.fulfill() }

            subject.restoreTabs()
            await fulfillment(of: [completed], timeout: 10)

            XCTAssertEqual(subject.tabs.map(\.tabUUID), [data[0].id.uuidString])
            XCTAssertEqual(subject.tabs.first?.url?.absoluteString, data[0].siteUrl)
            XCTAssertEqual(subject.tabs.first?.lastTitle, data[0].title)
            XCTAssertEqual(subject.tabs.first?.groupID, group.id)
            XCTAssertEqual(observer.restored.first?.groupID, group.id)
            if !flag { XCTAssertEqual(observer.added.first?.tabID, data[0].id.uuidString) }
            XCTAssertEqual(subject.tabGroupManager.tabIDs(in: group.id), group.tabIDs)
            let saves = await mockGroupStorage.savedSnapshots
            XCTAssertTrue(saves.isEmpty)
        }
    }

    @MainActor
    func testBothRestorePathsDoNotDuplicateGroupHostedElsewhere() async throws {
        let first = createSubject()
        try await first.tabGroupManager.restore()
        let group = try first.tabGroupManager.createGroup(title: "Other window")
        let tab = first.addTab(zombie: true, groupID: group)
        let data = try XCTUnwrap(first.tabDataForWindowMerge().first)
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
    func testOpeningDuringBothRestorePathsWaitsForExistingWindowTabs() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 1)
            let group = TabGroup(title: "Stored", tabIDs: [data[0].id.uuidString])
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group]))
            let subject = createSubject(windowUUID: UUID())
            mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID, activeTabId: data[0].id, tabData: data)
            let fetching = XCTestExpectation(description: "Fetching window data")
            let completed = XCTestExpectation(description: "Restored")
            AppEventQueue.wait(for: .tabRestoration(subject.windowUUID)) { completed.fulfill() }
            mockTabStore.suspendFetch = true
            mockTabStore.onFetch = { fetching.fulfill() }
            subject.restoreTabs()
            await fulfillment(of: [fetching], timeout: 10)
            do {
                _ = try await subject.openTabGroup(group.id)
                XCTFail("Cannot construct a tab from membership alone")
            } catch {}
            XCTAssertTrue(subject.tabs.isEmpty)

            mockTabStore.resumeFetch()
            await fulfillment(of: [completed], timeout: 10)
            _ = try await subject.openTabGroup(group.id)

            XCTAssertEqual(subject.tabs.count, 1)
            XCTAssertEqual(subject.tabs.first?.groupID, group.id)
            XCTAssertEqual(subject.selectedTab?.tabUUID, data[0].id.uuidString)
            for tab in subject.tabs { await tab.close() }
        }
    }

    @MainActor
    func testClosingWindowDuringBothRestorePathsKeepsOnlyMembershipMetadata() async throws {
        for flag in [false, true] {
            setIsDeeplinkOptimizationRefactorEnabled(flag)
            let data = getMockTabData(count: 1)
            let group = TabGroup(title: "Stored", tabIDs: [data[0].id.uuidString])
            await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group]))
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
            XCTAssertEqual(subject.tabGroupManager.tabIDs(in: group.id), group.tabIDs)
            do {
                _ = try await subject.openTabGroup(group.id)
                XCTFail("A closed window cannot open groups")
            } catch {}
        }
    }

    @MainActor
    func testSessionCleanupRetainsGroupMembershipIDs() async throws {
        let data = getMockTabData(count: 2)
        let group = TabGroup(title: "Stored", tabIDs: [data[1].id.uuidString])
        await mockGroupStorage.setSnapshot(TabGroupSnapshot(groups: [group]))
        let subject = createSubject()
        mockTabStore.fetchTabWindowData = WindowData(id: subject.windowUUID, activeTabId: data[0].id, tabData: [data[0]])
        let cleaned = XCTestExpectation(description: "Session cleanup")
        let groupedID = data[1].id
        mockSessionStore.onCleanup = { ids in
            XCTAssertTrue(ids.contains(groupedID))
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
    struct Selection {
        let tabID: TabUUID
        let previousTabID: TabUUID?
    }
    var added: [Membership] = []
    var restored: [Membership] = []
    var selections: [Selection] = []

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {
        added.append(Membership(tabID: tab.tabUUID, groupID: tab.groupID))
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        restored = tabManager.tabs.map { Membership(tabID: $0.tabUUID, groupID: $0.groupID) }
    }

    func tabManager(_ tabManager: TabManager,
                    didSelectedTabChange selectedTab: Tab,
                    previousTab: Tab?,
                    isRestoring: Bool) {
        selections.append(Selection(tabID: selectedTab.tabUUID, previousTabID: previousTab?.tabUUID))
    }
}
