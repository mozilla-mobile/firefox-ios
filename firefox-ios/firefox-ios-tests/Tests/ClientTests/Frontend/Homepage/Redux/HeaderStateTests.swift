// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

@MainActor
final class HeaderStateTests: XCTestCase {
    private var mockQuickAnswersStore: MockQuickAnswersStore!

    override func setUp() async throws {
        try await super.setUp()
        mockQuickAnswersStore = MockQuickAnswersStore()
    }

    override func tearDown() async throws {
        mockQuickAnswersStore = nil
        try await super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.isPrivate)
        XCTAssertFalse(initialState.showQuickAnswersButton)
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = headerReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isPrivate)
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

        let newState = reducer(
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

        let newState = reducer(
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

        let newState = reducer(
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
            quickAnswersStore: mockQuickAnswersStore
        )
    }

    private func headerReducer() -> Reducer<HeaderState> {
        return HeaderState.reducer
    }
}
