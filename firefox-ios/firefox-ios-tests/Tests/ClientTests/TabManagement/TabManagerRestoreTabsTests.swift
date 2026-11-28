// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import Common
@testable import Client

final class TabManagerRestoreTabsTests: TabManagerTestsBase {
    override func setUp() async throws {
        try await super.setUp()

        // Only needed for the temporary skip session diagnostic tests. A run killed before its teardown block leaks this key
        // and would skip restore for every test here.
        UserDefaults.standard.removeObject(forKey: DebugSettingsBundleOptions.skipSessionRestoreKey)
    }

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
        var tabData = getMockTabData(count: 3)
        tabData[1] = TabData(id: activeId,
                             title: tabData[1].title,
                             siteUrl: tabData[1].siteUrl,
                             faviconURL: tabData[1].faviconURL,
                             isPrivate: false,
                             lastUsedTime: tabData[1].lastUsedTime,
                             createdAtTime: tabData[1].createdAtTime,
                             temporaryDocumentSession: [:])
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: activeId,
                                                     tabData: tabData)

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

    @MainActor
    func testRestoreTabs_withDeeplinkFlagEnabled_preservesDeeplinkWhenRestorationResultIsEmpty() {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let testUUID = UUID()
        let deeplinkTabs = generateTabs(ofType: .normal, count: 1)
        let subject = createSubject(tabs: deeplinkTabs, windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        // No persisted window data — restoration result will be empty, but deeplink must survive.
        mockTabStore.fetchTabWindowData = nil

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, 1, "Deeplink should be preserved; no extra empty tab created")
                XCTAssertIdentical(subject.tabs.first, deeplinkTabs.first)
                XCTAssertIdentical(subject.selectedTab, deeplinkTabs.first, "Deeplink should be selected")
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_withDeeplinkFlagEnabled_selectsActiveRestoredTabOverDeeplink() {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let testUUID = UUID()
        let deeplinkTabs = generateTabs(ofType: .normal, count: 1)
        let subject = createSubject(tabs: deeplinkTabs, windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")

        let activeId = UUID()
        var tabData = getMockTabData(count: 3)
        tabData[1] = TabData(id: activeId,
                             title: tabData[1].title,
                             siteUrl: tabData[1].siteUrl,
                             faviconURL: tabData[1].faviconURL,
                             isPrivate: false,
                             lastUsedTime: tabData[1].lastUsedTime,
                             createdAtTime: tabData[1].createdAtTime,
                             temporaryDocumentSession: [:])
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: activeId,
                                                     tabData: tabData)

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, 4, "3 restored + 1 pre-restore deeplink tab")
                XCTAssertEqual(subject.selectedTab?.tabUUID,
                               activeId.uuidString,
                               "Active restored tab should win over deeplink")
                XCTAssertIdentical(subject.tabs.last, deeplinkTabs.first, "Deeplink should still land at the end")
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    // MARK: - Skipped session restore

    /// FXIOS-16244. The explicit timeout makes a regression fail rather than hang the suite.
    @MainActor
    func testRestoreTabs_whenSessionRestoreIsSkipped_stillCompletesTabRestorationEvent() {
        setSkipSessionRestore(true)
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [mockTabStore] in
            ensureMainThread {
                XCTAssertEqual(mockTabStore?.fetchWindowDataCalledCount, 0, "Restore should have been skipped")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: skippedRestoreTimeout)
    }

    @MainActor
    func testRestoreTabs_whenSessionRestoreIsSkippedWithDeeplinkFlagEnabled_stillCompletesTabRestorationEvent() {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        setSkipSessionRestore(true)
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [mockTabStore] in
            ensureMainThread {
                XCTAssertEqual(mockTabStore?.fetchWindowDataCalledCount, 0, "Restore should have been skipped")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: skippedRestoreTimeout)
    }

    @MainActor
    func testRestoreTabs_whenSessionRestoreIsSkipped_stillPreservesTabs() async throws {
        setSkipSessionRestore(true)
        let subject = createSubject()

        subject.restoreTabs()
        subject.preserveTabs(immediate: true)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertTrue(subject.tabRestoreHasFinished)
        XCTAssertEqual(mockTabStore.fetchWindowDataCalledCount, 0)
        XCTAssertGreaterThan(mockTabStore.saveWindowDataCalledCount, 0)
    }

    @MainActor
    func testRestoreTabs_whenSessionRestoreIsSkippedWithDeeplinkFlagEnabled_stillPreservesTabs() async throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        setSkipSessionRestore(true)
        let subject = createSubject()

        subject.restoreTabs()
        subject.preserveTabs(immediate: true)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertTrue(subject.tabRestoreHasFinished)
        XCTAssertEqual(mockTabStore.fetchWindowDataCalledCount, 0)
        XCTAssertGreaterThan(mockTabStore.saveWindowDataCalledCount, 0)
    }

    // MARK: - Stale skip session restore cleanup

    func testClearStaleSkipSessionRestore_onReleaseWithValueSet_clearsValueAndRecordsEvent() throws {
        let (defaults, _) = makeIsolatedDefaults()
        defaults.set(true, forKey: DebugSettingsBundleOptions.skipSessionRestoreKey)
        let telemetry = MockTabLossTelemetry()

        let didClear = DebugSettingsBundleOptions.clearStaleSkipSessionRestoreIfNeeded(userDefaults: defaults,
                                                                                       buildChannel: .release,
                                                                                       tabLossTelemetry: telemetry)

        let diagnostics = try XCTUnwrap(telemetry.savedStaleSkipSessionRestoreDiagnostics)
        XCTAssertTrue(didClear)
        XCTAssertNil(defaults.object(forKey: DebugSettingsBundleOptions.skipSessionRestoreKey))
        XCTAssertEqual(telemetry.recordStaleSkipSessionRestoreClearedCalled, 1)
        XCTAssertTrue(diagnostics.hasPrefix("type: bool, val: 1"))
    }

    func testClearStaleSkipSessionRestore_onDeveloperBuild_keepsValue() {
        let (defaults, _) = makeIsolatedDefaults()
        defaults.set(true, forKey: DebugSettingsBundleOptions.skipSessionRestoreKey)
        let telemetry = MockTabLossTelemetry()

        let didClear = DebugSettingsBundleOptions.clearStaleSkipSessionRestoreIfNeeded(userDefaults: defaults,
                                                                                       buildChannel: .developer,
                                                                                       tabLossTelemetry: telemetry)

        XCTAssertFalse(didClear)
        XCTAssertTrue(defaults.bool(forKey: DebugSettingsBundleOptions.skipSessionRestoreKey))
        XCTAssertEqual(telemetry.recordStaleSkipSessionRestoreClearedCalled, 0)
    }

    func testClearStaleSkipSessionRestore_onReleaseWithoutValue_doesNothing() {
        let (defaults, _) = makeIsolatedDefaults()
        let telemetry = MockTabLossTelemetry()

        let didClear = DebugSettingsBundleOptions.clearStaleSkipSessionRestoreIfNeeded(userDefaults: defaults,
                                                                                       buildChannel: .release,
                                                                                       tabLossTelemetry: telemetry)

        XCTAssertFalse(didClear)
        XCTAssertEqual(telemetry.recordStaleSkipSessionRestoreClearedCalled, 0)
    }

    // MARK: - Skip session restore diagnostics

    func testSkipSessionRestoreDiagnostics_whenKeyIsUnset_reportsNoDomains() {
        let (defaults, suiteName) = makeIsolatedDefaults()

        let result = DebugSettingsBundleOptions.skipSessionRestoreDiagnostics(userDefaults: defaults,
                                                                              appDomain: suiteName)

        XCTAssertEqual(result, "type: nil, val: nil, dom: none")
    }

    func testSkipSessionRestoreDiagnostics_whenBoolIsStored_reportsBoolInAppDomain() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defaults.set(true, forKey: DebugSettingsBundleOptions.skipSessionRestoreKey)

        let result = DebugSettingsBundleOptions.skipSessionRestoreDiagnostics(userDefaults: defaults,
                                                                              appDomain: suiteName)

        XCTAssertEqual(result, "type: bool, val: 1, dom: app")
    }

    func testSkipSessionRestoreDiagnostics_whenStringIsStored_reportsStringInAppDomain() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defaults.set("YES", forKey: DebugSettingsBundleOptions.skipSessionRestoreKey)

        let result = DebugSettingsBundleOptions.skipSessionRestoreDiagnostics(userDefaults: defaults,
                                                                              appDomain: suiteName)

        XCTAssertEqual(result, "type: string, val: YES, dom: app")
    }

    func testSkipSessionRestoreDiagnostics_whenNumberIsStored_reportsNumberInAppDomain() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defaults.set(1, forKey: DebugSettingsBundleOptions.skipSessionRestoreKey)

        let result = DebugSettingsBundleOptions.skipSessionRestoreDiagnostics(userDefaults: defaults,
                                                                              appDomain: suiteName)

        XCTAssertEqual(result, "type: number, val: 1, dom: app")
    }

    // MARK: - Helpers

    private let skippedRestoreTimeout: TimeInterval = 5

    private func setSkipSessionRestore(_ skip: Bool) {
        UserDefaults.standard.set(skip, forKey: DebugSettingsBundleOptions.skipSessionRestoreKey)

        addTeardownBlock {
            UserDefaults.standard.removeObject(forKey: DebugSettingsBundleOptions.skipSessionRestoreKey)
        }
    }

    private func makeIsolatedDefaults() -> (UserDefaults, String) {
        let suiteName = "TabManagerRestoreTabsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }

        return (defaults, suiteName)
    }
}
