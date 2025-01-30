// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class JumpBackInSectionStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.jumpBackInTabs, [])
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = jumpBackInSectionReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.jumpBackInTabs.count, 1)

        XCTAssertEqual(newState.jumpBackInTabs.first?.titleText, "JumpBack In Title")
        XCTAssertEqual(newState.jumpBackInTabs.first?.descriptionText, "JumpBack In Description")
        XCTAssertEqual(newState.jumpBackInTabs.first?.siteURL, "www.mozilla.com")
        XCTAssertEqual(newState.jumpBackInTabs.first?.accessibilityLabel, "JumpBack In Title, JumpBack In Description")
    }

    // MARK: - Private
    private func createSubject() -> JumpBackInSectionState {
        return JumpBackInSectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func jumpBackInSectionReducer() -> Reducer<JumpBackInSectionState> {
        return JumpBackInSectionState.reducer
    }
}
