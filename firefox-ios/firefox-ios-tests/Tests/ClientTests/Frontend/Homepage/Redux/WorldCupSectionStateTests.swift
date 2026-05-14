// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import XCTest
@testable import Client

@MainActor
final class WorldCupSectionStateTests: XCTestCase {
    func test_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.shouldShowSection)
        XCTAssertFalse(initialState.isMilestone2)
        XCTAssertNil(initialState.apiError)
    }

    func test_didUpdateAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = WorldCupSectionState.reducer

        let newState = reducer(
            initialState,
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: true,
                shouldShowMilestone2: true
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldShowSection)
        XCTAssertTrue(newState.isMilestone2)
        XCTAssertNil(newState.apiError)
    }

    func test_didUpdateAction_withApiError_propagatesErrorToState() {
        let initialState = createSubject()
        let reducer = WorldCupSectionState.reducer
        let apiError = WorldCupLoadError.network(reason: "offline")

        let newState = reducer(
            initialState,
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: true,
                shouldShowMilestone2: true,
                apiError: apiError
            )
        )

        XCTAssertEqual(newState.apiError, apiError)
    }

    func test_unhandledWorldCupActionType_returnsUnchangedState() {
        let initialState = createSubject()
        let reducer = WorldCupSectionState.reducer

        let newState = reducer(
            initialState,
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupActionType.selectTeam,
                selectedCountryId: "ARG"
            )
        )

        XCTAssertEqual(newState, initialState)
    }

    func test_defaultState_returnsSameState() {
        let state = createSubject()

        let result = WorldCupSectionState.defaultState(from: state)

        XCTAssertEqual(result, state)
    }

    // MARK: - Helpers

    private func createSubject() -> WorldCupSectionState {
        return WorldCupSectionState(windowUUID: .XCTestDefaultUUID)
    }
}
