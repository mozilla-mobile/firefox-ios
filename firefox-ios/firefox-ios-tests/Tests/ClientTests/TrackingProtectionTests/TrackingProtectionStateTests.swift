// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Redux

@testable import Client

final class TrackingProtectionStateTests: XCTestCase {
    private var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
    }

    override func tearDown() {
        mockProfile = nil
        super.tearDown()
    }

    func testDismissSurveyAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.shouldDismiss, false)

        let action = getMiddlewareAction(for: .dismissTrackingProtection)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.shouldDismiss, true)
        XCTAssertEqual(newState.showTrackingProtectionSettings, false)
    }

    func testShowTrackingProtectionSettingsAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.showTrackingProtectionSettings, false)

        let action = getMiddlewareAction(for: .navigateToSettings)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.shouldDismiss, true)
        XCTAssertEqual(newState.showTrackingProtectionSettings, true)
    }

    func testShowTrackingProtectionDetailsAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.showDetails, false)

        let action = getMiddlewareAction(for: .showTrackingProtectionDetails)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.showDetails, true)
    }

    func testShowBlockedTrackersAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.showBlockedTrackers, false)

        let action = getMiddlewareAction(for: .showBlockedTrackersDetails)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.shouldDismiss, false)
        XCTAssertEqual(newState.showBlockedTrackers, true)
    }

    func testToggleTrackingProtectionAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.trackingProtectionEnabled, true)

        let action = getAction(for: .toggleTrackingProtectionStatus)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.trackingProtectionEnabled, false)
    }

    // MARK: - Private
    private func createSubject() -> TrackingProtectionState {
        return TrackingProtectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func trackingProtectionReducer() -> Reducer<TrackingProtectionState> {
        return TrackingProtectionState.reducer
    }

    private func getMiddlewareAction(
        for actionType: TrackingProtectionMiddlewareActionType
    ) -> TrackingProtectionMiddlewareAction {
        return  TrackingProtectionMiddlewareAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func getAction(for actionType: TrackingProtectionActionType) -> TrackingProtectionAction {
        return  TrackingProtectionAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
