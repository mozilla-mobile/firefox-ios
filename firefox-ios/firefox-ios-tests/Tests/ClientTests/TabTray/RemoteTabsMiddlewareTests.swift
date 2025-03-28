// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage
import XCTest

@testable import Client

final class RemoteTabsMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockProfile: MockProfile!
    var mockStore: MockStoreForMiddleware<AppState>!
    var appState: AppState!

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        mockProfile = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_jumpBackInAction_returnsMostRecentTab() throws {
        let subject = createSubject()
        let action = JumpBackInAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: JumpBackInActionType.fetchRemoteTabs
        )

        let expectation = XCTestExpectation(description: "Most recent tab should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.remoteTabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? RemoteTabsAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? RemoteTabsMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, RemoteTabsMiddlewareActionType.fetchedMostRecentSyncedTab)
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.client.name, "Fake client")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.title, "Mozilla 3")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.URL.absoluteString, "www.mozilla.org")
    }

    func test_viewWillAppearHomeAction_returnsMostRecentTab() throws {
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.viewWillAppear
        )

        let expectation = XCTestExpectation(description: "Most recent tab should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.remoteTabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? RemoteTabsAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? RemoteTabsMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, RemoteTabsMiddlewareActionType.fetchedMostRecentSyncedTab)
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.client.name, "Fake client")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.title, "Mozilla 3")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.URL.absoluteString, "www.mozilla.org")
    }

    func test_dismissTabTrayAction_returnsMostRecentTab() throws {
        let subject = createSubject()
        let action = TabTrayAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabTrayActionType.dismissTabTray
        )

        let expectation = XCTestExpectation(description: "Most recent tab should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.remoteTabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? RemoteTabsAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? RemoteTabsMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, RemoteTabsMiddlewareActionType.fetchedMostRecentSyncedTab)
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.client.name, "Fake client")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.title, "Mozilla 3")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.URL.absoluteString, "www.mozilla.org")
    }

    func test_topTabsNewTabAction_returnsMostRecentTab() throws {
        let subject = createSubject()
        let action = TopTabsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopTabsActionType.didTapNewTab
        )

        let expectation = XCTestExpectation(description: "Most recent tab should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.remoteTabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? RemoteTabsAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? RemoteTabsMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, RemoteTabsMiddlewareActionType.fetchedMostRecentSyncedTab)
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.client.name, "Fake client")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.title, "Mozilla 3")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.URL.absoluteString, "www.mozilla.org")
    }

    func test_topTabsCloseTabAction_returnsMostRecentTab() throws {
        let subject = createSubject()
        let action = TopTabsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopTabsActionType.didTapNewTab
        )

        let expectation = XCTestExpectation(description: "Most recent tab should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.remoteTabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? RemoteTabsAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? RemoteTabsMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, RemoteTabsMiddlewareActionType.fetchedMostRecentSyncedTab)
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.client.name, "Fake client")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.title, "Mozilla 3")
        XCTAssertEqual(actionCalled.mostRecentSyncedTab?.tab.URL.absoluteString, "www.mozilla.org")
    }

    // MARK: - Helpers
    private func createSubject() -> RemoteTabsPanelMiddleware {
        mockProfile.mockClientAndTabs = [
            ClientAndTabs(
                client: remoteDesktopClient(),
                tabs: remoteTabs(
                    idRange: 1...3
                ))
        ]
        return RemoteTabsPanelMiddleware(profile: mockProfile)
    }

    func remoteDesktopClient(name: String = "Fake client") -> RemoteClient {
        return RemoteClient(guid: nil,
                            name: name,
                            modified: 1,
                            type: "desktop",
                            formfactor: nil,
                            os: nil,
                            version: nil,
                            fxaDeviceId: nil)
    }

    func remoteTabs(idRange: ClosedRange<Int> = 1...1) -> [RemoteTab] {
        var remoteTabs: [RemoteTab] = []

        for index in idRange {
            let tab = RemoteTab(clientGUID: String(index),
                                URL: URL(string: "www.mozilla.org")!,
                                title: "Mozilla \(index)",
                                history: [],
                                lastUsed: UInt64(index),
                                icon: nil,
                                inactive: false)
            remoteTabs.append(tab)
        }
        return remoteTabs
    }

    // MARK: StoreTestUtility
    func setupAppState() -> Client.AppState {
        appState = AppState()
        return appState
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
