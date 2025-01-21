// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MessageCardStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertNil(initialState.title)
        XCTAssertNil(initialState.description)
        XCTAssertNil(initialState.buttonLabel)
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = messageCardReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertNil(initialState.title)
        XCTAssertNil(initialState.description)
        XCTAssertNil(initialState.buttonLabel)
    }
    // MARK: - Private
    private func createSubject() -> MessageCardState {
        return MessageCardState(windowUUID: .XCTestDefaultUUID)
    }

    private func messageCardReducer() -> Reducer<MessageCardState> {
        return MessageCardState.reducer
    }
}
