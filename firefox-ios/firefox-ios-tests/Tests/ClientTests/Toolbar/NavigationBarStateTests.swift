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
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()

        // We must reset the global mock store prior to each test
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, windowUUID)
        XCTAssertEqual(initialState.middleButton, .newTab)
        XCTAssertFalse(initialState.displayBorder)
    }

    func test_didLoadToolbarsAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                toolbarPosition: .bottom,
                toolbarLayout: .version1,
                isTranslucent: true,
                addressBorderPosition: .none,
                displayNavBorder: true,
                middleButton: .newTab,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didLoadToolbars
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.displayBorder, true)
        XCTAssertEqual(newState.middleButton, .newTab)
    }

    func test_borderPositionChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                addressBorderPosition: .top,
                displayNavBorder: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.borderPositionChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.displayBorder, true)
    }

    func test_toolbarPositionChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                toolbarPosition: .top,
                addressBorderPosition: .bottom,
                displayNavBorder: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.toolbarPositionChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.displayBorder, true)
    }

    func test_navigationMiddleButtonDidChangeAction_updatesMiddleButton() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = reducer.legacyReducer(
            initialState,
            ToolbarAction(
                middleButton: .home,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.navigationMiddleButtonDidChange
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.middleButton, .home)
    }

    // MARK: - Private
    private func createSubject() -> NavigationBarState {
        return NavigationBarState(windowUUID: windowUUID)
    }

    private func navigationBarReducer() -> Reducer<NavigationBarState> {
        return NavigationBarState.reducer
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
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
}
