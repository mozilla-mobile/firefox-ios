// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HomepageStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)

        XCTAssertFalse(initialState.headerState.isPrivate)
        XCTAssertTrue(initialState.headerState.showPrivateModeToggle)
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)

        XCTAssertFalse(newState.headerState.isPrivate)
        XCTAssertTrue(newState.headerState.showPrivateModeToggle)
    }

    // MARK: - Private
    private func createSubject() -> HomepageState {
        return HomepageState(windowUUID: .XCTestDefaultUUID)
    }

    private func homepageReducer() -> Reducer<HomepageState> {
        return HomepageState.reducer
    }
}
