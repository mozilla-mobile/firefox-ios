// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class HomepageConfigurationStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
    }

    @MainActor
    func test_embeddedHomepageAction_withTrueZeroSearch_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = configurationReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                isZeroSearch: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    @MainActor
    func test_embeddedHomepageAction_withFalseZeroSearch_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = configurationReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                isZeroSearch: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isZeroSearch)
        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    @MainActor
    func test_didSelectedTabChangeToHomepageAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = configurationReducer()

        let newState = reducer.legacyReducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldTriggerImpression)
    }

    @MainActor
    func test_defaultAction_resetsShouldTriggerImpression() {
        let initialState = createSubject()
        let reducer = configurationReducer()

        let stateWithImpression = reducer.legacyReducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )
        XCTAssertTrue(stateWithImpression.shouldTriggerImpression)

        let newState = reducer.legacyReducer(
            stateWithImpression,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.viewWillAppear
            )
        )

        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    // MARK: - Private
    private func createSubject() -> HomepageConfigurationState {
        return HomepageConfigurationState(windowUUID: .XCTestDefaultUUID)
    }

    private func configurationReducer() -> Reducer<HomepageConfigurationState> {
        return HomepageConfigurationState.reducer
    }
}
