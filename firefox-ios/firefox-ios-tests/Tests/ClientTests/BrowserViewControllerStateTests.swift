// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class BrowserViewControllerStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testAddNewTabAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigateTo)

        let action = getAction(for: .addNewTab)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .newTab)
    }

    func testShowNewTabLongpPressActions() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.displayView)

        let action = getAction(for: .showNewTabLongPressActions)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.displayView, .newTabLongPressActions)
    }

    func testClearDataAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.displayView)

        let action = getAction(for: .clearData)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.displayView, .dataClearance)
    }

    // MARK: - Private
    private func createSubject() -> BrowserViewControllerState {
        return BrowserViewControllerState(windowUUID: .XCTestDefaultUUID)
    }

    private func browserViewControllerReducer() -> Reducer<BrowserViewControllerState> {
        return BrowserViewControllerState.reducer
    }

    private func getAction(for actionType: GeneralBrowserActionType) -> GeneralBrowserAction {
        return  GeneralBrowserAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
