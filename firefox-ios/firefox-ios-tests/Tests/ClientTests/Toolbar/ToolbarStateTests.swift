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
        XCTAssertTrue(initialState.shouldAnimate)
    }

    func test_didLoadToolbarsAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                toolbarPosition: .top,
                addressBorderPosition: .bottom,
                displayNavBorder: true,
                isNewTabFeatureEnabled: false,
                canShowDataClearanceAction: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didLoadToolbars)
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertEqual(newState.toolbarPosition, .top)
        XCTAssertFalse(newState.isPrivateMode)
        XCTAssertTrue(newState.isShowingNavigationToolbar)
        XCTAssertFalse(newState.isShowingTopTabs)
        XCTAssertFalse(newState.canGoBack)
        XCTAssertFalse(newState.canGoForward)
        XCTAssertEqual(newState.numberOfTabs, 1)
        XCTAssertFalse(newState.showMenuWarningBadge)
        XCTAssertFalse(newState.isNewTabFeatureEnabled)
        XCTAssertFalse(newState.canShowDataClearanceAction)
        XCTAssertFalse(newState.canShowNavigationHint)
    }

    func test_borderPositionChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                addressBorderPosition: .top,
                displayNavBorder: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.borderPositionChanged)
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_urlDidChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = loadWebsiteAction(state: initialState, reducer: reducer)

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertFalse(newState.isPrivateMode)
        XCTAssertTrue(newState.isShowingNavigationToolbar)
        XCTAssertTrue(newState.canGoBack)
        XCTAssertFalse(newState.canGoForward)
    }

    func test_didSetTextInLocationViewAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                searchTerm: "text",
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didSetTextInLocationView)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_didPasteSearchTermAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                searchTerm: "text",
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didPasteSearchTerm)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_didStartEditingUrlAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didStartEditingUrl)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_cancelEditAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.cancelEdit)
        )

        XCTAssertEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_cancelEditOnHomepageAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.cancelEditOnHomepage)
        )

        XCTAssertEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_hideKeyboardAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.hideKeyboard)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_websiteLoadingStateDidChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                isLoading: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.websiteLoadingStateDidChange)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_searchEngineDidChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.searchEngineDidChange)
        )

        XCTAssertEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_clearSearchAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.clearSearch)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_didDeleteSearchTermAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didDeleteSearchTerm)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_didEnterSearchTermAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didEnterSearchTerm)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_didSetSearchTermAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                searchTerm: "text",
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didSetSearchTerm)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_didStartTypingAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didStartTyping)
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_animationStateChanged_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                shouldAnimate: false,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.animationStateChanged)
        )

        XCTAssertNotEqual(newState.shouldAnimate, initialState.shouldAnimate)
        XCTAssertFalse(newState.shouldAnimate)
    }

    func test_showMenuWarningBadgeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                showMenuWarningBadge: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.showMenuWarningBadge
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertTrue(newState.showMenuWarningBadge)
    }

    func test_numberOfTabsChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

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
        XCTAssertEqual(newState.numberOfTabs, 2)
    }

    func test_toolbarPositionChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

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
        XCTAssertEqual(newState.toolbarPosition, .top)
    }

    func test_readerModeStateChangedAction_onHomepage_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                readerModeState: .available,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.readerModeStateChanged
            )
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_backForwardButtonStateChangedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

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
        XCTAssertTrue(newState.canGoBack)
        XCTAssertFalse(newState.canGoForward)
    }

    func test_traitCollectionDidChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                isShowingNavigationToolbar: false,
                isShowingTopTabs: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.traitCollectionDidChange
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertFalse(newState.isShowingNavigationToolbar)
        XCTAssertTrue(newState.isShowingTopTabs)
    }

    func test_navigationButtonDoubleTappedAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.navigationButtonDoubleTapped
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertTrue(newState.canShowNavigationHint)
    }

    func test_navigationHintFinishedPresentingAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            ToolbarAction(
                windowUUID: windowUUID,
                actionType: ToolbarActionType.navigationHintFinishedPresenting
            )
        )

        XCTAssertEqual(newState.windowUUID, windowUUID)
        XCTAssertFalse(newState.canShowNavigationHint)
    }

    func test_didTapSearchEngineAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()
        let searchEngineModel = SearchEngineModel(
            name: "Google",
            image: UIImage(named: StandardImageIdentifiers.ExtraSmall.chevronDown)!)

        let newState = reducer(
            initialState,
            SearchEngineSelectionAction(
                windowUUID: self.windowUUID,
                actionType: SearchEngineSelectionActionType.didTapSearchEngine,
                selectedSearchEngine: searchEngineModel
            )
        )

        XCTAssertNotEqual(newState.addressToolbar, initialState.addressToolbar)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    func test_urlDidChangeStateAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

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

        XCTAssertTrue(newState.shouldAnimate)
    }

    func test_didClearAlternativeSearchEngineAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = toolbarReducer()

        let newState = reducer(
            initialState,
            SearchEngineSelectionAction(
                windowUUID: self.windowUUID,
                actionType: SearchEngineSelectionMiddlewareActionType.didClearAlternativeSearchEngine
            )
        )

        XCTAssertNil(newState.addressToolbar.alternativeSearchEngine)
        XCTAssertEqual(newState.navigationToolbar, initialState.navigationToolbar)
    }

    // MARK: - Private
    private func createSubject() -> ToolbarState {
        return ToolbarState(windowUUID: windowUUID)
    }

    private func toolbarReducer() -> Reducer<ToolbarState> {
        return ToolbarState.reducer
    }

    private func loadWebsiteAction(state: ToolbarState, reducer: Reducer<ToolbarState>) -> ToolbarState {
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
