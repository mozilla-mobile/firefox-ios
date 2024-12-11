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
        XCTAssertEqual(initialState.navigationActions, [])
        XCTAssertEqual(initialState.pageActions, [])
        XCTAssertEqual(initialState.browserActions, [])
        XCTAssertNil(initialState.borderPosition)
        XCTAssertNil(initialState.url)
        XCTAssertNil(initialState.searchTerm)
        XCTAssertNil(initialState.lockIconImageName)
        XCTAssertNil(initialState.safeListedURLImageName)
        XCTAssertFalse(initialState.isEditing)
        XCTAssertTrue(initialState.shouldShowKeyboard)
        XCTAssertFalse(initialState.shouldSelectSearchTerm)
        XCTAssertFalse(initialState.isLoading)
        XCTAssertNil(initialState.readerModeState)
        XCTAssertFalse(initialState.didStartTyping)
        XCTAssertTrue(initialState.showQRPageAction)
    }

    func test_didLoadToolbarsAction_returnsExpectedState() {
        setupStore()
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
        XCTAssertTrue(newState.shouldShowKeyboard)
        XCTAssertFalse(newState.shouldSelectSearchTerm)
        XCTAssertFalse(newState.isLoading)
        XCTAssertNil(newState.readerModeState)
        XCTAssertFalse(newState.didStartTyping)
        XCTAssertTrue(newState.showQRPageAction)
    }

    func test_numberOfTabsChangedAction_returnsExpectedState() {
        setupStore()
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
        setupStore()
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
        setupStore()
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
        setupStore()
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
        setupStore()
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

    func test_backForwardButtonStateChangedAction_withNavigationToolbar_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

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
        XCTAssertEqual(newState.navigationActions.count, 0)
    }

    func test_backForwardButtonStateChangedAction_withoutNavigationToolbar_returnsExpectedState() {
        setupStore(with: initialToolbarState(isShowingNavigationToolbar: false))
        let initialState = createSubject()
        let reducer = addressBarReducer()

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
        XCTAssertEqual(newState.navigationActions.count, 2)
        XCTAssertEqual(newState.navigationActions[0].actionType, .back)
        XCTAssertEqual(newState.navigationActions[0].isEnabled, true)
        XCTAssertEqual(newState.navigationActions[1].actionType, .forward)
        XCTAssertEqual(newState.navigationActions[1].isEnabled, false)
    }

    func test_traitCollectionDidChangedAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        // iPhone in landscape
        let newState = reducer(
            initialState,
            ToolbarAction(
                isShowingNavigationToolbar: false,
                isShowingTopTabs: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.traitCollectionDidChange
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.navigationActions.count, 2)
        XCTAssertEqual(newState.navigationActions[0].actionType, .back)
        XCTAssertEqual(newState.navigationActions[1].actionType, .forward)

        XCTAssertEqual(newState.pageActions.count, 1)
        XCTAssertEqual(newState.pageActions[0].actionType, .qrCode)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)

        XCTAssertEqual(newState.searchTerm, nil)
    }

    func test_showMenuWarningBadgeAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                showMenuWarningBadge: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.showMenuWarningBadge
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.navigationActions.count, 0)

        XCTAssertEqual(newState.pageActions.count, 1)
        XCTAssertEqual(newState.pageActions[0].actionType, .qrCode)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)
        XCTAssertNotNil(newState.browserActions[1].badgeImageName)
        XCTAssertNotNil(newState.browserActions[1].maskImageName)

        XCTAssertEqual(newState.searchTerm, nil)
    }

    func test_borderPositionChangedAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                addressBorderPosition: .bottom,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.borderPositionChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.borderPosition, .bottom)
    }

    func test_toolbarPositionChangedAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                toolbarPosition: .bottom,
                addressBorderPosition: .top,
                displayNavBorder: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.toolbarPositionChanged
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.borderPosition, .top)
    }

    func test_didPasteSearchTermAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()
        let searchTerm = "mozilla"

        let newState = reducer(
            initialState,
            ToolbarAction(
                searchTerm: searchTerm,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didPasteSearchTerm
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.navigationActions.count, 1)
        XCTAssertEqual(newState.navigationActions[0].actionType, .cancelEdit)

        XCTAssertEqual(newState.pageActions.count, 0)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)

        XCTAssertEqual(newState.searchTerm, searchTerm)
        XCTAssertTrue(newState.isEditing)
        XCTAssertTrue(newState.shouldShowKeyboard)
        XCTAssertFalse(newState.shouldSelectSearchTerm)
        XCTAssertFalse(newState.didStartTyping)
        XCTAssertFalse(newState.showQRPageAction)
    }

    func test_didStartEditingUrlAction_onHomepage_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                searchTerm: nil,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didStartEditingUrl
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.navigationActions.count, 1)
        XCTAssertEqual(newState.navigationActions[0].actionType, .cancelEdit)

        XCTAssertEqual(newState.pageActions.count, 1)
        XCTAssertEqual(newState.pageActions[0].actionType, .qrCode)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)

        XCTAssertEqual(newState.searchTerm, nil)
        XCTAssertTrue(newState.isEditing)
        XCTAssertTrue(newState.shouldShowKeyboard)
        XCTAssertTrue(newState.shouldSelectSearchTerm)
        XCTAssertFalse(newState.didStartTyping)
        XCTAssertTrue(newState.showQRPageAction)
    }

    func test_didStartEditingUrlAction_withWebsite_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let urlDidChangeState = loadWebsiteAction(state: initialState, reducer: reducer)
        let newState = reducer(
            urlDidChangeState,
            ToolbarAction(
                searchTerm: nil,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didStartEditingUrl
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.navigationActions.count, 1)
        XCTAssertEqual(newState.navigationActions[0].actionType, .cancelEdit)

        XCTAssertEqual(newState.pageActions.count, 0)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)

        XCTAssertEqual(newState.searchTerm, nil)
        XCTAssertTrue(newState.isEditing)
        XCTAssertTrue(newState.shouldShowKeyboard)
        XCTAssertTrue(newState.shouldSelectSearchTerm)
        XCTAssertFalse(newState.didStartTyping)
        XCTAssertFalse(newState.showQRPageAction)
    }

    func test_cancelEditAction_onHomepage_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.cancelEdit
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.navigationActions.count, 0)

        XCTAssertEqual(newState.pageActions.count, 1)
        XCTAssertEqual(newState.pageActions[0].actionType, .qrCode)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)

        XCTAssertEqual(newState.searchTerm, nil)
        XCTAssertFalse(newState.isEditing)
        XCTAssertTrue(newState.shouldShowKeyboard)
        XCTAssertFalse(newState.shouldSelectSearchTerm)
        XCTAssertFalse(newState.didStartTyping)
        XCTAssertTrue(newState.showQRPageAction)
    }

    func test_cancelEditAction_withWebsite_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        let urlDidChangeState = loadWebsiteAction(state: initialState, reducer: reducer)
        let newState = reducer(
            urlDidChangeState,
            ToolbarAction(
                searchTerm: nil,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.cancelEdit
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.navigationActions.count, 0)

        XCTAssertEqual(newState.pageActions.count, 2)
        XCTAssertEqual(newState.pageActions[0].actionType, .share)
        XCTAssertEqual(newState.pageActions[1].actionType, .reload)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)

        XCTAssertEqual(newState.searchTerm, nil)
        XCTAssertFalse(newState.isEditing)
        XCTAssertTrue(newState.shouldShowKeyboard)
        XCTAssertFalse(newState.shouldSelectSearchTerm)
        XCTAssertFalse(newState.didStartTyping)
        XCTAssertFalse(newState.showQRPageAction)
    }

    func test_didSetTextInLocationViewAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()
        let searchTerm = "mozilla"

        let newState = reducer(
            initialState,
            ToolbarAction(
                searchTerm: searchTerm,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didSetTextInLocationView
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.navigationActions.count, 1)
        XCTAssertEqual(newState.navigationActions[0].actionType, .cancelEdit)

        XCTAssertEqual(newState.pageActions.count, 0)

        XCTAssertEqual(newState.browserActions.count, 2)
        XCTAssertEqual(newState.browserActions[0].actionType, .tabs)
        XCTAssertEqual(newState.browserActions[1].actionType, .menu)

        XCTAssertEqual(newState.searchTerm, searchTerm)
        XCTAssertTrue(newState.isEditing)
        XCTAssertFalse(newState.shouldShowKeyboard)
        XCTAssertFalse(newState.shouldSelectSearchTerm)
        XCTAssertFalse(newState.didStartTyping)
        XCTAssertFalse(newState.showQRPageAction)
}

    func test_hideKeyboardAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let reducer = addressBarReducer()

        XCTAssertTrue(initialState.shouldShowKeyboard)

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.hideKeyboard
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertFalse(newState.shouldShowKeyboard)
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
        XCTAssertFalse(newState.shouldSelectSearchTerm)
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
        XCTAssertFalse(newState.shouldSelectSearchTerm)
    }

    func test_didSetSearchTermAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = addressBarReducer()
        let searchTerm = "Search Term"

        let newState = reducer(
            initialState,
            ToolbarAction(
                searchTerm: searchTerm,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didSetSearchTerm
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.searchTerm, searchTerm)
        XCTAssertFalse(newState.didStartTyping)
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
        XCTAssertFalse(newState.shouldSelectSearchTerm)
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

    // MARK: Helper
    func setupAppState(with initialToolbarState: ToolbarState) -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: windowUUID
                        )
                    ),
                    .toolbar(initialToolbarState)
                ]
            )
        )
    }

    func setupStore(with initialToolbarState: ToolbarState) {
        StoreTestUtilityHelper.setupStore(
            with: setupAppState(with: initialToolbarState),
            middlewares: [ToolbarMiddleware().toolbarProvider]
        )
    }

    func initialToolbarState(isShowingNavigationToolbar: Bool) -> ToolbarState {
        let toolbarState = ToolbarState(windowUUID: windowUUID)
        return ToolbarState(
            windowUUID: windowUUID,
            toolbarPosition: toolbarState.toolbarPosition,
            isPrivateMode: toolbarState.isPrivateMode,
            addressToolbar: toolbarState.addressToolbar,
            navigationToolbar: toolbarState.navigationToolbar,
            isShowingNavigationToolbar: isShowingNavigationToolbar,
            isShowingTopTabs: toolbarState.isShowingTopTabs,
            canGoBack: toolbarState.canGoBack,
            canGoForward: toolbarState.canGoForward,
            numberOfTabs: toolbarState.numberOfTabs,
            showMenuWarningBadge: toolbarState.showMenuWarningBadge,
            isNewTabFeatureEnabled: toolbarState.isNewTabFeatureEnabled,
            canShowDataClearanceAction: toolbarState.canShowDataClearanceAction,
            canShowNavigationHint: toolbarState.canShowNavigationHint)
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
