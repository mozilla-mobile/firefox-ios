// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MainMenuStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testDismissSurveyAction() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertEqual(initialState.shouldDismiss, false)

        let action = getMiddleWareAction(for: .dismissMenu)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.shouldDismiss, true)
    }

    // MARK: - Private
    private func createSubject() -> MainMenuState {
        return MainMenuState(windowUUID: .XCTestDefaultUUID)
    }

    private func mainMenuReducer() -> Reducer<MainMenuState> {
        return MainMenuState.reducer
    }

    private func getMiddleWareAction(for actionType: MainMenuMiddlewareActionType) -> MainMenuAction {
        return MainMenuAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
