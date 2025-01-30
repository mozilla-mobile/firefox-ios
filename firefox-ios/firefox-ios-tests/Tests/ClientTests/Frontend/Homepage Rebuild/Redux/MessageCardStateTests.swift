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
        XCTAssertNil(initialState.messageCardConfiguration)
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = messageCardReducer()

        let newState = reducer(
            initialState,
            MessageCardAction(
                messageCardConfiguration: MessageCardConfiguration(
                    title: "Example Title",
                    description: "Example Description",
                    buttonLabel: "Example Button"
                ),
                windowUUID: .XCTestDefaultUUID,
                actionType: MessageCardMiddlewareActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.messageCardConfiguration?.title, "Example Title")
        XCTAssertEqual(newState.messageCardConfiguration?.description, "Example Description")
        XCTAssertEqual(newState.messageCardConfiguration?.buttonLabel, "Example Button")
    }

    func test_tappedOnActionButton_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = messageCardReducer()

        let newState = reducer(
            initialState,
            MessageCardAction(
                messageCardConfiguration: MessageCardConfiguration(
                    title: "Example Title",
                    description: "Example Description",
                    buttonLabel: "Example Button"
                ),
                windowUUID: .XCTestDefaultUUID,
                actionType: MessageCardActionType.tappedOnActionButton
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertNil(newState.messageCardConfiguration)
    }

    func test_tappedOnCloseButtonAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = messageCardReducer()

        let newState = reducer(
            initialState,
            MessageCardAction(
                messageCardConfiguration: MessageCardConfiguration(
                    title: "Example Title",
                    description: "Example Description",
                    buttonLabel: "Example Button"
                ),
                windowUUID: .XCTestDefaultUUID,
                actionType: MessageCardActionType.tappedOnCloseButton
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertNil(newState.messageCardConfiguration)
    }

    // MARK: - Private
    private func createSubject() -> MessageCardState {
        return MessageCardState(windowUUID: .XCTestDefaultUUID)
    }

    private func messageCardReducer() -> Reducer<MessageCardState> {
        return MessageCardState.reducer
    }
}
