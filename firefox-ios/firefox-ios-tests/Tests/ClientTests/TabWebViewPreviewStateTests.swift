// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Redux
import Common

@testable import Client

final class TabWebViewPreviewStateTests: XCTestCase, StoreTestUtility {
    override func setUp() {
        super.setUp()
        setupStore()
    }

    override func tearDown() {
        super.tearDown()
        resetStore()
    }

    private func test_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, WindowUUID.unavailable)
        XCTAssertEqual(initialState.addressBarPosition, SearchBarPosition.top)
    }

    private func test_changeAddressBarPosition_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = TabWebViewPreviewState.reducer
        let newState = reducer(
            initialState, TabWebViewPreviewAction(
                addressBarPosition: .bottom,
                actionType: TabWebViewPreviewActionType.changeAddressBarPosition
            )
        )

        XCTAssertEqual(newState.addressBarPosition, SearchBarPosition.bottom)
    }

    // MARK: - Helpers
    private func createSubject() -> TabWebViewPreviewState {
        return TabWebViewPreviewState()
    }

    // MARK: - StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .tabWebViewPreview(TabWebViewPreviewState())
                ]
            )
        )
    }

    func setupStore() {
        StoreTestUtilityHelper.setupStore(with: setupAppState(), middlewares: [])
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
