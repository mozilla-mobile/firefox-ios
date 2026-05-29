// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HeaderStateTests: XCTestCase {
    private var mockWorldCupStore: MockWorldCupStore!

    override func setUp() {
        super.setUp()
        mockWorldCupStore = MockWorldCupStore()
    }

    override func tearDown() {
        mockWorldCupStore = nil
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.isPrivate)
        XCTAssertFalse(initialState.showiPadSetup)
        XCTAssertTrue(initialState.isWorldCupSectionEnabled)
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
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true

        let state = createSubject()

        XCTAssertTrue(state.isWorldCupSectionEnabled)
    }

    func test_init_worldCupFeatureDisabled_setsWorldCupFlagFalse() {
        mockWorldCupStore.isFeatureEnabled = false
        mockWorldCupStore.isHomepageSectionEnabled = true

        let state = createSubject()

        XCTAssertFalse(state.isWorldCupSectionEnabled)
    }

    func test_init_worldCupSectionDisabled_setsWorldCupFlagFalse() {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = false

        let state = createSubject()

        XCTAssertFalse(state.isWorldCupSectionEnabled)
    }

    func test_init_privateMode_forcesWorldCupFlagFalse_evenWhenStoreEnabled() {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true

        let state = createSubject(isPrivate: true)

        XCTAssertTrue(state.isPrivate)
        XCTAssertFalse(state.isWorldCupSectionEnabled)
    }

    // MARK: - Private
    private func createSubject(isPrivate: Bool = false) -> HeaderState {
        return HeaderState(
            windowUUID: .XCTestDefaultUUID,
            isPrivate: isPrivate,
            worldCupStore: mockWorldCupStore
        )
    }

    private func headerReducer() -> Reducer<HeaderState> {
        return HeaderState.reducer
    }
}
