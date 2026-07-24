// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

@MainActor
final class HeaderStateTests: XCTestCase {
    private var mockWorldCupStore: MockWorldCupStore!
    private var mockQuickAnswersStore: MockQuickAnswersStore!

    override func setUp() async throws {
        try await super.setUp()
        mockWorldCupStore = MockWorldCupStore()
        mockQuickAnswersStore = MockQuickAnswersStore()
    }

    override func tearDown() async throws {
        mockWorldCupStore = nil
        mockQuickAnswersStore = nil
        try await super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.isPrivate)
        XCTAssertTrue(initialState.isWorldCupSectionEnabled)
        XCTAssertFalse(initialState.showQuickAnswersButton)
    }

    func test_worldCupDidUpdate_sectionEnabled_setsFlagTrue() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer.legacyReducer(
            initialState,
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: true
            )
        )

        XCTAssertTrue(newState.isWorldCupSectionEnabled)
    }

    func test_worldCupDidUpdate_sectionDisabled_setsFlagFalse() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer.legacyReducer(
            initialState,
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: false
            )
        )

        XCTAssertFalse(newState.isWorldCupSectionEnabled)
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isPrivate)
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

    func test_init_quickAnswersEnabled_setsShowQuickAnswersButtonTrue() {
        mockQuickAnswersStore.isQuickAnswersEnabled = true

        let state = createSubject()

        XCTAssertTrue(state.showQuickAnswersButton)
    }

    func test_init_quickAnswersDisabled_setsShowQuickAnswersButtonFalse() {
        mockQuickAnswersStore.isQuickAnswersEnabled = false

        let state = createSubject()

        XCTAssertFalse(state.showQuickAnswersButton)
    }

    func test_init_privateMode_forcesShowQuickAnswersButtonFalse_evenWhenStoreEnabled() {
        mockQuickAnswersStore.isQuickAnswersEnabled = true

        let state = createSubject(isPrivate: true)

        XCTAssertTrue(state.isPrivate)
        XCTAssertFalse(state.showQuickAnswersButton)
    }

    func test_quickAnswersDidUpdateSettings_enabled_setsShowQuickAnswersButtonTrue() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer.legacyReducer(
            initialState,
            QuickAnswersMiddlewareAction(
                isQuickAnswersEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: QuickAnswersMiddlewareActionType.didUpdateSettings
            )
        )

        XCTAssertTrue(newState.showQuickAnswersButton)
    }

    func test_quickAnswersDidUpdateSettings_disabled_setsShowQuickAnswersButtonFalse() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer.legacyReducer(
            initialState,
            QuickAnswersMiddlewareAction(
                isQuickAnswersEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: QuickAnswersMiddlewareActionType.didUpdateSettings
            )
        )

        XCTAssertFalse(newState.showQuickAnswersButton)
    }

    func test_quickAnswersDidUpdateSettings_enabledInPrivateMode_setsShowQuickAnswersButtonFalse() {
        let initialState = createSubject(isPrivate: true)
        let reducer = headerReducer()

        let newState = reducer.legacyReducer(
            initialState,
            QuickAnswersMiddlewareAction(
                isQuickAnswersEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: QuickAnswersMiddlewareActionType.didUpdateSettings
            )
        )

        XCTAssertFalse(newState.showQuickAnswersButton)
    }

    // MARK: - Private
    private func createSubject(isPrivate: Bool = false) -> HeaderState {
        return HeaderState(
            windowUUID: .XCTestDefaultUUID,
            isPrivate: isPrivate,
            worldCupStore: mockWorldCupStore,
            quickAnswersStore: mockQuickAnswersStore
        )
    }

    private func headerReducer() -> Reducer<HeaderState> {
        return HeaderState.reducer
    }
}
