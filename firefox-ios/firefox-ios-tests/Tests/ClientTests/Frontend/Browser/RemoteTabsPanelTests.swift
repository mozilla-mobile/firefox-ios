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

    func testRemoteTabsPanel_simpleCreation_hasNoLeaks() {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    func testRemoteTabs_whenSubscribeToReduxCalled_subscribesToReduxStore() {
        var subscribeCount = 0
        mockStore.subscribeCalled = {
            subscribeCount += 1
        }

        let subject = createSubject()
        subject.subscribeToRedux()

        XCTAssertFalse(mockStore.dispatchedActions.isEmpty)
        XCTAssertEqual(subscribeCount, 1)
    }

    func testRemoteTabs_whenUnsubscribeFromReduxCalled_dispatchesCloseScreenAction() {
        let subject = createSubject()
        subject.unsubscribeFromRedux()

        guard
            let action = try? XCTUnwrap(mockStore.dispatchedActions.last),
            let actionType = action.actionType as? ScreenActionType
        else {
            XCTFail("Incorrect action type")
            return
        }

        XCTAssertEqual(actionType, ScreenActionType.closeScreen)
    }

    // MARK: - Actions
    func testRemoteTabs_whenPulledToRefresh_refreshsTabs() {
        let subject = createSubject()
        subject.tableViewControllerDidPullToRefresh()

        guard
            let action = try? XCTUnwrap(mockStore.dispatchedActions.last),
            let actionType = action.actionType as? RemoteTabsPanelActionType
        else {
            XCTFail("Incorrect action type")
            return
        }
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
        RemoteTabsPanel(windowUUID: windowUUID)
    }
}
