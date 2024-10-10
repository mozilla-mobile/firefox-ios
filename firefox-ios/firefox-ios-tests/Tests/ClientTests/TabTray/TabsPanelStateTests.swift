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
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testTabsState_DidLoadTabPanel() {
        let initialState = createInitialState()
        XCTAssertTrue(initialState.tabs.isEmpty)
        let reducer = tabsPanelReducer()
        let tabs = createTabs()
        let tabDisplayModel = TabDisplayModel(isPrivateMode: false,
                                              tabs: tabs,
                                              normalTabsCount: "\(tabs.count)",
                                              inactiveTabs: [InactiveTabsModel](),
                                              isInactiveTabsExpanded: false,
                                              shouldScrollToTab: false)
        let action = TabPanelMiddlewareAction(tabDisplayModel: tabDisplayModel,
                                              windowUUID: .XCTestDefaultUUID,
                                              actionType: TabPanelMiddlewareActionType.didLoadTabPanel)
        let newState = reducer(initialState, action)
        XCTAssertFalse(newState.tabs.isEmpty)
    }

    func testTabsState_IsInactiveTabsExpanded() {
        let initialState = createInitialState()
        XCTAssertFalse(initialState.isInactiveTabsExpanded)
        let reducer = tabsPanelReducer()
        let action = TabPanelViewAction(panelType: .tabs,
                                        windowUUID: .XCTestDefaultUUID,
                                        actionType: TabPanelViewActionType.toggleInactiveTabs)
        let newState = reducer(initialState, action)
        XCTAssertTrue(newState.isInactiveTabsExpanded)
    }

    // MARK: - Private
    private func tabsPanelReducer() -> Reducer<TabsPanelState> {
        return TabsPanelState.reducer
    }

    private func createInitialState() -> TabsPanelState {
        return TabsPanelState(windowUUID: .XCTestDefaultUUID)
    }

    private func createTabs() -> [TabModel] {
        var tabs = [TabModel]()
        for index in 0...2 {
            let tab = TabModel.emptyTabState(tabUUID: "", title: "Tab\(index)")
            tabs.append(tab)
        }
        return tabs
    }

    private func createInactiveTabs() -> [InactiveTabsModel] {
        var inactiveTabs = [InactiveTabsModel]()
        for index in 0...2 {
            let inactiveTab = InactiveTabsModel(tabUUID: "4233-2323-3578",
                                                title: "InactiveTab\(index)",
                                                url: URL(string: "https://www.test\(index).com"))
            inactiveTabs.append(inactiveTab)
        }
        return inactiveTabs
    }
}
