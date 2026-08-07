// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class HomepageTelemetryStateTests: XCTestCase {
    func test_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
    }

    @MainActor
    func test_embeddedHomepageAction_withTrueZeroSearch_returnsExpectedState() {
        let initialState = createSubject()

        let newState = reducer().legacyReducer(
            initialState,
            HomepageAction(
                isZeroSearch: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    @MainActor
    func test_embeddedHomepageAction_withFalseZeroSearch_returnsExpectedState() {
        let initialState = createSubject(isZeroSearch: true)

        let newState = reducer().legacyReducer(
            initialState,
            HomepageAction(
                isZeroSearch: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertFalse(newState.isZeroSearch)
        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    @MainActor
    func test_embeddedHomepageAction_withoutZeroSearch_returnsDefaultState() {
        let initialState = createSubject(isZeroSearch: true)

        let newState = reducer().legacyReducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    @MainActor
    func test_didSelectedTabChangeToHomepageAction_returnsExpectedState() {
        let initialState = createSubject(isZeroSearch: true)

        let newState = reducer().legacyReducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )

        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertTrue(newState.shouldTriggerImpression)
    }

    @MainActor
    func test_unrelatedAction_resetsImpressionAndKeepsZeroSearch() {
        let initialState = createSubject(isZeroSearch: true, shouldTriggerImpression: true)

        let newState = reducer().legacyReducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    @MainActor
    func test_actionForDifferentWindow_returnsDefaultState() {
        let initialState = createSubject(isZeroSearch: true, shouldTriggerImpression: true)

        let newState = reducer().legacyReducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: WindowUUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )

        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    func test_defaultState_resetsImpressionAndKeepsZeroSearch() {
        let initialState = createSubject(isZeroSearch: true, shouldTriggerImpression: true)

        let newState = HomepageTelemetryState.defaultState(from: initialState)

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertFalse(newState.shouldTriggerImpression)
    }

    // MARK: - Private
    private func createSubject(
        isZeroSearch: Bool = false,
        shouldTriggerImpression: Bool = false
    ) -> HomepageTelemetryState {
        return HomepageTelemetryState(windowUUID: .XCTestDefaultUUID)
            .copy(isZeroSearch: isZeroSearch)
            .copy(shouldTriggerImpression: shouldTriggerImpression)
    }

    private func reducer() -> Reducer<HomepageTelemetryState> {
        return HomepageTelemetryState.reducer
    }
}
