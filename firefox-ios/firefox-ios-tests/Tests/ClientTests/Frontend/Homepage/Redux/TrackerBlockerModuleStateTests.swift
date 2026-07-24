// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class TrackerBlockerModuleStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_initialState_hasZeroBlockedCount() {
        let state = createSubject()
        XCTAssertEqual(state.blockedTrackerCount, 0)
    }

    @MainActor func test_updateBlockedCountAction_setsCount() {
        let state = createSubject()

        let newState = TrackerBlockerModuleState.reducer(
            state,
            TrackerBlockerModuleAction(
                blockedTrackerCount: 42,
                windowUUID: .XCTestDefaultUUID,
                actionType: TrackerBlockerModuleMiddlewareActionType.updateBlockedCount
            )
        )

        XCTAssertEqual(newState.blockedTrackerCount, 42)
    }

    @MainActor func test_updateBlockedCountAction_withoutCount_keepsExistingCount() {
        let state = TrackerBlockerModuleState.reducer(
            createSubject(),
            TrackerBlockerModuleAction(
                blockedTrackerCount: 7,
                windowUUID: .XCTestDefaultUUID,
                actionType: TrackerBlockerModuleMiddlewareActionType.updateBlockedCount
            )
        )

        // A malformed update (no count) must not clobber the previously stored value.
        let newState = TrackerBlockerModuleState.reducer(
            state,
            TrackerBlockerModuleAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: TrackerBlockerModuleMiddlewareActionType.updateBlockedCount
            )
        )

        XCTAssertEqual(newState.blockedTrackerCount, 7)
    }

    @MainActor func test_unrelatedAction_preservesCount() {
        let state = TrackerBlockerModuleState.reducer(
            createSubject(),
            TrackerBlockerModuleAction(
                blockedTrackerCount: 15,
                windowUUID: .XCTestDefaultUUID,
                actionType: TrackerBlockerModuleMiddlewareActionType.updateBlockedCount
            )
        )

        let newState = TrackerBlockerModuleState.reducer(
            state,
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewDidAppear)
        )

        XCTAssertEqual(newState.blockedTrackerCount, 15)
    }

    private func createSubject() -> TrackerBlockerModuleState {
        return TrackerBlockerModuleState(windowUUID: .XCTestDefaultUUID)
    }
}
