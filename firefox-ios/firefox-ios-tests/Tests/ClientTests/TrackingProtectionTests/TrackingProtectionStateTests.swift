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
        super.tearDown()
        mockProfile = nil
    }

    func testDismissTrackingProtectionAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.navigateTo, .home)
        XCTAssertNil(initialState.displayView)
        XCTAssertEqual(initialState.shouldClearCookies, false)

        let action = getMiddlewareAction(for: .dismissTrackingProtection)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .close)
        XCTAssertNil(newState.displayView)
        XCTAssertEqual(newState.shouldClearCookies, false)
    }

    func testNavigateToSettingsAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.navigateTo, .home)
        XCTAssertNil(initialState.displayView)

        let action = getMiddlewareAction(for: .navigateToSettings)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .settings)
        XCTAssertNil(newState.displayView)
    }

    func testShowTrackingProtectionDetailsAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertNil(initialState.displayView)
        XCTAssertEqual(initialState.navigateTo, .home)

        let action = getMiddlewareAction(for: .showTrackingProtectionDetails)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.displayView, .trackingProtectionDetails)
        XCTAssertNil(newState.navigateTo)
    }

    func testShowBlockedTrackersDetailsAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertNil(initialState.displayView)
        XCTAssertEqual(initialState.navigateTo, .home)

        let action = getMiddlewareAction(for: .showBlockedTrackersDetails)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.displayView, .blockedTrackersDetails)
        XCTAssertNil(newState.navigateTo)
    }

    func testToggleTrackingProtectionStatusAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.trackingProtectionEnabled, true)

        let action = getAction(for: .toggleTrackingProtectionStatus)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.trackingProtectionEnabled, false)
        XCTAssertNil(newState.navigateTo)
        XCTAssertNil(newState.displayView)
    }

    func testUpdateBlockedTrackerStatsAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.shouldUpdateBlockedTrackerStats, false)

        let action = getAction(for: .updateBlockedTrackerStats)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.shouldUpdateBlockedTrackerStats, true)
        XCTAssertEqual(newState.shouldUpdateConnectionStatus, false)
        XCTAssertNil(newState.navigateTo)
        XCTAssertNil(newState.displayView)
    }

    func testUpdateConnectionStatusAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.shouldUpdateConnectionStatus, false)

        let action = getAction(for: .updateConnectionStatus)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.shouldUpdateConnectionStatus, true)
        XCTAssertEqual(newState.shouldUpdateBlockedTrackerStats, false)
        XCTAssertNil(newState.navigateTo)
        XCTAssertNil(newState.displayView)
    }

    // MARK: - Private Helper Methods

    private func createSubject() -> TrackingProtectionState {
        return TrackingProtectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func trackingProtectionReducer() -> Reducer<TrackingProtectionState> {
        return TrackingProtectionState.reducer
    }

    private func getMiddlewareAction(
        for actionType: TrackingProtectionMiddlewareActionType
    ) -> Action {
        return TrackingProtectionMiddlewareAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func getAction(for actionType: TrackingProtectionActionType) -> Action {
        return TrackingProtectionAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
