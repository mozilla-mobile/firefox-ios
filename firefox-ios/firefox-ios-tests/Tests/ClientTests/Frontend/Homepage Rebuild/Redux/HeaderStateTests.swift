// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HeaderStateTests: XCTestCase {
    func testInitialization() {
        let initialState = createSubject()

        XCTAssertFalse(initialState.showHeader)
    }

    func test_windowUUID_returnsValidUUID() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
    }

    func test_different_windowUUID_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            HeaderAction(
                windowUUID: .DefaultUITestingUUID,
                actionType: HeaderActionType.updateHeader
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.showHeader)
    }

    func test_updateHeader_returnsTrue() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            HeaderAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HeaderActionType.updateHeader
            )
        )

        XCTAssertTrue(newState.showHeader)
    }

    // MARK: - Private
    private func createSubject() -> HeaderState {
        return HeaderState(windowUUID: .XCTestDefaultUUID)
    }

    private func headerReducer() -> Reducer<HeaderState> {
        return HeaderState.reducer
    }
}
