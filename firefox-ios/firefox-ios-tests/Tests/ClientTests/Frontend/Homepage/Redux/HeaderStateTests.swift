// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HeaderStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.isPrivate)
        XCTAssertFalse(initialState.showiPadSetup)
        XCTAssertFalse(initialState.isWorldCupSectionEnabled)
    }

    @MainActor
    func test_worldCupDidUpdate_sectionEnabled_setsFlagTrue() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: true
            )
        )

        XCTAssertTrue(newState.isWorldCupSectionEnabled)
    }

    @MainActor
    func test_worldCupDidUpdate_sectionDisabled_setsFlagFalse() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: false
            )
        )

        XCTAssertFalse(newState.isWorldCupSectionEnabled)
    }

    @MainActor
    func test_viewWillAppearAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                showiPadSetup: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.viewWillAppear
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isPrivate)
        XCTAssertTrue(newState.showiPadSetup)
    }

    @MainActor
    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                showiPadSetup: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isPrivate)
        XCTAssertTrue(newState.showiPadSetup)
    }

    @MainActor
    func test_initializeAction_withoutIpadSetup_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                showiPadSetup: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isPrivate)
        XCTAssertFalse(newState.showiPadSetup)
    }

    func test_init_worldCupFeatureAndSectionEnabled_setsWorldCupFlagTrue() {
        let store = MockWorldCupStore()
        store.isFeatureEnabled = true
        store.isHomepageSectionEnabled = true

        let state = HeaderState(windowUUID: .XCTestDefaultUUID, worldCupStore: store)

        XCTAssertTrue(state.isWorldCupSectionEnabled)
    }

    func test_init_worldCupFeatureDisabled_setsWorldCupFlagFalse() {
        let store = MockWorldCupStore()
        store.isFeatureEnabled = false
        store.isHomepageSectionEnabled = true

        let state = HeaderState(windowUUID: .XCTestDefaultUUID, worldCupStore: store)

        XCTAssertFalse(state.isWorldCupSectionEnabled)
    }

    func test_init_worldCupSectionDisabled_setsWorldCupFlagFalse() {
        let store = MockWorldCupStore()
        store.isFeatureEnabled = true
        store.isHomepageSectionEnabled = false

        let state = HeaderState(windowUUID: .XCTestDefaultUUID, worldCupStore: store)

        XCTAssertFalse(state.isWorldCupSectionEnabled)
    }

    func test_init_privateMode_forcesWorldCupFlagFalse_evenWhenStoreEnabled() {
        let store = MockWorldCupStore()
        store.isFeatureEnabled = true
        store.isHomepageSectionEnabled = true

        let state = HeaderState(
            windowUUID: .XCTestDefaultUUID,
            isPrivate: true,
            worldCupStore: store
        )

        XCTAssertTrue(state.isPrivate)
        XCTAssertFalse(state.isWorldCupSectionEnabled)
    }

    // MARK: - Private
    private func createSubject(worldCupStore: WorldCupStoreProtocol? = nil) -> HeaderState {
        let store = worldCupStore ?? {
            let mock = MockWorldCupStore()
            mock.isFeatureEnabled = false
            mock.isHomepageSectionEnabled = false
            return mock
        }()
        return HeaderState(windowUUID: .XCTestDefaultUUID, worldCupStore: store)
    }

    private func headerReducer() -> Reducer<HeaderState> {
        return HeaderState.reducer
    }
}
