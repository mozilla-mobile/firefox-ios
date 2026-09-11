// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import TabDataStore
import UIKit
import XCTest

@testable import Client

@MainActor
class MergeWindowsManagerTests: XCTestCase {
    private let mockTabDataStore = MockTabDataStore()

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Merging

    func testMergeAllWindows_withNoOtherWindows_doesNothing() {
        let windowManager = createWindowManager()
        let target = WindowUUID()
        let targetManager = MockTabManager(windowUUID: target)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: targetManager), uuid: target)
        let destroyer = MockSceneDestroyer()

        createSubject(windowManager: windowManager, sceneDestroyer: destroyer).mergeAllWindows(into: target)

        XCTAssertEqual(targetManager.addTabsFromWindowMergeCalled, 0)
        XCTAssertTrue(destroyer.destroyedUUIDs.isEmpty)
    }

    func testMergeAllWindows_movesOtherWindowsTabsAndClosesThem() {
        let windowManager = createWindowManager()
        let target = WindowUUID()
        let other = WindowUUID()
        let targetManager = MockTabManager(windowUUID: target)
        let otherManager = MockTabManager(windowUUID: other)
        otherManager.tabDataForWindowMergeResult = [makeMergeTabData(), makeMergeTabData()]
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: targetManager), uuid: target)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: otherManager), uuid: other)
        let destroyer = MockSceneDestroyer()

        createSubject(windowManager: windowManager, sceneDestroyer: destroyer).mergeAllWindows(into: target)

        XCTAssertEqual(otherManager.tabDataForWindowMergeCalled, 1)
        XCTAssertEqual(targetManager.addTabsFromWindowMergeCalled, 1)
        XCTAssertEqual(targetManager.addedWindowMergeTabData.count, 2)
        XCTAssertEqual(destroyer.destroyedUUIDs, [other])
    }

    /// The merged-away window must give up its tabs before its scene is torn down, otherwise the
    /// save it performs on the way down recreates the window data and every merged tab comes back
    /// the next time a window is opened.
    func testMergeAllWindows_discardsSourceTabsBeforeDestroyingScenes() {
        let windowManager = createWindowManager()
        let target = WindowUUID()
        let other = WindowUUID()
        let targetManager = MockTabManager(windowUUID: target)
        let otherManager = MockTabManager(windowUUID: other)
        otherManager.tabDataForWindowMergeResult = [makeMergeTabData()]
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: targetManager), uuid: target)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: otherManager), uuid: other)
        let destroyer = MockSceneDestroyer()
        destroyer.onDestroy = {
            XCTAssertEqual(
                otherManager.discardTabsMovedToAnotherWindowCalled,
                1,
                "Source window must be emptied before its scene is destroyed"
            )
        }

        createSubject(windowManager: windowManager, sceneDestroyer: destroyer).mergeAllWindows(into: target)

        XCTAssertEqual(otherManager.discardTabsMovedToAnotherWindowCalled, 1)
        XCTAssertEqual(targetManager.discardTabsMovedToAnotherWindowCalled, 0)
    }

    func testMergeAllWindows_whenSceneFailsToClose_leavesMergedTabsInTargetOnly() {
        let windowManager = createWindowManager()
        let target = WindowUUID()
        let other = WindowUUID()
        let targetManager = MockTabManager(windowUUID: target)
        let otherManager = MockTabManager(windowUUID: other)
        otherManager.tabDataForWindowMergeResult = [makeMergeTabData()]
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: targetManager), uuid: target)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: otherManager), uuid: other)
        let destroyer = MockSceneDestroyer()
        destroyer.errorToReport = TestError.sceneDestructionFailed

        createSubject(windowManager: windowManager, sceneDestroyer: destroyer).mergeAllWindows(into: target)

        // The failure is reported rather than swallowed, and the window that would not close has
        // already handed its tabs over, so no tab UUID is owned by two windows.
        XCTAssertEqual(destroyer.reportedErrorUUIDs, [other])
        XCTAssertEqual(otherManager.discardTabsMovedToAnotherWindowCalled, 1)
        XCTAssertEqual(targetManager.addedWindowMergeTabData.count, 1)
    }

    // MARK: - Removing window data

    func testMergeAllWindows_doesNotRemoveWindowDataUntilTheSceneCloses() {
        let windowManager = createWindowManager()
        let windows = configureTwoWindows(on: windowManager)

        createSubject(windowManager: windowManager,
                      sceneDestroyer: MockSceneDestroyer()).mergeAllWindows(into: windows.target)

        XCTAssertEqual(windows.targetManager.addTabsFromWindowMergeCalled, 1, "merge must have run")
        XCTAssertEqual(mockTabDataStore.removeWindowDataCalled, 0)
    }

    func testWindowDidClose_removesWindowDataForTheMergedWindow() async {
        let windowManager = createWindowManager()
        let windows = configureTwoWindows(on: windowManager)
        let subject = createSubject(windowManager: windowManager, sceneDestroyer: MockSceneDestroyer())
        subject.mergeAllWindows(into: windows.target)

        let removed = expectation(description: "window data removed")
        mockTabDataStore.removeWindowDataExpectation = removed
        subject.windowDidClose(uuid: windows.other)
        await fulfillment(of: [removed], timeout: 5)

        XCTAssertEqual(mockTabDataStore.removedWindowDataUUIDs, [windows.other])
    }

    /// A window that iOS refused to close is still on screen, so its stored data must survive.
    func testWindowDidClose_whenTheSceneFailedToClose_keepsWindowData() {
        let windowManager = createWindowManager()
        let windows = configureTwoWindows(on: windowManager)
        let destroyer = MockSceneDestroyer()
        destroyer.errorToReport = TestError.sceneDestructionFailed
        let subject = createSubject(windowManager: windowManager, sceneDestroyer: destroyer)
        subject.mergeAllWindows(into: windows.target)

        subject.windowDidClose(uuid: windows.other)

        XCTAssertEqual(destroyer.reportedErrorUUIDs, [windows.other], "the close must have failed")
        XCTAssertEqual(mockTabDataStore.removeWindowDataCalled, 0)
    }

    func testWindowDidClose_ignoresWindowsThatWereNotMerged() {
        let windowManager = createWindowManager()
        let windows = configureTwoWindows(on: windowManager)
        let subject = createSubject(windowManager: windowManager, sceneDestroyer: MockSceneDestroyer())
        subject.mergeAllWindows(into: windows.target)

        subject.windowDidClose(uuid: WindowUUID())

        XCTAssertEqual(windows.targetManager.addTabsFromWindowMergeCalled, 1, "merge must have run")
        XCTAssertEqual(mockTabDataStore.removeWindowDataCalled, 0)
    }

    // MARK: - Quick action

    func testQuickAction_addedWhenEnabledAndTwoOrMoreWindowsOpen() {
        let windowManager = createWindowManager()
        windowManager.newBrowserWindowConfigured(AppWindowInfo(), uuid: WindowUUID())
        windowManager.newBrowserWindowConfigured(AppWindowInfo(), uuid: WindowUUID())
        let quickActions = MockMergeQuickActions()

        createController(windowManager: windowManager, quickActions: quickActions, isEnabled: true).update()

        XCTAssertEqual(quickActions.addedTypes, [.mergeWindows])
        XCTAssertTrue(quickActions.removedTypes.isEmpty)
    }

    func testQuickAction_removedWhenFewerThanTwoWindowsOpen() {
        let windowManager = createWindowManager()
        windowManager.newBrowserWindowConfigured(AppWindowInfo(), uuid: WindowUUID())
        let quickActions = MockMergeQuickActions()

        createController(windowManager: windowManager, quickActions: quickActions, isEnabled: true).update()

        XCTAssertEqual(quickActions.removedTypes, [.mergeWindows])
        XCTAssertTrue(quickActions.addedTypes.isEmpty)
    }

    func testQuickAction_removedWhenFeatureDisabled() {
        let windowManager = createWindowManager()
        windowManager.newBrowserWindowConfigured(AppWindowInfo(), uuid: WindowUUID())
        windowManager.newBrowserWindowConfigured(AppWindowInfo(), uuid: WindowUUID())
        let quickActions = MockMergeQuickActions()

        createController(windowManager: windowManager, quickActions: quickActions, isEnabled: false).update()

        XCTAssertEqual(quickActions.removedTypes, [.mergeWindows])
        XCTAssertTrue(quickActions.addedTypes.isEmpty)
    }

    // MARK: - Helpers

    private enum TestError: Error {
        case sceneDestructionFailed
    }

    private func createWindowManager() -> WindowManagerImplementation {
        return WindowManagerImplementation(tabDataStore: mockTabDataStore)
    }

    /// Holds the tab managers as well as the UUIDs: `AppWindowInfo.tabManager` is weak, so a test
    /// that drops them would silently be exercising a merge that found no windows.
    private struct MergedWindows {
        let target: WindowUUID
        let other: WindowUUID
        let targetManager: MockTabManager
        let otherManager: MockTabManager
    }

    private func configureTwoWindows(on windowManager: WindowManagerImplementation) -> MergedWindows {
        let target = WindowUUID()
        let other = WindowUUID()
        let targetManager = MockTabManager(windowUUID: target)
        let otherManager = MockTabManager(windowUUID: other)
        otherManager.tabDataForWindowMergeResult = [makeMergeTabData()]
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: targetManager), uuid: target)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: otherManager), uuid: other)
        return MergedWindows(target: target,
                             other: other,
                             targetManager: targetManager,
                             otherManager: otherManager)
    }

    private func createSubject(windowManager: WindowManager,
                               sceneDestroyer: SceneDestroying) -> MergeWindowsManager {
        return MergeWindowsManager(windowManager: windowManager,
                                   tabDataStore: mockTabDataStore,
                                   sceneDestroyer: sceneDestroyer)
    }

    private func createController(windowManager: WindowManager,
                                  quickActions: QuickActions,
                                  isEnabled: Bool) -> MergeWindowsQuickActionController {
        let featureFlags = MockNimbusFeatureFlags()
        if isEnabled { featureFlags.enabledFlags = [.mergeWindows] }
        return MergeWindowsQuickActionController(quickActions: quickActions,
                                                 windowManager: windowManager,
                                                 application: .shared,
                                                 featureFlags: featureFlags)
    }

    private func makeMergeTabData() -> TabData {
        return TabData(id: UUID(),
                       title: "Test",
                       siteUrl: "https://example.com",
                       faviconURL: nil,
                       isPrivate: false,
                       lastUsedTime: Date(),
                       createdAtTime: Date(),
                       temporaryDocumentSession: [:])
    }
}

