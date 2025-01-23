// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HeaderStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.isPrivate)
        XCTAssertFalse(initialState.showiPadSetup)
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                showiPadSetup: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isPrivate)
        XCTAssertTrue(newState.showiPadSetup)
    }

    func test_initializeAction_withoutIpadSetup_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                showiPadSetup: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isPrivate)
        XCTAssertFalse(newState.showiPadSetup)
    }

    // MARK: - Private
    private func createSubject() -> HeaderState {
        return HeaderState(windowUUID: .XCTestDefaultUUID)
    }

    private func headerReducer() -> Reducer<HeaderState> {
        return HeaderState.reducer
    }
}
