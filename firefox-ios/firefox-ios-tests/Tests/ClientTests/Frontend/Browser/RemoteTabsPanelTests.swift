// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class RemoteTabsPanelTests: XCTestCase, StoreTestUtility {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func testRemoteTabs_whenSubscribeToReduxCalled_subscribesToReduxStore() {
        let subject = createSubject()
        subject.subscribeToRedux()

        XCTAssertFalse(mockStore.dispatchedActions.isEmpty)
        XCTAssertEqual(mockStore.subscribeCallCount, 1)
    }

    func testRemoteTabs_whenUnsubscribeFromReduxCalled_dispatchesCloseScreenAction() throws {
        let subject = createSubject()
        subject.unsubscribeFromRedux()

        let action = try XCTUnwrap(mockStore.dispatchedActions.last)
        let actionType = try XCTUnwrap(action.actionType as? ScreenActionType)

        XCTAssertEqual(actionType, ScreenActionType.closeScreen)
    }

    // MARK: - Actions
    func testRemoteTabs_whenPulledToRefresh_refreshsTabs() throws {
        let subject = createSubject()
        subject.tableViewControllerDidPullToRefresh()

        let action = try XCTUnwrap(mockStore.dispatchedActions.last)
        let actionType = try XCTUnwrap(action.actionType as? RemoteTabsPanelActionType)

        XCTAssertEqual(actionType, RemoteTabsPanelActionType.refreshTabs)
    }

    // MARK: - StoreTestUtility
    func setupAppState() -> Client.AppState {
        return AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }

    // MARK: - Helpers
    private func createSubject() -> RemoteTabsPanel {
        let subject = RemoteTabsPanel(windowUUID: windowUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
