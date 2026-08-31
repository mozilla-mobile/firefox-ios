// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common

@testable import Client

@MainActor
final class NavigationActionsStateTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    func test_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, windowUUID)
        XCTAssertTrue(initialState.isShowingNavigationToolbar)
        XCTAssertFalse(initialState.canGoBack)
        XCTAssertFalse(initialState.canGoForward)
        XCTAssertEqual(initialState.actions, [])
    }

    func test_didLoadToolbarsAction_resetsToInitialState() {
        let initialState = NavigationActionsState(
            windowUUID: windowUUID,
            isShowingNavigationToolbar: false,
            canGoBack: true,
            canGoForward: true
        )
        let reducer = navigationActionsReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.didLoadToolbars)
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertTrue(newState.isShowingNavigationToolbar)
        XCTAssertFalse(newState.canGoBack)
        XCTAssertFalse(newState.canGoForward)
        XCTAssertEqual(newState.actions, [])
    }

    func test_backForwardButtonStateChangedAction_updatesCanGoBackAndCanGoForward() {
        let initialState = createSubject()
        let reducer = navigationActionsReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                canGoBack: true,
                canGoForward: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.backForwardButtonStateChanged
            )
        )

        XCTAssertTrue(newState.canGoBack)
        XCTAssertTrue(newState.canGoForward)
    }

    func test_backForwardButtonStateChangedAction_withOnlyCanGoBack_preservesCanGoForward() {
        let initialState = createSubject().copy(canGoForward: true)
        let reducer = navigationActionsReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                canGoBack: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.backForwardButtonStateChanged
            )
        )

        XCTAssertTrue(newState.canGoBack)
        XCTAssertTrue(newState.canGoForward)
    }

    func test_traitCollectionDidChangeAction_updatesIsShowingNavigationToolbar() {
        let initialState = createSubject()
        let reducer = navigationActionsReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                isShowingNavigationToolbar: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.traitCollectionDidChange
            )
        )

        XCTAssertFalse(newState.isShowingNavigationToolbar)
    }

    func test_urlDidChangeAction_updatesAllThreeFields() {
        let initialState = createSubject()
        let reducer = navigationActionsReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                isShowingNavigationToolbar: false,
                canGoBack: true,
                canGoForward: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.urlDidChange
            )
        )

        XCTAssertFalse(newState.isShowingNavigationToolbar)
        XCTAssertTrue(newState.canGoBack)
        XCTAssertTrue(newState.canGoForward)
    }

    func test_unrelatedAction_returnsUnchangedState() {
        let initialState = createSubject().copy(canGoBack: true)
        let reducer = navigationActionsReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.didSetSearchTerm)
        )

        XCTAssertEqual(newState, initialState)
    }

    func test_actions_whenShowingNavigationToolbar_isEmpty() {
        let initialState = createSubject()
        let reducer = navigationActionsReducer()

        let state = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                canGoBack: true,
                canGoForward: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.backForwardButtonStateChanged
            )
        )

        XCTAssertEqual(state.actions, [])
    }

    func test_actions_whenNotShowingNavigationToolbar_returnsBackAndForward() {
        let initialState = createSubject()
        let reducer = navigationActionsReducer()

        let state = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                isShowingNavigationToolbar: false,
                canGoBack: true,
                canGoForward: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.urlDidChange
            )
        )

        XCTAssertEqual(state.actions.count, 2)
        XCTAssertEqual(state.actions[0].actionType, .back)
        XCTAssertEqual(state.actions[0].isEnabled, true)
        XCTAssertEqual(state.actions[1].actionType, .forward)
        XCTAssertEqual(state.actions[1].isEnabled, false)
    }

    // MARK: - Helper
    private func createSubject() -> NavigationActionsState {
        return NavigationActionsState(windowUUID: windowUUID)
    }

    private func navigationActionsReducer() -> Reducer<NavigationActionsState> {
        return NavigationActionsState.reducer
    }
}
