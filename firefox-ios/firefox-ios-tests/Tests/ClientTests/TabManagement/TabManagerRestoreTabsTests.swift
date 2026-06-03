// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import Common
@testable import Client

final class TabManagerRestoreTabsTests: TabManagerTestsBase {
    @MainActor
    func testRestoreTabs() {
        // Needed to ensure AppEventQueue is not fired from a previous test case with the same WindowUUID
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 4))

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [mockTabStore] in
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, 4)
                XCTAssertEqual(mockTabStore?.fetchWindowDataCalledCount, 1)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    // MARK: - Deeplink-optimization refactor path (snapshot-and-merge)

    @MainActor
    func testRestoreTabs_withDeeplinkFlagEnabled_restoresPersistedTabs() {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 3))

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [mockTabStore] in
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, 3)
                XCTAssertEqual(mockTabStore?.fetchWindowDataCalledCount, 1)
                XCTAssertTrue(subject.tabRestoreHasFinished)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_withDeeplinkFlagEnabled_mergesPreRestoreTabsAtEndOfArray() {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let testUUID = UUID()
        // Simulate a deeplink tab added before restore ran.
        let deeplinkTabs = generateTabs(ofType: .normal, count: 1)
        let subject = createSubject(tabs: deeplinkTabs, windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 2))

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, 3, "2 restored + 1 pre-restore deeplink tab")
                XCTAssertIdentical(subject.tabs.last, deeplinkTabs.first, "Deeplink tab should land at the end")
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_withDeeplinkFlagEnabled_isOneShotPerSession() {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 2))

        subject.restoreTabs()
        // Second call must be a no-op even though tabs are no longer empty post-restore.
        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [mockTabStore] in
            ensureMainThread {
                XCTAssertEqual(mockTabStore?.fetchWindowDataCalledCount,
                               1,
                               "Data store should be fetched at most once per session")
                XCTAssertEqual(subject.tabs.count, 2)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_withDeeplinkFlagEnabled_selectsActiveTabFromRestorationResult() {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")

        let activeId = UUID()
        let tabData = getMockTabData(count: 3)
        var taggedTabData = tabData
        taggedTabData[1] = TabData(id: activeId,
                                   title: tabData[1].title,
                                   siteUrl: tabData[1].siteUrl,
                                   faviconURL: tabData[1].faviconURL,
                                   isPrivate: false,
                                   lastUsedTime: tabData[1].lastUsedTime,
                                   createdAtTime: tabData[1].createdAtTime,
                                   temporaryDocumentSession: tabData[1].temporaryDocumentSession)
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: activeId,
                                                     tabData: taggedTabData)

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                XCTAssertEqual(subject.selectedTab?.tabUUID, activeId.uuidString)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_withDeeplinkFlagEnabled_createsNewTabWhenNothingToRestore() {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        // No persisted window data — restoration result will be empty.
        mockTabStore.fetchTabWindowData = nil

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, 1, "Should fall back to creating a fresh tab")
                XCTAssertNotNil(subject.selectedTab)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }
}
