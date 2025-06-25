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
        XCTAssertTrue(initialState.shouldShowSearchBar)
    }

    func test_tapOnHomepageSearchBarAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = searchBarReducer()

        let newState = reducer(
            initialState,
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.zeroSearch),
                windowUUID: .XCTestDefaultUUID,
                actionType: NavigationBrowserActionType.tapOnHomepageSearchBar
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.shouldShowSearchBar)
    }

    func test_toolbarCancelEditAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = searchBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: ToolbarActionType.cancelEdit
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldShowSearchBar)
    }

    // MARK: - Private
    private func createSubject() -> SearchBarState {
        return SearchBarState(windowUUID: .XCTestDefaultUUID)
    }

    private func searchBarReducer() -> Reducer<SearchBarState> {
        return SearchBarState.reducer
    }
}
