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

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()

        // We must reset the global mock store prior to each test
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, windowUUID)
        XCTAssertEqual(initialState.actions, [])
        XCTAssertFalse(initialState.displayBorder)
    }

    func test_didLoadToolbarsAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                displayNavBorder: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didLoadToolbars
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.displayBorder, true)

        XCTAssertEqual(newState.actions.count, 5)
        XCTAssertEqual(newState.actions[0].actionType, .back)
        XCTAssertEqual(newState.actions[0].isEnabled, false)
        XCTAssertEqual(newState.actions[1].actionType, .forward)
        XCTAssertEqual(newState.actions[1].isEnabled, false)
        XCTAssertEqual(newState.actions[2].actionType, .search)
        XCTAssertEqual(newState.actions[3].actionType, .menu)
        XCTAssertEqual(newState.actions[4].actionType, .tabs)
    }

    func test_urlDidChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = loadWebsiteAction(state: initialState, reducer: reducer)

        XCTAssertEqual(newState.windowUUID, windowUUID)

        XCTAssertEqual(newState.actions.count, 5)
        XCTAssertEqual(newState.actions[0].actionType, .back)
        XCTAssertEqual(newState.actions[0].isEnabled, true)
        XCTAssertEqual(newState.actions[1].actionType, .forward)
        XCTAssertEqual(newState.actions[1].isEnabled, false)
        XCTAssertEqual(newState.actions[2].actionType, .home)
        XCTAssertEqual(newState.actions[3].actionType, .menu)
        XCTAssertEqual(newState.actions[4].actionType, .tabs)
    }

    func test_numberOfTabsChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                numberOfTabs: 2,
                isShowingTopTabs: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.numberOfTabsChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.actions.count, 5)
        XCTAssertEqual(newState.actions[0].actionType, .back)
        XCTAssertEqual(newState.actions[1].actionType, .forward)
        XCTAssertEqual(newState.actions[2].actionType, .search)
        XCTAssertEqual(newState.actions[3].actionType, .menu)
        XCTAssertEqual(newState.actions[4].actionType, .tabs)
        XCTAssertEqual(newState.actions[4].numberOfTabs, 2)
    }

    func test_backForwardButtonStateChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let urlDidChangeState = loadWebsiteAction(state: initialState, reducer: reducer)
        let newState = reducer(
            urlDidChangeState,
            ToolbarAction(
                canGoBack: true,
                canGoForward: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.backForwardButtonStateChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.actions[0].actionType, .back)
        XCTAssertEqual(newState.actions[0].isEnabled, true)
        XCTAssertEqual(newState.actions[1].actionType, .forward)
        XCTAssertEqual(newState.actions[1].isEnabled, false)
    }

    func test_showMenuWarningBadgeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                showMenuWarningBadge: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.showMenuWarningBadge
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)

        XCTAssertEqual(newState.actions[3].actionType, .menu)
        XCTAssertNotNil(newState.actions[3].badgeImageName)
        XCTAssertNotNil(newState.actions[3].maskImageName)
    }

    func test_borderPositionChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = navigationBarReducer()

        let newState = reducer(
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

        let newState = reducer(
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

    // MARK: - Private
    private func createSubject() -> NavigationBarState {
        return NavigationBarState(windowUUID: windowUUID)
    }

    private func navigationBarReducer() -> Reducer<NavigationBarState> {
        return NavigationBarState.reducer
    }

    private func loadWebsiteAction(state: NavigationBarState, reducer: Reducer<NavigationBarState>) -> NavigationBarState {
        return reducer(
            state,
            ToolbarAction(
                url: URL(string: "http://mozilla.com"),
                isPrivate: false,
                isShowingNavigationToolbar: true,
                canGoBack: true,
                canGoForward: false,
                lockIconImageName: StandardImageIdentifiers.Large.lockFill,
                safeListedURLImageName: nil,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.urlDidChange
            )
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
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
