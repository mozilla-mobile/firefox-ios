// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class TabTrayStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
//        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
//        DependencyHelperMock().reset()
    }
    
    func testDidLoadTabTrayAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getAction(for: .didLoadTabTray)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.shareURL, nil)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }
    
    func testChangePanelAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()

        let action = getAction(for: .changePanel)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.shareURL, nil)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }
    
    func testDismissTabTrayAction() {
        let initialState = createSubject()
        let reducer = tabTrayReducer()
        XCTAssertEqual(initialState.shouldDismiss, false)

        let action = getAction(for: .dismissTabTray)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, false)
        XCTAssertEqual(newState.selectedPanel, .tabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, true)
        XCTAssertEqual(newState.shareURL, nil)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }
    
    func testFirefoxAccountChangedAction() {
        let initialState = createSubject(panelType: .privateTabs)
        let reducer = tabTrayReducer()
        let action = getAction(for: .firefoxAccountChanged)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.isPrivateMode, true)
        XCTAssertEqual(newState.selectedPanel, .privateTabs)
        XCTAssertEqual(newState.hasSyncableAccount, false)
        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.shareURL, nil)
        XCTAssertEqual(newState.normalTabsCount, "0")
        XCTAssertEqual(newState.showCloseConfirmation, false)
    }

    // MARK: - Private
    private func createSubject(panelType:TabTrayPanelType = .tabs) -> TabTrayState {
        return TabTrayState(windowUUID: .XCTestDefaultUUID, panelType: panelType)
    }

    private func tabTrayReducer() -> Reducer<TabTrayState> {
        return TabTrayState.reducer
    }

    private func getAction(for actionType: TabTrayActionType) -> TabTrayAction {
        return  TabTrayAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
