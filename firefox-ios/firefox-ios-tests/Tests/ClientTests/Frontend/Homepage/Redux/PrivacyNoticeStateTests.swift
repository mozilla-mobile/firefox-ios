// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class PrivacyNoticeStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.shouldShowPrivacyNotice)
    }

    @MainActor
    func test_handlePrivacyNoticeInitialization_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = privacyNoticeReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldShowPrivacyNotice)
    }

    @MainActor
    func test_handlePrivacyNoticeCloseButtonTapped_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = privacyNoticeReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.privacyNoticeCloseButtonTapped
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.shouldShowPrivacyNotice)
    }

    // MARK: - Private
    private func createSubject() -> PrivacyNoticeState {
        return PrivacyNoticeState(windowUUID: .XCTestDefaultUUID)
    }

    private func privacyNoticeReducer() -> Reducer<PrivacyNoticeState> {
        return PrivacyNoticeState.reducer
    }
}
