// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common

@testable import Client

final class TabTrayStateTests: XCTestCase {
    func testInitialState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.isPrivateMode, false)
        XCTAssertEqual(initialState.selectedPanel, .tabs)
        XCTAssertEqual(initialState.hasSyncableAccount, false)
        XCTAssertEqual(initialState.shouldDismiss, false)
        XCTAssertEqual(initialState.normalTabsCount, "0")
        XCTAssertEqual(initialState.showCloseConfirmation, false)
    }

    func testDidLoadTabTrayAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()
        let action = getTabTrayAction(for: .didLoadTabTray)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testChangePanelAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabTrayAction(for: .changePanel)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testDismissTabTrayAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabTrayAction(for: .dismissTabTray)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, true)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testFirefoxAccountChangedAction() {
        let initialState = createSubject(panelType: .privateTabs)
        let reducer = tabTrayReducer()

        let action = getTabTrayAction(for: .firefoxAccountChanged)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, true)
        XCTAssertEqual(newState.selectedPanel, .privateTabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testTabTrayDidLoadAction() {
        let initialState = createSubject(panelType: .syncedTabs)
        let reducer = tabTrayReducer()

        let action = getTabTrayAction(for: .firefoxAccountChanged)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .syncedTabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testDidLoadTabPanelAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelMiddleWareAction(for: .didLoadTabPanel)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testDidChangeTabPanelAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelMiddleWareAction(for: .didChangeTabPanel)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testDidRefreshTabsAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelMiddleWareAction(for: .refreshTabs)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testRefreshInactiveTabsAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelMiddleWareAction(for: .refreshInactiveTabs)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testShowToastAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelMiddleWareAction(for: .showToast)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testCloseAllTabsAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelViewAction(for: .closeAllTabs)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, true)
    }

    func testSelectTabAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelViewAction(for: .selectTab)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testTabPanelDidLoadAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelViewAction(for: .tabPanelDidLoad)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    // test for unimplemented TabPanelViewActionType
    func testCloseTabAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getTabPanelViewAction(for: .closeTab)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    func testDefaultState() {
        var initialState = createSubject()

        initialState.shouldDismiss = true
        initialState.showCloseConfirmation = true
        let defaultState = TabTrayState.defaultState(from: initialState)

        XCTAssertEqual(defaultState.windowUUID, initialState.windowUUID)
        XCTAssertEqual(defaultState.isPrivateMode, initialState.isPrivateMode)
        XCTAssertEqual(defaultState.selectedPanel, initialState.selectedPanel)
        XCTAssertEqual(defaultState.hasSyncableAccount, initialState.hasSyncableAccount)
        XCTAssertEqual(defaultState.normalTabsCount, initialState.normalTabsCount)
        XCTAssertNotEqual(defaultState.shouldDismiss, initialState.shouldDismiss)
        XCTAssertNotEqual(defaultState.showCloseConfirmation, initialState.showCloseConfirmation)
    }

    // MARK: - Private
    private func createSubject(panelType: TabTrayPanelType = .tabs) -> TabTrayState {
        return TabTrayState(windowUUID: .XCTestDefaultUUID, panelType: panelType)
    }

    private func tabTrayReducer() -> Reducer<TabTrayState> {
        return TabTrayState.reducer
    }

    private func getTabTrayAction(for actionType: TabTrayActionType) -> TabTrayAction {
        return  TabTrayAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func getTabPanelMiddleWareAction(for actionType: TabPanelMiddlewareActionType) -> TabPanelMiddlewareAction {
        return  TabPanelMiddlewareAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func getTabPanelViewAction(for actionType: TabPanelViewActionType) -> TabPanelViewAction {
        return  TabPanelViewAction(panelType: .tabs, windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
