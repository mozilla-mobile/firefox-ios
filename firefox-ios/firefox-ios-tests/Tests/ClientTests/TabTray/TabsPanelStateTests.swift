// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage
import Shared
import XCTest

@testable import Client

final class TabPanelStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testTabsState_InitialState {
        let initialState = TabsPanelState()
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


    // MARK: - Private

    private func tabsPanelReducer() -> Reducer<TabsPanelState> {
        return TabsPanelState.reducer
    }

    private func createInitialState() -> TabsPanelState {
        return TabsPanelState()
    }

    private func createTabs() -> [TabModel] {
        var tabs = [TabModel]()
        for index in 0...2 {
            let tab = TabModel.emptyTabState(tabUUID: "", title: "Tab1")
            tabs.append(tab)
        }
        return tabs
    }

    private func createSubject() -> RemoteTabsPanelState {
        let subject = RemoteTabsPanelState()
        return subject
    }
}