// MARK: - Test doubles

final class MockSceneDestroyer: SceneDestroying {
    var destroyedUUIDs: [WindowUUID] = []
    var reportedErrorUUIDs: [WindowUUID] = []
    /// When set, every window is reported as having failed to close.
    var errorToReport: (any Error)?
    /// Runs at the moment the scenes would be destroyed, to assert on ordering.
    var onDestroy: (() -> Void)?

    func destroyScenes(for windowUUIDs: [WindowUUID],
                       errorHandler: @escaping @MainActor (WindowUUID, any Error) -> Void) {
        onDestroy?()
        destroyedUUIDs = windowUUIDs
        guard let errorToReport else { return }
        for uuid in windowUUIDs {
            reportedErrorUUIDs.append(uuid)
            errorHandler(uuid, errorToReport)
        }
    }
}

final class MockMergeQuickActions: QuickActions, @unchecked Sendable {
    var addedTypes: [ShortcutType] = []
    var removedTypes: [ShortcutType] = []

    func addDynamicApplicationShortcutItemOfType(_ type: ShortcutType,
                                                 withUserData userData: [String: String],
                                                 toApplication application: UIApplication) {
        addedTypes.append(type)
    }

    func removeDynamicApplicationShortcutItemOfType(_ type: ShortcutType,
                                                    fromApplication application: UIApplication) {
        removedTypes.append(type)
    }
}
