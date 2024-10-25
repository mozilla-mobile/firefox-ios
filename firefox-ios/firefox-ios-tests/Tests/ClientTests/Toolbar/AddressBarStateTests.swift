// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class AddressBarStateTests: XCTestCase, StoreTestUtility {
    let storeUtilityHelper = StoreTestUtilityHelper()
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupTestingStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetTestingStore()
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.navigationActions, [])
        XCTAssertEqual(initialState.pageActions, [])
        XCTAssertEqual(initialState.browserActions, [])
        XCTAssertNil(initialState.borderPosition)
        XCTAssertNil(initialState.url)
        XCTAssertNil(initialState.searchTerm)
        XCTAssertNil(initialState.lockIconImageName)
        XCTAssertNil(initialState.safeListedURLImageName)
        XCTAssertFalse(initialState.isEditing)
        XCTAssertFalse(initialState.isScrollingDuringEdit)
        XCTAssertTrue(initialState.shouldSelectSearchTerm)
        XCTAssertFalse(initialState.isLoading)
        XCTAssertNil(initialState.readerModeState)
        XCTAssertFalse(initialState.didStartTyping)
        XCTAssertTrue(initialState.showQRPageAction)
    }

    func test_didLoadToolbarsAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                addressBorderPosition: .top,
                windowUUID: .XCTestDefaultUUID,
                actionType: ToolbarActionType.didLoadToolbars
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.navigationActions, [])

        XCTAssertEqual(newState.pageActions.count, 1)
        XCTAssertEqual(newState.pageActions[0].actionType, .qrCode)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)

        XCTAssertEqual(newState.borderPosition, .top)
        XCTAssertNil(newState.url)
        XCTAssertNil(newState.searchTerm)
        XCTAssertNil(newState.lockIconImageName)
        XCTAssertNil(newState.safeListedURLImageName)
        XCTAssertFalse(newState.isEditing)
        XCTAssertFalse(newState.isScrollingDuringEdit)
        XCTAssertTrue(newState.shouldSelectSearchTerm)
        XCTAssertFalse(newState.isLoading)
        XCTAssertNil(newState.readerModeState)
        XCTAssertFalse(newState.didStartTyping)
        XCTAssertTrue(newState.showQRPageAction)
    }

    func test_numberOfTabsChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                numberOfTabs: 2,
                isShowingTopTabs: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: ToolbarActionType.numberOfTabsChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.browserActions.count, 3)
        XCTAssertEqual(newState.browserActions[0].actionType, .newTab)
        XCTAssertEqual(newState.browserActions[1].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].numberOfTabs, 2)
        XCTAssertEqual(newState.browserActions[2].actionType, .menu)
    }

    func test_didStartTypingAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: ToolbarActionType.didStartTyping
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.didStartTyping)
    }

    // MARK: - Private
    private func createSubject() -> AddressBarState {
        return AddressBarState(windowUUID: .XCTestDefaultUUID)
    }

    private func addressBarReducer() -> Reducer<AddressBarState> {
        return AddressBarState.reducer
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
                    .toolbar(
                        ToolbarState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    )
                ]
            )
        )
    }

    func setupTestingStore() {
        storeUtilityHelper.setupTestingStore(
            with: setupAppState(),
            middlewares: [ToolbarMiddleware().toolbarProvider]
        )
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetTestingStore() {
        storeUtilityHelper.resetTestingStore()
    }
}
