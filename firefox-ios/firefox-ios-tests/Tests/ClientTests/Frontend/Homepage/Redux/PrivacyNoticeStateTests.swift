// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class PrivacyNoticeStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_initialState_doesNotShowPrivacyNotice() {
        let state = createSubject()

        XCTAssertFalse(state.shouldShowPrivacyNotice)
        XCTAssertEqual(state.windowUUID, .XCTestDefaultUUID)
    }

    @MainActor
    func test_configuredPrivacyNoticeAction_showsPrivacyNotice() {
        let newState = PrivacyNoticeState.reducer.legacyReducer(
            createSubject(),
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
            )
        )

        XCTAssertTrue(newState.shouldShowPrivacyNotice)
    }

    @MainActor
    func test_privacyNoticeCloseButtonTappedAction_hidesPrivacyNotice() {
        let newState = PrivacyNoticeState.reducer.legacyReducer(
            configuredState(),
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.privacyNoticeCloseButtonTapped
            )
        )

        XCTAssertFalse(newState.shouldShowPrivacyNotice)
    }

    @MainActor
    func test_unrelatedAction_keepsPrivacyNoticeShown() {
        let newState = PrivacyNoticeState.reducer.legacyReducer(
            configuredState(),
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewDidAppear)
        )

        XCTAssertTrue(newState.shouldShowPrivacyNotice)
    }

    @MainActor
    func test_actionForAnotherWindow_keepsPrivacyNoticeShown() {
        let newState = PrivacyNoticeState.reducer.legacyReducer(
            configuredState(),
            HomepageAction(
                windowUUID: WindowUUID(uuidString: "E9E9E9E9-E9E9-E9E9-E9E9-CCCCCCCCCCCC")!,
                actionType: HomepageActionType.privacyNoticeCloseButtonTapped
            )
        )

        XCTAssertTrue(newState.shouldShowPrivacyNotice)
    }

    private func createSubject() -> PrivacyNoticeState {
        return PrivacyNoticeState(windowUUID: .XCTestDefaultUUID)
    }

    /// A state that is already showing the notice, so tests can observe it being turned off or preserved.
    @MainActor
    private func configuredState() -> PrivacyNoticeState {
        return PrivacyNoticeState.reducer.legacyReducer(
            createSubject(),
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
            )
        )
    }
}
