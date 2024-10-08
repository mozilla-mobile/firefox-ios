// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HomepageStateTests: XCTestCase {
    func testInitialization() {
        let initialState = createSubject()

        XCTAssertFalse(initialState.loadInitialData)
    }

    func test_windowUUID_returnsValidUUID() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
    }

    func test_different_windowUUID_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HeaderAction(
                windowUUID: .DefaultUITestingUUID,
                actionType: HeaderActionType.updateHeader
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.loadInitialData)
    }

    func test_initializeData_returnsTrue() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertTrue(newState.loadInitialData)
    }

    func test_updateHeader_returnsTrue() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HeaderAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HeaderActionType.updateHeader
            )
        )

        XCTAssertTrue(newState.headerState.showHeader)
    }

    // MARK: - Private
    private func createSubject() -> HomepageState {
        return HomepageState(windowUUID: .XCTestDefaultUUID)
    }

    private func homepageReducer() -> Reducer<HomepageState> {
        return HomepageState.reducer
    }
}
