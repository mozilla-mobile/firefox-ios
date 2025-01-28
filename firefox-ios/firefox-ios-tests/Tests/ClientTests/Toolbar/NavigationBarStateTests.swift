// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common

@testable import Client

final class NavigationBarStateTests: XCTestCase, StoreTestUtility {
    let storeUtilityHelper = StoreTestUtilityHelper()
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, windowUUID)
        XCTAssertEqual(initialState.actions, [])
        XCTAssertFalse(initialState.displayBorder)
    }
    // MARK: - Private
    private func createSubject() -> NavigationBarState {
        return NavigationBarState(windowUUID: windowUUID)
    }

    func setupStore(with initialToolbarState: ToolbarState) {
        StoreTestUtilityHelper.setupStore(
            with: setupAppState(with: initialToolbarState),
            middlewares: [ToolbarMiddleware().toolbarProvider]
        )
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: windowUUID
                        )
                    ),
                    .toolbar(
                        ToolbarState(
                            windowUUID: windowUUID
                        )
                    )
                ]
            )
        )
    }

    func setupStore() {
        StoreTestUtilityHelper.setupStore(
            with: setupAppState(),
            middlewares: [ToolbarMiddleware().toolbarProvider]
        )
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
