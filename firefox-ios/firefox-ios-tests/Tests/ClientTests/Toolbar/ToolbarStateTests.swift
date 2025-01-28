// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common

@testable import Client

final class ToolbarStateTests: XCTestCase, StoreTestUtility {
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
        XCTAssertEqual(initialState.toolbarPosition, .top)
        XCTAssertFalse(initialState.isPrivateMode)
        XCTAssertEqual(initialState.addressToolbar, AddressBarState(windowUUID: windowUUID))
        XCTAssertEqual(initialState.navigationToolbar, NavigationBarState(windowUUID: windowUUID))
        XCTAssertTrue(initialState.isShowingNavigationToolbar)
        XCTAssertFalse(initialState.isShowingTopTabs)
        XCTAssertFalse(initialState.canGoBack)
        XCTAssertFalse(initialState.canGoForward)
        XCTAssertEqual(initialState.numberOfTabs, 1)
        XCTAssertFalse(initialState.showMenuWarningBadge)
        XCTAssertFalse(initialState.isNewTabFeatureEnabled)
        XCTAssertFalse(initialState.canShowDataClearanceAction)
        XCTAssertFalse(initialState.canShowNavigationHint)
    }

    // MARK: - Private
    private func createSubject() -> ToolbarState {
        return ToolbarState(windowUUID: windowUUID)
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
