// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class SearchBarStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(initialState.isShowingCenterSearchBar)
    }

    @MainActor
    func test_configuredSearchBarAction_withTrueAndHomepageVisible_returnsExpectedState() {
        let reducer = searchBarReducer()
        let visibleState = reducer.legacyReducer(
            createSubject(),
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewWillAppear)
        )

        let newState = reducer.legacyReducer(
            visibleState,
            HomepageAction(
                isCenterSearchEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredSearchBar
            )
        )

        XCTAssertTrue(newState.isShowingCenterSearchBar)
    }

    @MainActor
    func test_configuredSearchBarAction_withTrueAndHomepageNotVisible_returnsExpectedState() {
        let reducer = searchBarReducer()

        let newState = reducer.legacyReducer(
            createSubject(),
            HomepageAction(
                isCenterSearchEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredSearchBar
            )
        )

        XCTAssertFalse(newState.isShowingCenterSearchBar)
    }

    @MainActor
    func test_viewWillDisappear_hidesSearchBar() {
        let reducer = searchBarReducer()
        let visibleState = reducer.legacyReducer(
            createSubject(),
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewWillAppear)
        )
        let shownState = reducer.legacyReducer(
            visibleState,
            HomepageAction(
                isCenterSearchEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredSearchBar
            )
        )

        let newState = reducer.legacyReducer(
            shownState,
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewWillDisappear)
        )

        XCTAssertFalse(newState.isShowingCenterSearchBar)
        XCTAssertFalse(newState.isHomepageVisible)
    }

    @MainActor
    func test_configuredSearchBarAction_withFalse_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = searchBarReducer()

        let newState = reducer.legacyReducer(
            initialState,
            HomepageAction(
                isCenterSearchEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredSearchBar
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isShowingCenterSearchBar)
    }

    @MainActor
    func test_enteredZeroSearchState_withGeneralBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = searchBarReducer()

        let newState = reducer.legacyReducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.enteredZeroSearchScreen
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isShowingCenterSearchBar)
    }

    // MARK: - Private
    private func createSubject() -> SearchBarState {
        return SearchBarState(windowUUID: .XCTestDefaultUUID)
    }

    private func searchBarReducer() -> Reducer<SearchBarState> {
        return SearchBarState.reducer
    }
}
