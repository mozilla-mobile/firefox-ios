// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common

@testable import Client

final class AddressBarStateTests: XCTestCase, StoreTestUtility {
    let storeUtilityHelper = StoreTestUtilityHelper()
    let windowUUID: WindowUUID = .XCTestDefaultUUID

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

        XCTAssertEqual(initialState.windowUUID, windowUUID)
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
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didLoadToolbars
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
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
                windowUUID: windowUUID,
                actionType: ToolbarActionType.numberOfTabsChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[0].numberOfTabs, 2)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)
    }

    func test_readerModeStateChangedAction_onHomepage_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                readerModeState: .available,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.readerModeStateChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.pageActions.count, 1)
        XCTAssertEqual(newState.pageActions[0].actionType, .qrCode)
    }

    func test_readerModeStateChangedAction_onWebsite_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let urlDidChangeState = loadWebsiteAction(state: initialState, reducer: reducer)
        let newState = reducer(
            urlDidChangeState,
            ToolbarAction(
                readerModeState: .available,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.readerModeStateChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.pageActions.count, 3)
        XCTAssertEqual(newState.pageActions[0].actionType, .readerMode)
        XCTAssertEqual(newState.pageActions[0].iconName, StandardImageIdentifiers.Large.readerView)
        XCTAssertEqual(newState.pageActions[1].actionType, .share)
        XCTAssertEqual(newState.pageActions[2].actionType, .reload)
    }

    func test_websiteLoadingStateDidChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let urlDidChangeState = loadWebsiteAction(state: initialState, reducer: reducer)
        let newState = reducer(
            urlDidChangeState,
            ToolbarAction(
                isLoading: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.websiteLoadingStateDidChange
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.pageActions.count, 2)
        XCTAssertEqual(newState.pageActions[0].actionType, .share)
        XCTAssertEqual(newState.pageActions[1].actionType, .stopLoading)
    }

    func test_urlDidChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = loadWebsiteAction(state: initialState, reducer: reducer)

        XCTAssertEqual(newState.windowUUID, windowUUID)

        XCTAssertEqual(newState.pageActions.count, 2)
        XCTAssertEqual(newState.pageActions[0].actionType, .share)
        XCTAssertEqual(newState.pageActions[1].actionType, .reload)

        XCTAssertEqual(newState.browserActions.count, 3)
        XCTAssertEqual(newState.browserActions[0].actionType, .newTab)
        XCTAssertEqual(newState.browserActions[1].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[2].actionType, .menu)
    }

    func test_clearSearchAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.clearSearch
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)

        XCTAssertEqual(newState.pageActions.count, 1)
        XCTAssertEqual(newState.pageActions[0].actionType, .qrCode)

        XCTAssertTrue(newState.isEditing)
        XCTAssertTrue(newState.showQRPageAction)
    }

    func test_didDeleteSearchTermAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didDeleteSearchTerm
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)

        XCTAssertEqual(newState.pageActions.count, 1)
        XCTAssertEqual(newState.pageActions[0].actionType, .qrCode)

        XCTAssertTrue(newState.isEditing)
        XCTAssertTrue(newState.didStartTyping)
        XCTAssertTrue(newState.showQRPageAction)
    }

    func test_didEnterSearchTermAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didEnterSearchTerm
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.pageActions.count, 0)
        XCTAssertTrue(newState.isEditing)
        XCTAssertTrue(newState.didStartTyping)
        XCTAssertFalse(newState.showQRPageAction)
    }

    func test_didStartTypingAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didStartTyping
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertTrue(newState.didStartTyping)
    }

    // MARK: - Private
    private func createSubject() -> AddressBarState {
        return AddressBarState(windowUUID: windowUUID)
    }

    private func addressBarReducer() -> Reducer<AddressBarState> {
        return AddressBarState.reducer
    }

    private func loadWebsiteAction(state: AddressBarState, reducer: Reducer<AddressBarState>) -> AddressBarState {
        return reducer(
            state,
            ToolbarAction(
                url: URL(string: "http://mozilla.com", invalidCharacters: false),
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
