// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Redux
@testable import Client

final class TermsOfUseStateTests: XCTestCase {
    let windowUUID = WindowUUID.XCTestDefaultUUID

    func testInit_WithWindowUUID_CreatesDefaultState() {
        let state = TermsOfUseState(windowUUID: windowUUID)

        XCTAssertEqual(state.windowUUID, windowUUID)
        XCTAssertFalse(state.hasAccepted)
        XCTAssertFalse(state.wasDismissed)
    }

    func testInit_WithAllParameters_SetsCorrectValues() {
        let state = TermsOfUseState(
            windowUUID: windowUUID,
            hasAccepted: true,
            wasDismissed: true
        )

        XCTAssertEqual(state.windowUUID, windowUUID)
        XCTAssertTrue(state.hasAccepted)
        XCTAssertTrue(state.wasDismissed)
    }

    func testInit_FromAppState_WithNoExistingState_CreatesDefault() {
        let appState = AppState()
        let state = TermsOfUseState(appState: appState, uuid: windowUUID)

        XCTAssertEqual(state.windowUUID, windowUUID)
        XCTAssertFalse(state.hasAccepted)
        XCTAssertFalse(state.wasDismissed)
    }

    @MainActor
    func testReducer_TermsAccepted_SetsAcceptedTrue() {
        var state = TermsOfUseState(windowUUID: windowUUID)
        let action = TermsOfUseAction(windowUUID: windowUUID, actionType: .termsAccepted)

        state = TermsOfUseState.reducer(state, action)

        XCTAssertTrue(state.hasAccepted)
        XCTAssertFalse(state.wasDismissed)
    }

    @MainActor
    func testReducer_GestureDismiss_SetsDismissedTrue() {
        var state = TermsOfUseState(windowUUID: windowUUID)
        let action = TermsOfUseAction(windowUUID: windowUUID, actionType: .gestureDismiss)

        state = TermsOfUseState.reducer(state, action)

        XCTAssertFalse(state.hasAccepted)
        XCTAssertTrue(state.wasDismissed)
    }

    @MainActor
    func testReducer_RemindMeLaterTapped_SetsDismissedTrue() {
        var state = TermsOfUseState(windowUUID: windowUUID)
        let action = TermsOfUseAction(windowUUID: windowUUID, actionType: .remindMeLaterTapped)

        state = TermsOfUseState.reducer(state, action)

        XCTAssertFalse(state.hasAccepted)
        XCTAssertTrue(state.wasDismissed)
    }

    @MainActor
    func testReducer_LinkActions_DoNotChangeState() {
        var state = TermsOfUseState(
            windowUUID: windowUUID,
            hasAccepted: true,
            wasDismissed: false
        )

        let action = TermsOfUseAction(windowUUID: windowUUID, actionType: .learnMoreLinkTapped)
        state = TermsOfUseState.reducer(state, action)

        XCTAssertTrue(state.hasAccepted)
        XCTAssertFalse(state.wasDismissed)
    }

    @MainActor
    func testReducer_WithDifferentWindowUUID_ReturnsDefaultState() {
        var state = TermsOfUseState(
            windowUUID: windowUUID,
            hasAccepted: true,
            wasDismissed: true
        )

        let differentUUID = WindowUUID()
        let action = TermsOfUseAction(windowUUID: differentUUID, actionType: .termsAccepted)

        state = TermsOfUseState.reducer(state, action)

        XCTAssertTrue(state.hasAccepted)
        XCTAssertTrue(state.wasDismissed)
    }

    func testDefaultState_PreservesValues() {
        let originalState = TermsOfUseState(
            windowUUID: windowUUID,
            hasAccepted: true,
            wasDismissed: true
        )

        let defaultState = TermsOfUseState.defaultState(from: originalState)

        XCTAssertEqual(defaultState.windowUUID, originalState.windowUUID)
        XCTAssertEqual(defaultState.hasAccepted, originalState.hasAccepted)
        XCTAssertEqual(defaultState.wasDismissed, originalState.wasDismissed)
    }
}
