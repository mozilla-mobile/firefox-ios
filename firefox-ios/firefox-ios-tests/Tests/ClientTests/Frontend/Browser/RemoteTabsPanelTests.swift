// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class RemoteTabsPanelTests: XCTestCase, StoreTestUtility {
    private enum Constants {
        static let testUrlString = "https://mozilla.org"
        static let testDeviceId = "testDeviceId"
    }

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

    func testViewDidLoad_dispachesDisplayRelatedActionsToStore() throws {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        let action1 = try XCTUnwrap(mockStore.dispatchedActions[0])
        let action1Type = try XCTUnwrap(action1.actionType as? ScreenActionType)
        let action2 = try XCTUnwrap(mockStore.dispatchedActions[1])
        let action2Type = try XCTUnwrap(action2.actionType as? RemoteTabsPanelActionType)

        XCTAssertEqual(action1Type, ScreenActionType.showScreen)
        XCTAssertEqual(action2Type, RemoteTabsPanelActionType.panelDidAppear)
        XCTAssertEqual(mockStore.subscribeCallCount, 1)
    }

    func testUnsubscribeFromRedux_dispatchesCloseScreenActionToStore() throws {
        let subject = createSubject()
        subject.unsubscribeFromRedux()

        let action = try XCTUnwrap(mockStore.dispatchedActions.last)
        let actionType = try XCTUnwrap(action.actionType as? ScreenActionType)

        XCTAssertEqual(actionType, ScreenActionType.closeScreen)
    }

    // MARK: - Actions
    func testTableViewControllerDidPullToRefresh_dispatchesRefreshsTabsAction() throws {
        let subject = createSubject()
        subject.tableViewControllerDidPullToRefresh()

        let action = try XCTUnwrap(mockStore.dispatchedActions.last)
        let actionType = try XCTUnwrap(action.actionType as? RemoteTabsPanelActionType)

        XCTAssertEqual(actionType, RemoteTabsPanelActionType.refreshTabs)
    }

    func testNewState_setsNewStateInTableViewController() {
        let subject = createSubject()
        let newState = RemoteTabsPanelState(
            windowUUID: windowUUID,
            refreshState: .refreshing,
            allowsRefresh: false,
            clientAndTabs: [],
            showingEmptyState: nil,
            devices: []
        )
        subject.newState(state: newState)

        XCTAssertEqual(subject.state.refreshState, .refreshing)
        XCTAssertEqual(subject.tableViewController.state.refreshState, .refreshing)
    }

    // MARK: - RemoteTabsClientAndTabsDataSourceDelegate
    func testRemoteTabsClientAndTabsDataSourceDidSelectURL_dispatchesCloseSelectedRemoteURLAction() throws {
        let subject = createSubject()
        subject.remoteTabsClientAndTabsDataSourceDidSelectURL(
            URL(string: Constants.testUrlString)!,
            visitType: .link
        )

        let action = try XCTUnwrap(mockStore.dispatchedActions.last)
        let actionType = try XCTUnwrap(action.actionType as? RemoteTabsPanelActionType)

        XCTAssertEqual(actionType, RemoteTabsPanelActionType.openSelectedURL)
    }

    func testRemoteTabsClientAndTabsDataSourceDidCloseURL_dispatchesCloseSelectedRemoteURL() throws {
        let subject = createSubject()
        subject.remoteTabsClientAndTabsDataSourceDidCloseURL(
            deviceId: Constants.testDeviceId,
            url: URL(string: Constants.testUrlString)!
        )

        let action = try XCTUnwrap(mockStore.dispatchedActions.first)
        let actionType = try XCTUnwrap(action.actionType as? RemoteTabsPanelActionType)

        XCTAssertEqual(actionType, RemoteTabsPanelActionType.closeSelectedRemoteURL)
    }

    func testRemoteTabsClientAndTabsDataSourceDidUndo_dispatchesUndoCloseSelectedRemoteURL() throws {
        let subject = createSubject()
        subject.remoteTabsClientAndTabsDataSourceDidUndo(
            deviceId: Constants.testDeviceId,
            url: URL(string: Constants.testUrlString)!
        )

        let action = try XCTUnwrap(mockStore.dispatchedActions.first)
        let actionType = try XCTUnwrap(action.actionType as? RemoteTabsPanelActionType)

        XCTAssertEqual(actionType, RemoteTabsPanelActionType.undoCloseSelectedRemoteURL)
    }

    func testRemoteTabsClientAndTabsDataSourceDidTabCommandsFlush_dispatchesFlushTabCommands() throws {
        let subject = createSubject()
        subject.remoteTabsClientAndTabsDataSourceDidTabCommandsFlush(deviceId: Constants.testDeviceId)

        let action = try XCTUnwrap(mockStore.dispatchedActions.first)
        let actionType = try XCTUnwrap(action.actionType as? RemoteTabsPanelActionType)

        XCTAssertEqual(actionType, RemoteTabsPanelActionType.flushTabCommands)
    }

    // MARK: - RemotePanelDelegate
    func testRemotePanelDidRequestToSignIn_forwardsCallsToDelegate() {
        let mockDelegate = RemoteTabsPanelDelegateMock()
        let subject = createSubject()
        subject.remoteTabsDelegate = mockDelegate

        subject.remotePanelDidRequestToSignIn()

        XCTAssertEqual(mockDelegate.presentFirefoxAccountSignInCallCount, 1)
    }

    func testPresentFxAccountSettings_forwardsCallsToDelegate() {
        let mockDelegate = RemoteTabsPanelDelegateMock()
        let subject = createSubject()
        subject.remoteTabsDelegate = mockDelegate

        subject.presentFxAccountSettings()

        XCTAssertEqual(mockDelegate.presentFxAccountSettingsCallCount, 1)
    }

    // MARK: - RemoteTabsEmptyViewDelegate
    func testRemotePanelDidRequestToOpenInNewTab_dispatchesCloseSelectedRemoteURLAction() throws {
        let subject = createSubject()
        subject.remotePanelDidRequestToOpenInNewTab(
            URL(string: Constants.testUrlString)!,
            isPrivate: false
        )

        let action = try XCTUnwrap(mockStore.dispatchedActions.last)
        let actionType = try XCTUnwrap(action.actionType as? RemoteTabsPanelActionType)

        XCTAssertEqual(actionType, RemoteTabsPanelActionType.openSelectedURL)
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
