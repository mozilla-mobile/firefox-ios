// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import SummarizeKit

@testable import Client

final class BrowserViewControllerStateTests: XCTestCase, StoreTestUtility {
    let storeUtilityHelper = StoreTestUtilityHelper()

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    func testAddNewTabAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigateTo)

        let action = getAction(for: .addNewTab)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .newTab)
    }

    func testShowNewTabLongpPressActions() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.displayView)

        let action = getAction(for: .showNewTabLongPressActions)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.displayView, .newTabLongPressActions)
    }

    func testClearDataAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.displayView)

        let action = getAction(for: .clearData)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.displayView, .dataClearance)
    }

    func testShowPasswordGeneratorAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()
        let mockEvaluator = MockPasswordGeneratorScriptEvaluator()
        let frameContext = PasswordGeneratorFrameContext(origin: "https://foo.com",
                                                         host: "foo.com",
                                                         scriptEvaluator: mockEvaluator,
                                                         frameInfo: nil)

        XCTAssertNil(initialState.displayView)

        let action = GeneralBrowserAction(frameContext: frameContext,
                                          windowUUID: .XCTestDefaultUUID,
                                          actionType: GeneralBrowserActionType.showPasswordGenerator)
        let newState = reducer(initialState, action)
        let displayView = newState.displayView!
        let desiredDisplayView =
        BrowserViewControllerState.DisplayType.passwordGenerator

        XCTAssertEqual(displayView, desiredDisplayView)
        XCTAssertNotNil(newState.frameContext)
    }

    func testReloadWebsiteAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigateTo)

        let action = getAction(for: .reloadWebsite)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .reload)
    }

    func testShowSummarizerAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        let action = getAction(for: .showSummarizer)
        let newState = reducer(initialState, action)

        guard case .summarizer = newState.displayView else {
            return XCTFail("Expected .summarizer")
        }
    }

    // MARK: - Navigation Browser Action
    func test_tapOnCell_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = getNavigationBrowserAction(for: .tapOnCell, destination: .link, url: url)
        let newState = reducer(initialState, action)

        let destination = newState.navigationDestination?.destination
        switch destination {
        case .link:
            break
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(newState.navigationDestination?.url?.absoluteString, "www.example.com")
    }

    func test_tapOnLink_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = getNavigationBrowserAction(for: .tapOnLink, destination: .link, url: url)
        let newState = reducer(initialState, action)

        let destination = newState.navigationDestination?.destination
        switch destination {
        case .link:
            break
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(newState.navigationDestination?.url?.absoluteString, "www.example.com")
    }

    func test_tapOnShareSheet_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let shareSheetConfiguration = ShareSheetConfiguration(
            shareType: .site(url: url),
            shareMessage: nil,
            sourceView: UIView(),
            sourceRect: nil,
            toastContainer: UIView(),
            popoverArrowDirection: [.up]
        )
        let action = getNavigationBrowserAction(
            for: .tapOnShareSheet,
            destination: .shareSheet(shareSheetConfiguration)
        )
        let newState = reducer(initialState, action)

        let destination = newState.navigationDestination?.destination
        switch destination {
        case .shareSheet(let configuration):
            switch configuration.shareType {
            case .site(let url):
                XCTAssertEqual(url, try XCTUnwrap(URL(string: "www.example.com")))
            default:
                XCTFail("shareType is not the right type")
            }
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(newState.navigationDestination?.url, nil)
    }

    func test_longPressOnCell_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = getNavigationBrowserAction(for: .longPressOnCell, destination: .link, url: url)
        let newState = reducer(initialState, action)

        let destination = newState.navigationDestination?.destination
        switch destination {
        case .link:
            break
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(newState.navigationDestination?.url?.absoluteString, "www.example.com")
    }

    func test_tapOnOpenInNewTab_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.newTab, url: url, isPrivate: false, selectNewTab: false),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnOpenInNewTab
        )
        let newState = reducer(initialState, action)

        let navigationDestination = try XCTUnwrap(newState.navigationDestination)
        switch navigationDestination.destination {
        case .newTab:
            break
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(navigationDestination.url?.absoluteString, "www.example.com")
        XCTAssertFalse(navigationDestination.isPrivate ?? true)
        XCTAssertFalse(navigationDestination.selectNewTab ?? true)
    }

    func test_tapOnOpenInNewTab_forPrivateTab_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.newTab, url: url, isPrivate: true, selectNewTab: true),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnOpenInNewTab
        )
        let newState = reducer(initialState, action)

        let navigationDestination = try XCTUnwrap(newState.navigationDestination)
        switch navigationDestination.destination {
        case .newTab:
            break
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(navigationDestination.url?.absoluteString, "www.example.com")
        XCTAssertTrue(navigationDestination.isPrivate ?? false)
        XCTAssertTrue(navigationDestination.selectNewTab ?? false)
    }

    func test_tapOnSettingsSection_navigationBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = getNavigationBrowserAction(for: .tapOnSettingsSection, destination: .settings(.topSites))
        let newState = reducer(initialState, action)

        let destination = newState.navigationDestination?.destination
        switch destination {
        case .settings(let section):
            XCTAssertEqual(section, .topSites)
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(newState.navigationDestination?.url, nil)
    }

    // MARK: StartAtHomeAction

    func test_shouldStartAtHome_withStartAtHomeAction_returnsTrue() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertFalse(initialState.shouldStartAtHome)

        let action = StartAtHomeAction(
            shouldStartAtHome: true,
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted
        )
        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.shouldStartAtHome)
    }

    func test_shouldStartAtHome_withStartAtHomeAction_returnsFalse() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertFalse(initialState.shouldStartAtHome)

        let action = StartAtHomeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted
        )
        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.shouldStartAtHome)
    }

    // MARK: - Summarizer
    func test_configuredSummarizer_summarizerAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        let action = SummarizeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: SummarizeMiddlewareActionType.configuredSummarizer,
            summarizerConfig: SummarizerConfig(instructions: "Test instructions", options: [:])
        )
        let newState = reducer(initialState, action)
        let expectedConfig = SummarizerConfig(instructions: "Test instructions", options: [:])
        let destination = newState.navigationDestination?.destination
        switch destination {
        case .summarizer(let config):
            XCTAssertEqual(config, expectedConfig)
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(newState.navigationDestination?.url, nil)
    }

    // MARK: - Zero Search State

    func test_tapOnHomepageSearchBar_navigationBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = getNavigationBrowserAction(for: .tapOnHomepageSearchBar, destination: .homepageZeroSearch)
        let newState = reducer(initialState, action)
        let destination = newState.navigationDestination?.destination
        switch destination {
        case .homepageZeroSearch:
            break
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(newState.navigationDestination?.url, nil)
    }

    func test_didTapButtonToolbarAction_withHomepageSearch_andSearchButtonType_navigateToZeroSearch() {
        setupStoreForSearchBar()
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = ToolbarMiddlewareAction(
            buttonType: .search,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )
        let newState = reducer(initialState, action)
        let destination = newState.navigationDestination?.destination
        switch destination {
        case .homepageZeroSearch:
            break
        default:
            XCTFail("destination is not the right type")
        }

        XCTAssertEqual(newState.navigationDestination?.url, nil)
    }

    func test_didTapButtonToolbarAction_withHomepageSearch_andNoButtonType_navigateToZeroSearch() {
        setupStoreForSearchBar()
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = ToolbarMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )
        let newState = reducer(initialState, action)

        XCTAssertNil(newState.navigationDestination)
    }

    func test_didTapButtonToolbarAction_withoutHomepageSearch_andSearchButtonType_doesNotNavigateToZeroSearch() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = ToolbarMiddlewareAction(
            buttonType: .search,
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )
        let newState = reducer(initialState, action)

        XCTAssertNil(newState.navigationDestination)
    }

    func test_didTapButtonToolbarAction_withoutHomepageSearch_andNoButtonType_doesNotNavigateToZeroSearch() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = ToolbarMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton
        )
        let newState = reducer(initialState, action)

        XCTAssertNil(newState.navigationDestination)
    }

    // MARK: - Shortcuts Library

    func test_tapOnShortcutsShowAllButton_navigationBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = getNavigationBrowserAction(for: .tapOnShortcutsShowAllButton, destination: .shortcutsLibrary)
        let newState = reducer(initialState, action)

        let destination = newState.navigationDestination?.destination
        switch destination {
        case .shortcutsLibrary:
            break
        default:
            XCTFail("destination is not the right type")
        }
    }

    // MARK: - Stories Feed

    func test_tapOnAllStoriesButton_navigationBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = getNavigationBrowserAction(for: .tapOnAllStoriesButton, destination: .storiesFeed)
        let newState = reducer(initialState, action)

        let destination = newState.navigationDestination?.destination
        switch destination {
        case .storiesFeed:
            break
        default:
            XCTFail("destination is not the right type")
        }
    }

    // MARK: - Privacy Notice Link

    func test_tapOnPrivacyNoticeLink_navigationBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        guard let url = URL(string: "https://www.mozilla.com") else { return }

        let action = getNavigationBrowserAction(for: .tapOnPrivacyNoticeLink, destination: .privacyNoticeLink(url))
        let newState = reducer(initialState, action)

        let destination = newState.navigationDestination?.destination
        switch destination {
        case .privacyNoticeLink:
            break
        default:
            XCTFail("destination is not the right type")
        }
    }

    // MARK: - Private
    private func createSubject() -> BrowserViewControllerState {
        return BrowserViewControllerState(windowUUID: .XCTestDefaultUUID)
    }

    private func browserViewControllerReducer() -> Reducer<BrowserViewControllerState> {
        return BrowserViewControllerState.reducer
    }

    private func getAction(for actionType: GeneralBrowserActionType) -> GeneralBrowserAction {
        return  GeneralBrowserAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func getNavigationBrowserAction(
        for actionType: NavigationBrowserActionType,
        destination: BrowserNavigationDestination,
        url: URL? = nil
    ) -> NavigationBrowserAction {
        return NavigationBrowserAction(
            navigationDestination: NavigationDestination(destination, url: url),
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }

    private func getPrivateModeAction(isPrivate: Bool, for actionType: PrivateModeActionType) -> PrivateModeAction {
        return  PrivateModeAction(isPrivate: isPrivate, windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    func getGeneralBrowserAction(selectedTabURL: URL? = nil,
                                 isNativeErrorPage: Bool? = nil,
                                 for actionType: GeneralBrowserActionType) -> GeneralBrowserAction {
        return  GeneralBrowserAction(selectedTabURL: selectedTabURL,
                                     isNativeErrorPage: isNativeErrorPage,
                                     windowUUID: .XCTestDefaultUUID,
                                     actionType: actionType)
    }

    /// We need to set up the state for the homepage search bar in order to test method that relies on this state
    func setupStoreForSearchBar() {
        let initialHomepageState = HomepageState
            .reducer(
                HomepageState(windowUUID: .XCTestDefaultUUID),
                HomepageAction(
                    windowUUID: .XCTestDefaultUUID,
                    actionType: HomepageActionType.initialize
                )
            )
        let newHomepageState = HomepageState
            .reducer(
                initialHomepageState,
                HomepageAction(
                    isSearchBarEnabled: true,
                    windowUUID: .XCTestDefaultUUID,
                    actionType: HomepageMiddlewareActionType.configuredSearchBar
                )
            )

        StoreTestUtilityHelper.setupStore(
            with: AppState(
                activeScreens: ActiveScreensState(
                    screens: [
                        .browserViewController(
                            BrowserViewControllerState(
                                windowUUID: .XCTestDefaultUUID
                            )
                        ),
                        .homepage(
                            newHomepageState
                        )
                    ]
                )
            ),
            middlewares: []
        )
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
                    )
                ]
            )
        )
    }

    func setupStore() {
        StoreTestUtilityHelper.setupStore(
            with: setupAppState(),
            middlewares: []
        )
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
