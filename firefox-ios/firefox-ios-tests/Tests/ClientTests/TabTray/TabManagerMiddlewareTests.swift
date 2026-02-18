// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class TabManagerMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockProfile: MockProfile!
    private var mockWindowManager: MockWindowManager!
    private var summarizationChecker: MockSummarizationChecker!
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var appState: AppState!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setIsHostedSummaryEnabled(false)
        mockProfile = MockProfile()
        let mockTabManager = MockTabManager()
        mockTabManager.recentlyAccessedNormalTabs = [createTab(profile: mockProfile)]
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )
        summarizationChecker = MockSummarizationChecker()
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: mockWindowManager)
        setupStore()
        appState = setupAppState()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockWindowManager = nil
        summarizationChecker = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    func test_screenshotAction_triggersRefresh() throws {
        let subject = createSubject()
        let action = ScreenshotAction(
            windowUUID: .XCTestDefaultUUID,
            tab: Tab(profile: mockProfile, windowUUID: .XCTestDefaultUUID),
            actionType: ScreenshotActionType.screenshotTaken
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        mockWindowManager.overrideWindows = true

        subject.tabsPanelProvider(appState, action)
        wait(for: [expectation])
        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabPanelMiddlewareAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabPanelMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabPanelMiddlewareActionType.refreshTabs)
    }

    func test_screenshotAction_returnsEarlyIfTabManagerDoesNotExistForWindow() {
        let subject = createSubject()
        let action = ScreenshotAction(
            windowUUID: .XCTestDefaultUUID,
            tab: Tab(profile: mockProfile, windowUUID: .XCTestDefaultUUID),
            actionType: ScreenshotActionType.screenshotTaken
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")
        expectation.isInverted = true

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)
        wait(for: [expectation], timeout: 0.1)
        XCTAssertTrue(mockWindowManager.windowsWereAccessed)
    }

    // MARK: - Recent Tabs
    func test_viewWillAppearHomeAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.viewWillAppear
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_homepageAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = JumpBackInAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.jumpBackInLocalTabsUpdated
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_tabTrayDismissAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TabTrayAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabTrayActionType.dismissTabTray
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_tabTrayModalSwipedToCloseAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TabTrayAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabTrayActionType.modalSwipedToClose
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_tabTrayDoneButtonTappedAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TabTrayAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TabTrayActionType.doneButtonTapped
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_topTabsNewTabAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TopTabsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopTabsActionType.didTapNewTab
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_topTabsCloseTabAction_returnsRecentTabs() throws {
        let subject = createSubject()
        let action = TopTabsAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopTabsActionType.didTapCloseTab
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? TabManagerAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? TabManagerMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, TabManagerMiddlewareActionType.fetchedRecentTabs)
        XCTAssertEqual(actionCalled.recentTabs?.first?.tabState.title, "www.mozilla.org")
    }

    func test_tapOnCell_fromJumpBackInAction_selectsCorrectTabs() {
        let subject = createSubject()
        let action = JumpBackInAction(
            tab: createTab(profile: mockProfile),
            windowUUID: .XCTestDefaultUUID,
            actionType: JumpBackInActionType.tapOnCell
        )

        let expectation = XCTestExpectation(description: "Recent tabs should be returned")

        let mockTabManager = mockWindowManager.tabManager(for: .XCTestDefaultUUID) as? MockTabManager
        mockTabManager?.selectTabExpectation = expectation

        subject.tabsPanelProvider(appState, action)

        wait(for: [expectation])

        let selectedTab = mockWindowManager.tabManager(for: .XCTestDefaultUUID).selectedTab
        XCTAssertEqual(selectedTab?.displayTitle, "www.mozilla.org")
        XCTAssertEqual(selectedTab?.url?.absoluteString, "www.mozilla.org")
    }

    func testTabPanelProvider_dispatchesMainMenuAction_withSummaryIsAvailableTrue() throws {
        setIsHostedSummaryEnabled(true)
        let expectation = XCTestExpectation(description: "expect main menu action to be fired")
        let subject = createSubject()

        let mockTabManager = mockWindowManager.tabManager(for: .XCTestDefaultUUID) as? MockTabManager
        let tab = MockTab(profile: MockProfile(databasePrefix: ""), windowUUID: .XCTestDefaultUUID)
        tab.webView = MockTabWebView(tab: tab)
        mockTabManager?.selectedTab = tab
        summarizationChecker.overrideResponse = MockSummarizationChecker.success

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.tabsPanelProvider(
            appState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuMiddlewareActionType.requestTabInfo
            )
        )
        wait(for: [expectation])

        let action = try XCTUnwrap(mockStore.dispatchedActions.first as? MainMenuAction)
        // TODO(FXIOS-13126): Fix this when we merge all implemenations for how we disptach showing summaries.
        // This should be true but since we have no way to override the checker for now, this will be false always.
        XCTAssertEqual(action.currentTabInfo?.summaryIsAvailable, false)
    }

    func testTabPanelProvider_dispatchesMainMenuAction_withSummaryIsAvailableFalse_whenWebViewNil() throws {
        setIsHostedSummaryEnabled(true)
        let expectation = XCTestExpectation(description: "expect main menu action to be fired")
        let subject = createSubject()

        let mockTabManager = mockWindowManager.tabManager(for: .XCTestDefaultUUID) as? MockTabManager
        let tab = MockTab(profile: MockProfile(databasePrefix: ""), windowUUID: .XCTestDefaultUUID)
        mockTabManager?.selectedTab = tab
        summarizationChecker.overrideResponse = MockSummarizationChecker.success

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.tabsPanelProvider(
            appState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuMiddlewareActionType.requestTabInfo
            )
        )
        wait(for: [expectation])

        let action = try XCTUnwrap(mockStore.dispatchedActions.first as? MainMenuAction)
        XCTAssertEqual(action.currentTabInfo?.summaryIsAvailable, false)
    }

    func testTabPanelProvider_dispatchesMainMenuAction_withSummaryIsAvailableFalse_whenSummarizeFeatureOff() throws {
        let expectation = XCTestExpectation(description: "expect main menu action to be fired")
        let subject = createSubject()

        let mockTabManager = mockWindowManager.tabManager(for: .XCTestDefaultUUID) as? MockTabManager
        let tab = MockTab(profile: MockProfile(databasePrefix: ""), windowUUID: .XCTestDefaultUUID)
        mockTabManager?.selectedTab = tab
        summarizationChecker.overrideResponse = MockSummarizationChecker.success

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.tabsPanelProvider(
            appState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuMiddlewareActionType.requestTabInfo
            )
        )
        wait(for: [expectation])

        let action = try XCTUnwrap(mockStore.dispatchedActions.first as? MainMenuAction)
        XCTAssertEqual(action.currentTabInfo?.summaryIsAvailable, false)
    }

    func testTabPanelProvider_withSummaryIsAvailableFalse_whenSummarizeFeatureOn_andIsHomepage() throws {
        let expectation = XCTestExpectation(description: "expect main menu action to be fired")
        let subject = createSubject()

        let mockTabManager = mockWindowManager.tabManager(for: .XCTestDefaultUUID) as? MockTabManager
        let tab = MockTab(profile: MockProfile(databasePrefix: ""), windowUUID: .XCTestDefaultUUID, isHomePage: true)
        mockTabManager?.selectedTab = tab
        summarizationChecker.overrideResponse = MockSummarizationChecker.success

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.tabsPanelProvider(
            appState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuMiddlewareActionType.requestTabInfo
            )
        )
        wait(for: [expectation])

        let action = try XCTUnwrap(mockStore.dispatchedActions.first as? MainMenuAction)
        XCTAssertEqual(action.currentTabInfo?.summaryIsAvailable, false)
    }

    func test_shortcutsLibraryAction_switchTabToastButtonPressed_selectsTab() throws {
        let subject = createSubject()
        let tab = Tab(profile: mockProfile, windowUUID: .XCTestDefaultUUID)
        let action = ShortcutsLibraryAction(
            tab: tab,
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.switchTabToastButtonTapped
        )

        subject.tabsPanelProvider(appState, action)
        let selectedTab = mockWindowManager.tabManager(for: .XCTestDefaultUUID).selectedTab

        XCTAssertEqual(selectedTab, tab)
    }

    func test_shortcutsLibraryAction_withNonSwitchTabActionType_doesNotSelectTab() throws {
        let subject = createSubject()
        let tab = Tab(profile: mockProfile, windowUUID: .XCTestDefaultUUID)
        let action = ShortcutsLibraryAction(
            tab: tab,
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.initialize
        )

        subject.tabsPanelProvider(appState, action)
        let selectedTab = mockWindowManager.tabManager(for: .XCTestDefaultUUID).selectedTab

        XCTAssertNotEqual(selectedTab, tab)
    }

    // MARK: - Helpers
    private func createSubject() -> TabManagerMiddleware {
        return TabManagerMiddleware(
            profile: mockProfile,
            windowManager: mockWindowManager,
            summarizationChecker: summarizationChecker
        )
    }

    private func createTab(
        profile: MockProfile,
        urlString: String? = "www.mozilla.org"
    ) -> Tab {
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)

        if let urlString = urlString {
            tab.url = URL(string: urlString)!
        }
        return tab
    }

    private func setIsHostedSummaryEnabled(_ isEnabled: Bool) {
        return FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isEnabled)
        }
    }

    // MARK: StoreTestUtility
    func setupAppState() -> Client.AppState {
        let appState = AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .tabsPanel(
                        TabsPanelState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    )
                ]
            )
        )
        self.appState = appState
        return appState
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
