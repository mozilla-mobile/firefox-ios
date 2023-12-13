// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage
import Shared
import XCTest

@testable import Client

final class RemoteTabPanelStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testTabsRefreshSkippedIfNotAllowed() {
        let initialState = RemoteTabsPanelState()
        XCTAssertEqual(initialState.refreshState,
                       RemoteTabsPanelRefreshState.idle)

        let reducer = remoteTabsPanelReducer()

        let newState = reducer(initialState, RemoteTabsPanelAction.refreshTabs)

        // Refresh should fail since Profile.hasSyncableAccount
        // is false for unit test, expected state is .idle
        XCTAssertEqual(newState.refreshState,
                       RemoteTabsPanelRefreshState.idle)
    }

    func testTabsRefreshSuccessStateChange() {
        let initialState = createSubject()
        let reducer = remoteTabsPanelReducer()
        let testTabs = generateOneClientTwoTabs()

        XCTAssertEqual(initialState.clientAndTabs.count, 0)

        let newState = reducer(initialState, RemoteTabsPanelAction.refreshDidSucceed(testTabs))

        XCTAssertEqual(newState.clientAndTabs.count, 1)
        XCTAssertEqual(newState.clientAndTabs.first!.tabs.count, 2)
    }

    func testTabsRefreshFailedStateChange() {
        let initialState = createSubject()
        let reducer = remoteTabsPanelReducer()

        let newState = reducer(initialState, RemoteTabsPanelAction.refreshDidFail(.failedToSync))

        XCTAssertEqual(newState.refreshState, RemoteTabsPanelRefreshState.idle)
        XCTAssertNotNil(newState.showingEmptyState)
    }

    // MARK: - Private

    private func remoteTabsPanelReducer() -> Reducer<RemoteTabsPanelState> {
        return RemoteTabsPanelState.reducer
    }

    private func generateEmptyState() -> RemoteTabsPanelState {
        return RemoteTabsPanelState()
    }

    private func generateOneClientTwoTabs() -> [ClientAndTabs] {
        let tab1 = RemoteTab(clientGUID: "123",
                             URL: URL(string: "https://mozilla.com")!,
                             title: "Mozilla Homepage",
                             history: [],
                             lastUsed: 0,
                             icon: nil)
        let tab2 = RemoteTab(clientGUID: "123",
                             URL: URL(string: "https://google.com")!,
                             title: "Google Homepage",
                             history: [],
                             lastUsed: 0,
                             icon: nil)
        let fakeTabs: [RemoteTab] = [tab1, tab2]
        let client = RemoteClient(guid: "123",
                                  name: "Client",
                                  modified: 0,
                                  type: "Type (Test)",
                                  formfactor: "Test",
                                  os: "macOS",
                                  version: "v1.0",
                                  fxaDeviceId: "12345")
        let fakeData = [ClientAndTabs(client: client, tabs: fakeTabs)]
        return fakeData
    }

    private func createSubject() -> RemoteTabsPanelState {
        let subject = RemoteTabsPanelState()
        return subject
    }
}
